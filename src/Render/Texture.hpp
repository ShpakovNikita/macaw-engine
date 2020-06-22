#pragma once

#include <string>

#import "Metal/Metal.h"

namespace mcw
{
    class Texture
    {
    public:
        void LoadFromFile(const std::string& filename);
        void LoadFromBuffer(const void* data, MTLPixelFormat imageFormat, size_t width, size_t height, bool convertRGB8ToRGBA8 = false);
        
        id<MTLTexture> metalTexture;
        
        size_t width = 0, height = 0;
    };
}
