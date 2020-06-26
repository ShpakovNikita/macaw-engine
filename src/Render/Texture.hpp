#pragma once

#include <string>

#import "Metal/Metal.h"

namespace mcw
{
    class Texture
    {
    public:
        void CreateEmpty(size_t w, size_t h, MTLPixelFormat imageFormat);
        void LoadFromFile(const std::string& filename);
        void LoadFromBuffer(const void* data, MTLPixelFormat imageFormat, size_t width, size_t height, bool convertRGB8ToRGBA8 = false, MTLStorageMode storageMode = MTLStorageModeManaged, MTLTextureUsage usage = MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite);
        
        id<MTLTexture> metalTexture;
        
        size_t width = 0, height = 0;
    };
}
