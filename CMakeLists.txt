cmake_minimum_required(VERSION 3.16)
project(anime_aggressors_performance)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Performance optimization flags
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -march=native -mtune=native -flto -DNDEBUG")
set(CMAKE_CXX_FLAGS_DEBUG "-O0 -g -DDEBUG")

# Find required packages
find_package(Threads REQUIRED)

# Include directories
include_directories(include)
include_directories(src)

# Source files
set(SOURCES
    src/performance_engine.cpp
    src/fighting_system.cpp
    src/input_system.cpp
    src/graphics_engine.cpp
    src/audio_engine.cpp
    src/physics_engine.cpp
    src/ai_engine.cpp
    src/memory_pool.cpp
    src/thread_pool.cpp
    src/cache_system.cpp
    src/analytics.cpp
)

# Header files
set(HEADERS
    include/performance_engine.h
    include/fighting_system.h
    include/input_system.h
    include/graphics_engine.h
    include/audio_engine.h
    include/physics_engine.h
    include/ai_engine.h
    include/memory_pool.h
    include/thread_pool.h
    include/cache_system.h
    include/analytics.h
    include/common.h
)

# Create shared library
add_library(anime_aggressors_performance SHARED ${SOURCES} ${HEADERS})

# Link libraries
target_link_libraries(anime_aggressors_performance 
    Threads::Threads
    ${CMAKE_DL_LIBS}
)

# Compiler-specific optimizations
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    target_compile_options(anime_aggressors_performance PRIVATE -Wall -Wextra -Wpedantic)
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    target_compile_options(anime_aggressors_performance PRIVATE -Wall -Wextra -Wpedantic)
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    target_compile_options(anime_aggressors_performance PRIVATE /W4)
endif()

# Install targets
install(TARGETS anime_aggressors_performance
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
)

install(FILES ${HEADERS} DESTINATION include)

# Create executable for testing
add_executable(performance_test tests/performance_test.cpp)
target_link_libraries(performance_test anime_aggressors_performance)

# Benchmark executable
add_executable(benchmark tests/benchmark.cpp)
target_link_libraries(benchmark anime_aggressors_performance)

# Set output directories
set_target_properties(anime_aggressors_performance PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin
)

# Enable testing
enable_testing()
add_test(NAME performance_test COMMAND performance_test)
add_test(NAME benchmark_test COMMAND benchmark)

