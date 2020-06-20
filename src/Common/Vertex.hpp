#include <simd/simd.h>

typedef enum VertexInputIndex
{
    VertexInputIndexVertices     = 0,
} VertexInputIndex;

typedef struct
{
    vector_float2 position;
    vector_float4 color;
} Vertex;
