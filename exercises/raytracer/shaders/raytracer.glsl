// version not included here because it is a partial file
// This describes the functionality of when to ray trace and where - and main
//#version 330 core

in vec3 _rt_viewPos;

out vec4 FragColor;

Ray _rt_pendingRays[_rm_MaxRays];
uint _rt_rayCount;

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

const float infinity = 1.0f/0.0f;

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

            //todo check reflection
            PushRay(o.refractPoint, o.refractDirection, vec3(0.1f));
            /*
            Ray reflectionRay;
            reflectionRay.point = o.refractPoint + 0.001f * o.refractDirection;
            reflectionRay.direction = o.refractDirection;
            reflectionRay.colorFilter = vec3(0.1f);
            Output reflectionO;
            if(castRay(reflectionRay, distance, reflectionO)) {
                color += reflectionRay.colorFilter * ProcessOutput(reflectionRay, reflectionO);
            }
            */
        }
    }

    FragColor = vec4(color, 1);
}