#pragma once

#include "ImmutableConfig.hpp"

#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

struct SDL_Window;
struct SDL_Renderer;

namespace mcw {
    class Engine
    {
    public:
        Engine(const ImmutableConfig& config);
        
        void Run();
    
    private:
        void Init();
        void Prepare();
        void MainTick(float dt);
        void Cleanup();
        
        const std::string GetAssetsPath() const;
        
        void CreateVertexBuffer();
        void CreateSimplePipeline();
        
        bool quit = false;
        
        ImmutableConfig config;
        
        SDL_Window *window;
        
        id<MTLRenderPipelineState> renderPipelineState;
        // TODO: move to model class
        id<MTLBuffer> vertexBuffer;
    };
}
