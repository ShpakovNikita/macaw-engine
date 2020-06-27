#pragma once

#import "Metal/Metal.h"

namespace mcw
{
    class EnvironmentProbe
    {
    public:
        EnvironmentProbe();
        ~EnvironmentProbe();
        
        void CreateTexture();
        
        size_t probeResolution = 1024;
        
        id<MTLTexture> metalTexture;
        id<MTLSamplerState> samplerState;
    };
}
