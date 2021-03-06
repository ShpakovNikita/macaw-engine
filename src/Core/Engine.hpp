#pragma once

#include "ImmutableConfig.hpp"

#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

struct SDL_Window;
struct SDL_Renderer;

namespace mcw
{
    class Scene;
    class Texture;
    class EnvironmentProbe;

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
        
        void CreateSimplePipeline();
        void CreateDepthTexture();
        void CreateSkybox();
        
        void DrawSkybox(id<MTLRenderCommandEncoder> renderEncoder);
        
        bool quit = false;
        
        ImmutableConfig config;
        
        id<MTLRenderPipelineState> renderPipelineState;
        id<MTLRenderPipelineState> skyboxPipelineState;
        id<MTLDepthStencilState> depthLessEqual;
        
        std::unique_ptr<Texture> depthTexture;
        std::unique_ptr<Scene> scene;
        std::unique_ptr<EnvironmentProbe> skybox;
        std::unique_ptr<Scene> skyboxModel;
    };
}
