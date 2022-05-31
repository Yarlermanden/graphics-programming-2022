#include "Camera.h"

#include <glm/gtc/matrix_transform.hpp>
#include <iostream>

Camera::Camera()
    : m_Position(0.0f, 0.0f, 0.0f), m_LookAt(0.0f, 0.0f, -10.f), m_Up(0.0f, 1.0f, 0.0f)
    , m_Fov(FOV), m_Aspect(0.6f), m_Near(0.1f), m_Far(100.0f)
    //new variables
    , Front(glm::vec3(0.0f, 0.0f, -1.0f)), Right(glm::vec3(1.0f, 0.0f, 0.0f))
    , MovementSpeed(SPEED), MouseSensitivity(SENSITIVITY)
{
    WorldUp = m_Up;
    Yaw = YAW;
    Pitch = PITCH;
    updateCameraVectors();
}

glm::mat4 Camera::GetViewMatrix() {
    return glm::lookAt(m_Position, m_Position + m_LookAt, m_Up);
}

glm::mat4 Camera::GetProjMatrix()
{
    return glm::perspective(glm::radians(m_Fov), m_Aspect, m_Near, m_Far);
}

glm::vec3 Camera::ToViewSpace(glm::vec3 xyz, float w)
{
    glm::vec4 v(xyz.x, xyz.y, xyz.z, w);
    v = GetViewMatrix()* v;
    return glm::vec3(v.x, v.y, v.z);
}

// Processes input received from any keyboard-like input system. Accepts input parameter in the form of camera defined ENUM (to abstract it from windowing systems)
void Camera::ProcessKeyboard(Camera_Movement direction, float deltaTime)
{
    float velocity = MovementSpeed * deltaTime;
    if (direction == FORWARD)
        m_Position += m_LookAt*velocity;
    if (direction == BACKWARD)
        m_Position -= m_LookAt*velocity;
    if (direction == LEFT)
        m_Position -= Right*velocity;
    if (direction == RIGHT)
        m_Position += Right * velocity;
}

// Processes input received from a mouse input system. Expects the offset value in both the x and y direction.
void Camera::ProcessMouseMovement(float xoffset, float yoffset, GLboolean constrainPitch)
{
    https://learnopengl.com/Getting-Started/Camera
    xoffset *= -MouseSensitivity;
    yoffset *= -MouseSensitivity;

    Yaw   += xoffset;
    Pitch += yoffset;

    if (constrainPitch)
    {
        if (Pitch > 89.0f)
            Pitch = 89.0f;
        if (Pitch < -89.0f)
            Pitch = -89.0f;
    }
    updateCameraVectors();
}

// Processes input received from a mouse scroll-wheel event. Only requires input on the vertical wheel-axis
void Camera::ProcessMouseScroll(float yoffset)
{
    if (m_Fov >= 1.0f && m_Fov <= 45.0f)
        m_Fov -= yoffset;
    if (m_Fov <= 1.0f)
        m_Fov = 1.0f;
    if (m_Fov >= 45.0f)
        m_Fov = 45.0f;
}