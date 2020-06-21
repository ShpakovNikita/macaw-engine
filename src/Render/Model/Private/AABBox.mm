#include "Render/Model/AABBox.hpp"

mcw::AABBox mcw::AABBox::GetAABB(const glm::mat4& m)
{
    glm::vec3 locMin = glm::vec3(m[3]);
    glm::vec3 locaMax = locMin;
    glm::vec3 v0, v1;

    glm::vec3 right = glm::vec3(m[0]);
    v0 = right * this->min.x;
    v1 = right * this->max.x;
    locMin += glm::min(v0, v1);
    locaMax += glm::max(v0, v1);

    glm::vec3 up = glm::vec3(m[1]);
    v0 = up * this->min.y;
    v1 = up * this->max.y;
    locMin += glm::min(v0, v1);
    locaMax += glm::max(v0, v1);

    glm::vec3 back = glm::vec3(m[2]);
    v0 = back * this->min.z;
    v1 = back * this->max.z;
    locMin += glm::min(v0, v1);
    locaMax += glm::max(v0, v1);

    return AABBox(locMin, locaMax);
}
