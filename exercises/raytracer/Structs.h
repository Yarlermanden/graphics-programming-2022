//
// Created by Martin Holst on 29/05/2022.
//

#include <glm/glm.hpp>

struct ObjectMaterial {
    glm::vec3 color; //reflectionColor
    float transparency;
    glm::vec3 reflectionGlobal;
    float indexOfRefraction;

    //PhongLighting
    float I_aK_a; //I_a * K_a
    float diffuse; //I_light *I Kdf

    //PBR
    float metalness;
    float roughness;
    glm::vec3 ambientLightColor;
    float diffuseReflectance;
    glm::vec3 albedo;
    float PADDING;
};

struct Sphere {
    glm::vec3 center;
    float radius;
    ObjectMaterial material;
};

struct Rectangle
{
    glm::vec4 bounds[2];
    ObjectMaterial material;
};

class MaterialHelper {
public:
    static ObjectMaterial getMetalMaterial() ;
    static ObjectMaterial getNormalMaterial() ;
    static ObjectMaterial getGlassMaterial() ;
};
