#include "Render/MetalContext.hpp"

#include "Render/TextureManager.hpp"

#include <SDL.h>

mcw::MetalContext::MetalContext() = default;
mcw::MetalContext::~MetalContext() = default;

mcw::MetalContext& mcw::MetalContext::Get()
{
    static MetalContext context;
    return context;
}

void mcw::MetalContext::Init(SDL_Window& window)
{
    textureManager = std::make_unique<TextureManager>();
    
    renderer = SDL_CreateRenderer(&window, -1, SDL_RENDERER_PRESENTVSYNC);

    swapchain = (__bridge CAMetalLayer *)SDL_RenderGetMetalLayer(renderer);
    device = swapchain.device;
    queue = [device newCommandQueue];
}

void mcw::MetalContext::Cleanup()
{
    SDL_DestroyRenderer(renderer);
    
    textureManager = nullptr;
}

const std::string mcw::MetalContext::GetAssetsPath() const
{
#if defined(ASSETS_DIR)
    return ASSETS_DIR;
#else
    return "./../assets/";
#endif
}

