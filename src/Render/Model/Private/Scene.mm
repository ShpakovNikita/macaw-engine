#include "Render/Model/Scene.hpp"

#include "Render/Model/AABBox.hpp"
#include "Render/Model/Material.hpp"
#include "Render/Model/Mesh.hpp"
#include "Render/Model/Node.hpp"
#include "Render/Model/Primitive.hpp"
#include "Render/MetalContext.hpp"
#include "Common/Vertex.hpp"
#include "Core/Exceptions.hpp"

#include "tinygltf/tiny_gltf.h"

namespace SScene
{
template <typename T>
void FillVertexAttribute(const tinygltf::Primitive& primitive, const tinygltf::Model& input, const std::string& attrName, int compSize, const T** buffer, int& bufferStride)
{
    if (primitive.attributes.find(attrName) != primitive.attributes.end()) {
        const tinygltf::Accessor& accessor = input.accessors[primitive.attributes.find(attrName)->second];
        const tinygltf::BufferView& view = input.bufferViews[accessor.bufferView];
        *buffer = reinterpret_cast<const T*>(&(input.buffers[view.buffer].data[accessor.byteOffset + view.byteOffset]));
        bufferStride = accessor.ByteStride(view) ? (accessor.ByteStride(view) / sizeof(T)) : tinygltf::GetNumComponentsInType(compSize);
    }
}
}

void mcw::Scene::LoadFromFile(const std::string& filename, float scale/* = 1.0f*/)
{
    tinygltf::Model glTFInput;
    tinygltf::TinyGLTF gltfContext;
    std::string error, warning;

    bool fileLoaded = gltfContext.LoadASCIIFromFile(&glTFInput, &error, &warning, filename);
    
    if (fileLoaded) {
        LoadTextureSamplers(glTFInput);
        LoadTextures(glTFInput);
        LoadMaterials(glTFInput);

        if (glTFInput.scenes.empty()) {
            throw AssetLoadingException("Could not the load file!");
        }

        const tinygltf::Scene& scene = glTFInput.scenes[glTFInput.defaultScene > -1 ? glTFInput.defaultScene : 0];
        for (size_t i = 0; i < scene.nodes.size(); i++) {
            const tinygltf::Node node = glTFInput.nodes[scene.nodes[i]];
            LoadNode(nullptr, node, scene.nodes[i], glTFInput, scale);
        }
        
        for (auto node : allNodes) {
            if (node->mesh)
            {
                node->UpdateRecursive();
            }
        }

        CalculateSize();
    } else {
        throw AssetLoadingException("Could not open the glTF file. Check, if it is correct");
        return;
}

std::vector<std::unique_ptr<mcw::Material>>& mcw::Scene::GetMaterials()
{
    return materials;
}

const std::vector<mcw::Texture>& mcw::Scene::GetTextures() const
{
    return textures;
}

const std::vector<std::unique_ptr<mcw::Node>>& mcw::Scene::GetNodes() const
{
    return nodes;
}

const std::vector<mcw::Node*>& mcw::Scene::GetFlatNodes() const
{
    return allNodes;
}

const glm::vec3& mcw::Scene::GetSize() const
{
    return size;
}

const uint32_t mcw::Scene::GetPrimitivesCount() const
{
    uint32_t primCount = 0;
    for (const auto& node : allNodes) {
        if (node->mesh) {
            primCount += static_cast<uint32_t>(node->mesh->primitives.size());
        }
    }

    return primCount;
}

/*
// from GLTF2 specs
uint32_t mcw::Scene::GetWrapMode(int32_t wrapMode)
{
    switch (wrapMode) {
    case 10497:
        return MODE_REPEAT;
    case 33071:
        return MODE_CLAMP_TO_EDGE;
    case 33648:
        return MODE_MIRRORED_REPEAT;
    default:
        return MODE_REPEAT;
    }
}

// from GLTF2 specs
uint32_t mcw::Scene::GetFilterMode(int32_t filterMode)
{
    switch (filterMode) {
    case 9728:
        return FILTER_NEAREST;
    case 9729:
        return FILTER_LINEAR;
    case 9984:
        return FILTER_NEAREST;
    case 9985:
        return FILTER_NEAREST;
    case 9986:
        return FILTER_LINEAR;
    case 9987:
        return FILTER_LINEAR;
    default:
        return FILTER_NEAREST;
    }
}
*/

void mcw::Scene::LoadTextureSamplers(const tinygltf::Model& input)
{
    textureSamplers.resize(input.samplers.size());
    
    for (tinygltf::Sampler smpl : input.samplers) {
        TextureSampler sampler;
        /*
        sampler.minFilter = GetFilterMode(smpl.minFilter);
        sampler.magFilter = GetFilterMode(smpl.magFilter);
        sampler.addressModeU = GetWrapMode(smpl.wrapS);
        sampler.addressModeV = GetWrapMode(smpl.wrapT);
        sampler.addressModeW = sampler.addressModeV;
         */
        textureSamplers.push_back(sampler);
    }
}

void mcw::Scene::LoadTextures(const tinygltf::Model& input)
{
    textures.reserve(input.textures.size());

    for (const tinygltf::Texture& tex : input.textures) {
        const tinygltf::Image& image = input.images[tex.source];
        /*
        TextureSampler textureSampler;
        if (tex.sampler == -1) {
            textureSampler.magFilter = FILTER_LINEAR;
            textureSampler.minFilter = FILTER_LINEAR;
            textureSampler.addressModeU = SAMPLER_ADDRESS_MODE_REPEAT;
            textureSampler.addressModeV = SAMPLER_ADDRESS_MODE_REPEAT;
            textureSampler.addressModeW = SAMPLER_ADDRESS_MODE_REPEAT;
        } else {
            textureSampler = textureSamplers[tex.sampler];
        }
        */
        Texture texture;
        texture.FromGLTFImage(image);
        textures.push_back(texture);
    }
}

void mcw::Scene::LoadMaterials(const tinygltf::Model& input)
{
    materials.reserve(input.materials.size() + 1);
    
    for (const tinygltf::Material& mat : input.materials) {
        std::unique_ptr<Material> material = std::make_unique<Material>();
        if (mat.values.find("baseColorTexture") != mat.values.end()) {
            material->baseColorTexture = &textures[mat.values.at("baseColorTexture").TextureIndex()];
            material->texCoordSets.baseColor = mat.values.at("baseColorTexture").TextureTexCoord();
        }
        if (mat.values.find("metallicRoughnessTexture") != mat.values.end()) {
            material->metallicRoughnessTexture = &textures[mat.values.at("metallicRoughnessTexture").TextureIndex()];
            material->texCoordSets.metallicRoughness = mat.values.at("metallicRoughnessTexture").TextureTexCoord();
        }
        if (mat.values.find("roughnessFactor") != mat.values.end()) {
            material->roughnessFactor = static_cast<float>(mat.values.at("roughnessFactor").Factor());
        }
        if (mat.values.find("metallicFactor") != mat.values.end()) {
            material->metallicFactor = static_cast<float>(mat.values.at("metallicFactor").Factor());
        }
        if (mat.values.find("baseColorFactor") != mat.values.end()) {
            material->baseColorFactor = glm::make_vec4(mat.values.at("baseColorFactor").ColorFactor().data());
        }
        if (mat.additionalValues.find("normalTexture") != mat.additionalValues.end()) {
            material->normalTexture = &textures[mat.additionalValues.at("normalTexture").TextureIndex()];
            material->texCoordSets.normal = mat.additionalValues.at("normalTexture").TextureTexCoord();
        }
        if (mat.additionalValues.find("emissiveTexture") != mat.additionalValues.end()) {
            material->emissiveTexture = &textures[mat.additionalValues.at("emissiveTexture").TextureIndex()];
            material->texCoordSets.emissive = mat.additionalValues.at("emissiveTexture").TextureTexCoord();
        }
        if (mat.additionalValues.find("occlusionTexture") != mat.additionalValues.end()) {
            material->occlusionTexture = &textures[mat.additionalValues.at("occlusionTexture").TextureIndex()];
            material->texCoordSets.occlusion = mat.additionalValues.at("occlusionTexture").TextureTexCoord();
        }
        if (mat.additionalValues.find("emissiveFactor") != mat.additionalValues.end()) {
            material->emissiveFactor = glm::vec4(glm::make_vec3(mat.additionalValues.at("emissiveFactor").ColorFactor().data()), 1.0);
            material->emissiveFactor = glm::vec4(0.0f);
        }

        Material::MaterialParams materialParams;

        materialParams.baseColorFactor = material->baseColorFactor;
        materialParams.metallicFactor = material->metallicFactor;
        materialParams.roughnessFactor = material->roughnessFactor;
        materialParams.emissiveFactor = material->emissiveFactor;

        // Notice: this value used in shader
        materialParams.workflow = 0.0f;

        materialParams.colorTextureSet = material->baseColorTexture != nullptr ? material->texCoordSets.baseColor : -1;
        materialParams.physicalDescriptorTextureSet = material->metallicRoughnessTexture != nullptr ? material->texCoordSets.metallicRoughness : -1;
        materialParams.normalTextureSet = material->normalTexture != nullptr ? material->texCoordSets.normal : -1;
        materialParams.occlusionTextureSet = material->occlusionTexture != nullptr ? material->texCoordSets.occlusion : -1;
        materialParams.emissiveTextureSet = material->emissiveTexture != nullptr ? material->texCoordSets.emissive : -1;

        materialParams.baseColorFactor = material->baseColorFactor;
        materialParams.metallicFactor = material->metallicFactor;
        materialParams.roughnessFactor = material->roughnessFactor;
        materialParams.alphaMaskCutoff = material->alphaCutoff;
        material->materialParamsData = materialParams;

        material->UpdateUniformBuffers();

        materials.push_back(std::move(material));
    }
    // Push a default material at the end of the list for meshes with no material assigned
    auto defaultMaterial = std::make_unique<Material>();
    defaultMaterial->UpdateUniformBuffers();
    materials.push_back(std::move(defaultMaterial));
}

void mcw::Scene::CalculateSize()
{
    AABBox dimension;

   dimension.min = glm::vec3(std::numeric_limits<float>::max());
   dimension.max = glm::vec3(-std::numeric_limits<float>::max());

   for (const auto& node : allNodes) {
       if (node->mesh && node->mesh->bbox.valid) {
           AABBox bbox = node->mesh->bbox.GetAABB(node->GetWorldMatrix());
           dimension.min = glm::min(dimension.min, bbox.min);
           dimension.max = glm::max(dimension.max, bbox.max);
       }
   }

   size = glm::vec3(dimension.max[0] - dimension.min[0], dimension.max[1] - dimension.min[1], dimension.max[2] - dimension.min[2]);
}

void mcw::Scene::CreatePrimitiveBuffers(Primitive* newPrimitive, std::vector<Vertex>& vertexBuffer,
    std::vector<uint32_t>& indexBuffer)
{
    newPrimitive->vertices = [MetalContext::Get().device newBufferWithBytes:vertexBuffer.data()
                       length:sizeof(Vertex) * vertexData.size()
                       options:MTLResourceStorageModeShared];
    
    newPrimitive->indices = [MetalContext::Get().device newBufferWithBytes:indexBuffer.data()
                       length:sizeof(uint32_t) * indexBuffer.size()
                       options:MTLResourceStorageModeShared];
    
}

void mcw::Scene::LoadNode(Node* parent, const tinygltf::Node& node, uint32_t nodeIndex, const tinygltf::Model& input,
    float globalscale)
{
    std::unique_ptr<Node> newNode = std::make_unique<Node>();
    newNode->index = nodeIndex;
    newNode->parent = parent;
    newNode->name = node.name;
    newNode->matrix = glm::mat4(1.0f);

    // Generate local node matrix
    glm::vec3 translation = glm::vec3(0.0f);
    if (node.translation.size() == 3) {
        translation = glm::make_vec3(node.translation.data());
        newNode->translation = translation;
    }
    glm::mat4 rotation = glm::mat4(1.0f);
    if (node.rotation.size() == 4) {
        glm::quat q = glm::make_quat(node.rotation.data());
        newNode->rotation = glm::mat4(q);
    }
    glm::vec3 scale = glm::vec3(1.0f);
    if (node.scale.size() == 3) {
        scale = glm::make_vec3(node.scale.data());
        newNode->scale = scale;
    }
    if (node.matrix.size() == 16) {
        newNode->matrix = glm::make_mat4x4(node.matrix.data());
    };

    // Node with children
    if (node.children.size() > 0) {
        for (size_t i = 0; i < node.children.size(); i++) {
            LoadNode(newNode.get(), input.nodes[node.children[i]], node.children[i], input, globalscale);
        }
    }

    // Node contains mesh data
    if (node.mesh > -1) {
        const tinygltf::Mesh mesh = input.meshes[node.mesh];
        std::unique_ptr<Mesh> newMesh = std::make_unique<Mesh>(newNode->matrix);
        for (size_t j = 0; j < mesh.primitives.size(); j++) {
            const tinygltf::Primitive& primitive = mesh.primitives[j];

            std::vector<uint32_t> indexBuffer;
            indexBuffer.reserve(4096);
            std::vector<Vertex> vertexBuffer;
            vertexBuffer.reserve(4096);

            uint32_t indexStart = 0;
            uint32_t vertexStart = 0;
            uint32_t indexCount = 0;
            uint32_t vertexCount = 0;
            bool hasSkin = false;
            bool hasIndices = primitive.indices > -1;

            glm::vec3 posMin {};
            glm::vec3 posMax {};

            // Vertices
            {
                const float* bufferPos = nullptr;
                const float* bufferNormals = nullptr;
                const float* bufferTexCoordSet0 = nullptr;
                const float* bufferTexCoordSet1 = nullptr;
                const uint16_t* bufferJoints = nullptr;
                const float* bufferWeights = nullptr;

                int posByteStride = 0;
                int normByteStride = 0;
                int uv0ByteStride = 0;
                int uv1ByteStride = 0;

                // Position attribute is required
                assert(primitive.attributes.find("POSITION") != primitive.attributes.end());

                const tinygltf::Accessor& posAccessor = input.accessors[primitive.attributes.find("POSITION")->second];
                vertexCount = static_cast<uint32_t>(posAccessor.count);

                SGLTFModel::FillVertexAttribute(primitive, input, "POSITION", TINYGLTF_TYPE_VEC3, &bufferPos, posByteStride);
                SGLTFModel::FillVertexAttribute(primitive, input, "NORMAL", TINYGLTF_TYPE_VEC3, &bufferNormals, normByteStride);
                SGLTFModel::FillVertexAttribute(primitive, input, "TEXCOORD_0", TINYGLTF_TYPE_VEC2, &bufferTexCoordSet0, uv0ByteStride);
                SGLTFModel::FillVertexAttribute(primitive, input, "TEXCOORD_1", TINYGLTF_TYPE_VEC2, &bufferTexCoordSet1, uv1ByteStride);

                posMin = glm::vec3(posAccessor.minValues[0], posAccessor.minValues[1], posAccessor.minValues[2]);
                posMax = glm::vec3(posAccessor.maxValues[0], posAccessor.maxValues[1], posAccessor.maxValues[2]);

                hasSkin = (bufferJoints && bufferWeights);

                for (size_t v = 0; v < posAccessor.count; ++v) {
                    Vertex vert = {};
                    vert.pos = glm::vec4(glm::make_vec3(&bufferPos[v * posByteStride]), 1.0f);
                    vert.normal = glm::vec4(glm::normalize(glm::vec3(bufferNormals ? glm::make_vec3(&bufferNormals[v * normByteStride]) : glm::vec3(0.0f))), 1.0f);
                    glm::vec2 uv0 = bufferTexCoordSet0 ? glm::make_vec2(&bufferTexCoordSet0[v * uv0ByteStride]) : glm::vec2(0.0f);
                    glm::vec2 uv1 = bufferTexCoordSet1 ? glm::make_vec2(&bufferTexCoordSet1[v * uv1ByteStride]) : glm::vec2(0.0f);
                    vert.uv = glm::vec4(uv0.x, uv0.y, uv1.x, uv1.y);
                    
                    vertexBuffer.push_back(vert);
                }
            }
            
            // Indices
            if (hasIndices) {
                const tinygltf::Accessor& accessor = input.accessors[primitive.indices > -1 ? primitive.indices : 0];
                const tinygltf::BufferView& bufferView = input.bufferViews[accessor.bufferView];
                const tinygltf::Buffer& buffer = input.buffers[bufferView.buffer];

                indexCount = static_cast<uint32_t>(accessor.count);
                const void* dataPtr = &(buffer.data[accessor.byteOffset + bufferView.byteOffset]);

                switch (accessor.componentType) {
                case TINYGLTF_PARAMETER_TYPE_UNSIGNED_INT: {
                    const uint32_t* buf = static_cast<const uint32_t*>(dataPtr);
                    for (size_t index = 0; index < accessor.count; index++) {
                        indexBuffer.push_back(buf[index] + vertexStart);
                    }
                    break;
                }
                case TINYGLTF_PARAMETER_TYPE_UNSIGNED_SHORT: {
                    const uint16_t* buf = static_cast<const uint16_t*>(dataPtr);
                    for (size_t index = 0; index < accessor.count; index++) {
                        indexBuffer.push_back(buf[index] + vertexStart);
                    }
                    break;
                }
                case TINYGLTF_PARAMETER_TYPE_UNSIGNED_BYTE: {
                    const uint8_t* buf = static_cast<const uint8_t*>(dataPtr);
                    for (size_t index = 0; index < accessor.count; index++) {
                        indexBuffer.push_back(buf[index] + vertexStart);
                    }
                    break;
                }
                default:
                    std::cerr << "Index component type " << accessor.componentType << " not supported!" << std::endl;
                    return;
                }
            }

            // Loading last material as default one
            std::unique_ptr<Primitive> newPrimitive = std::make_unique<Primitive>(indexStart, vertexStart, indexCount, vertexCount,
                primitive.material > -1 ? *materials[primitive.material] : *materials.back());
            newPrimitive->bbox = AABBox(posMin, posMax);

            CreatePrimitiveBuffers(newPrimitive.get(), vertexBuffer, indexBuffer);

            newMesh->primitives.push_back(std::move(newPrimitive));
        }

        // Mesh BB from BBs of primitives
        for (const auto& p : newMesh->primitives) {
            if (p->bbox.valid && !newMesh->bbox.valid) {
                newMesh->bbox = p->bbox;
                newMesh->bbox.valid = true;
            }
            newMesh->bbox.min = glm::min(newMesh->bbox.min, p->bbox.min);
            newMesh->bbox.max = glm::max(newMesh->bbox.max, p->bbox.max);
        }
        newNode->mesh = std::move(newMesh);
    }
    if (parent)
    {
        parent->children.push_back(std::move(newNode));
        allNodes.push_back(parent->children.back().get());
    } else
    {
        nodes.push_back(std::move(newNode));
        allNodes.push_back(nodes.back().get());
    }
}

void mcw::Scene::Draw(id<MTLRenderCommandEncoder>)
{
    /*
    [renderEncoder setVertexBuffer:vertexBuffer
                            offset:0
                           atIndex:VertexInputIndexVertices];

     [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                       vertexStart:0
                       vertexCount:3];
     */
}
