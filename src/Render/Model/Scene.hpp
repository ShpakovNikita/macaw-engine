#pragma once

#import "Metal/Metal.h"

#include <string>
#include <vector>
#include <memory>

#include "glm/vec3.hpp"

struct Vertex;

namespace tinygltf
{
    class Node;
    class Model;
    struct Image;
}

namespace mcw
{
    struct TextureSampler;
    class Material;
    class Node;
    class Texture;
    class Primitive;

    class Scene
    {
    public:
        Scene();
        ~Scene();

        void LoadFromFile(const std::string& filename, float scale = 1.0f);

        std::vector<std::unique_ptr<Material>>& GetMaterials();
        const std::vector<Texture>& GetTextures() const;
        const std::vector<std::unique_ptr<Node>>& GetNodes() const;
        const std::vector<Node*>& GetFlatNodes() const;

        const glm::vec3& GetSize() const;
        const uint32_t GetPrimitivesCount() const;
        
        void Draw(id<MTLRenderCommandEncoder> renderEncoder);
        
    private:
        // static VkSamplerAddressMode GetVkWrapMode(int32_t wrapMode);
        // static VkFilter GetVkFilterMode(int32_t filterMode);

        void LoadTextureSamplers(const tinygltf::Model& input);
        void LoadTextures(const tinygltf::Model& input);
        void LoadMaterials(const tinygltf::Model& input);

        void CalculateSize();

        void CreatePrimitiveBuffers(Primitive* newPrimitive, std::vector<Vertex>& vertexBuffer,
            std::vector<uint32_t>& indexBuffer);

        void LoadNode(Node* parent, const tinygltf::Node& node, uint32_t nodeIndex, const tinygltf::Model& input,
            float globalscale);

        // Model data
        std::vector<std::unique_ptr<Node>> nodes;
        std::vector<Node*> allNodes;

        std::vector<Texture> textures;
        std::vector<TextureSampler> textureSamplers;
        std::vector<std::unique_ptr<Material>> materials;

        glm::vec3 size = {};

    };
}
