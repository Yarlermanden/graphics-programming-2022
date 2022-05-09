//This describes the scene
const uint _rm_MaxRays = 100u;
const float PI = 3.14159265359;

const float metalness = 0.4f;
const float diffuseReflectance = 6.25f;
const float roughness = 0.3f;
const vec3 ambientLightColor = vec3(1.0f, 1.0f, 1.0f);

bool castRay(Ray ray, inout float distance, out Output o)
{
    Sphere sphere;
    sphere.center = vec3(0,0,-30);
    sphere.radius = 2.0f;
    sphere.material.color = vec3(1);

    bool hit = raySphereIntersection(ray, sphere, distance, o);
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
    if(shadingMode == 1){
        return PhongLighting(ray, o, light_pos);
    }
    else if(shadingMode == 2){
        return PBRLighting(ray, o, light_pos);
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

vec3 GetAmbientLighting(vec3 albedo, vec3 normal){
    //vec3 ambient = textureLod(skybox, normal, 5.0f).rgb;
    vec3 ambient = ambientLightColor.rgb;
    ambient *= albedo/PI;

    //only apply ambient during the first light pass - if we have multiple
    //todo should the line below be uncommented?
    //ambient *= ambientLightColor.a;

    // NEW! Ambient occlusion (try disabling it to see how it affects the visual result)
    //float ambientOcclusion = texture(texture_ambient1, textureCoordinates).r;
    //ambient *= ambientOcclusion;
    return ambient;
}

/*
vec3 GetEnvironmentLighting(vec3 N, vec3 V){
    //NEW! Environment reflection

    // Compute reflected light vector (R)
    vec3 R = reflect(-V, N);

    // Sample cubemap
    // HACK: We sample a different mipmap depending on the roughness. Rougher surface will have blurry reflection
    vec3 reflection = textureLod(skybox, R, roughness * 5.0f).rgb;

    // We packed the amount of reflection in ambientLightColor.a
    // Only apply reflection (and ambient) during the first light pass
    reflection *= ambientLightColor.a;
    return reflection;
}
*/

vec3 GetLambertianDiffuseLighting(vec3 N, vec3 L, vec3 albedo){
    vec3 diffuse = diffuseReflectance * albedo;
    diffuse /= PI;
    return diffuse;
}

float DistributionGGX(vec3 N, vec3 H, float a)
{
    float a2 = pow(a, 2);
    float nh = max(dot(N, H), 0);
    return a2/(PI * pow(pow(nh, 2)*(a2-1)+1, 2));
}

float GeometrySchlickGGX(float cosAngle, float a)
{
    float a2 = pow(a, 2);
    return (2*cosAngle)/(cosAngle + sqrt(a2 + (1-a2)*pow(cosAngle, 2)));
}

float GeometrySmith(vec3 N, vec3 V, vec3 L, float a)
{
    float g1 = GeometrySchlickGGX(max(dot(L, N), 0), a);
    float g2 = GeometrySchlickGGX(max(dot(V, N), 0), a);
    return g1*g2;
}

vec3 GetCookTorranceSpecularLighting(vec3 N, vec3 L, vec3 V)
{
    vec3 H = normalize(L + V);

    // Remap alpha parameter to roughness^2
    float a = roughness * roughness;
    float D = DistributionGGX(N, H, a);
    float G = GeometrySmith(N, V, L, a);
    float cosI = max(dot(N, L), 0.0);
    float cosO = max(dot(N, V), 0.0);

    // Important! Notice that Fresnel term (F) is not here because we apply it later when mixing with diffuse
    float specular = (D * G) / (4.0f * cosO * cosI + 0.0001f);

    return vec3(specular);
}

vec3 FresnelSchlick(vec3 F0, float cosTheta)
{
    return F0 + (1-F0)*(pow(1-cosTheta, 5));
}

vec3 PBRLighting(Ray ray, Output o, vec3 light_pos){
    vec3 albedo = vec3(0.3f); //from material shader
    albedo *= o.material.color;

    vec3 L = normalize(light_pos - o.point); //light direction
    vec3 V = normalize(-o.point); //view direction - camera(0,0,0) - though not true

    vec3 ambient = GetAmbientLighting(albedo, o.normal);
    //vec3 environment = GetEnvironmentLighting(N, V);
    vec3 diffuse = GetLambertianDiffuseLighting(o.normal, L, albedo);
    vec3 specular = GetCookTorranceSpecularLighting(o.normal, L, V);

    /*
    vec3 lightRadiance = vec3(1.f); //light color
    // Modulate lightRadiance by distance attenuation (only for positional lights)
    float attenuation = positional ? GetAttenuation(P) : 1.0f;
    lightRadiance *= attenuation;
    // Modulate lightRadiance by shadow (only for directional light)
    float shadow = positional ? 1.0f : GetShadow();
    lightRadiance *= shadow;
    // Modulate the radiance with the angle of incidence
    lightRadiance *= max(dot(N, L), 0.0);
    */

    vec3 F0 = vec3(0.04f);
    F0 = mix(F0, albedo, metalness);

    diffuse = mix(diffuse, vec3(0.0f), metalness);
    ambient = mix(ambient, vec3(0.0f), metalness);

    vec3 fresnelAmbient = FresnelSchlick(F0, clamp(dot(o.normal, V), 0, 1));
    //vec3 indirectLight = mix(ambient, environment, fresnelAmbient);
    vec3 indirectLight = ambient;

    vec3 H = normalize(L + V);
    vec3 fresnel = FresnelSchlick(F0, clamp(dot(H, V), 0, 1));

    vec3 directLight = mix(diffuse, specular, fresnel);

    //directLight *= lightRadiance;

    vec3 lighting = indirectLight + directLight;
    return lighting;
}