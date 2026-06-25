cmake_minimum_required(VERSION 3.16)
project(anime_aggressors_engine LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_library(aa_engine STATIC
  src/simulation.cpp
)

target_include_directories(aa_engine PUBLIC include)

if(MSVC)
  target_compile_options(aa_engine PRIVATE /W4)
else()
  target_compile_options(aa_engine PRIVATE -Wall -Wextra -Wpedantic)
endif()

enable_testing()

add_executable(aa_engine_determinism_test tests/determinism_test.cpp)
target_link_libraries(aa_engine_determinism_test PRIVATE aa_engine)
add_test(NAME determinism COMMAND aa_engine_determinism_test)
