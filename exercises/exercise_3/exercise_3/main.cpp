#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <iostream>
#include <vector>
#include <chrono>
#include <shader_s.h>
#include <glm/glm.hpp>
#include <glm/gtx/transform.hpp>
#include <glm/gtc/matrix_transform.hpp>

#include "glmutils.h"

// the plane model is stored in the file so that we do not need to deal with model loading yet
#include "plane_model.h"

// structure to hold the info necessary to render an object
struct SceneObject{
    unsigned int VAO;
    unsigned int vertexCount;
};

// function declarations
// ---------------------
unsigned int createArrayBuffer(std::vector<float> &array);
unsigned int createElementArrayBuffer(std::vector<unsigned int> &array);
unsigned int createVertexArray(std::vector<float> &positions, std::vector<float> &colors, std::vector<unsigned int> &indices);
void setup();
void drawSceneObject(SceneObject obj);
void drawPlane();

// glfw functions
// --------------
void framebuffer_size_callback(GLFWwindow* window, int width, int height);
void processInput(GLFWwindow *window);

// settings
// --------
const unsigned int SCR_WIDTH = 600;
const unsigned int SCR_HEIGHT = 600;

// plane parts
// -----------
SceneObject planeBody;
SceneObject planeWing;
SceneObject planePropeller;

float currentTime;
Shader* shaderProgram;

float planeHeading = 0.0f;
float tiltAngle = 0.0f;
float planeSpeed = 0.005f;
glm::vec2 planePosition = glm::vec2(0.0,0.0);
float planeRotation = 0.0f;


int main()
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
    GLFWwindow* window = glfwCreateWindow(SCR_WIDTH, SCR_HEIGHT, "Exercise 3", NULL, NULL);
    if (window == NULL)
    {
        std::cout << "Failed to create GLFW window" << std::endl;
        glfwTerminate();
        return -1;
    }
    glfwMakeContextCurrent(window);
    glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);

    // glad: load all OpenGL function pointers
    // ---------------------------------------
    if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress))
    {
        std::cout << "Failed to initialize GLAD" << std::endl;
        return -1;
    }

    // build and compile our shader program
    // ------------------------------------
    shaderProgram = new Shader("shaders/shader.vert", "shaders/shader.frag");

    // the model was originally baked with lights for a left handed coordinate system, we are "fixing" the z-coordinate
    // so we can work with a right handed coordinate system
    PlaneModel::getInstance().invertModelZ();


    // setup mesh objects
    // ---------------------------------------
    setup();

    // NEW!
    // set up the z-buffer
    glDepthRange(1,-1); // make the NDC a right handed coordinate system, with the camera pointing towards -z
    glEnable(GL_DEPTH_TEST); // turn on z-buffer depth test
    glDepthFunc(GL_LESS); // keep fragments that are closer to the camera/screen in NDC


    // render loop
    // -----------
    // render every loopInterval seconds
    float loopInterval = 0.02f;
    auto begin = std::chrono::high_resolution_clock::now();

    while (!glfwWindowShouldClose(window))
    {
        // update current time
        auto frameStart = std::chrono::high_resolution_clock::now();
        std::chrono::duration<float> appTime = frameStart - begin;
        currentTime = appTime.count();

        processInput(window);

        glClearColor(0.5f, 0.5f, 1.0f, 1.0f);

        // NEW!
        // notice that we now have two screen buffers, one for color image and one for depth (aka z-buffer)
        // we need to clear both at every new frame (otherwise we write on top of a previous frame!)
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        shaderProgram->use();
        drawPlane();

        // we swap buffers because we have two color buffers:
        // one with the currently displayed image (aka front buffer) and one where we draw into (aka back buffer)
        // swapbuffers swaps the two buffers (front buffer becomes the back buffer, and vice versa)
        glfwSwapBuffers(window);
        glfwPollEvents();

        // control render loop frequency
        std::chrono::duration<float> elapsed = std::chrono::high_resolution_clock::now()-frameStart;
        while (loopInterval > elapsed.count()) { // busy wait
            elapsed = std::chrono::high_resolution_clock::now() - frameStart;
        }
    }

    // glfw: terminate, clearing all previously allocated GLFW resources.
    // ------------------------------------------------------------------
    glfwTerminate();
    return 0;
}


void drawPlane(){
    // TODO 3.all create and apply your transformation matrices here
    //  you will need to transform the pose of the pieces of the plane by manipulating glm matrices and uploading a
    //  uniform mat4 transform matrix to the vertex shader

    //Plane wrap around:
    if(planePosition.x > 1)
        planePosition.x = -1;
    else if(planePosition.x < -1)
        planePosition.x = 1;
    if(planePosition.y >= 1)
        planePosition.y = -1;
    else if(planePosition.y < -1)
        planePosition.y = 1;

    planePosition.x += -sin(glm::radians(planeRotation))*planeSpeed; //find movement in x direction
    planePosition.y += cos(glm::radians(planeRotation))*planeSpeed; //find movement in y direction

    //Defining perspective:
    glm::vec3 camPos = glm::vec3(0, 0, -2); //lookAt view matrix - from where we look - the camera position -
    // if this is (0,0,2) we look at it from the bottom ,so (0,0,-2) make us look at it from the top? maybe the other way around, is the plane on its head?

    glm::vec3 targetPos = glm::vec3(0, 0, 0); //looking at (0,0,0)
    glm::vec3 up = glm::vec3(0, 1, 0); //the up vector
    glm::mat4 lookAt = glm::lookAt(camPos, targetPos, up);
    glm::mat4 projection = glm::perspective(1.0f, 0.95f, 0.1f, 10.0f);

    //Creating model
    glm::mat4 model = glm::mat4(1.0f);

    //Multiplying projection, model and view to create perspective
    model = projection * lookAt * model; // perspective * view * model

    model = glm::translate(model, glm::vec3(planePosition.x, planePosition.y, 0)); //position plane
    model = glm::rotate(model, glm::radians(planeRotation), glm::vec3(0.0f, 0.0f, 1.0f)); //make plane body rotate to direction it points at


    //scale to 1/10
    glm::mat4 trans = model;
    trans = glm::scale(trans, glm::vec3(0.1f, 0.1f, 0.1f));
    trans = glm::rotate(trans, glm::radians(tiltAngle),glm::vec3(0.0f, 1.0f, 0.0f));//make the plane body tilt according to direction rotating in

    glm::mat4 planeBodyMatrix = trans;
    unsigned int transformLoc = glGetUniformLocation(shaderProgram->ID, "transform");
    glUniformMatrix4fv(transformLoc, 1, GL_FALSE, glm::value_ptr(planeBodyMatrix));

    // body
    drawSceneObject(planeBody);

    // right wing
    drawSceneObject(planeWing);

    //left wing
    trans = glm::scale(trans, glm::vec3(-1.0f, 1.0f, 1.0f)); //flips it the other way
    glUniformMatrix4fv(transformLoc, 1, GL_FALSE, glm::value_ptr(trans));
    drawSceneObject(planeWing);

    //right tail wing
    trans = planeBodyMatrix;
    trans = glm::scale(trans, glm::vec3(0.5f, 0.5f, 1.0f)); //makes it smaller
    trans = glm::translate(trans, glm::vec3(0, -1.0f, 0)); //moves it to the bottom of the plane
    glUniformMatrix4fv(transformLoc, 1, GL_FALSE, glm::value_ptr(trans));
    drawSceneObject(planeWing);

    //left tail wing
    trans = glm::scale(trans, glm::vec3(-1.0f, 1.0f, 1.0f)); //flips it to the other side (still transposed by the previous)
    glUniformMatrix4fv(transformLoc, 1, GL_FALSE, glm::value_ptr(trans));
    drawSceneObject(planeWing);

    //propeller
    trans = planeBodyMatrix;
    trans = glm::scale(trans, glm::vec3(0.5f, 0.5f, 1.0f));
    trans = glm::translate(trans, glm::vec3(0, 1.0f, 0));
    trans = glm::rotate(trans, glm::radians(90.0f), glm::vec3(1.0f, 0, 0));
    trans = glm::rotate(trans, glm::radians(360.0f*currentTime), glm::vec3(0, 0, 1.0f)); //rotate propeller with time
    glUniformMatrix4fv(transformLoc, 1, GL_FALSE, glm::value_ptr(trans));
    drawSceneObject(planePropeller);
}

void drawSceneObject(SceneObject obj){
    glBindVertexArray(obj.VAO);
    glDrawElements(GL_TRIANGLES,  obj.vertexCount, GL_UNSIGNED_INT, 0);
}

void setup(){

    // TODO 3.3 you will need to load one additional object.
    PlaneModel &airplane = PlaneModel::getInstance();
    // initialize plane body mesh objects
    planeBody.VAO = createVertexArray(airplane.planeBodyVertices,
                                      airplane.planeBodyColors,
                                      airplane.planeBodyIndices);
    planeBody.vertexCount = airplane.planeBodyIndices.size();

    // initialize plane wing mesh objects
    planeWing.VAO = createVertexArray(airplane.planeWingVertices,
                                      airplane.planeWingColors,
                                      airplane.planeWingIndices);
    planeWing.vertexCount = airplane.planeWingIndices.size();

    planePropeller.VAO = createVertexArray(airplane.planePropellerVertices,
                                           airplane.planePropellerColors,
                                           airplane.planePropellerIndices);
    planePropeller.vertexCount = airplane.planePropellerIndices.size();
}


unsigned int createVertexArray(std::vector<float> &positions, std::vector<float> &colors, std::vector<unsigned int> &indices){
    unsigned int VAO;
    glGenVertexArrays(1, &VAO);
    // bind vertex array object
    glBindVertexArray(VAO);

    // set vertex shader attribute "pos"
    createArrayBuffer(positions); // creates and bind  the VBO
    int posAttributeLocation = glGetAttribLocation(shaderProgram->ID, "pos");
    glEnableVertexAttribArray(posAttributeLocation);
    glVertexAttribPointer(posAttributeLocation, 3, GL_FLOAT, GL_FALSE, 0, 0);

    // set vertex shader attribute "color"
    createArrayBuffer(colors); // creates and bind the VBO
    int colorAttributeLocation = glGetAttribLocation(shaderProgram->ID, "color");
    glEnableVertexAttribArray(colorAttributeLocation);
    glVertexAttribPointer(colorAttributeLocation, 4, GL_FLOAT, GL_FALSE, 0, 0);

    // creates and bind the EBO
    createElementArrayBuffer(indices);

    return VAO;
}

unsigned int createArrayBuffer(std::vector<float> &array){
    unsigned int VBO;
    glGenBuffers(1, &VBO);

    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, array.size() * sizeof(GLfloat), &array[0], GL_STATIC_DRAW);

    return VBO;
}

unsigned int createElementArrayBuffer(std::vector<unsigned int> &array){
    unsigned int EBO;
    glGenBuffers(1, &EBO);

    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, array.size() * sizeof(unsigned int), &array[0], GL_STATIC_DRAW);

    return EBO;
}

// process all input: query GLFW whether relevant keys are pressed/released this frame and react accordingly
// ---------------------------------------------------------------------------------------------------------
void processInput(GLFWwindow *window)
{
    if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS)
        glfwSetWindowShouldClose(window, true);
    // TODO 3.4 control the plane (turn left and right) using the A and D keys
    if(glfwGetKey(window, GLFW_KEY_D) == GLFW_PRESS){
        planeRotation += 1.0f;
        tiltAngle = -45.0f;
        if(planeRotation >= 360.0f)
            planeRotation = 0;
    }
    if(glfwGetKey(window, GLFW_KEY_A) == GLFW_PRESS){
        planeRotation -= 1.0f;
        tiltAngle = 45.0f;
        if(planeRotation <= 0.0f)
            planeRotation = 360;
    }
}

// glfw: whenever the window size changed (by OS or user resize) this callback function executes
// ---------------------------------------------------------------------------------------------
void framebuffer_size_callback(GLFWwindow* window, int width, int height)
{
    // make sure the viewport matches the new window dimensions; note that width and
    // height will be significantly larger than specified on retina displays.
    glViewport(0, 0, width, height);
}