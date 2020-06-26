#pragma once

#include <cstdlib>

struct SDL_Window;

namespace mcw
{
    class Window
    {
    public:
        Window(size_t width, size_t height);
        ~Window();
        
        SDL_Window* GetSDLWindow();
        
        size_t GetWidth() const;
        size_t GetHeight() const;
        
    private:
        SDL_Window *window;
        size_t width = 0, height = 0;
    };
}
