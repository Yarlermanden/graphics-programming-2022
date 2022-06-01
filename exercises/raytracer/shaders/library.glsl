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
const uint _rm_MaxRays = 100u;
const float infinity = 1.0f/0.0f;
const int sphereCount = 15;
const int boxCount = 1;

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

// ------------------------------------ const material -------------------------------------------
//todo remove these material methods
ObjectMaterial getMetalMaterial() {
    ObjectMaterial material;
    material.color = vec3(0.2f); //reflectionColor
    material.indexOfRefraction = 1.0f;
    material.transparency = 0.f;
    material.reflectionGlobal = vec3(0.7f);

    material.I_aK_a = 0.05f;
    material.diffuse = 0.4f;

    material.ambientLightColor = vec3(0.2f);
    material.metalness = 0.9f;
    material.roughness = 0.1f;
    material.diffuseReflectance = 20.f;
    material.albedo = vec3(.3f);
    return material;
}

ObjectMaterial getNormalMaterial() {
    ObjectMaterial material;
    material.color = vec3(1.f); //reflectionColor
    material.indexOfRefraction = 1.0f;
    material.transparency = 0.f;
    material.reflectionGlobal = vec3(0.01f);

    material.I_aK_a = 0.05f;
    material.diffuse = 0.7f;

    material.ambientLightColor = vec3(0.1f);
    material.metalness = 0.2f;
    material.roughness = 0.3f;
    material.diffuseReflectance = 20.f;
    material.albedo = vec3(0.3f);
    return material;
}

ObjectMaterial getGlassMaterial() {
    ObjectMaterial material;
    material.color = vec3(1.f); //reflectionColor
    material.indexOfRefraction = 1.0f;
    material.transparency = 0.9f; //transmissionGlobal
    material.reflectionGlobal = vec3(0.1f);

    material.I_aK_a = 0.05f;
    material.diffuse = 0.1f;

    material.metalness = 0.3f;
    material.roughness = 0.1f;
    material.diffuseReflectance = 10.f;
    material.ambientLightColor = vec3(0.1f);
    material.albedo = vec3(0.1f);
    return material;
}

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
    bool inShadow = castRay(rayTowardsLight, distanceToLight, shadowOutput);
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
            float d = -b - sqrt(discr);
            if(d < 0.f) {
                //todo Need to handle, when it hits the edge of the object
                //return false;
                distance = d;
                o.point = ray.point + max((-b + sqrt(discr) + 0.1f), 0.f) * ray.direction;
                o.normal = normalize(sphere.center - o.point);
                o.material = sphere.material;
                //o.reflectionDirection = normalize(2*dot(-ray.direction, -o.normal) * -o.normal + ray.direction);
                o.reflectionDirection = normalize(2*dot(-ray.direction, o.normal) * o.normal + ray.direction);
                Refraction(ray, o);
                hit = true;
                //return true; //if d is less than small, the ray.point is inside the object
            }
            else if (d < distance)
            {
                distance = d;
                if(o.lowestTransparency > sphere.material.transparency) o.lowestTransparency = sphere.material.transparency;
                o.totalInternalReflection = false;
                o.point = ray.point + d * ray.direction;
                o.normal = normalize(o.point - sphere.center);
                o.material = sphere.material;
                o.reflectionDirection = normalize(2*dot(-ray.direction, o.normal)*o.normal + ray.direction);

                if (o.material.transparency != 0.f) {
                    Refraction(ray, o);
                    //o.refractPoint = ray.point + max(-b + sqrt(discr) + 0.1f, 0.f) * o.refractionDirection;
                    //o.refractPoint = o.point + (rectangle.bounds[1].-b + sqrt(discr) + 0.1f, 0.f) - d) * o.refractionDirection; //need to make the distance a bit smaller depending on the angle
                }

                hit = true;
            }
        }
    }
    return hit;
}


mat3 rotateX(float angle)
{
    angle *= PI/180;
    float s = sin(angle);
    float c = cos(angle);
    return mat3(1, 0, 0,
                0, c, -s,
                0, s, c);
}

mat3 rotateY(float angle)
{
    angle *= PI/180;
    float s = sin(angle);
    float c = cos(angle);
    return mat3(c, 0, s,
                0, 1, 0,
                -s, 0, c);
}

mat3 rotateZ(float angle)
{
    angle *= PI/180;
    float s = sin(angle);
    float c = cos(angle);
    return mat3(c, -s, 0,
                s, c, 0,
                0, 0, 1);
}

bool rayWallIntersection(Ray ray, Wall wall, inout float distance, inout Output o)
{
    //Inspired by : https://stackoverflow.com/questions/8812073/ray-and-square-wall-intersection-in-3d
    bool hit = false;

    vec3 R0 = ray.point;
    vec3 D = ray.direction;
    float t = 1.0f/0.0f;

    vec3 P0 = wall.point;

    mat3 rotationMatrix = rotateX(wall.rotation.x) * rotateY(wall.rotation.y) * rotateZ(wall.rotation.z);
    vec3 S1 = rotationMatrix*vec3(wall.width, 0.f, 0.f);
    vec3 S2 = rotationMatrix*vec3(0.f, wall.height, 0.f);
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
                o.reflectionDirection = normalize(2*dot(-ray.direction, o.normal)*o.normal + ray.direction); //from book
                //Refraction(ray, o);

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
    if(d < 0) {
        d = tmax;
        if (d < 0) return false;
        //would this mean we are inside?
    }
    if(d > distance) return false;
    //------- It has hit --------
    distance = d;

    if(o.lowestTransparency > rectangle.material.transparency) o.lowestTransparency = rectangle.material.transparency;
    o.totalInternalReflection = false;
    o.point = ray.point + distance * ray.direction;

    if(o.point.x - rectangle.bounds[0].x < 0.01) {
        //We know we hit the smallest of the x boundings.
        //Now the question is whether this is from inside or outside
        if(ray.direction.x > 0) o.normal = vec3(-1, 0, 0); //outside
        else o.normal = vec3(1, 0, 0); //inside
    }
    else if(o.point.x - rectangle.bounds[1].x < 0.01) {
        if(ray.direction.x > 0) o.normal = vec3(-1, 0, 0); //inside
        else o.normal = vec3(1, 0, 0); //outside
    }
    else if(o.point.y - rectangle.bounds[0].y < 0.01 || o.point.y - rectangle.bounds[1].y < 0.01) {
        if(ray.direction.y > 0) o.normal = vec3(0, -1, 0);
        else o.normal = vec3(0, 1, 0);
    }
    else if(o.point.z - rectangle.bounds[0].z < 0.01 || o.point.z - rectangle.bounds[1].z < 0.01) {
        if(ray.direction.z > 0) o.normal = vec3(0, 0, -1);
        else o.normal = vec3(0, 0, 1);
    }
    o.material = rectangle.material;
    o.reflectionDirection = normalize(2*dot(-ray.direction, o.normal)*o.normal + ray.direction);

    if (o.material.transparency != 0.f) {
        Refraction(ray, o); //todo find refraction from rectangle
    }
    return true;
}