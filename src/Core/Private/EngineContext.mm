#include "Core/EngineContext.hpp"

#include "Core/Window.hpp"

#include "Core/ImmutableConfig.hpp"

mcw::EngineContext::EngineContext() = default;
mcw::EngineContext::~EngineContext() = default;

mcw::EngineContext& mcw::EngineContext::Get()
{
    static EngineContext context;
    return context;
}

mcw::Window* mcw::EngineContext::GetWindow() const
{
    return window.get();
}

void mcw::EngineContext::Init(const mcw::ImmutableConfig& config)
{
    window = std::make_unique<Window>(config.width, config.height);
}

void mcw::EngineContext::Cleanup()
{
    window = nullptr;
}

const std::string mcw::EngineContext::GetAssetsPath() const
{
#if defined(ASSETS_DIR)
    return ASSETS_DIR;
#else
    return "./../assets/";
#endif
}


