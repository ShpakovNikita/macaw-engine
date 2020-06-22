#include "Render/Texture.hpp"

#include <filesystem>

#include "Core/Exceptions.hpp"
#include "Render/MetalContext.hpp"

#include "stb_image.h"

namespace STexture
{
    bool IsHDRType(const std::string& filename)
    {
        std::string extension = std::filesystem::path(filename).extension();
        std::transform(extension.begin(), extension.end(), extension.begin(),
                       [](unsigned char c){ return std::tolower(c); });
        
        if (extension == ".hdr")
        {
            return true;
        }
        
        return false;
    }

    template<typename T>
    T* FromRGBToRGBA(const void* data, size_t width, size_t height)
    {
        uint64_t pixelsCount = width * height;
        size_t imageSize = pixelsCount * 4;
        T* rgba = new T[imageSize];
        const T* rgb = static_cast<const T*>(data);
        for (size_t pixel = 0; pixel < pixelsCount; ++pixel)
        {
            for (int32_t j = 0; j < 3; ++j)
            {
                rgba[j] = rgb[j];
            }
            rgba[3] = 0;

            rgba += 4;
            rgb += 3;
        }
        
        return rgba;
    }
}

void mcw::Texture::LoadFromFile(const std::string& filename)
{
    bool isHDR = STexture::IsHDRType(filename);
    
    int imageWidth, imageHeight, nrComponents;
    void* data = nullptr;
    if (isHDR)
    {
        stbi_set_flip_vertically_on_load(true);
        data = stbi_loadf(filename.c_str(), &imageWidth, &imageHeight, &nrComponents, 0);
        stbi_set_flip_vertically_on_load(false);
    }
    else
    {
        data = stbi_load(filename.c_str(), &imageWidth, &imageHeight, &nrComponents, 0);
    }

    if (data)
    {
        width = static_cast<uint32_t>(imageWidth);
        height = static_cast<uint32_t>(imageHeight);
        size_t imageSize = 0;

        if (isHDR)
        {
            imageSize = width * height * 4 * sizeof(float);
            
            if (nrComponents == 3)
            {
                data = STexture::FromRGBToRGBA<float>(data, width, height);
            }
            
            LoadFromBuffer(data, MTLPixelFormatRGBA32Float, width, height);
        }
        else
        {
            imageSize = width * height * 4 * sizeof(unsigned char);
            
            if (nrComponents == 3)
            {
                data = STexture::FromRGBToRGBA<unsigned char>(data, width, height);
            }
            
            LoadFromBuffer(data, MTLPixelFormatRGBA8Unorm, width, height);
        }

        stbi_image_free(data);
    }
    else
    {
        throw AssetLoadingException("Failed to load image! Make sure that it has RGBE or RGB format!");
    }
}

void mcw::Texture::LoadFromBuffer(const void* data, MTLPixelFormat imageFormat, size_t width, size_t height, bool convertRGB8ToRGBA8/* = false*/)
{
    const void* buffer = data;
    
    if (convertRGB8ToRGBA8)
    {
        buffer = STexture::FromRGBToRGBA<unsigned char>(buffer, width, height);
    }
    
    MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
    textureDescriptor.pixelFormat = imageFormat;
    
    textureDescriptor.width = width;
    textureDescriptor.height = height;
    
    metalTexture = [MetalContext::Get().device newTextureWithDescriptor:textureDescriptor];
    
    NSUInteger bytesPerRow = 4 * width;
    
    MTLRegion region = {
        { 0, 0, 0 },       // MTLOrigin
        {width, height, 1} // MTLSize
    };
    
    [metalTexture replaceRegion:region
                    mipmapLevel:0
                      withBytes:buffer
                    bytesPerRow:bytesPerRow];
}
