#include "Render/Model/Mesh.hpp"

mcw::Mesh::Mesh(const glm::mat4& meshMat)
{
    uniformBlock.matrix = meshMat;

    UpdateUniformBuffers();
}

void mcw::Mesh::UpdateUniformBuffers()
{
    // TODO: update buffers;
}
