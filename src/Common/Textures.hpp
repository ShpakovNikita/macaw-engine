#pragma once

typedef enum TextureIndex
{
    SkyboxTexture = 0,
    
    // PBR textures
    BaseColorTexture,
    MetallicRoughnessTexture,
    NormalTexture,
    OcclusionTexture,
    EmissiveTexture,
    
} TextureIndex;

typedef enum TextureSamplerIndex
{
    SkyboxSampler = 0,
    
    // PBR texture samplers
    BaseColorSampler,
    MetallicRoughnessSampler,
    NormalSampler,
    OcclusionSampler,
    EmissiveSampler,
    
} TextureSamplerIndex;
