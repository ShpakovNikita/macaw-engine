#pragma once

#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

struct SDL_Window;
struct SDL_Renderer;

namespace mcw
{
    class MetalContext
    {
    public:
        static MetalContext& Get();
        
        void Init(SDL_Window& window);
        void Cleanup();
        
        CAMetalLayer *swapchain;
        id<MTLDevice> device;
        id<MTLCommandQueue> queue;
    
    private:
        SDL_Renderer *renderer;
    };
}
