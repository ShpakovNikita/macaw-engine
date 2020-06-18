#include "Core/Engine.hpp"

#import "Foundation/Foundation.h"

#include <chrono>
#include <algorithm>
#include <SDL.h>

mcw::Engine::Engine(const mcw::ImmutableConfig& aConfig)
    : config(aConfig)
{}

void mcw::Engine::Run()
{
    Init();
    
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
    renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_PRESENTVSYNC);

    // Init metal
    swapchain = (__bridge CAMetalLayer *)SDL_RenderGetMetalLayer(renderer);
    device = swapchain.device;
    queue = [device newCommandQueue];
}

void mcw::Engine::MainTick(float dt)
{
    static MTLClearColor color = MTLClearColorMake(0, 0, 0, 1);
    
    SDL_Event e;
    while (SDL_PollEvent(&e) != 0) {
        switch (e.type) {
            case SDL_QUIT: quit = true; break;
        }
    }

    id<CAMetalDrawable> surface = [swapchain nextDrawable];
    
    color.red = (color.red > 1.0) ? 0 : color.red + dt;

    MTLRenderPassDescriptor *pass = [MTLRenderPassDescriptor renderPassDescriptor];
    pass.colorAttachments[0].clearColor = color;
    pass.colorAttachments[0].loadAction  = MTLLoadActionClear;
    pass.colorAttachments[0].storeAction = MTLStoreActionStore;
    pass.colorAttachments[0].texture = surface.texture;

    id<MTLCommandBuffer> buffer = [queue commandBuffer];
    id<MTLRenderCommandEncoder> encoder = [buffer renderCommandEncoderWithDescriptor:pass];
    [encoder endEncoding];
    [buffer presentDrawable:surface];
    [buffer commit];
}

void mcw::Engine::Cleanup()
{
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
}
