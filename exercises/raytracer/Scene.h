//
// Created by Martin Holst on 29/05/2022.
//

#ifndef CELSHADING_SHADER_SCENE_H
#define CELSHADING_SHADER_SCENE_H

#endif //CELSHADING_SHADER_SCENE_H

#include <Structs.h>

class Scene {
    Sphere sphere1;
    //Array of spheres
    //Array of walls

public:
    Scene() {
        //Setup scene with the objects
        sphere1.center = glm::vec3(1.f);
        sphere1.radius = 3.f;
        sphere1.material = getNormalMaterial();
    }

    //Method for updating scene
    void UpdateScene(float currentFrame) {
        //Move objects

    }

};