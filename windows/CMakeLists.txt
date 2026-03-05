cmake_minimum_required(VERSION 3.14)
project(maplestory_flutter LANGUAGES CXX)

set(BINARY_NAME "maplestory_flutter")

# Configure build options
set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")

# Add the Flutter tool dependency
find_package(Flutter REQUIRED)

# Add the executable
add_executable(${BINARY_NAME} WIN32
  "flutter/generated_plugin_registrant.cc"
  "runner/main.cpp"
  "runner/runner.exe.manifest"
  "runner/resource.h"
  "runner/resources.rc"
  "runner/runner.cpp"
  "runner/runner.h"
  "runner/utils.cpp"
  "runner/utils.h"
  "runner/win32_window.cpp"
  "runner/win32_window.h"
)

# Link libraries
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# Add the Flutter assets
target_compile_definitions(${BINARY_NAME} PRIVATE NDEBUG)

# Install the application
install(TARGETS ${BINARY_NAME} DESTINATION .)
