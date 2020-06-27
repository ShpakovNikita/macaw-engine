#include "Render/EnvironmentProbe.hpp"

#include "Core/EngineContext.hpp"

#include "Render/MetalContext.hpp"
#include "Render/Texture.hpp"

#include <memory>
#include <vector>

mcw::EnvironmentProbe::EnvironmentProbe()
{
    CreateTexture();
}

mcw::EnvironmentProbe::~EnvironmentProbe()
{
    
}

void mcw::EnvironmentProbe::CreateTexture()
{
    std::vector<std::unique_ptr<Texture>> textures;
    textures.reserve(6);
    textures.emplace_back(std::make_unique<Texture>())->LoadFromFile(EngineContext::Get().GetAssetsPath() + "textures/Storforsen4/posx.jpg");
    textures.emplace_back(std::make_unique<Texture>())->LoadFromFile(EngineContext::Get().GetAssetsPath() + "textures/Storforsen4/negx.jpg");
    textures.emplace_back(std::make_unique<Texture>())->LoadFromFile(EngineContext::Get().GetAssetsPath() + "textures/Storforsen4/posy.jpg");
    textures.emplace_back(std::make_unique<Texture>())->LoadFromFile(EngineContext::Get().GetAssetsPath() + "textures/Storforsen4/negy.jpg");
    textures.emplace_back(std::make_unique<Texture>())->LoadFromFile(EngineContext::Get().GetAssetsPath() + "textures/Storforsen4/posz.jpg");
    textures.emplace_back(std::make_unique<Texture>())->LoadFromFile(EngineContext::Get().GetAssetsPath() + "textures/Storforsen4/negz.jpg");
    
    const CGFloat cubeSize = textures[0]->width;
    
    const NSUInteger bytesPerPixel = 4;
    const NSUInteger bytesPerRow = bytesPerPixel * cubeSize;
    const NSUInteger bytesPerImage = bytesPerRow * cubeSize;

    MTLRegion region = MTLRegionMake2D(0, 0, cubeSize, cubeSize);
    
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor textureCubeDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm size:cubeSize mipmapped:NO];
    
    metalTexture = [MetalContext::Get().device newTextureWithDescriptor:textureDescriptor];

    for (size_t slice = 0; slice < 6; ++slice)
    {
        const void *imageData = textures[slice]->buffer;
        
        [metalTexture replaceRegion:region
                   mipmapLevel:0
                         slice:slice
                     withBytes:imageData
                   bytesPerRow:bytesPerRow
                 bytesPerImage:bytesPerImage];
    }
    
    MTLSamplerDescriptor *samplerDescriptor = [MTLSamplerDescriptor new];
    samplerDescriptor.minFilter = MTLSamplerMinMagFilterNearest;
    samplerDescriptor.magFilter = MTLSamplerMinMagFilterLinear;
    
    samplerState = [MetalContext::Get().device newSamplerStateWithDescriptor:samplerDescriptor];
}
