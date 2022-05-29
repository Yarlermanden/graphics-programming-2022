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

//--------------------------- Structs -----------------------------------
struct Ray
{
    vec3 point;
    vec3 direction;
    vec3 colorFilter;
    float indexOfRefraction;
};

struct Material
{
    vec3 color; //reflectionColor
    float metalness;
    float roughness;
    float diffuseReflectance;
    vec3 ambientLightColor;
    vec3 albedo;
    float transparency;
    float indexOfRefraction;
    vec3 reflectionGlobal;
};

struct Output
{
    vec3 point;
    vec3 normal;
    vec3 refractPoint;
    vec3 reflectionDirection;
    vec3 refractionDirection;
    Material material;
    float lowestTransparency; //used for shadow check
    bool totalInternalReflection;
};

struct Sphere
{
    vec3 center;
    float radius;
    Material material;
};

struct Rectangle
{
    vec3 point; //upper left
    float width;
    float height;
    float depth;
    vec3 rotation;
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

// ------------------------------------ const material -------------------------------------------
Material getMetalMaterial() {
    Material material;
    material.color = vec3(1.f); //reflectionColor
    material.metalness = 0.8f;
    material.roughness = 0.1f;
    material.diffuseReflectance = 20.f;
    material.ambientLightColor = vec3(0.1f);
    material.albedo = vec3(0.5f);
    material.indexOfRefraction = 1.0f;
    material.transparency = 0.f;
    material.reflectionGlobal = vec3(0.7f);
    return material;
}

Material getNormalMaterial() {
    Material material;
    material.color = vec3(1.f); //reflectionColor
    material.metalness = 0.2f;
    material.roughness = 0.3f;
    material.diffuseReflectance = 20.f;
    material.ambientLightColor = vec3(0.1f);
    material.albedo = vec3(0.3f);
    material.indexOfRefraction = 1.0f;
    material.transparency = 0.f;
    material.reflectionGlobal = vec3(0.3f);
    return material;
}

Material getGlassMaterial() {
    Material material;
    material.color = vec3(1.f); //reflectionColor
    material.metalness = 0.3f;
    material.roughness = 0.1f;
    material.diffuseReflectance = 10.f;
    material.ambientLightColor = vec3(0.1f);
    material.albedo = vec3(0.1f);
    material.transparency = 0.7f; //transmissionGlobal
    material.indexOfRefraction = 1.4f;
    material.reflectionGlobal = vec3(0.3f);
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

void Refraction(Ray ray, inout Output o, Sphere sphere){
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

    /*
    vec3 v_lat = v - (dot(v, n)*n);
    vec3 t_lat = -pow(index, -1) * v_lat;
    if(length(t_lat) >= 1) {
        //No refraction
        o.totalInternalReflection = true;
        return;
    }
    o.totalInternalReflection = false;

    vec3 t_perp = -sqrt(1-pow(length(t_lat), 2) * n);
    vec3 t = t_lat + t_perp;
    */
    o.refractionDirection = t;

    //1.5 for glass
    //1.3 for water
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
                Refraction(ray, o, sphere);
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
                    Refraction(ray, o, sphere);
                    //o.refractPoint = ray.point + max(-b + sqrt(discr) + 0.1f, 0.f) * o.refractionDirection;
                    //o.refractPoint = o.point + (max(-b + sqrt(discr) + 0.1f, 0.f) - d) * o.refractionDirection; //need to make the distance a bit smaller depending on the angle
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

bool rayRectangleIntersection(Ray ray, Rectangle rectangle, inout float distance, inout Output o)
{
    bool hit = false;
    Wall wall;

    /*
    //front surface
    wall.point = rectangle.point;
    wall.width = rectangle.width;
    wall.height = rectangle.height;
    wall.rotation = rectangle.rotation;
    wall.material = rectangle.material;
    hit = rayWallIntersection(ray, wall, distance, o) || hit;

    //left surface
    wall.point = rectangle.point;
    wall.width = rectangle.depth;
    wall.height = rectangle.height;
    wall.rotation = normalize(rectangle.rotation + vec3(0.f, 270.f, 0.f));
    wall.rotation = vec3(70.f, 0.f, 0.f);
    wall.material = rectangle.material;
    hit = rayWallIntersection(ray, wall, distance, o) || hit;
    */


    return hit;
}