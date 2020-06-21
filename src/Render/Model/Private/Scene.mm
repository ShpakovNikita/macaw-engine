#include "Render/Model/Scene.hpp"

void mcw::Scene::LoadFromFile(const std::string& filename, float scale = 1.0f)
{
    /*
    const std::vector<Vertex> vertexData =
    {
       { {  0.5,  -0.5 }, { 1, 0, 0, 1 } },
       { { -0.5,  -0.5 }, { 0, 1, 0, 1 } },
       { {    0,   0.5 }, { 0, 0, 1, 1 } },
    };
    
    vertexBuffer = [MetalContext::Get().device newBufferWithBytes:vertexData.data()
                           length:sizeof(vertexData[0]) * vertexData.size()
                           options:MTLResourceStorageModeShared];
    */
}

std::vector<std::unique_ptr<mcw::Material>>& mcw::Scene::GetMaterials()
{
    
}

const std::vector<mcw::Texture>& mcw::Scene::GetTextures() const
{
    
}

const std::vector<std::unique_ptr<mcw::Node>>& mcw::Scene::GetNodes() const
{
    
}

const std::vector<mcw::Node*>& mcw::Scene::GetFlatNodes() const
{
    
}

const glm::vec3& mcw::Scene::GetSize() const
{
    
}

const uint32_t mcw::Scene::GetPrimitivesCount() const
{
    
}

void mcw::Scene::Draw(id<MTLRenderCommandEncoder>)
{
    /*
    [renderEncoder setVertexBuffer:vertexBuffer
                            offset:0
                           atIndex:VertexInputIndexVertices];

     [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                       vertexStart:0
                       vertexCount:3];
     */
}
