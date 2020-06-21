#pragma once

#include <memory>

#import "Metal/Metal.h"

#include "Render/Model/Primitive.hpp"
#include "Render/Model/AABBox.hpp"

namespace mcw
{
    class Mesh
    {
    public:
        std::vector<std::unique_ptr<Primitive>> primitives = {};

        AABBox bbox = {};

        id<MTLBuffer> uniformBuffer;
        
        struct UniformBlock {
            glm::mat4 matrix;
        } uniformBlock;

        Mesh(const glm::mat4& meshMat);

        void UpdateUniformBuffers();
    };
}
