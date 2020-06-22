#pragma once

#include <stdexcept>

namespace mcw
{
    struct AssetLoadingException : public std::runtime_error {
        AssetLoadingException(const char* msg)
            : std::runtime_error(msg)
        {
        }
    };
}
