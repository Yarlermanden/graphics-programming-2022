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
const uint _rm_MaxRays = 10u;
const float infinity = 1.0f/0.0f;
const int sphereCount = 17;
const int boxCount = 10;
const int lightCount = 2;

//--------------------------- Structs -----------------------------------
struct Ray
{
    vec3 point;
    vec3 direction;
    vec3 colorFilter;
    float indexOfRefraction;
    //vec3 invDir;
    //int sign[3];
};

struct ObjectMaterial
{
    vec3 color; //reflectionColor
    float transparency;
    vec3 reflectionGlobal;
    float indexOfRefraction;

    //PhongLighting
    float I_aK_a; //I_a * K_a
    float diffuse; //I Kdf
    float Ks; //specular reflectance
    float exp; //specular exponent

    //PBR
    float metalness;
    float roughness;
    float padding1;
    float padding2;
    vec3 ambientLightColor;
    float diffuseReflectance;
    vec3 albedo;
    float padding3;
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
    float invAmountOfShadow[lightCount]; //keeps track of amount of shadow for each light - used for shadow check
    bool totalInternalReflection;
    int indexOfObjectHit;
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

struct Light
{
    vec3 point;
    float PADDING1;
    vec3 color; //intensity and color
    float PADDING2;
};

layout (std140) uniform Scene {
    Sphere spheres[sphereCount];
    Rectangle rectangles[boxCount];
    Light lights[lightCount];
};

//-------------------------------------- Methods -------------------------------------------------
// Fill in this function to define your scene
bool castRay(Ray ray, inout float distance, out Output o, bool shadowCheck);
bool castRay(Ray ray, inout float distance)
{
    Output o;
    return castRay(ray, distance, o, false);
}

void CheckForShadow(inout Output o){
    for(int i = 0; i < lightCount; i++) {
        Ray rayTowardsLight;
        rayTowardsLight.direction = normalize(lights[i].point - o.point); //direction to light
        rayTowardsLight.point = o.point + (0.1f*rayTowardsLight.direction);
        float distanceToLight = length(lights[i].point - o.point);
        Output shadowOutput;
        bool inShadow = castRay(rayTowardsLight, distanceToLight, shadowOutput, true);
        o.invAmountOfShadow[i] = shadowOutput.lowestTransparency;
    }
}

vec3 PhongLighting(Ray ray, Output o);
vec3 PBRLighting(Ray ray, Output o, vec3 light_pos);
// Fill in this function to process the output once the ray has found a hit
vec3 ProcessOutput(Ray ray, Output o, out bool inShadow);

// Function to enable recursive rays
bool PushRay(vec3 point, vec3 direction, vec3 colorFilter);

void Refraction(Ray ray, inout Output o){
    vec3 v = -ray.direction;
    vec3 n = o.normal;
    float index = o.material.indexOfRefraction == ray.indexOfRefraction ? 1/o.material.indexOfRefraction : o.material.indexOfRefraction;

    vec3 t_lat = (dot(v, n)*n - v)/index; //angle between transmission direction and inverted normal
    float sinSq = pow(length(t_lat), 2);
    if(sinSq > 1) {
        o.totalInternalReflection = true;
        return;
    }
    vec3 t = t_lat - sqrt(1 - sinSq)*n;
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
                //if(o.lowestTransparency > sphere.material.transparency) o.lowestTransparency = sphere.material.transparency;
                distance = d;
                if(d < 0.f) { //inside object
                    distance = (-b + sqrt(discr) + 0.1f);
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

    /* -- Possible optimization
    float tmin, tmax, tymin, tymax, tzmin, tzmax;

    tmin = (rectangle.bounds[ray.sign[0]].x - ray.point.x) * ray.invDir.x;
    tmax = (rectangle.bounds[1-ray.sign[0]].x - ray.point.x) * ray.invDir.x;
    tymin = (rectangle.bounds[ray.sign[1]].y - ray.point.y) * ray.invDir.y;
    tymax = (rectangle.bounds[1-ray.sign[1]].y - ray.point.y) * ray.invDir.y;

    if ((tmin > tymax) || (tymin > tmax)) return false; //misses y completely
    if (tymin > tmin) tmin = tymin;
    if (tymax < tmax) tmax = tymax;

    tzmin = (rectangle.bounds[ray.sign[2]].z - ray.point.z) * ray.invDir.z;
    tzmax = (rectangle.bounds[1-ray.sign[2]].z - ray.point.z) * ray.invDir.z;

    if ((tmin > tzmax) || (tzmin > tmax)) return false; //misses z completely
    if (tzmin > tmin) tmin = tzmin;
    if (tzmax < tmax) tmax = tzmax;
    */

    float d = tmin;
    if(d < 0) {
        d = tmax;
        if (d < 0) {
            return false;
        }
    }
    if(o.lowestTransparency > rectangle.material.transparency) o.lowestTransparency = rectangle.material.transparency;
    if(d >= distance) return false; //Another object is closer
    //------- It has hit --------
    distance = d;
    return true;
}

void calculateOutputFromIntersection(Ray ray, inout Output o, float distance)
{
    o.totalInternalReflection = false;
    o.point = ray.point + distance * ray.direction;
    if(o.indexOfObjectHit < sphereCount) //hit sphere
    {
        Sphere sphere = spheres[o.indexOfObjectHit];
        o.material = sphere.material;

        if(length(ray.point-o.point) > length(ray.point-sphere.center)) //inside
        {
            o.normal = normalize(sphere.center - o.point);
        }
        else //outside
        {
            o.normal = normalize(o.point - sphere.center);
        }

    } else //hit rectangle
    {
        Rectangle rectangle = rectangles[o.indexOfObjectHit-sphereCount];
        o.material = rectangle.material;
        if(abs(o.point.x - rectangle.bounds[0].x) < 0.001 || abs(o.point.x - rectangle.bounds[1].x) < 0.01) {
            if(ray.direction.x > 0) o.normal = vec3(-1, 0, 0);
            else o.normal = vec3(1, 0, 0);
        }
        else if(abs(o.point.y - rectangle.bounds[0].y) < 0.001 || abs(o.point.y - rectangle.bounds[1].y) < 0.01) {
            if(ray.direction.y > 0) o.normal = vec3(0, -1, 0);
            else o.normal = vec3(0, 1, 0);
        }
        else if(abs(o.point.z - rectangle.bounds[0].z) < 0.001 || abs(o.point.z - rectangle.bounds[1].z) < 0.01) {
            if(ray.direction.z > 0) o.normal = vec3(0, 0, -1);
            else o.normal = vec3(0, 0, 1);
        }
    }
    o.reflectionDirection = normalize(2*dot(-ray.direction, o.normal)*o.normal + ray.direction);
    if (o.material.transparency > 0.f) {
        Refraction(ray, o);
    }
}