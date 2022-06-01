#version 330 core

// No main in this file, it is just a library
// This just describes the structs and general methods
in vec3 _rt_viewPos;
in vec3 _rt_viewDir;

uniform mat4 _rt_View;
uniform mat4 _rt_InvView;
uniform mat4 _rt_Proj;
uniform mat4 _rt_InvProj;
uniform float _rt_Time;
uniform int shadingMode;

const float PI = 3.14159265359;
const uint _rm_MaxRays = 20u;
const float infinity = 1.0f/0.0f;
const int sphereCount = 15;
const int boxCount = 7;

//--------------------------- Structs -----------------------------------
struct Ray
{
    vec3 point;
    vec3 direction;
    vec3 colorFilter;
    float indexOfRefraction;
};

struct ObjectMaterial
{
    vec3 color; //reflectionColor
    float transparency;
    vec3 reflectionGlobal;
    float indexOfRefraction;

    //PhongLighting
    float I_aK_a; //I_a * K_a
    float diffuse; //I_light *I Kdf

    //PBR
    float metalness;
    float roughness;
    vec3 ambientLightColor;
    float diffuseReflectance;
    vec3 albedo;
    float PADDING;
};

struct Output
{
    vec3 point;
    vec3 normal;
    vec3 refractPoint;
    vec3 reflectionDirection;
    vec3 refractionDirection;
    ObjectMaterial material;
    float lowestTransparency; //used for shadow check
    bool totalInternalReflection;
};

struct Sphere
{
    vec3 center;
    float radius;
    ObjectMaterial material;
};

struct Rectangle
{
    vec4 bounds[2];
    ObjectMaterial material;
};

struct Wall
{
    vec3 point;
    float width;
    float height;
    vec3 rotation;
    ObjectMaterial material;
};

//-------------------------------------- Methods -------------------------------------------------
// Fill in this function to define your scene
bool castRay(Ray ray, inout float distance, out Output o);
bool castRay(Ray ray, inout float distance)
{
    Output o;
    return castRay(ray, distance, o);
}

bool CheckForShadow(vec3 light_pos, inout Output o){
    Ray rayTowardsLight;
    rayTowardsLight.direction = normalize(light_pos - o.point); //direction to light
    rayTowardsLight.point = o.point + (0.001f*rayTowardsLight.direction);
    float distanceToLight = length(light_pos - o.point);
    Output shadowOutput;
    bool inShadow = castRay(rayTowardsLight, distanceToLight, shadowOutput); //todo do this for each light
    //bool pushed = PushRay(rayTowardsLight.point, rayTowardsLight.direction, vec3(0.f));
    //bool inShadow = false;
    o.lowestTransparency = shadowOutput.lowestTransparency;
    return inShadow;
}

vec3 PhongLighting(Ray ray, Output o, vec3 light_pos, bool inShadow);
vec3 PBRLighting(Ray ray, Output o, vec3 light_pos, bool inShadow);
// Fill in this function to process the output once the ray has found a hit
vec3 ProcessOutput(Ray ray, Output o, out bool inShadow);

// Function to enable recursive rays
bool PushRay(vec3 point, vec3 direction, vec3 colorFilter);

void Refraction(Ray ray, inout Output o){
    vec3 v = -ray.direction;
    vec3 n = o.normal;
    float index = o.material.indexOfRefraction == ray.indexOfRefraction ? 1/o.material.indexOfRefraction : o.material.indexOfRefraction;

    vec3 t_lat = (dot(v, n)*n - v)/index;
    float sinSq = pow(length(t_lat), 2);
    if(sinSq > 1) {
        o.totalInternalReflection = true;
        return;
    }
    vec3 t = t_lat - sqrt(1 - sinSq*n);
    o.refractionDirection = t;
}

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
            if(o.lowestTransparency > sphere.material.transparency) o.lowestTransparency = sphere.material.transparency;
            float d = -b - sqrt(discr);
            if(d >= distance) return false; //Another object is closer
            else {
                o.material = sphere.material;
                distance = d;
                if(d < 0.f) { //inside object
                    o.point = ray.point + max((-b + sqrt(discr) + 0.1f), 0.f) * ray.direction;
                    o.normal = normalize(sphere.center - o.point);
                }
                else //outside
                {
                    o.totalInternalReflection = false;
                    o.point = ray.point + d * ray.direction;
                    o.normal = normalize(o.point - sphere.center);
                }
                o.reflectionDirection = normalize(2*dot(-ray.direction, o.normal)*o.normal + ray.direction);
                if (o.material.transparency != 0.f) {
                    Refraction(ray, o);
                }
                hit = true;
            }
        }
    }
    return hit;
}

void conditionalSwap(inout float min, inout float max) {
    if(min > max) {
        float temp = min;
        min = max;
        max = temp;
    }
}

bool rayRectangleIntersection(Ray ray, Rectangle rectangle, inout float distance, inout Output o)
{
    //Inspired from:
    //https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-box-intersection
    bool hit = false;

    float tmin = (rectangle.bounds[0].x - ray.point.x) / ray.direction.x;
    float tmax = (rectangle.bounds[1].x - ray.point.x) / ray.direction.x;
    conditionalSwap(tmin, tmax);

    float tymin = (rectangle.bounds[0].y - ray.point.y) / ray.direction.y;
    float tymax = (rectangle.bounds[1].y - ray.point.y) / ray.direction.y;
    conditionalSwap(tymin, tymax);

    if ((tmin > tymax) || (tymin > tmax)) return false;
    if (tymin > tmin) tmin = tymin;
    if (tymax < tmax) tmax = tymax;

    float tzmin = (rectangle.bounds[0].z - ray.point.z) / ray.direction.z;
    float tzmax = (rectangle.bounds[1].z - ray.point.z) / ray.direction.z;
    conditionalSwap(tzmin, tzmax);

    if ((tmin > tzmax) || (tzmin > tmax)) return false;
    if (tzmin > tmin) tmin = tzmin;
    if (tzmax < tmax) tmax = tzmax;

    float d = tmin;
    bool inside = false;
    if(d < 0) {
        d = tmax;
        if (d < 0) {
            return false;
        }
        inside = true;
        //would this mean we are inside?
    }
    if(d > distance) return false;
    //------- It has hit --------
    distance = d;

    if(o.lowestTransparency > rectangle.material.transparency) o.lowestTransparency = rectangle.material.transparency;
    o.totalInternalReflection = false;
    o.point = ray.point + distance * ray.direction;

    if(abs(o.point.x - rectangle.bounds[0].x) < 0.01 || abs(o.point.x - rectangle.bounds[1].x) < 0.01) {
        if(ray.direction.x > 0) o.normal = vec3(-1, 0, 0);
        else o.normal = vec3(1, 0, 0);
    }
    else if(abs(o.point.y - rectangle.bounds[0].y) < 0.01 || abs(o.point.y - rectangle.bounds[1].y) < 0.01) {
        if(ray.direction.y > 0) o.normal = vec3(0, -1, 0);
        else o.normal = vec3(0, 1, 0);
    }
    else if(abs(o.point.z - rectangle.bounds[0].z) < 0.01 || abs(o.point.z - rectangle.bounds[1].z) < 0.01) {
        if(ray.direction.z > 0) o.normal = vec3(0, 0, -1);
        else o.normal = vec3(0, 0, 1);
    }
    o.material = rectangle.material;
    o.reflectionDirection = normalize(2*dot(-ray.direction, o.normal)*o.normal + ray.direction);

    if (o.material.transparency != 0.f) {
        if(inside) o.material.color = vec3(0, 1, 0);
        //if(inside) o.normal = -o.normal; //todo anything we need to do regarding refraction for rectangles when inside?
        Refraction(ray, o);
    }
    return true;
}