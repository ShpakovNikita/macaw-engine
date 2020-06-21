#pragma once

#include <vcruntime_exception.h>

namespace mcw
{
    struct AssetLoadingException : public std::exception {
        AssetLoadingException(const char* msg)
            : std::exception(msg)
        {
        }
    };
}
