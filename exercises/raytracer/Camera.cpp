#include "Camera.h"

#include <glm/gtc/matrix_transform.hpp>
#include <iostream>

Camera::Camera()
    : m_Position(0.0f, 0.0f, 10.0f), m_LookAt(0.0f), m_Up(0.0f, 1.0f, 0.0f)
    , m_Fov(glm::radians(60.0f)), m_Aspect(1.0f), m_Near(0.1f), m_Far(100.0f)
    //new variables
    , Position(0.0f, 0.0f, 0.0f), Front(glm::vec3(0.0f, 0.0f, -1.0f)), Right(glm::vec3(1.0f, 0.0f, 0.0f))
    , MovementSpeed(SPEED), MouseSensitivity(SENSITIVITY), Zoom(ZOOM)
{
}

// Constructor with vectors
Camera::Camera(glm::vec3 position, glm::vec3 up, float yaw, float pitch)
    : Front(glm::vec3(0.0f, 0.0f, -1.0f)), MovementSpeed(SPEED), MouseSensitivity(SENSITIVITY), Zoom(ZOOM)
{
    Position = position;
    WorldUp = up;
    Yaw = yaw;
    Pitch = pitch;
    updateCameraVectors();
}
// Constructor with scalar values
Camera::Camera(float posX, float posY, float posZ, float upX, float upY, float upZ, float yaw, float pitch)
    : Front(glm::vec3(0.0f, 0.0f, -1.0f)), MovementSpeed(SPEED), MouseSensitivity(SENSITIVITY), Zoom(ZOOM)
{
    Position = glm::vec3(posX, posY, posZ);
    WorldUp = glm::vec3(upX, upY, upZ);
    Yaw = yaw;
    Pitch = pitch;
    updateCameraVectors();
}



glm::mat4 Camera::GetViewMatrix() const
{
    //return glm::lookAt(m_Position, m_LookAt, m_Up);
    return glm::lookAt(m_Position, m_LookAt, m_Up);
}

glm::mat4 Camera::GetViewMatrix() {
    return glm::lookAt(Position, m_LookAt, m_Up);
}

glm::mat4 Camera::GetProjMatrix() const
{
    return glm::perspective(m_Fov, m_Aspect, m_Near, m_Far);
}


/*
// Returns the view matrix calculated using Euler Angles and the LookAt Matrix
glm::mat4 GetViewMatrix()
{
    return glm::lookAt(Position, Position + Front, Up);
}
*/


glm::vec3 Camera::ToViewSpace(glm::vec3 xyz, float w) const
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
        Position += Front * velocity;
    if (direction == BACKWARD)
        Position -= Front * velocity;
    if (direction == LEFT)
        Position -= Right * velocity;
    if (direction == RIGHT)
        Position += Right * velocity;
}

// Processes input received from a mouse input system. Expects the offset value in both the x and y direction.
void Camera::ProcessMouseMovement(float xoffset, float yoffset, GLboolean constrainPitch)
{
    xoffset *= MouseSensitivity;
    yoffset *= MouseSensitivity;

    Yaw   += xoffset;
    Pitch += yoffset;

    // Make sure that when pitch is out of bounds, screen doesn't get flipped
    if (constrainPitch)
    {
        if (Pitch > 89.0f)
            Pitch = 89.0f;
        if (Pitch < -89.0f)
            Pitch = -89.0f;
    }

    // Update Front, Right and Up Vectors using the updated Euler angles
    updateCameraVectors();
}

// Processes input received from a mouse scroll-wheel event. Only requires input on the vertical wheel-axis
void Camera::ProcessMouseScroll(float yoffset)
{
    if (Zoom >= 1.0f && Zoom <= 45.0f)
        Zoom -= yoffset;
    if (Zoom <= 1.0f)
        Zoom = 1.0f;
    if (Zoom >= 45.0f)
        Zoom = 45.0f;
}