#include <simd/simd.h>

typedef enum VertexInputIndex
{
    VertexInputIndexVertices     = 0,
} VertexInputIndex;

typedef struct
{
    vector_float4 position;
    vector_float4 normal;
    vector_float4 uv; // uv0 + uv1
} Vertex;
