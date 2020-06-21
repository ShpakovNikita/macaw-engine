// TODO: something with cmake includes
#include "../Common/Vertex.hpp"

typedef struct
{
    float4 position [[position]];
    float4 color;
} RasterizerData;

vertex RasterizerData
VertexShader(uint vertexID [[vertex_id]],
             constant Vertex *vertices [[buffer(VertexInputIndexVertices)]])
{
    float2 pixelSpacePosition = vertices[vertexID].position.xy;
    
    RasterizerData out;
    out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
    out.position.xy = pixelSpacePosition;
    out.color = vertices[vertexID].normal;

    return out;
}

fragment float4 FragmentShader(RasterizerData in [[stage_in]])
{
    return in.color;
}
