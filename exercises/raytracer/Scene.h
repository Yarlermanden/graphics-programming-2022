//
// Created by Martin Holst on 29/05/2022.
//

#include <Structs.h>

class Scene {
public:
    Sphere spheres[14];
    //Array of walls

    Scene() {
        //Setup scene with the objects
        spheres[0].center = glm::vec3(10.f, 10.f, -50.f);
        spheres[0].radius = 3.f;
        spheres[0].material = MaterialHelper::getMetalMaterial();

        spheres[1].center = glm::vec3(0, 0, -200);
        spheres[1].radius = 100.f;
        spheres[1].material = MaterialHelper::getMetalMaterial();

        //steady ball
        spheres[2].center = glm::vec3(0,10,-25);
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
