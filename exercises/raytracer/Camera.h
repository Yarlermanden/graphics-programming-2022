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
const float SPEED       =  2.5f;
const float SENSITIVITY =  0.1f;
const float ZOOM        =  45.0f;

class Camera
{
public:
    // Camera Attributes
    glm::vec3 Position;
    glm::vec3 Front;
    glm::vec3 Up;
    glm::vec3 Right;
    glm::vec3 WorldUp;
    // Euler Angles
    float Yaw;
    float Pitch;
    // Camera options
    float MovementSpeed;
    float MouseSensitivity;
    float Zoom;


    Camera();
    //Camera(glm::vec3 position = glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3 up = glm::vec3(0.0f, 1.0f, 0.0f), float yaw = YAW, float pitch = PITCH);
    Camera(glm::vec3 position, glm::vec3 up = glm::vec3(0.0f, 1.0f, 0.0f), float yaw = YAW, float pitch = PITCH);
    Camera(float posX, float posY, float posZ, float upX, float upY, float upZ, float yaw, float pitch);

    glm::mat4 GetViewMatrix() const;
    glm::mat4 GetProjMatrix() const;

    glm::vec3 GetPosition() const { return m_Position; }
    void SetPosition(const glm::vec3 &position) { m_Position = position; }
    glm::vec3 GetLookAt() const { return m_LookAt; }
    void SetLookAt(const glm::vec3 &lookAt) { m_LookAt = lookAt; }
    glm::vec3 GetUpVector() const { return m_Up; }
    void SetUpVector(const glm::vec3 &up) { m_Up = up; }

    float GetFov() const { return m_Fov; }
    void SetFov(float fov) { m_Fov = fov; }
    float GetAspect() const { return m_Aspect; }
    void SetAspect(float aspect) { m_Aspect = aspect; }
    float GetNear() const { return m_Near; }
    void SetNear(float near) { m_Near = near; }
    float GetFar() const { return m_Far; }
    void SetFar(float far) { m_Far = far; }

    glm::vec3 ToViewSpace(glm::vec3 xyz, float w) const;

    void ProcessKeyboard(Camera_Movement direction, float deltaTime);
    void ProcessMouseMovement(float xoffset, float yoffset, GLboolean constrainPitch = true);
    void ProcessMouseScroll(float yoffset);


private:

    glm::vec3 m_Position;
    glm::vec3 m_LookAt;
    glm::vec3 m_Up;

    float m_Fov;
    float m_Aspect;
    float m_Near;
    float m_Far;

    // Calculates the front vector from the Camera's (updated) Euler Angles
    void updateCameraVectors()
    {
        // Calculate the new Front vector
        glm::vec3 front;
        front.x = cos(glm::radians(Yaw)) * cos(glm::radians(Pitch));
        front.y = sin(glm::radians(Pitch));
        front.z = sin(glm::radians(Yaw)) * cos(glm::radians(Pitch));
        Front = glm::normalize(front);
        // Also re-calculate the Right and Up vector
        Right = glm::normalize(glm::cross(Front, WorldUp));  // Normalize the vectors, because their length gets closer to 0 the more you look up or down which results in slower movement.
        Up    = glm::normalize(glm::cross(Right, Front));
    }
};

