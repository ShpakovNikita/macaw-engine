// TODO: something with cmake includes
#include "../Common/Vertex.hpp"
#include "../Common/Uniforms.hpp"

typedef struct
{
    float4 position [[position]];
    float4 color;
} RasterizerData;

vertex RasterizerData
VertexShader(uint vertexID [[vertex_id]],
             constant Vertex *vertices [[buffer(VertexInputIndexVertices)]],
             constant CameraUniforms & cameraUniforms [[ buffer(BufferIndexCameraUniforms) ]])
{
    RasterizerData out;
    out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
    out.position = cameraUniforms.projection * cameraUniforms.view * vertices[vertexID].position;
    out.color = metal::normalize(vertices[vertexID].normal);

    return out;
}

fragment float4 FragmentShader(RasterizerData in [[stage_in]])
{
    return in.color;
}
