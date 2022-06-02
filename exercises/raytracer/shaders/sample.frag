//This describes the scene
// --------------------------- Setup Scene ---------------------------------
bool castRay(Ray ray, inout float distance, out Output o)
{
    bool hit = false;
    bool tempHit = false;
    o.lowestTransparency = 1.f;

    for (int i = 0; i < sphereCount; i++){
        tempHit = raySphereIntersection(ray, spheres[i], distance, o);
        if(tempHit) o.indexOfObjectHit = i;
        hit = hit || tempHit;
    }
    for (int i = 0; i < boxCount; i++) {
        tempHit = rayRectangleIntersection(ray, rectangles[i], distance, o);
        if(tempHit) o.indexOfObjectHit = i+sphereCount;
        hit = hit || tempHit;
    }
    calculateOutputFromIntersection(ray, o, distance);
    return hit;
}

// ------------------------------ Process color/shading ------------------------------------------------
vec3 ProcessOutput(Ray ray, Output o, out bool inShadow)
{
    CheckForShadow(o); //Shadow feeler - shadow rays

    if(shadingMode == 1){
        return PhongLighting(ray, o);
    }
    else if(shadingMode == 2){
        //todo handle transparent objects in shadowcheck
        //todo handle multiple lights
        //return PBRLighting(ray, o, lights[0].point, length(o.invAmountOfShadow[0]) < 1);
        return PBRLighting(ray, o, lights[0].point);
    }
    return o.material.color;
}

vec3 PhongLighting(Ray ray, Output o){
    vec3 R_ambient = o.material.I_aK_a * o.material.color; //Ia * Ka * color
    vec3 col = R_ambient;

    for(int i = 0; i < lightCount; i++) {
        vec3 L = normalize(lights[i].point - o.point); //light direction
        vec3 R_diffuse = lights[i].color * o.material.diffuse * max(dot(o.normal, L), 0.0f) * o.material.color; //I_light * Kd * (N•L) * Color

        vec3 V = -ray.direction; //view direction
        vec3 H = normalize(L+V); //halfway vector between light direction and view direction
        vec3 R_specular = lights[i].color * o.material.Ks * pow(max(dot(o.normal, H), 0.0f), o.material.exp); //I_light * Ks * (N•H)^exp

        float distance = length(lights[i].point - o.point);
        float attenuation = 1/pow(distance,2);

        col += o.invAmountOfShadow[i] * attenuation * (R_diffuse + R_specular);
    }
    return col;
}

vec3 GetAmbientLighting(vec3 albedo, Output o){
    //vec3 ambient = textureLod(skybox, o.normal, 5.0f).rgb;
    vec3 ambient = o.material.ambientLightColor.rgb;
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

vec3 GetLambertianDiffuseLighting(vec3 N, vec3 L, vec3 albedo, Output o){
    //todo This should probably be updated with the lights
    vec3 diffuse = o.material.diffuseReflectance * albedo;
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

vec3 GetCookTorranceSpecularLighting(vec3 L, vec3 V, Output o)
{
    vec3 H = normalize(L + V);

    // Remap alpha parameter to roughness^2
    float a = o.material.roughness * o.material.roughness;
    float D = DistributionGGX(o.normal, H, a);
    float G = GeometrySmith(o.normal, V, L, a);
    float cosI = max(dot(o.normal, L), 0.0);
    float cosO = max(dot(o.normal, V), 0.0);

    // Important! Notice that Fresnel term (F) is not here because we apply it later when mixing with diffuse
    //todo so the comment above tells we don't add according to light intensity yet? but where?
    float specular = (D * G) / (4.0f * cosO * cosI + 0.0001f);

    return vec3(specular);
}

vec3 FresnelSchlick(vec3 F0, float cosTheta)
{
    return F0 + (1-F0)*(pow(1-cosTheta, 5));
}

vec3 PBRLighting(Ray ray, Output o, vec3 light_pos){
    vec3 albedo = o.material.albedo;
    albedo *= o.material.color;

    vec3 L = normalize(light_pos - o.point); //light direction
    //vec3 V = normalize(_rt_viewPos-o.point); //view direction - camera(0,0,0) - though not true
    vec3 V = normalize(-ray.direction);

    vec3 ambient = GetAmbientLighting(albedo, o);
    //vec3 environment = GetEnvironmentLighting(N, V);
    vec3 diffuse = GetLambertianDiffuseLighting(o.normal, L, albedo, o);
    vec3 specular = GetCookTorranceSpecularLighting(L, V, o);

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
    F0 = mix(F0, albedo, o.material.metalness);

    diffuse = mix(diffuse, vec3(0.0f), o.material.metalness);
    ambient = mix(ambient, vec3(0.0f), o.material.metalness);

    vec3 fresnelAmbient = FresnelSchlick(F0, clamp(dot(o.normal, V), 0, 1));
    //vec3 indirectLight = mix(ambient, environment, fresnelAmbient);
    vec3 indirectLight = ambient;

    vec3 H = normalize(L + V);
    vec3 fresnel = FresnelSchlick(F0, clamp(dot(H, V), 0, 1));

    vec3 directLight = mix(diffuse, specular, fresnel);

    //directLight *= lightRadiance;

    vec3 lighting = indirectLight;
    lighting += o.invAmountOfShadow[0] * directLight;
    return lighting;
}