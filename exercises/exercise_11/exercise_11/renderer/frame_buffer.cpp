//
// Created by Martin Holst on 24/04/2022.
//

#include "frame_buffer.h"
#include "assert.h"

template<typename T>
FrameBuffer<T>::FrameBuffer(unsigned int width, unsigned int height) : W(width), H(height) {
    buffer = new T[W * H];
}

template<class T>
FrameBuffer<T>::~FrameBuffer() { delete[] buffer; } // clean our memory

template<class T>
void FrameBuffer<T>::clearBuffer(T value) {
    int size = W * H;
    for (int i = 0; i < size; i++)
        buffer[i] = value;
}

template<class T>
void FrameBuffer<T>::paintAt(unsigned int x, unsigned int y, T value) {
    assert(x < W && y < H); // ensure valid position, crash if not (sooo dramatic!)
    buffer[x + y * W] = value;
}

template<class T>
T FrameBuffer<T>::valueAt(unsigned int x, unsigned int y) {
    assert(x < W && y < H);
    return buffer[x + y * W];
}

template class FrameBuffer<int>;
template class FrameBuffer<unsigned int>;
template class FrameBuffer<char*>;


