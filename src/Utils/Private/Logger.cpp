#include "Utils/Logger.hpp"

#include "Common/Constants.hpp"

#include <map>

namespace SLogger
{

    class NullOstream : public std::ostream
    {
    public:
        NullOstream() = default;
        
        template<typename T>
        NullOstream &operator <<(const T&)
        {
            return *this;
        };
    };

    static NullOstream NullLogStream;

    std::string BuildPrefix(const std::string& appendix, mcw::eTag tag)
    {
        static const std::map<mcw::eTag, std::string> TagNames =
        {
            { mcw::eTag::kBase,         "Base"         },
            { mcw::eTag::kRender,       "Render"       },
            { mcw::eTag::kAssetLoading, "AssetLoading" },
            { mcw::eTag::kEngine,       "Engine"       },
        };
        
        return appendix + std::string("[") + TagNames.find(tag)->second + std::string("]: ");
    }
}

std::ostream& mcw::LogD(eTag tag)
{
    if constexpr (IsDebugBuild)
    {
        return std::cout << SLogger::BuildPrefix("(Debug)", tag);
    }
    
    return SLogger::NullLogStream;
}

std::ostream& mcw::LogI(eTag tag)
{
    return std::cout << SLogger::BuildPrefix("(Info)", tag);
}

std::ostream& mcw::LogW(eTag tag)
{
    return std::cerr << SLogger::BuildPrefix("(Warning)", tag);
}

std::ostream& mcw::LogE(eTag tag)
{
    return std::cerr << SLogger::BuildPrefix("(Error)", tag);
}
