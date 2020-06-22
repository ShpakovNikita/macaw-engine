#pragma once

#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

#include <string>
#include <memory>

struct SDL_Window;
struct SDL_Renderer;

namespace mcw
{
    class TextureManager;

    class MetalContext
    {
    public:
        static MetalContext& Get();
        
        MetalContext();
        ~MetalContext();
        
        void Init(SDL_Window& window);
        void Cleanup();
        
        const std::string GetAssetsPath() const;
        
        CAMetalLayer *swapchain;
        id<MTLDevice> device;
        id<MTLCommandQueue> queue;
        
        std::unique_ptr<TextureManager> textureManager;
    
    private:
        SDL_Renderer *renderer;
    };
}
