#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>

#include <imgui.h>
#include <imgui_impl_glfw.h>
#include <imgui_impl_opengl3.h>

#include <iostream>

#include "RayTracer.h"

// glfw and input functions
// ------------------------
GLFWwindow* initOpenGL(unsigned int width, unsigned int height, const char* title);
void shutdownOpenGL();
void key_input_callback(GLFWwindow* window, int button, int other, int action, int mods);
void framebuffer_size_callback(GLFWwindow* window, int width, int height);
void processInput(GLFWwindow *window);
void button_input_callback(GLFWwindow* window, int button, int action, int mods);
void cursor_input_callback(GLFWwindow* window, double posX, double posY);

// imgui functions
void initImGui(GLFWwindow* window);
void drawGui();
void shutdownImGui();
bool showGui = false;

// screen settings
// ---------------
const unsigned int SCR_WIDTH = 1280;
const unsigned int SCR_HEIGHT = 720;

//settings
int shadingMode = 1;

// Global raytracer to reload shaders
RayTracer* s_RayTracer = nullptr;

Camera camera;
float deltaTime = 0;

int main()
{
    GLFWwindow* window = initOpenGL(SCR_WIDTH, SCR_HEIGHT, "Raytracer");
    if (!window)
        return -1;

    initImGui(window);

    glEnable(GL_FRAMEBUFFER_SRGB);
    glEnable(GL_DEPTH_TEST);
    glDepthMask(true);

    glEnable(GL_DEPTH_CLAMP);
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);

    RayTracer rayTracer(SHADER_FOLDER "sample.frag");
    camera.SetAspect((float)SCR_WIDTH / SCR_HEIGHT);
    s_RayTracer = &rayTracer;

    float loopInterval = 1.f/60.f;
    auto begin = std::chrono::high_resolution_clock::now();

    while (!glfwWindowShouldClose(window))
    {
        auto frameStart = std::chrono::high_resolution_clock::now();
        std::chrono::duration<float> appTime = frameStart - begin;

        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        std::chrono::duration<float> elapsed = std::chrono::high_resolution_clock::now()-frameStart;
        while (loopInterval > elapsed.count()) {
            elapsed = std::chrono::high_resolution_clock::now() - frameStart;
        }
        deltaTime = elapsed.count();
        processInput(window);
        rayTracer.Render(shadingMode, camera);

        if (showGui)
        {
            drawGui();
        }

        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    s_RayTracer = nullptr;

    shutdownImGui();
    shutdownOpenGL();
    return 0;
}

GLFWwindow* initOpenGL(unsigned int width, unsigned int height, const char* title)
{
    // glfw: initialize and configure
    // ------------------------------
    glfwInit();
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

#ifdef __APPLE__
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE); // uncomment this statement to fix compilation on OS X
#endif

    // glfw window creation
    // --------------------
    GLFWwindow* window = glfwCreateWindow(width, height, title, NULL, NULL);
    if (window == NULL)
    {
        std::cout << "Failed to create GLFW window" << std::endl;
        glfwTerminate();
        return nullptr;
    }
    glfwMakeContextCurrent(window);
    glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);
    glfwSetMouseButtonCallback(window, button_input_callback);
    glfwSetCursorPosCallback(window, cursor_input_callback);
    glfwSetKeyCallback(window, key_input_callback);
    glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);

    // glad: load all OpenGL function pointers
    // ---------------------------------------
    if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress))
    {
        std::cout << "Failed to initialize GLAD" << std::endl;
        return nullptr;
    }

    return window;
}

void shutdownOpenGL()
{
    // glfw: terminate, clearing all previously allocated GLFW resources.
    // ------------------------------------------------------------------
    glfwTerminate();
}

void initImGui(GLFWwindow* window)
{
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    // Setup Dear ImGui style
    ImGui::StyleColorsDark();
    // Setup Platform/Renderer bindings
    ImGui_ImplGlfw_InitForOpenGL(window, true);
    ImGui_ImplOpenGL3_Init("#version 330 core");
}

void drawGui()
{
    ImGui_ImplOpenGL3_NewFrame();
    ImGui_ImplGlfw_NewFrame();
    ImGui::NewFrame();
    {
        ImGui::Begin("Properties");

        ImGui::Text("Shading model: ");
        {
            if (ImGui::RadioButton("No Shading", shadingMode == 0)) { shadingMode = 0; }
            if (ImGui::RadioButton("Blinn-Phong Shading", shadingMode == 1)) { shadingMode = 1; }
            if (ImGui::RadioButton("PBR Shading", shadingMode == 2)) { shadingMode = 2; }
        }

        ImGui::Text("Application average %.3f ms/frame (%.1f FPS)", 1000.0f / ImGui::GetIO().Framerate, ImGui::GetIO().Framerate);
        ImGui::End();
    }

    ImGui::Render();
    ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
}

void shutdownImGui()
{
    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();
    ImGui::DestroyContext();
}

void key_input_callback(GLFWwindow* window, int key, int scancode, int action, int mods)
{
    if (action == GLFW_PRESS)
    {
        switch (key)
        {
        case GLFW_KEY_ESCAPE:
            glfwSetWindowShouldClose(window, true);
            break;
        case GLFW_KEY_SPACE:
            showGui = !showGui;
            break;
        case GLFW_KEY_R:
            if (s_RayTracer)
                s_RayTracer->ReloadShaders();
            break;
        }

    }
}

void processInput(GLFWwindow *window){
    if (glfwGetKey(window, GLFW_KEY_W) == GLFW_PRESS)
        camera.ProcessKeyboard(FORWARD, deltaTime);
    if (glfwGetKey(window, GLFW_KEY_S) == GLFW_PRESS)
        camera.ProcessKeyboard(BACKWARD, deltaTime);
    if (glfwGetKey(window, GLFW_KEY_A) == GLFW_PRESS)
        camera.ProcessKeyboard(LEFT, deltaTime);
    if (glfwGetKey(window, GLFW_KEY_D) == GLFW_PRESS)
        camera.ProcessKeyboard(RIGHT, deltaTime);
}

void cursor_input_callback(GLFWwindow* window, double posX, double posY){
    // camera rotation
    static float lastX = (float)SCR_WIDTH / 2.0;
    static float lastY = (float)SCR_HEIGHT / 2.0;
    static bool firstMouse = true;

    if (firstMouse)
    {
        lastX = posX;
        lastY = posY;
        firstMouse = false;
    }

    float xoffset = posX - lastX;
    float yoffset = lastY - posY; // reversed since y-coordinates go from bottom to top

    lastX = posX;
    lastY = posY;

    // we use the handy camera class from LearnOpenGL to handle our camera
    camera.ProcessMouseMovement(xoffset, yoffset);
}

void button_input_callback(GLFWwindow* window, int button, int action, int mods){
    static bool toggleClicked = true;
    if (button == GLFW_MOUSE_BUTTON_LEFT && action == GLFW_PRESS) {
        toggleClicked = !toggleClicked;
        glfwSetInputMode(window, GLFW_CURSOR, toggleClicked ? GLFW_CURSOR_NORMAL : GLFW_CURSOR_DISABLED);
    }
}

void framebuffer_size_callback(GLFWwindow* window, int width, int height)
{
    // glfw: whenever the window size changed (by OS or user resize) this callback function executes

    // make sure the viewport matches the new window dimensions; note that width and
    // height will be significantly larger than specified on retina displays.
    glViewport(0, 0, width, height);

    if (s_RayTracer)
        s_RayTracer->GetCamera().SetAspect((float)width / height);
}
