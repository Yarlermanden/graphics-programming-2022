#pragma clang diagnostic push
#pragma ide diagnostic ignored "openmp-use-default-none"
//
// Created by henrique on 04/11/2021.
//

#ifndef ITU_GRAPHICS_PROGRAMMING_RT_RENDERER_H
#define ITU_GRAPHICS_PROGRAMMING_RT_RENDERER_H

#include <vector>
#include <glm/glm.hpp>
#include <glm/gtx/transform.hpp>
#include "rt_types.h"
#include "frame_buffer.h"

#include <omp.h>

namespace rt{
    using namespace Colors;
    using namespace glm;

    class Renderer{

        const unsigned int max_recursion = 5;
        float p_rg = 0.4f;

    public:
        void render(const std::vector<vertex> &vts,
                    const glm::mat4 &m,
                    const glm::mat4 &v,
                    const float fov_degrees,
                    unsigned int depth,
                    FrameBuffer <uint32_t> &fb) {

            float aspect_ratio = ((float) fb.H) / fb.W;
            // we use the fov and the tangent function to compute where is the bottom of the projection plane,
            // we assume that the projection place is 1 unit in front of the camera (z == -1)
            float bottom = - tan(abs(radians(fov_degrees)) * 0.5f);

            // find the transformation that move points from camera space to model space
            mat4 view_to_model = inverse(v * m);
            // the bottom left corner of the image plane/camera sensor
            vec4 lower_left_corner = vec4(bottom * aspect_ratio, bottom, -1, 1);
            // we transform the camera position (also the convergence point of light rays) from camera coordinates to model coordinates
            // notice that we implicitly assume that the camera position is at 0,0,0 in its one coordinate space
            vec4 cam_pos = view_to_model * vec4(0,0,0,1);

            // the distance from the center of one pixel to the next along the horizontal and vertical axes of the screen
            // notice that * and / are applied component wise
            vec2 pixel_size = abs(vec2(lower_left_corner)) * 2.0f / vec2(fb.H, fb.W);


            // TODO ex 11.1 iterate through all pixels in the buffer (width: [0, fb.W), height:[0, fb.H])
            //  for each pixel,
            //omp_set_num_threads(10);
            //#pragma omp parallel default(none)
            #pragma omp parallel for
            //#pragma omp target teams distribute parallel for
            for (int i = 0; i < fb.W; i++) {
                //#pragma omp parallel for
                for (int j = 0; j < fb.H; j++) {
                    //  - find its position in the space of the camera,
                    vec4 position = lower_left_corner + vec4(float(i) / float(fb.W), float(j) / float(fb.H), 0, 0);

                    //  - apply the view_to_model transformation so that we place the pixel in the space of the model
                    vec4 position_in_model = view_to_model * position;
                    //  (do you notice a different pattern? contrary to the typical raster pipeline, it is sometimes cheaper to
                    //  transform from camera space than the other way around -fewer computations-, what is important is that
                    //  all intersection computations should happen in the same space, no matter what that space is)

                    //  - create a ray with the camera origin, and the vector from the camera origin to the pixel you have just found
                    auto ray = Ray(cam_pos, position_in_model - cam_pos);

                    //  - call the TraceRay method using that ray, and store the resulting color in the frame buffer (fb)
                    color c = TraceRay(ray, depth, vts);

                    fb.paintAt(i, j, toRGBA32(c));
                }
            }
        }


        color TraceRay(const Ray & ray,
                       unsigned int depth,
                       const std::vector<vertex> &vts){
            // this is here to ensure we don't end up with a long recurssion that can freeze the program (or a stack overflow)
            depth = depth > max_recursion ? max_recursion : depth;

            color col = black; // used to output a color
            Hit hitInfo; // used to store the hit information
            if (!RayModelIntersection(ray, vts, hitInfo)) return col; // no hit, return black


            // TODO ex 11.2 replace the current i_normal and i_col computation with their interpolated versions
            auto corner1 = vts[hitInfo.hit_ID];
            auto corner2 = vts[hitInfo.hit_ID+1];
            auto corner3 = vts[hitInfo.hit_ID+2];
            vec3 i_normal = normalize(vts[hitInfo.hit_ID].norm * hitInfo.barycentric.x
                    + vts[hitInfo.hit_ID+1].norm * hitInfo.barycentric.y
                    + vts[hitInfo.hit_ID+2].norm * hitInfo.barycentric.z);
            color i_col = vts[hitInfo.hit_ID].col * hitInfo.barycentric.x
                    + vts[hitInfo.hit_ID+1].col * hitInfo.barycentric.y
                    + vts[hitInfo.hit_ID+2].col * hitInfo.barycentric.z;
            vec3 i_pos = ray.origin + ray.direction * hitInfo.dist;

            // TODO ex 11.3 implement the phong reflection model for the point light below

            float I_aK_a = 0.1f; //I_a * K_a
            auto R_ambient = I_aK_a * i_col; //Ia * Ka * color

            //float diffuse = 0.5f; //I_light * Kd
            float diffuse = corner1.mat.diffuse; //I_light * Kd
            vec3 light_pos(0,1.9f,0); // light position in model space
            vec3 L = normalize(light_pos - i_pos); //light direction

            auto R_diffuse =  diffuse * max(dot(i_normal, L), 0.0f) * i_col; //I_light * Kd * (N•L) * Color

            float I_light = 1.f; //intensity of light
            //float Ks = 0.6f; //specular reflectance
            float Ks = corner1.mat.specularReflectance; //specular reflectance
            //float exp = 40.f; //specular exponent of material - shininess
            float exp = corner1.mat.specularExp; //specular exponent of material - shininess
            vec3 V = normalize(-i_pos); //view direction - as camera is at (0,0,0)
            vec3 H = normalize(L+V); //halfway vector between light direction and view direction
            float R_specular = I_light * Ks * pow(max(dot(i_normal, H), 0.0f), exp); //I_light * Ks * (N•H)^exp
            //float R_specular = I_light * Ks * pow(max(dot(L, i_normal), 0.0f), exp); //I_light * Ks * (N•H)^exp

            col = R_ambient;

            //Check for shadow
            Ray shadow_ray(i_pos + i_normal * .001f, L); // ray towards light from hitpoint
            float dist_to_light = length(light_pos - i_pos);
            Hit shadow_hit;
            // check if there is a hit closer than distance to light
            if (!RayModelIntersection(shadow_ray, vts, shadow_hit) || dist_to_light < shadow_hit.dist) {
                col += R_diffuse + R_specular; //combined light
            }

            // the recursion/reflection happens here!
            if (depth > 1) {
                Ray reflected_ray(i_pos, reflect(ray.direction, i_normal));
                reflected_ray.origin -= ray.direction * .001f; // this is a small offset to address numerical precision issues
                // integrate the current color with the reflection color by a p_rg factor
                col += p_rg * TraceRay(reflected_ray, depth - 1, vts);
            }

            return col;
        }

        // returns false if no intersection
        // intersection results are returned in the "hit" reference variable
        static bool RayModelIntersection(const Ray & ray,
                                         const std::vector<vertex> &vts,
                                         Hit &hit){
            for (int i = 0; i < vts.size(); i+=3)
            {
                float dist_temp = FLT_MAX;
                vec3 barycentric_temp;
                // notice that we use the hit.dist to ensure that if new intersections happen, they are closer to the
                // convergence point than the previously stored hit.
                if (RayTriangleIntersection(ray, vts[i], vts[i+1], vts[i+2], dist_temp, barycentric_temp) && dist_temp < hit.dist)
                {
                    hit.hit_ID = i;
                    hit.dist = dist_temp;
                    hit.barycentric = barycentric_temp;
                }
            }
            return hit.hit_ID >= 0;
        }

        // returns false if no intersection
        static bool RayTriangleIntersection(const Ray & ray,
                                            const vertex & p1,
                                            const vertex & p2,
                                            const vertex & p3,
                                            float & t, vec3 & barycentric)
        {
            vec3 e1 = p2.pos - p1.pos;
            vec3 e2 = p3.pos - p1.pos;
            vec3 q = cross(ray.direction, e2);
            float a = dot(e1, q);

            float tolerance = 10e-7f;
            // for numerical stability, a = 0 means that triangle plane and ray are parallel
            if (abs(a) < tolerance) return false;

            float f = 1.0f / a;
            vec3 s = ray.origin - vec3(p1.pos);
            float u = f * dot(s, q);

            // if u < 0, intersection with plane is not within the triangle
            if (u < -tolerance) return false;

            vec3 r = cross(s, e1);
            float v = f * dot(ray.direction, r);

            // if v < 0 or u+v > 1, intersection with plane is not within the triangle
            if (v < -tolerance || u + v > 1) return false;

            t = f * dot(e2, r);

            if (t < 0)
                return false;

            barycentric = vec3(1.0f - u - v, u, v);

            return true;
        }
    };
}


#endif //ITU_GRAPHICS_PROGRAMMING_RT_RENDERER_H

#pragma clang diagnostic pop