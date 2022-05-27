// version not included here because it is a partial file
// This describes the functionality of when to ray trace and where - and main
//#version 330 core

in vec3 _rt_viewPos;

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
        _rt_pendingRays[_rt_rayCount++] = ray;
        pushed = true;
    }
    return pushed;
}

const float infinity = 1.0f/0.0f;

void main()
{
    _rt_rayCount = 0u;
    PushRay(_rt_viewPos, normalize(_rt_viewPos), vec3(1.0f), 1.f);

    vec3 color = vec3(0);

    for (uint i = 0u; i < _rt_rayCount; ++i)
    {
        Ray ray = _rt_pendingRays[i];

        Output o;
        float distance = infinity;
        if (castRay(ray, distance, o))
        {
            bool inShadow;
            color += (1-o.material.transparency) * ray.colorFilter * ProcessOutput(ray, o, inShadow);

            //todo reflection shouuld be multiple rays as surface isn't perfectly flat - BRDF to weight result
            float reflectionStrength = (1-o.material.roughness)*o.material.metalness*2 * (1-o.material.transparency);
            //if(inShadow) reflectionStrength /= 100;

            PushRay(o.point, o.reflectionDirection, vec3(reflectionStrength), ray.indexOfRefraction);
            if(o.material.transparency != 0.f) {
                float newIndex = o.material.indexOfRefraction == ray.indexOfRefraction ? 1.f : o.material.indexOfRefraction; //todo maybe this should be o.indexOfIncidence and then be handled when calculating angle
                PushRay(o.point, o.refractionDirection, vec3(o.material.transparency), newIndex); //refraction
            }
        }
    }

    FragColor = vec4(color, 1);
}