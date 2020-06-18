#pragma once

#include "ImmutableConfig.hpp"

#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

struct SDL_Window;
struct SDL_Renderer;

namespace mcw {
    class Engine
    {
    public:
        Engine(const ImmutableConfig& config);
        
        void Run();
    
    private:
        void Init();
        void MainTick(float dt);
        void Cleanup();
        
        bool quit = false;
        
        ImmutableConfig config;
        
        SDL_Window *window;
        SDL_Renderer *renderer;
        
        CAMetalLayer *swapchain;
        id<MTLDevice> device;
        id<MTLCommandQueue> queue;
    };
}
