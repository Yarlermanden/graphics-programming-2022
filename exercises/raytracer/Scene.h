//
// Created by Martin Holst on 29/05/2022.
//

#include <Structs.h>
static const int sphereCount = 17;
static const int boxCount = 10;
static const int lightCount = 2;

struct Scene {
public:
    Sphere spheres[sphereCount];
    Rectangle rectangles[boxCount];
    Light lights[lightCount];
    Scene() {
        //Setup scene with the objects
        spheres[0].center = glm::vec3(10.f, 10.f, -50.f);
        spheres[0].radius = 3.f;
        spheres[0].material = MaterialHelper::getMetalMaterial();

        //spheres[1].center = glm::vec3(-50, 40, -80);
        spheres[1].center = glm::vec3(-65, 55, -95);
        spheres[1].radius = 20.f;
        spheres[1].material = MaterialHelper::getMetalMaterial();

        //steady ball
        spheres[2].center = glm::vec3(-20,10,-25);
        spheres[2].radius = 2.0f;
        spheres[2].material = MaterialHelper::getNormalMaterial();
        spheres[2].material.color = glm::vec3(0, 0, 1);

        spheres[3].center = glm::vec3(20, 10, -28);
        spheres[3].radius = 2.0f;
        spheres[3].material = MaterialHelper::getMetalMaterial();
        spheres[3].material.color = glm::vec3(1, 0, 0);

        //moving balls
        for (int i = 4; i < 14; ++i)
        {
            spheres[i].radius = 2.0f;
            if(i <= 5) spheres[i].material = MaterialHelper::getMetalMaterial();
            else if (i == 7) spheres[i].material = MaterialHelper::getGlassMaterial();
            else spheres[i].material = MaterialHelper::getNormalMaterial();
            spheres[i].center = glm::vec3(0.f);
        }

        //spheres[14].center = glm::vec3(20,20,-40);
        spheres[14].center = glm::vec3(10,15,-30);
        spheres[14].radius = 2.0f;
        spheres[14].material = MaterialHelper::getGlassMaterial();
        spheres[14].material.color = glm::vec3(1.f);


        //Rectangles: ----------------
        rectangles[0].bounds[0] = glm::vec4(-20, 0, 0, 0);
        rectangles[0].bounds[1] = glm::vec4(-5, 10, 5, 0);
        rectangles[0].material = MaterialHelper::getGlassMaterial();

        //Floor
        rectangles[1].bounds[0] = glm::vec4(-70, -11, -100, 0);
        rectangles[1].bounds[1] = glm::vec4(70, -10, 50, 0);
        rectangles[1].material = MaterialHelper::getNormalMaterial();

        //Left wall
        rectangles[2].bounds[0] = glm::vec4(-70, -11, -100, 0);
        rectangles[2].bounds[1] = glm::vec4(-69, 60, 50, 0);
        rectangles[2].material = MaterialHelper::getNormalMaterial();
        rectangles[2].material.color = glm::vec3(0.2, 0, 0);

        //Right wall
        rectangles[3].bounds[0] = glm::vec4(69, -11, -100, 0);
        rectangles[3].bounds[1] = glm::vec4(70, 60, 50, 0);
        rectangles[3].material = MaterialHelper::getNormalMaterial();
        rectangles[3].material.color = glm::vec3(1, 0.2, 0.2);

        //Back wall
        rectangles[4].bounds[0] = glm::vec4(-70, -11, -101, 0);
        rectangles[4].bounds[1] = glm::vec4(70, 61, -100, 0);
        rectangles[4].material = MaterialHelper::getNormalMaterial();
        rectangles[4].material.color = glm::vec3(0.2, 0.2, 0.6);

        //Ceiling wall - mirror
        rectangles[5].bounds[0] = glm::vec4(-70, 60, -100, 0);
        rectangles[5].bounds[1] = glm::vec4(70, 61, 50, 0);
        rectangles[5].material = MaterialHelper::getMetalMaterial();

        //Floor mirror
        rectangles[9].bounds[0] = glm::vec4(0, -10, -40, 0);
        rectangles[9].bounds[1] = glm::vec4(20, -9.5, -20, 0);
        rectangles[9].material = MaterialHelper::getMetalMaterial();

        //Square glass box
        rectangles[6].bounds[0] = glm::vec4(30, 0, -40, 0);
        rectangles[6].bounds[1] = glm::vec4(40, 10, -30, 0);
        rectangles[6].material = MaterialHelper::getGlassMaterial();

        //Square metal box
        rectangles[7].bounds[0] = glm::vec4(30, 0, -20, 0);
        rectangles[7].bounds[1] = glm::vec4(40, 10, -10, 0);
        rectangles[7].material = MaterialHelper::getMetalMaterial();

        //Square normal box
        rectangles[8].bounds[0] = glm::vec4(30, 0, 0, 0);
        rectangles[8].bounds[1] = glm::vec4(40, 10, 10, 0);
        rectangles[8].material = MaterialHelper::getNormalMaterial();

        //Lights --------
        spheres[16].center = glm::vec3(0,105, 700);
        spheres[16].radius = 50;
        spheres[16].material = MaterialHelper::getNormalMaterial();
        spheres[16].material.color = glm::vec3(1,1,0);
        lights[0].point = glm::vec3(0, 100, 500);
        lights[0].color = glm::vec3(100000);

        lights[1].point = glm::vec3(65, 55, -95);
        lights[1].color = glm::vec3(250, 250, 220);
    }

    //Method for updating scene
    void UpdateScene(float currentFrame) {
        //moving balls
        for (int i = 4; i < 14; ++i)
        {
            glm::vec3 offset = 5.0f * glm::vec3( sin(3*i+currentFrame), sin(2*i+currentFrame), sin(4*i+currentFrame)) - glm::vec3(i);
            glm::vec3 color = 5.0f * glm::vec3( sin(3*i), sin(2*i), sin(4*i));
            spheres[i].center = offset + glm::vec3(5,10,-20);
            spheres[i].material.color = normalize(color) * 0.5f + 0.5f;
        }
        spheres[7].material.color = glm::vec3(1.f);
    }
};
