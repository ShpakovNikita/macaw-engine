#include "Render/TextureManager.hpp"

#include "Render/Texture.hpp"

mcw::TextureManager::TextureManager() = default;

mcw::TextureManager::~TextureManager() = default;

const mcw::Texture& mcw::TextureManager::GetTexture(const std::string& texturePath) const
{
    Texture& texture = textureCache[texturePath];
    
    if (texture.height == 0 || texture.width == 0)
    {
        texture.LoadFromFile(texturePath);
    }
    
    return texture;
}
