#version 330 core

// No main in this file, it is just a library
// This just describes the structs and general methods

uniform mat4 _rt_View;
uniform mat4 _rt_InvView;
uniform mat4 _rt_Proj;
uniform mat4 _rt_InvProj;
uniform float _rt_Time;
uniform int shadingMode;

const float PI = 3.14159265359;

struct Ray
{
    vec3 point;
    vec3 direction;
    vec3 colorFilter;
};

struct Material
{
    vec3 color; //reflectionColor
    float metalness;
    float roughness;
    float diffuseReflectance;
    vec3 ambientLightColor;
    vec3 albedo;
};

struct Output
{
    vec3 point;
    vec3 normal;
    vec3 refractPoint;
    vec3 refractDirection;
    Material material;
};

// Fill in this function to define your scene
bool castRay(Ray ray, inout float distance, out Output o);
bool castRay(Ray ray, inout float distance)
{
    Output o;
    return castRay(ray, distance, o);
}

bool CheckForShadow(vec3 light_pos, Output o){
    Ray rayTowardsLight;
    rayTowardsLight.direction = normalize(light_pos - o.point); //direction to light
    rayTowardsLight.point = o.point + (0.001f*rayTowardsLight.direction);
    float distanceToLight = length(light_pos - o.point);
    Output shadowOutput;
    bool inShadow = castRay(rayTowardsLight, distanceToLight, shadowOutput);
    //bool pushed = PushRay(rayTowardsLight.point, rayTowardsLight.direction, vec3(0.f));
    //bool inShadow = false;
    return inShadow;
}

vec3 PhongLighting(Ray ray, Output o, vec3 light_pos, bool inShadow);
vec3 PBRLighting(Ray ray, Output o, vec3 light_pos, bool inShadow);
// Fill in this function to process the output once the ray has found a hit
vec3 ProcessOutput(Ray ray, Output o, out bool inShadow);

// Function to enable recursive rays
bool PushRay(vec3 point, vec3 direction, vec3 colorFilter);



struct Sphere
{
    vec3 center;
    float radius;
    Material material;
};

bool raySphereIntersection(Ray ray, Sphere sphere, inout float distance, inout Output o)
{
    bool hit = false;

    vec3 m = ray.point - sphere.center;

    float b = dot(m, ray.direction);
    float c = dot(m, m) - sphere.radius * sphere.radius;

    if (c <= 0.0f || b <= 0.0f)
    {
        float discr = b * b - c;
        if (discr >= 0.0f)
        {
            float d = max(-b - sqrt(discr), 0.0f);

            if (d < distance)
            {
                distance = d;

                o.point = ray.point + d * ray.direction;
                o.normal = normalize(o.point - sphere.center);
                o.material = sphere.material;

                //todo if transparent object, we need to cast ray through the object - refraction
                o.refractPoint = o.point;
                //o.refractDirection = normalize(-ray.direction + o.normal);
                //o.refractDirection = 2*dot(-ray.direction, o.normal)*o.normal + ray.direction;
                o.refractDirection = normalize(2*dot(-ray.direction, o.normal)*o.normal + ray.direction);

                hit = true;
            }
        }
    }

    return hit;
}

struct Rectangle
{
    vec3 point; //upper left
    float width;
    float height;
    float depth;
    Material material;
};

struct Wall
{
    vec3 point;
    float width;
    float height;
    vec3 rotation;
    Material material;
};



mat4 rotationMatrix(vec3 axis, float angle)
{
    angle *= PI/180;
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;

    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
    oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
    oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
    0.0,                                0.0,                                0.0,                                1.0);
}

bool rayWallIntersection(Ray ray, Wall wall, inout float distance, inout Output o)
{
    //Inspired by : https://stackoverflow.com/questions/8812073/ray-and-square-wall-intersection-in-3d
    bool hit = false;

    vec3 R0 = ray.point;
    vec3 D = ray.direction;
    float t = 1.0f/0.0f;

    vec3 P0 = wall.point;
    mat4 rotationMatrixX = rotationMatrix(vec3(1.f, 0, 0), wall.rotation.x);
    mat4 rotationMatrixY = rotationMatrix(vec3(0.f, 1.f, 0), wall.rotation.y);
    mat4 rotationMatrixZ = rotationMatrix(vec3(0.f, 0.f, 1.f), wall.rotation.z);
    vec3 S1 = vec3(wall.width, 0.f, 0.f);
    vec3 S2 = vec3(0.f, wall.height, 0.f);
    //S1 = (vec4(S1, 1) * rotationMatrixX).xyz;
    //S2 = (vec4(S2, 1) * rotationMatrixY).xyz;
    mat4 rotationMatrix = rotationMatrixX * rotationMatrixY * rotationMatrixZ;
    vec4 S14 = rotationMatrix * vec4(S1, 1);
    S1 = S14.xyz;
    vec4 S24 = rotationMatrix * vec4(S2, 1);
    S2 = S24.xyz;
    vec3 N = cross(S1, S2);

    if(dot(D, N) < 0) {
        float d = dot((P0 - R0), N) / dot(D, N);

        if(d < distance){
            vec3 P = ray.point + d * ray.direction;
            vec3 P0P = P0-P;
            //check if point is within wall
            float Q1 = length(P0P.x);
            float Q2 = length(P0P.y);
            if((0 <= Q1 && Q1 <= length(S1)) && (0 <= Q2 && Q2 <= length(S2))) {
                o.point = P;
                o.normal = normalize(N) +0.01f;
                o.material = wall.material;
                //todo if transparent object, we need to cast ray through the object - refraction
                o.refractPoint = o.point;
                //o.refractDirection = normalize(-ray.direction + o.normal);
                //o.refractDirection = normalize(o.normal);

                o.refractDirection = normalize(2*dot(-ray.direction, o.normal)*o.normal + ray.direction);
                hit = true;
            }
        }
    }
    return hit;
}

bool rayRectangleIntersection(Ray ray, Rectangle rectangle, inout float distance, inout Output o)
{
    bool hit = false;

    Wall wall;
    wall.point = rectangle.point;
    wall.width = rectangle.width;
    wall.height = rectangle.height;
    wall.rotation = vec3(90, 0.f, 0);
    wall.material = rectangle.material;
    hit = rayWallIntersection(ray, wall, distance, o) || hit;
    return hit;
}