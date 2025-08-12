#include "raylib.h"

int main(void) {
    InitWindow(800, 450, "raylib OK");
    SetTargetFPS(60);
    while (!WindowShouldClose()) {
        BeginDrawing();
        ClearBackground(RAYWHITE);
        DrawText("raylib funciona en Windows (MSVC + CMake)", 100, 200, 20, DARKGRAY);
        EndDrawing();
    }
    CloseWindow();
    return 0;
}