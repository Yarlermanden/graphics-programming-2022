// version not included here because it is a partial file
// This describes the functionality of when to ray trace and where - and main
//#version 330 core

out vec4 FragColor;

Ray _rt_pendingRays[_rm_MaxRays];
uint _rt_rayCount;

bool PushRay(vec3 point, vec3 direction, vec3 colorFilter, float indexOfRefraction)
{
    bool pushed = false;
    if (_rt_rayCount < _rm_MaxRays)
    {
        Ray ray;
        ray.point = point + 0.01f * direction;
        ray.direction = direction;
        ray.colorFilter = colorFilter;
        ray.indexOfRefraction = indexOfRefraction;
        /*
        ray.invDir = 1/ray.direction;
        ray.sign[0] = (ray.invDir.x < 0) ? 1 : 0;
        ray.sign[1] = (ray.invDir.y < 0) ? 1 : 0;
        ray.sign[2] = (ray.invDir.z < 0) ? 1 : 0;
        */
        _rt_pendingRays[_rt_rayCount++] = ray;
        pushed = true;
    }
    return pushed;
}

void main()
{
    _rt_rayCount = 0u;
    PushRay(_rt_viewPos, normalize(_rt_viewDir), vec3(1.0f), 1.f); //Original ray
    vec3 color = vec3(0);

    for (uint i = 0u; i < _rt_rayCount; ++i)
    {
        Ray ray = _rt_pendingRays[i];
        Output o;
        float distance = infinity;

        if (castRay(ray, distance, o, false)) //Checks for collision
        {
            bool inShadow;
            if(o.totalInternalReflection) continue;
            color += ray.colorFilter * ProcessOutput(ray, o, inShadow); //only apply color according to filter

            if(length(ray.colorFilter) < 0.001) continue; //For performance - to stop insignificant rays
            PushRay(o.point, o.reflectionDirection, ray.colorFilter*o.material.reflectionGlobal, ray.indexOfRefraction); //Reflection ray
            if(o.material.transparency > 0.f) {
                float newIndex = o.material.indexOfRefraction == ray.indexOfRefraction ? 1.f : o.material.indexOfRefraction; //todo maybe this should be o.indexOfIncidence and then be handled when calculating angle
                PushRay(o.point, o.refractionDirection, ray.colorFilter*vec3(o.material.transparency), newIndex); //refraction ray
            }
        }
    }
    FragColor = vec4(color, 1);
}