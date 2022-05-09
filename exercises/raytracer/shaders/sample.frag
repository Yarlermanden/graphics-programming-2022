//This describes the scene
const uint _rm_MaxRays = 100u;

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

vec3 ProcessOutput(Ray ray, Output o)
{
    //todo implement phong or PBR
    vec3 light_pos = vec3(0, 1.9f, 0); //light position in model space
    if(lightingMode == 1){
        return PhongLighting(ray, o, light_pos);
    }
    return o.material.color;
}

vec3 PhongLighting(Ray ray, Output o, vec3 light_pos){
    float I_aK_a = 0.1f; //I_a * K_a
    vec3 R_ambient = I_aK_a * o.material.color; //Ia * Ka * color

    float diffuse = 0.5f; //I_light * Kdf
    vec3 L = normalize(light_pos - o.point); //light direction

    vec3 R_diffuse = diffuse * max(dot(o.normal, L), 0.0f) * o.material.color; //I_light * Kd * (N•L) * Color

    float I_light = 1.f; //Intensity of light
    float Ks = 0.6f; //specular reflectance
    float exp = 40.f; //specular exponent of material - shininess
    vec3 V = normalize(-o.point); //view direction //todo is this the same, as we now are in camera coordinates? And camera is not (0,0,0)
    vec3 H = normalize(L+V); //halfway vector between light direction and view direction
    float R_specular = I_light * Ks * pow(max(dot(o.normal, H), 0.0f), exp); //I_light * Ks * (N•H)^exp

    vec3 col = R_ambient;

    if(true) { //not in shadow
        col += R_diffuse + R_specular;
    }
    return col;
}