#include "Core/Engine.hpp"

#import "Foundation/Foundation.h"

#include "Render/MetalContext.hpp"
#include "Common/AAPLVertex.hpp"

#include <chrono>
#include <algorithm>
#include <SDL.h>

mcw::Engine::Engine(const mcw::ImmutableConfig& aConfig)
    : config(aConfig)
{}

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

void mcw::Engine::CreateVertexBuffer()
{
    const std::vector<AAPLVertex> vertexData =
    {
       { {  250,  -250 }, { 1, 0, 0, 1 } },
       { { -250,  -250 }, { 0, 1, 0, 1 } },
       { {    0,   250 }, { 0, 0, 1, 1 } },
    };
    
    vertexBuffer = [MetalContext::Get().device newBufferWithBytes:vertexData.data()
                           length:sizeof(vertexData[0]) * vertexData.size()
                           options:MTLResourceOptionCPUCacheModeDefault];
}

void mcw::Engine::CreateSimplePipeline()
{
    NSError *error;
    
    id<MTLLibrary> defaultLibrary = [MetalContext::Get().device newDefaultLibrary];

    id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];
    id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader"];
    
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.label = @"Simple Pipeline";
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    pipelineStateDescriptor.fragmentFunction = fragmentFunction;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = MetalContext::Get().swapchain.pixelFormat;
    
    renderPipelineState = [MetalContext::Get().device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
    error:&error];
    
    NSCAssert(renderPipelineState, @"Failed to create pipeline state: %@", error);
}

const std::string mcw::Engine::GetAssetsPath() const
{
#if defined(ASSETS_DIR)
    return ASSETS_DIR;
#else
    return "./../assets/";
#endif
}

void mcw::Engine::Prepare()
{
    CreateVertexBuffer();
    CreateSimplePipeline();
}

void mcw::Engine::MainTick(float dt)
{
    @autoreleasepool
    {
        const std::vector<AAPLVertex> vertexData =
        {
           { {  250,  -250 }, { 1, 0, 0, 1 } },
           { { -250,  -250 }, { 0, 1, 0, 1 } },
           { {    0,   250 }, { 0, 0, 1, 1 } },
        };
        
        const vector_uint2 viewportSize = { config.width, config.height };
        
        static MTLClearColor color = MTLClearColorMake(0, 0, 0, 1);
        
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
        id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:pass];
        
        id<MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:pass];
        renderEncoder.label = @"MyRenderEncoder";

        MTLViewport viewport = {0.0, 0.0, static_cast<double>(viewportSize.x), static_cast<double>(viewportSize.y), 0.0, 1.0 };
        [renderEncoder setViewport:viewport];
        
        [renderEncoder setRenderPipelineState:renderPipelineState];

        [renderEncoder setVertexBytes:vertexData.data()
                               length:sizeof(AAPLVertex) * vertexData.size()
                              atIndex:AAPLVertexInputIndexVertices];
        
        [renderEncoder setVertexBytes:&viewportSize
                               length:sizeof(viewportSize)
                              atIndex:AAPLVertexInputIndexViewportSize];

        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                          vertexStart:0
                          vertexCount:3];
        
        [encoder endEncoding];
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
