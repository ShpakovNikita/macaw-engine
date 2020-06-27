#pragma once

#include <simd/simd.h>

typedef struct
{
    matrix_float4x4 view;
    matrix_float4x4 projection;
    matrix_float4x4 rotation;
} CameraUniforms;
