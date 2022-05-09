#version 330 core
//Combining all into one file for understanding - this is not necessary

uniform mat4 _rt_View;
uniform mat4 _rt_InvView;
uniform mat4 _rt_Proj;
uniform mat4 _rt_InvProj;
uniform float _rt_Time;

in vec3 _rt_viewPos;
out vec4 FragColor;

const float infinity = 1.0f/0.0f;
const uint _rm_MaxRays = 100u;

struct Ray
{
    vec3 point;
    vec3 direction;
    vec3 colorFilter;
};

Ray _rt_pendingRays[_rm_MaxRays];
uint _rt_rayCount;

struct Material
{
    vec3 color;
};

struct Output
{
    vec3 point;
    vec3 normal;
    vec3 refractPoint;
    vec3 refractDirection;
    Material material;
};

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

                hit = true;
            }
        }
    }

    return hit;
}

// Fill in this function to define your scene
bool castRay(Ray ray, inout float distance, out Output o)
{
    Sphere sphere;
    sphere.center = vec3(0,0,-10);
    sphere.radius = 2.0f;
    sphere.material.color = vec3(1);

    bool hit = false;
    for (int i = 1; i <= 10; ++i)
    {
        vec3 offset = 5.0f * vec3(sin(3*i+_rt_Time), sin(2*i+_rt_Time), sin(4*i+_rt_Time));
        sphere.center = offset + vec3(0,0,-20);
        sphere.material.color = normalize(offset) * 0.5f + 0.5f;
        hit = raySphereIntersection(ray, sphere, distance, o) || hit;
    }
    return hit;
}

bool castRay(Ray ray, inout float distance)
{
    Output o;
    return castRay(ray, distance, o);
}

// Fill in this function to process the output once the ray has found a hit
vec3 ProcessOutput(Ray ray, Output o)
{
    return o.material.color;
}

// Function to enable recursive rays
bool PushRay(vec3 point, vec3 direction, vec3 colorFilter)
{
    bool pushed = false;
    if (_rt_rayCount < _rm_MaxRays)
    {
        Ray ray;
        ray.point = point + 0.001f * direction;
        ray.direction = direction;
        ray.colorFilter = colorFilter;
        _rt_pendingRays[_rt_rayCount++] = ray;
        pushed = true;
    }
    return pushed;
}

void main()
{
    _rt_rayCount = 0u;
    PushRay(_rt_viewPos, normalize(_rt_viewPos), vec3(1.0f));

    vec3 color = vec3(0);
    for (uint i = 0u; i < _rt_rayCount; ++i)
    {
        Ray ray = _rt_pendingRays[i];
        Output o;
        float distance = infinity;
        if (castRay(ray, distance, o))
        {
            color += ray.colorFilter * ProcessOutput(ray, o);
        }
    }
    FragColor = vec4(color, 1);
}

