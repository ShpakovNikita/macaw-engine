#include "Render/Model/Scene.hpp"

#include "Render/Model/AABBox.hpp"
#include "Render/Model/Material.hpp"
#include "Render/Model/Mesh.hpp"
#include "Render/Model/Node.hpp"
#include "Render/Model/Primitive.hpp"
#include "Render/MetalContext.hpp"
#include "Render/TextureManager.hpp"
#include "Render/Texture.hpp"
#include "Core/Exceptions.hpp"
#include "Utils/Logger.hpp"

#define STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_WRITE_IMPLEMENTATION
#define TINYGLTF_IMPLEMENTATION

#include "tinygltf/tiny_gltf.h"

#include "glm/ext/matrix_transform.hpp"
#include <glm/gtc/type_ptr.hpp>

namespace SScene
{
    const std::string kDefaultTexturePath = mcw::MetalContext::Get().GetAssetsPath() + "textures/ffffff.png";

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

mcw::Scene::Scene() = default;
mcw::Scene::~Scene() = default;

void mcw::Scene::LoadFromFile(const std::string& filename, float scale/* = 1.0f*/)
{
    tinygltf::Model glTFInput;
    tinygltf::TinyGLTF gltfContext;
    std::string error, warning;

    bool fileLoaded = gltfContext.LoadASCIIFromFile(&glTFInput, &error, &warning, filename);
    
    if (fileLoaded)
    {
        LoadTextures(glTFInput);
        LoadMaterials(glTFInput);

        if (glTFInput.scenes.empty())
        {
            throw AssetLoadingException("Could not the load file!");
        }

        const tinygltf::Scene& scene = glTFInput.scenes[glTFInput.defaultScene > -1 ? glTFInput.defaultScene : 0];
        for (size_t i = 0; i < scene.nodes.size(); i++)
        {
            const tinygltf::Node node = glTFInput.nodes[scene.nodes[i]];
            LoadNode(nullptr, node, scene.nodes[i], glTFInput, scale);
        }
        
        for (auto node : allNodes)
        {
            if (node->mesh)
            {
                node->UpdateRecursive();
            }
        }

        CalculateSize();
    }
    else
    {
        throw AssetLoadingException("Could not open the glTF file. Check, if it is correct");
        return;
    }
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

size_t mcw::Scene::GetPrimitivesCount() const
{
    size_t primCount = 0;
    for (const auto& node : allNodes) {
        if (node->mesh) {
            primCount += static_cast<uint32_t>(node->mesh->primitives.size());
        }
    }

    return primCount;
}

void mcw::Scene::LoadTextures(const tinygltf::Model& input)
{
    textures.reserve(input.textures.size());

    for (const tinygltf::Texture& tex : input.textures) {
        const tinygltf::Image& image = input.images[tex.source];
        
        Texture texture;
        texture.LoadFromBuffer(static_cast<const void*>(image.image.data()), MTLPixelFormatRGBA8Unorm, image.width, image.height, image.component == 3);
        textures.push_back(texture);
    }
}

void mcw::Scene::LoadMaterials(const tinygltf::Model& input)
{
    materials.reserve(input.materials.size() + 1);
    
    for (const tinygltf::Material& mat : input.materials) {
        std::unique_ptr<Material> material = std::make_unique<Material>();
        Material::MaterialParams materialParams;
        
        if (mat.values.find("baseColorTexture") != mat.values.end()) {
            material->baseColorTexture = &textures[mat.values.at("baseColorTexture").TextureIndex()];
            materialParams.colorTextureSet = mat.values.at("baseColorTexture").TextureTexCoord();
        }
        if (mat.values.find("metallicRoughnessTexture") != mat.values.end()) {
            material->metallicRoughnessTexture = &textures[mat.values.at("metallicRoughnessTexture").TextureIndex()];
            materialParams.physicalDescriptorTextureSet = mat.values.at("metallicRoughnessTexture").TextureTexCoord();
        }
        if (mat.values.find("roughnessFactor") != mat.values.end()) {
            materialParams.roughnessFactor = static_cast<float>(mat.values.at("roughnessFactor").Factor());
        }
        if (mat.values.find("metallicFactor") != mat.values.end()) {
            materialParams.metallicFactor = static_cast<float>(mat.values.at("metallicFactor").Factor());
        }
        if (mat.values.find("baseColorFactor") != mat.values.end()) {
            materialParams.baseColorFactor = glm::make_vec4(mat.values.at("baseColorFactor").ColorFactor().data());
        }
        if (mat.additionalValues.find("normalTexture") != mat.additionalValues.end()) {
            material->normalTexture = &textures[mat.additionalValues.at("normalTexture").TextureIndex()];
            materialParams.normalTextureSet = mat.additionalValues.at("normalTexture").TextureTexCoord();
        }
        if (mat.additionalValues.find("emissiveTexture") != mat.additionalValues.end()) {
            material->emissiveTexture = &textures[mat.additionalValues.at("emissiveTexture").TextureIndex()];
            materialParams.emissiveTextureSet = mat.additionalValues.at("emissiveTexture").TextureTexCoord();
        }
        if (mat.additionalValues.find("occlusionTexture") != mat.additionalValues.end()) {
            material->occlusionTexture = &textures[mat.additionalValues.at("occlusionTexture").TextureIndex()];
            materialParams.occlusionTextureSet = mat.additionalValues.at("occlusionTexture").TextureTexCoord();
        }
        if (mat.additionalValues.find("emissiveFactor") != mat.additionalValues.end()) {
            materialParams.emissiveFactor = glm::vec4(glm::make_vec3(mat.additionalValues.at("emissiveFactor").ColorFactor().data()), 1.0);
        }
        
        const Texture& defaultTexture = MetalContext::Get().textureManager->GetTexture(SScene::kDefaultTexturePath);
        
        material->baseColorTexture = material->baseColorTexture ? material->baseColorTexture : &defaultTexture;
        material->metallicRoughnessTexture = material->metallicRoughnessTexture ? material->metallicRoughnessTexture : &defaultTexture;
        material->emissiveTexture = material->emissiveTexture ? material->emissiveTexture : &defaultTexture;
        material->occlusionTexture = material->occlusionTexture ? material->occlusionTexture : &defaultTexture;
        material->normalTexture = material->normalTexture ? material->normalTexture : &defaultTexture;
        
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
                       length:sizeof(Vertex) * vertexBuffer.size()
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
    if (node.translation.size() == 3) {
        glm::vec3 translation = glm::make_vec3(node.translation.data());
        newNode->translation = translation;
    }
    if (node.rotation.size() == 4) {
        glm::quat q = glm::make_quat(node.rotation.data());
        newNode->rotation = glm::mat4(q);
    }
    if (node.scale.size() == 3) {
        glm::vec3 scale = glm::make_vec3(node.scale.data());
        newNode->scale = scale * globalscale;
    }
    if (node.matrix.size() == 16) {
        newNode->matrix = glm::make_mat4x4(node.matrix.data());
    };

    for (size_t i = 0; i < node.children.size(); i++) {
        LoadNode(newNode.get(), input.nodes[node.children[i]], node.children[i], input, globalscale);
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
            bool hasIndices = primitive.indices > -1;

            glm::vec3 posMin {};
            glm::vec3 posMax {};

            // Vertices
            {
                const float* bufferPos = nullptr;
                const float* bufferNormals = nullptr;
                const float* bufferTexCoordSet0 = nullptr;
                const float* bufferTexCoordSet1 = nullptr;

                int posByteStride = 0;
                int normByteStride = 0;
                int uv0ByteStride = 0;
                int uv1ByteStride = 0;

                // Position attribute is required
                assert(primitive.attributes.find("POSITION") != primitive.attributes.end());

                const tinygltf::Accessor& posAccessor = input.accessors[primitive.attributes.find("POSITION")->second];
                vertexCount = static_cast<uint32_t>(posAccessor.count);

                SScene::FillVertexAttribute(primitive, input, "POSITION", TINYGLTF_TYPE_VEC3, &bufferPos, posByteStride);
                SScene::FillVertexAttribute(primitive, input, "NORMAL", TINYGLTF_TYPE_VEC3, &bufferNormals, normByteStride);
                SScene::FillVertexAttribute(primitive, input, "TEXCOORD_0", TINYGLTF_TYPE_VEC2, &bufferTexCoordSet0, uv0ByteStride);
                SScene::FillVertexAttribute(primitive, input, "TEXCOORD_1", TINYGLTF_TYPE_VEC2, &bufferTexCoordSet1, uv1ByteStride);

                posMin = glm::vec3(posAccessor.minValues[0], posAccessor.minValues[1], posAccessor.minValues[2]);
                posMax = glm::vec3(posAccessor.maxValues[0], posAccessor.maxValues[1], posAccessor.maxValues[2]);
                
                for (size_t v = 0; v < posAccessor.count; ++v) {
                    struct GLMVertex
                    {
                        glm::vec4 position;
                        glm::vec4 normal;
                        glm::vec4 uv;
                    } vert = {};
                    
                    vert.position = glm::vec4(glm::make_vec3(&bufferPos[v * posByteStride]), 1.0f);
                    vert.position *= 0.08f;
                    vert.position.z += 1.5f;
                    vert.normal = glm::vec4(glm::normalize(glm::vec3(bufferNormals ? glm::make_vec3(&bufferNormals[v * normByteStride]) : glm::vec3(0.0f))), 1.0f);
                    glm::vec2 uv0 = bufferTexCoordSet0 ? glm::make_vec2(&bufferTexCoordSet0[v * uv0ByteStride]) : glm::vec2(0.0f);
                    glm::vec2 uv1 = bufferTexCoordSet1 ? glm::make_vec2(&bufferTexCoordSet1[v * uv1ByteStride]) : glm::vec2(0.0f);
                    vert.uv = glm::vec4(uv0.x, uv0.y, uv1.x, uv1.y);
                    
                    Vertex* castedVert = reinterpret_cast<Vertex*>(&vert);
                    vertexBuffer.push_back(*castedVert);
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
                    LogW(eTag::kAssetLoading) << "Index component type " << accessor.componentType << " not supported!" << std::endl;
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

void mcw::Scene::Draw(id<MTLRenderCommandEncoder> renderEncoder)
{
    for (const Node* node : allNodes)
    {
        node->Draw(renderEncoder);
    }
}
