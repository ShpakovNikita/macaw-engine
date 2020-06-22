#pragma once

#include <unordered_map>
#include <string>

namespace mcw
{
class Texture;

    class TextureManager
    {
    public:
        TextureManager();
        ~TextureManager();
        
        const Texture& GetTexture(const std::string& texturePath) const;
    
    private:
        mutable std::unordered_map<std::string, Texture> textureCache;
    };
}
