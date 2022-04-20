
// Configure ray marcher
void GetRayMarcherConfig(out int maxSteps, out float maxDistance, out float surfaceDistance)
{
    maxSteps = 100;
    maxDistance = 100.0f;
    surfaceDistance = 0.001f;
}

// Required struct for o data (can't be empty)
struct Output
{
    vec3 color;
};

// Default value for o
void InitOutput(out Output o)
{
    o.color = vec3(0.0f);
}

float LandScape(float x, float y, float z) {
    //return 5*x + 3*y + 2*z;
    return 1;
}

// Signed distance function
float GetDistance(vec3 p, inout Output o)
{
    /*
    //float wave = sin(p.x / 15.0) + cos(p.z / 100.0);
    //float wave = sin(p.x / 15.0);
    //float wave = sin(0.1 + p.y / 360.0) + cos(0.5 + p.x)/100.0;
    //float wave = sin(p.y*p.y);
    float time = 0.1f;
    float wave = 7.0 * sin(p.x / 15.0 + time * 1.3) + 6.0 * cos(p.y / 15.0 + time / 1.1);

    float dSphere = sdfSphere(transformToLocal(p, vec3(0.1f, 0.1f, 0.0f)), 0.2f);
    float dSphere1 = sdfSphere(transformToLocal(p, vec3(-2, 0, -6)), 1.25f);
    float dSphere2 = sdfSphere(transformToLocal(p, vec3(-1.5, 0, -8)), 1.25f);
    float dSphere3 = sdfSphere(transformToLocal(p, vec3(-1, 0, -10)), 1.25f);

    float sphereMinimum = smin(smin(dSphere1, dSphere2, 2), dSphere3, 2);

    o.color = vec3(0.1f, 0.1f, 0.8f);

    //return sphereMinimum;
    return wave;
    //return min(min(min(dSphere, dSphere1), dSphere2), dSphere3);
    //return dSphere;
    */

    o.color = vec3(0.1f, 0.1f, 0.8f);
    return LandScape(p.x, p.y, p.z);
}

// Output function: Compute the final color
vec4 GetOutputColor(vec3 point, float distance, Output o)
{
    vec3 normal = calculateNormal(point);
    float dotNV = dot(normalize(-point), normal);
    return vec4(dotNV * o.color, 1.0f);
}
