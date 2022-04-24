//
// Created by Martin Holst on 24/04/2022.
//

#include "rt_types.h"

rt::vertex operator/(rt::vertex v, float sc) {
    return rt::vertex{v.pos / sc, v.norm / sc, v.col / sc, v.uv / sc};
}

rt::vertex operator*(rt::vertex v, float sc) {
    return rt::vertex{v.pos * sc, v.norm * sc, v.col * sc, v.uv * sc};
}

rt::vertex operator-(rt::vertex v1, const rt::vertex &v2) {
    return rt::vertex{v1.pos - v2.pos, v1.norm - v2.norm, v1.col - v2.col, v1.uv - v2.uv};
}

rt::vertex operator+(rt::vertex v1, const rt::vertex &v2) {
    return rt::vertex{v1.pos + v2.pos, v1.norm + v2.norm, v1.col + v2.col, v1.uv + v2.uv};
}