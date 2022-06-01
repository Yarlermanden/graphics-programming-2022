//
// Created by Martin Holst on 29/05/2022.
//

#include <glm/glm.hpp>

struct ObjectMaterial {
    glm::vec3 color; //object color
    float transparency; //amount of refraction - transmissionGlobal
    glm::vec3 reflectionGlobal; //amount of reflection
    float indexOfRefraction;

    //PhongLighting
    float I_aK_a; //I_a * K_a
    float diffuse; //I Kdf //
    float Ks; //specular reflectance
    float exp; //specular exponent

    //PBR
    float metalness;
    float roughness;
    float padding1;
    float padding2;
    glm::vec3 ambientLightColor;
    float diffuseReflectance;
    glm::vec3 albedo;
    float padding3;
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

struct Light
{
    glm::vec3 point;
    float PADDING1;
    glm::vec3 color; //intensity and color
    float PADDING2;
};

class MaterialHelper {
public:
    static ObjectMaterial getMetalMaterial() ;
    static ObjectMaterial getNormalMaterial() ;
    static ObjectMaterial getGlassMaterial() ;
};
