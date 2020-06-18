#pragma once

#include <string>
#include <vector>

namespace mcw {
    struct ImmutableConfig
    {
        const uint32_t width;
        const uint32_t height;
        
        std::vector<std::string> args;
    };
}
