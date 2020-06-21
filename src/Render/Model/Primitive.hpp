#pragma once

#import <Metal/Metal.h>

#include "Render/Model/AABBox.h"

namespace mcw
{
    class Material;

    struct Primitive {
        uint32_t firstIndex = 0;
        uint32_t firstVertex = 0;
        uint32_t indexCount = 0;
        uint32_t vertexCount = 0;

        id<MTLBuffer> vertices = {};
        id<MTLBuffer> indices = {};

        Material& material;
        bool hasIndices;

        AABBox bbox;

        Primitive(
            uint32_t firstIndex,
            uint32_t firstVertex,
            uint32_t indexCount,
            uint32_t vertexCount,
            Material& material)
            : firstIndex(firstIndex)
            , firstVertex(firstVertex)
            , indexCount(indexCount)
            , vertexCount(vertexCount)
            , material(material)
        {
            hasIndices = indexCount > 0;
        };
    };
}
