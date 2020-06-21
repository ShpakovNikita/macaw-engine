#pragma once

#import <Metal/Metal.h>

#include "glm/vec4.hpp"

namespace mcw
{
    class Material
    {
        struct MaterialParams {
            glm::vec4 baseColorFactor = glm::vec4(1.0f);
            glm::vec4 emissiveFactor = glm::vec4(0.0f);
            glm::vec4 diffuseFactor = glm::vec4(1.0f);
            glm::vec4 specularFactor = glm::vec4(1.0f);
            int colorTextureSet = -1;
            int physicalDescriptorTextureSet = -1;
            int normalTextureSet = -1;
            int occlusionTextureSet = -1;
            int emissiveTextureSet = -1;
            float metallicFactor = 0.0f;
            float roughnessFactor = 0.0f;
        } materialParamsData = {};
        
        id<MTLBuffer> materialParamsBuffer;
    };
}
