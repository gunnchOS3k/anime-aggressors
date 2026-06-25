cmake_minimum_required(VERSION 3.16)
project(anime_aggressors)

# Root CMake delegates to the native deterministic engine library.
# Legacy performance_engine sources under legacy/game-prototype are not built here.
add_subdirectory(native/engine)
