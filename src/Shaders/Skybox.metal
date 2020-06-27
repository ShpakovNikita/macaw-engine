// TODO: something with cmake includes
#include <metal_stdlib>

#include "../Common/Vertex.hpp"
#include "../Common/Uniforms.hpp"
#include "../Common/Textures.hpp"

using namespace metal;

typedef struct
{
    float4 position [[position]];
    float4 worldPosition;
} RasterizerData;

vertex RasterizerData
SkyboxVertexShader(uint vertexID [[vertex_id]],
             constant Vertex *vertices [[buffer(VertexInputIndexVertices)]],
             constant CameraUniforms & cameraUniforms [[ buffer(BufferIndexCameraUniforms) ]])
{
    RasterizerData out;
    out.position = cameraUniforms.projection * cameraUniforms.rotation * vertices[vertexID].position;
    out.worldPosition = vertices[vertexID].position;
    return out;
}

fragment float4 SkyboxFragmentShader(RasterizerData in              [[stage_in]],
                                     texturecube<float> cubeTexture [[texture(SkyboxTexture)]],
                                     sampler cubeSampler            [[sampler(SkyboxSampler)]])
{
    float3 texCoords = float3(in.worldPosition.x, in.worldPosition.y, in.worldPosition.z);
    return cubeTexture.sample(cubeSampler, texCoords);
}
