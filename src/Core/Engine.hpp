#pragma once

#include "ImmutableConfig.hpp"

#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

struct SDL_Window;
struct SDL_Renderer;

namespace mcw
{
    class Scene;

    class Engine
    {
    public:
        Engine(const ImmutableConfig& config);
        ~Engine();
        
        void Run();
    
    private:
        void Init();
        void Prepare();
        void MainTick(float dt);
        void Cleanup();
        
        void LoadModel(const std::string& filepath);
        
        const std::string GetAssetsPath() const;
        
        void CreateSimplePipeline();
        
        bool quit = false;
        
        ImmutableConfig config;
        
        SDL_Window *window;
        
        id<MTLRenderPipelineState> renderPipelineState;
        
        std::unique_ptr<Scene> scene;
    };
}
