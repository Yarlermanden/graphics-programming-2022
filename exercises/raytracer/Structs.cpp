//
// Created by Martin Holst on 29/05/2022.
//

#include "Structs.h"

ObjectMaterial MaterialHelper::getMetalMaterial() {
    ObjectMaterial material;
    material.color = glm::vec3(0.1f); //reflectionColor
    material.indexOfRefraction = 1.0f;
    material.transparency = 0.f;
    material.reflectionGlobal = glm::vec3(0.9f);

    material.I_aK_a = 0.05f;
    material.diffuse = 0.3f;

    material.ambientLightColor = glm::vec3(0.2f);
    material.metalness = 0.9f;
    material.roughness = 0.1f;
    material.diffuseReflectance = 20.f;
    material.albedo = glm::vec3(.3f);
    return material;
}

ObjectMaterial MaterialHelper::getNormalMaterial() {
    ObjectMaterial material;
    material.color = glm::vec3(0.3f); //reflectionColor
    material.indexOfRefraction = 1.0f;
    material.transparency = 0.0f;
    material.reflectionGlobal = glm::vec3(0.01f);

    material.I_aK_a = 0.05f;
    material.diffuse = 0.9f;

    material.ambientLightColor = glm::vec3(0.1f);
    material.metalness = 0.2f;
    material.roughness = 0.3f;
    material.diffuseReflectance = 20.f;
    material.albedo = glm::vec3(0.3f);
    return material;
}

ObjectMaterial MaterialHelper::getGlassMaterial() {
    ObjectMaterial material;
    material.color = glm::vec3(0.0f); //reflectionColor
    material.indexOfRefraction = 1.4f;
    material.transparency = 0.9f; //transmissionGlobal
    material.reflectionGlobal = glm::vec3(0.1f);

    material.I_aK_a = 0.05f;
    material.diffuse = 0.05f;

    material.metalness = 0.3f;
    material.roughness = 0.1f;
    material.diffuseReflectance = 10.f;
    material.ambientLightColor = glm::vec3(0.1f);
    material.albedo = glm::vec3(0.1f);
    return material;
}
