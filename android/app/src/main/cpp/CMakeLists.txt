cmake_minimum_required(VERSION 3.10.2)

project(llama_inference)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Include directories
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)

# Add llama.cpp as a subproject
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp)

# Define the library target
add_library(
    llama_inference
    SHARED
    llama_inference.cpp
)

# Link against llama.cpp library
target_link_libraries(
    llama_inference
    llama
    android
    log
)

# Export JNI functions
set_target_properties(
    llama_inference
    PROPERTIES
    LINKER_LANGUAGE CXX
)