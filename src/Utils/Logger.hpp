#pragma once

#include <string>
#include <iostream>

namespace mcw
{
    enum class eTag
    {
        kBase = 0,
        kRender,
        kAssetLoading,
        kEngine,
    };

    // TODO: return logger instance
    std::ostream& LogD(eTag tag);
    std::ostream& LogI(eTag tag);
    std::ostream& LogW(eTag tag);
    std::ostream& LogE(eTag tag);
}
