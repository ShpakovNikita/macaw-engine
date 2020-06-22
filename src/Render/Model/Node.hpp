#pragma once

#import "Metal/Metal.h"

#include "Render/Model/AABBox.hpp"

#include <vector>
#include <memory>
#include <string>

#include <glm/vec3.hpp>
#include "glm/ext/quaternion_float.hpp"
#include <glm/mat4x4.hpp>

namespace mcw
{
    class Mesh;

    class Node {
    public:
        Node* parent = nullptr;
        uint32_t index;
        std::vector<std::unique_ptr<Node>> children;
        glm::mat4 matrix;
        std::string name;
        std::unique_ptr<Mesh> mesh;
        glm::vec3 translation = {};
        glm::vec3 scale = glm::vec3{ 1.0f };
        glm::quat rotation = {};

        AABBox bbox = {};

        Node();
        
        glm::mat4 GetLocalMatrix();
        glm::mat4 GetWorldMatrix();
        
        void DrawNode(id<MTLRenderCommandEncoder> renderEncoder) const;

        void UpdateRecursive();
    };
}
