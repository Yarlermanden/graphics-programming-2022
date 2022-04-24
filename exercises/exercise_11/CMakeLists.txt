# obtain the list of subdirectories
SUBDIRLIST(SUBDIRS ${CMAKE_CURRENT_LIST_DIR})

# ---------------------------------------------------------------------------------
# Executable and target include/link libraries
# ---------------------------------------------------------------------------------
# list of libraries
#set(libraries glad glfw imgui)
#set(libraries glad glfw imgui /opt/homebrew/Cellar/llvm/13.0.1_1/lib/libomp.dylib)
set(libraries glad glfw imgui /opt/homebrew/Cellar/libomp/14.0.0/lib/libomp.dylib)

#option(WITH_OPENMP
#        "Include support for parallelization through OpenMP"
#        OFF)

#include(FindOpenMP)
#find_package(OpenMP REQUIRED)

#if(OPENMP_FOUND)
#    set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}")
#    set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS}")
#endif()
#set(CMAKE_C_FLAGS "-fopenmp")
#set (CMAKE_CXX_FLAGS -fopenmp /opt/homebrew/Cellar/llvm/13.0.1_1/lib/clang/13.0.1/include/omp.h)
#set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS} -c /opt/homebrew/Cellar/llvm/13.0.1_1/lib/libomp.dylib")
#set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS} -c /opt/homebrew/Cellar/llvm/13.0.1_1/lib/libomp.dylib")

#set (CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS} "-std=c++11 -pthread")
set (CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS})

if(APPLE)
    find_library(IOKIT_LIBRARY IOKit)
    find_library(COCOA_LIBRARY Cocoa)
    find_library(OPENGL_LIBRARY OpenGL)
    find_library(COREVIDEO_LIBRARY CoreVideo)

    list(APPEND libraries
            ${OPENGL_LIBRARY}
            ${COCOA_LIBRARY}
            ${IOKIT_LIBRARY}
            ${COREVIDEO_LIBRARY}
            )
endif()


FOREACH(subdir ${SUBDIRS})
    add_subdirectory(${subdir})
ENDFOREACH()