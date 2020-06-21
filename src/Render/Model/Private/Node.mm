#include "Render/Model/Node.hpp"

#include "Render/Model/Mesh.hpp"

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
