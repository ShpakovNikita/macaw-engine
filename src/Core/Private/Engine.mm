#include "Core/Engine.hpp"

#import "Foundation/Foundation.h"

#include "Common/Textures.hpp"

#include "Core/EngineContext.hpp"
#include "Core/Window.hpp"

#include "Render/Model/Scene.hpp"
#include "Render/MetalContext.hpp"
#include "Render/Camera.hpp"
#include "Render/Texture.hpp"
#include "Render/EnvironmentProbe.hpp"

#include <chrono>
#include <thread>
#include <algorithm>
#include <SDL.h>

mcw::Engine::Engine(const mcw::ImmutableConfig& aConfig)
    : config(aConfig)
{}

mcw::Engine::~Engine() = default;

void mcw::Engine::Run()
{
    Init();
    Prepare();
    
    std::chrono::time_point<std::chrono::steady_clock> currentTime = std::chrono::steady_clock::now();
    
    while (!quit) {
        const float expectedFrameTime = 1.0f / 60.0f;
        std::chrono::time_point<std::chrono::steady_clock> newCurrentTime = std::chrono::steady_clock::now();
        float frameDeltaSec = std::chrono::duration_cast<std::chrono::microseconds>(newCurrentTime - currentTime).count() / 1000.0f / 1000.0f;

        // Breakpoint case
        if (frameDeltaSec >= 1.0f)
        {
            frameDeltaSec = std::clamp(frameDeltaSec, 0.0f, expectedFrameTime);
        }
        
        currentTime = newCurrentTime;
        
        MainTick(frameDeltaSec);
        
        const float sleepTime = expectedFrameTime - frameDeltaSec;
        if (sleepTime > 0.0f)
        {
            std::this_thread::sleep_for(std::chrono::microseconds(static_cast<size_t>(sleepTime * 1000.0f * 1000.0f)));
        }
    }

    Cleanup();
}

void mcw::Engine::Init()
{
    // Init SDL
    SDL_SetHint(SDL_HINT_RENDER_DRIVER, "metal");
    SDL_InitSubSystem(SDL_INIT_VIDEO);
    
    EngineContext::Get().Init(config);
    MetalContext::Get().Init(*EngineContext::Get().GetWindow()->GetSDLWindow());
}

void mcw::Engine::CreateSimplePipeline()
{
    NSError *error;
    
    id<MTLLibrary> defaultLibrary = [MetalContext::Get().device newDefaultLibrary];

    id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"VertexShader"];
    id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"FragmentShader"];
    
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.label = @"Simple Pipeline";
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    pipelineStateDescriptor.fragmentFunction = fragmentFunction;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = MetalContext::Get().swapchain.pixelFormat;
    pipelineStateDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    
    renderPipelineState = [MetalContext::Get().device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
    error:&error];
    NSCAssert(renderPipelineState, @"Failed to create pipeline state: %@", error);
    
    id<MTLFunction> skyboxVertexFunction = [defaultLibrary newFunctionWithName:@"SkyboxVertexShader"];
    id<MTLFunction> skyboxFragmentFunction = [defaultLibrary newFunctionWithName:@"SkyboxFragmentShader"];
    
    pipelineStateDescriptor.vertexFunction = skyboxVertexFunction;
    pipelineStateDescriptor.fragmentFunction = skyboxFragmentFunction;
    
    skyboxPipelineState = [MetalContext::Get().device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
    error:&error];
    NSCAssert(skyboxPipelineState, @"Failed to create skybox pipeline state: %@", error);
    
    MTLDepthStencilDescriptor *depthDescriptor = [MTLDepthStencilDescriptor new];
    depthDescriptor.depthCompareFunction = MTLCompareFunctionLessEqual;
    depthDescriptor.depthWriteEnabled = YES;
    depthLessEqual = [MetalContext::Get().device newDepthStencilStateWithDescriptor:depthDescriptor];
    NSCAssert(depthLessEqual, @"Failed to create pipeline state: %@", error);
}

void mcw::Engine::CreateSkybox()
{
    skybox = std::make_unique<EnvironmentProbe>();
    skyboxModel = std::make_unique<Scene>();
    skyboxModel->LoadFromFile(EngineContext::Get().GetAssetsPath() + "models/glTF-Sample-Models/2.0/Cube/glTF/Cube.gltf");
}

void mcw::Engine::Prepare()
{
    CreateSimplePipeline();
    LoadModel(EngineContext::Get().GetAssetsPath() + "models/glTF-Sample-Models/2.0/MetalRoughSpheres/glTF/MetalRoughSpheres.gltf");
    CreateDepthTexture();
    CreateSkybox();
}

void mcw::Engine::CreateDepthTexture()
{
    depthTexture = std::make_unique<Texture>();
    depthTexture->CreateEmpty(config.width, config.height, MTLPixelFormatDepth32Float);
}

void mcw::Engine::LoadModel(const std::string& filepath)
{
    scene = std::make_unique<Scene>();
    scene->LoadFromFile(filepath, 0.08f);
}

void mcw::Engine::MainTick(float dt)
{
    @autoreleasepool
    {
        const vector_uint2 viewportSize = { config.width, config.height };
        
        SDL_Event e;
        while (SDL_PollEvent(&e) != 0) {
            if (scene)
            {
                scene->GetCamera()->PollEvent(e, dt);
            }
            
            switch (e.type) {
                case SDL_QUIT: quit = true; break;
            }
        }
        
        if (scene)
        {
            scene->GetCamera()->UpdateUniformBuffers(dt);
        }

        id<CAMetalDrawable> surface = [MetalContext::Get().swapchain nextDrawable];
        
        MTLRenderPassDescriptor *pass = [MTLRenderPassDescriptor renderPassDescriptor];
        
        pass.depthAttachment.texture      = depthTexture->metalTexture;
        pass.depthAttachment.loadAction   = MTLLoadActionClear;
        pass.depthAttachment.clearDepth   = 1.0;
        pass.depthAttachment.storeAction  = MTLStoreActionStore;
        
        pass.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1);
        pass.colorAttachments[0].loadAction  = MTLLoadActionClear;
        pass.colorAttachments[0].storeAction = MTLStoreActionStore;
        pass.colorAttachments[0].texture = surface.texture;

        id<MTLCommandBuffer> commandBuffer = [MetalContext::Get().queue commandBuffer];
        
        {
            id<MTLRenderCommandEncoder> renderEncoder =
            [commandBuffer renderCommandEncoderWithDescriptor:pass];
            renderEncoder.label = @"MyRenderEncoder";

            MTLViewport viewport = {0.0, 0.0, static_cast<double>(viewportSize.x), static_cast<double>(viewportSize.y), 0.0, 1.0 };
            [renderEncoder setViewport:viewport];

            DrawSkybox(renderEncoder);
            
            if (scene)
            {
                [renderEncoder setRenderPipelineState:renderPipelineState];
                [renderEncoder setDepthStencilState:depthLessEqual];
                
                [renderEncoder setCullMode:MTLCullModeFront];
                
                // best practices for small buffers less than 4 KB
                static_assert(sizeof(CameraUniforms) < 4 * 1024, "Use update buffer instead of setVertexBytes!");
                
                [renderEncoder setVertexBytes:&scene->GetCamera()->cameraUniforms length:sizeof(CameraUniforms) atIndex:BufferIndexCameraUniforms];
                
                scene->Draw(renderEncoder);
            }
            
            [renderEncoder endEncoding];
        }
        
        [commandBuffer presentDrawable:surface];
        [commandBuffer commit];
    }
}

void mcw::Engine::DrawSkybox(id<MTLRenderCommandEncoder> renderEncoder)
{
    if (skyboxModel)
    {
        [renderEncoder setRenderPipelineState:skyboxPipelineState];
        
        [renderEncoder setCullMode:MTLCullModeBack];
        
        // best practices for small buffers less than 4 KB
        static_assert(sizeof(CameraUniforms) < 4 * 1024, "Use update buffer instead of setVertexBytes!");
        
        [renderEncoder setVertexBytes:&scene->GetCamera()->cameraUniforms length:sizeof(CameraUniforms) atIndex:BufferIndexCameraUniforms];
        
        [renderEncoder setFragmentTexture:skybox->metalTexture atIndex:SkyboxTexture];
        [renderEncoder setFragmentSamplerState:skybox->samplerState atIndex:SkyboxSampler];
        
        skyboxModel->Draw(renderEncoder);
    }
}

void mcw::Engine::Cleanup()
{
    MetalContext::Get().Cleanup();
    EngineContext::Get().Cleanup();
    
    SDL_Quit();
}
