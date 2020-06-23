#include "Core/Engine.hpp"

#import "Foundation/Foundation.h"

#include "Render/Model/Scene.hpp"
#include "Render/MetalContext.hpp"

#include <chrono>
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
        const float expectedFrameTime = 1000.0f / 60.0f;
        std::chrono::time_point<std::chrono::steady_clock> newCurrentTime = std::chrono::steady_clock::now();
        float frameDeltaSec = std::chrono::duration_cast<std::chrono::microseconds>(newCurrentTime - currentTime).count() / 1000.0f / 1000.0f;

        // Breakpoint case
        if (frameDeltaSec >= 1.0f)
        {
            frameDeltaSec = std::clamp(frameDeltaSec, 0.0f, expectedFrameTime);
        }
        
        currentTime = newCurrentTime;
        
        MainTick(frameDeltaSec);
    }

    Cleanup();
}

void mcw::Engine::Init()
{
    // Init SDL
    SDL_SetHint(SDL_HINT_RENDER_DRIVER, "metal");
    SDL_InitSubSystem(SDL_INIT_VIDEO);
    window = SDL_CreateWindow("SDL Metal", -1, -1, config.width, config.height, SDL_WINDOW_ALLOW_HIGHDPI);
    
    MetalContext::Get().Init(*window);
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
    
    renderPipelineState = [MetalContext::Get().device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
    error:&error];
    
    NSCAssert(renderPipelineState, @"Failed to create pipeline state: %@", error);
}

void mcw::Engine::Prepare()
{
    CreateSimplePipeline();
    LoadModel(MetalContext::Get().GetAssetsPath() + "models/glTF-Sample-Models/2.0/MetalRoughSpheres/glTF/MetalRoughSpheres.gltf");
}

void mcw::Engine::LoadModel(const std::string& filepath)
{
    scene = std::make_unique<Scene>();
    scene->LoadFromFile(filepath, 0.08f);
}

void mcw::Engine::MainTick(float dt)
{
    static MTLClearColor color = MTLClearColorMake(0, 0, 0, 1);
    
    @autoreleasepool
    {
        const vector_uint2 viewportSize = { config.width, config.height };
        
        SDL_Event e;
        while (SDL_PollEvent(&e) != 0) {
            switch (e.type) {
                case SDL_QUIT: quit = true; break;
            }
        }

        id<CAMetalDrawable> surface = [MetalContext::Get().swapchain nextDrawable];
        
        color.red = (color.red > 1.0) ? 0 : color.red + dt;

        MTLRenderPassDescriptor *pass = [MTLRenderPassDescriptor renderPassDescriptor];
        pass.colorAttachments[0].clearColor = color;
        pass.colorAttachments[0].loadAction  = MTLLoadActionClear;
        pass.colorAttachments[0].storeAction = MTLStoreActionStore;
        pass.colorAttachments[0].texture = surface.texture;

        id<MTLCommandBuffer> commandBuffer = [MetalContext::Get().queue commandBuffer];
        
        {
            id<MTLRenderCommandEncoder> renderEncoder =
            [commandBuffer renderCommandEncoderWithDescriptor:pass];
            renderEncoder.label = @"MyRenderEncoder";

            MTLViewport viewport = {0.0, 0.0, static_cast<double>(viewportSize.x * 2.0), static_cast<double>(viewportSize.y * 2.0), 0.0, 1.0 };
            [renderEncoder setViewport:viewport];
            
            [renderEncoder setRenderPipelineState:renderPipelineState];

            if (scene)
            {
                scene->Draw(renderEncoder);
            }
            
            [renderEncoder endEncoding];
        }
        
        [commandBuffer presentDrawable:surface];
        [commandBuffer commit];
    }
}

void mcw::Engine::Cleanup()
{
    MetalContext::Get().Cleanup();
    
    SDL_DestroyWindow(window);
    SDL_Quit();
}
