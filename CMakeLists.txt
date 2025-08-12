cmake_minimum_required(VERSION 3.21)
project(CellShot C)
set(CMAKE_C_STANDARD 99)

# Opcional: generar binarios en carpetas por config
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

include(FetchContent)
set(RAYLIB_VERSION 5.0)
FetchContent_Declare(
  raylib
  GIT_REPOSITORY https://github.com/raysan5/raylib.git
  GIT_TAG        ${RAYLIB_VERSION}
)
FetchContent_MakeAvailable(raylib)

add_executable(cellshot src/main.c)
target_link_libraries(cellshot PRIVATE raylib)

# Ajustes MSVC (avisos y Unicode)
if(MSVC)
  target_compile_options(cellshot PRIVATE /W4 /utf-8)
  # Ejecutar desde la raíz del proyecto al depurar en Visual Studio
  set_property(TARGET cellshot PROPERTY VS_DEBUGGER_WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}")
endif()