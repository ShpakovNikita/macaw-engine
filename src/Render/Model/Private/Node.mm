#include "Render/Model/Node.hpp"

#import "Metal/MTLStageInputOutputDescriptor.h"

#include "Render/Model/Mesh.hpp"
#include "Render/Model/Material.hpp"
#include "Render/Texture.hpp"
#include "Common/Vertex.hpp"

mcw::Node::Node() = default;

glm::mat4 mcw::Node::GetLocalMatrix()
{
        return glm::translate(glm::mat4(1.0f), translation) * glm::mat4(rotation) * glm::scale(glm::mat4(1.0f), scale) * matrix;
}

glm::mat4 mcw::Node::GetWorldMatrix()
{
    glm::mat4 localMat = GetLocalMatrix();
    Node* currentParent = parent;
    while (currentParent) {
        localMat = currentParent->GetLocalMatrix() * localMat;
        currentParent = currentParent->parent;
    }
    return localMat;
}

void mcw::Node::UpdateRecursive()
{
    if (mesh) {
        mesh->uniformBlock.matrix = GetWorldMatrix();
        mesh->UpdateUniformBuffers();
    }

    for (auto& child : children) {
        child->UpdateRecursive();
    }
}

void mcw::Node::DrawNode(id<MTLRenderCommandEncoder> renderEncoder) const
{
    if (mesh)
    {
        for (const auto& primitive : mesh->primitives)
        {
            [renderEncoder setVertexBuffer:primitive->vertices
                                    offset:0
                                   atIndex:VertexInputIndexVertices];
            
            [renderEncoder setFragmentTexture:primitive->material.albedoColorTexture->metalTexture
                                      atIndex:VertexInputAlbedoColorTexture];
            [renderEncoder setFragmentTexture:primitive->material.metallicRoughnessTexture->metalTexture
                                      atIndex:VertexInputMetallicRoughnessTexture];
            [renderEncoder setFragmentTexture:primitive->material.normalTexture->metalTexture
                                      atIndex:VertexInputNormalTexture];
            [renderEncoder setFragmentTexture:primitive->material.occlusionTexture->metalTexture
                                      atIndex:VertexInputOcclusionTexture];
            [renderEncoder setFragmentTexture:primitive->material.emissiveTexture->metalTexture
                                      atIndex:VertexInputEmissiveTexture];
            
            [renderEncoder drawIndexedPrimitives: MTLPrimitiveTypeTriangle
                                      indexCount: primitive->indexCount,
                                       indexType: MTLIndexTypeUInt32,
                                     indexBuffer: primitive.indices,
                               indexBufferOffset: 0];
        }
    }
}
