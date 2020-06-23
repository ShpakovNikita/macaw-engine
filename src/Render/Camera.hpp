#pragma once

#include "Common/Uniforms.hpp"

#include <array>

#include "glm/mat4x4.hpp"
#include "glm/vec3.hpp"
#include "SDL_events.h"

namespace mcw
{
    class Camera
    {
    public:
        enum class eCameraMode
        {
            kFirstPerson = 0,
            kLookAt,
        };
        
        static constexpr glm::vec3 kUpVector = glm::vec3(0.0f, 1.0f, 0.0f);
        
        CameraUniforms cameraUniforms;
        
        Camera();
        
        void PollEvent(const SDL_Event& event, float dt);
        void UpdateUniformBuffers(float dt);
        
        glm::vec3 position;
        glm::vec3 rotation = glm::vec3(90.0f, 0.0f, 0.0f); // {yaw, pitch, roll} in degrees
        
        float cameraSpeed = 1.0f;
        float cameraSensitivity = 0.05f;
        float cameraFOV = 45.0f;
        
        eCameraMode cameraMode = eCameraMode::kFirstPerson;
    
    private:
        std::array<bool, 256> keyStates;
        
        float lastX = 0;
        float lastY = 0;
        
        float currentX = 0;
        float currentY = 0;
        
        bool isHolding = false;
    };
}
