//
// Created by henrique on 04/11/2021.
//

#ifndef ITU_GRAPHICS_PROGRAMMING_FRAME_BUFFER_H
#define ITU_GRAPHICS_PROGRAMMING_FRAME_BUFFER_H


template<class T>
class FrameBuffer {
public:
    unsigned int W, H;
    T *buffer;
    FrameBuffer(unsigned int width, unsigned int height);
    ~FrameBuffer();
    void clearBuffer(T value);
    void paintAt(unsigned int x, unsigned int y, T value);
    T valueAt(unsigned int x, unsigned int y);
};


#endif //ITU_GRAPHICS_PROGRAMMING_FRAME_BUFFER_H
