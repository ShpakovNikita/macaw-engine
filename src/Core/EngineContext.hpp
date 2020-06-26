#pragma once

#include <string>
#include <memory>

namespace mcw
{
    class Window;
    struct ImmutableConfig;

    class EngineContext
    {
    public:
        static EngineContext& Get();
        
        EngineContext();
        ~EngineContext();
        
        void Init(const mcw::ImmutableConfig& config);
        void Cleanup();
        
        const std::string GetAssetsPath() const;
        
        Window* GetWindow() const;
        
    private:
        std::unique_ptr<Window> window;
    };
}

