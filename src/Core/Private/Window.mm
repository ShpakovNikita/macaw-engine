#include "Core/Window.hpp"

#include "SDL.h"

mcw::Window::Window(size_t aWidth, size_t aHeight)
    : width(aWidth)
    , height(aHeight)
{
    window = SDL_CreateWindow("SDL Metal", -1, -1, width / 2.0, height / 2.0, SDL_WINDOW_ALLOW_HIGHDPI);
}

mcw::Window::~Window()
{
    SDL_DestroyWindow(window);
}
        
SDL_Window* mcw::Window::GetSDLWindow()
{
    return window;
}

size_t mcw::Window::GetWidth() const
{
    return width;
}

size_t mcw::Window::GetHeight() const
{
    return height;
}
