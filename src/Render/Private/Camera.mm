#include "Render/Camera.hpp"

#include "Core/EngineContext.hpp"
#include "Core/Window.hpp"

#include "Render/MetalContext.hpp"

#include <algorithm>

#include "glm/ext/matrix_transform.hpp"
#include "glm/ext/matrix_clip_space.hpp"
#include "glm/gtx/euler_angles.hpp"

#include "SDL_keyboard.h"

mcw::Camera::Camera()
{
    std::fill(keyStates.begin(), keyStates.end(), false);
}

void mcw::Camera::PollEvent(const SDL_Event& event, float dt)
{
    switch (event.type) {
    case SDL_MOUSEWHEEL: {
        float speedDelta = cameraSpeed + event.wheel.y * dt;
        cameraSpeed = glm::clamp(speedDelta, 0.1f, 15.0f);
    } break;

    case SDL_MOUSEMOTION: {
        currentX = event.button.x;
        currentY = event.button.y;
    } break;

    case SDL_MOUSEBUTTONDOWN: {
        isHolding = true;
        currentX = event.button.x;
        currentY = event.button.y;
        lastX = currentX;
        lastY = currentY;
    } break;

    case SDL_MOUSEBUTTONUP: {
        isHolding = false;
        currentX = event.button.x;
        currentY = event.button.y;
        lastX = currentX;
        lastY = currentY;
    } break;
            
    case SDL_KEYDOWN: {
        keyStates[event.key.keysym.sym] = true;
    } break;

    case SDL_KEYUP: {
        keyStates[event.key.keysym.sym] = false;
    } break;
    }
}

void mcw::Camera::UpdateUniformBuffers(float dt)
{
    static bool firstMouseUpdate = true;
    
    if (isHolding)
    {
        if (firstMouseUpdate)
        {
            lastX = currentX;
            lastY = currentY;
            firstMouseUpdate = false;
        }

        float xoffset = currentX - lastX;
        float yoffset = lastY - currentY;
        lastX = currentX;
        lastY = currentY;
        
        xoffset *= cameraSensitivity;
        yoffset *= cameraSensitivity;

        rotation.x += xoffset;
        rotation.y += yoffset;
        
        rotation.y = std::clamp(rotation.y, -89.0f, 89.0f);
    }
    
    glm::vec3 front;
    front.x = cos(glm::radians(rotation.x)) * cos(glm::radians(rotation.y));
    front.y = sin(glm::radians(rotation.y));
    front.z = sin(glm::radians(rotation.x)) * cos(glm::radians(rotation.y));
    glm::vec3 cameraFront = glm::normalize(front);
    
    if(keyStates[SDLK_a])
    {
        position -= glm::normalize(glm::cross(cameraFront, kUpVector)) * cameraSpeed * dt;
    }
    if(keyStates[SDLK_d])
    {
        position += glm::normalize(glm::cross(cameraFront, kUpVector)) * cameraSpeed * dt;
    }
    if(keyStates[SDLK_w])
    {
        position += cameraSpeed * cameraFront * dt;
    }
    if(keyStates[SDLK_s])
    {
        position -= cameraSpeed * cameraFront * dt;
    }
    
    struct GLMCameraUniforms
    {
        glm::mat4 view;
        glm::mat4 projection;
        glm::mat4 rotation;
    } uniforms;
    
    uniforms.view = glm::lookAt(position, position + cameraFront, kUpVector);
    float cameraAspect = static_cast<float>(EngineContext::Get().GetWindow()->GetWidth()) / EngineContext::Get().GetWindow()->GetHeight();
    uniforms.projection = glm::perspective(cameraFOV, cameraAspect, 0.1f, 100.0f);
    uniforms.rotation = glm::mat3(uniforms.view);
    
    cameraUniforms = *reinterpret_cast<CameraUniforms*>(&uniforms);
}
