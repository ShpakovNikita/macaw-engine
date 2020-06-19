#include "Render/MetalContext.hpp"

#include <SDL.h>

mcw::MetalContext& mcw::MetalContext::Get()
{
    static MetalContext context;
    return context;
}

void mcw::MetalContext::Init(SDL_Window& window)
{
    renderer = SDL_CreateRenderer(&window, -1, SDL_RENDERER_PRESENTVSYNC);

    swapchain = (__bridge CAMetalLayer *)SDL_RenderGetMetalLayer(renderer);
    device = swapchain.device;
    queue = [device newCommandQueue];
}

void mcw::MetalContext::Cleanup()
{
    SDL_DestroyRenderer(renderer);
}
