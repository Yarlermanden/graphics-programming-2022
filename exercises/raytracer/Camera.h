#pragma once

#include <glad/glad.h>
#include <glm/glm.hpp>

enum Camera_Movement {
    FORWARD,
    BACKWARD,
    LEFT,
    RIGHT
};

// Default camera values
const float YAW         = -90.0f;
const float PITCH       =  0.0f;
const float SPEED       =  20.5f;
const float SENSITIVITY =  0.1f;
const float FOV =  45.0f;

class Camera
{
public:
    // Camera Attributes
    glm::vec3 Front;
    glm::vec3 Right;
    glm::vec3 WorldUp;
    // Euler Angles
    float Yaw;
    float Pitch;
    // Camera options
    float MovementSpeed;
    float MouseSensitivity;

    glm::vec3 m_Position;
    glm::vec3 m_LookAt;
    glm::vec3 m_Up;

    float m_Fov;
    float m_Aspect;
    float m_Near;
    float m_Far;


    Camera();
    glm::mat4 GetViewMatrix();
    glm::mat4 GetProjMatrix();

    glm::vec3 ToViewSpace(glm::vec3 xyz, float w);

    void ProcessKeyboard(Camera_Movement direction, float deltaTime);
    void ProcessMouseMovement(float xoffset, float yoffset, GLboolean constrainPitch = true);
    void ProcessMouseScroll(float yoffset);

private:

    // Calculates the front vector from the Camera's (updated) Euler Angles
    void updateCameraVectors()
    {
        // https://learnopengl.com/Getting-Started/Camera
        glm::vec3 front;
        front.x = cos(glm::radians(Yaw)) * cos(glm::radians(Pitch));
        front.y = sin(glm::radians(Pitch));
        front.z = sin(glm::radians(Yaw)) * cos(glm::radians(Pitch));
        Front = glm::normalize(front);
        // Also re-calculate the Right and Up vector
        Right = glm::normalize(glm::cross(Front, WorldUp));  // Normalize the vectors, because their length gets closer to 0 the more you look up or down which results in slower movement.
        m_Up    = glm::normalize(glm::cross(Right, Front));
        m_LookAt = Front;
    }
};

