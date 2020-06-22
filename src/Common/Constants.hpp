#pragma once

#ifdef MCW_DEBUG
    constexpr bool IsDebugBuild = true;
#else
    constexpr bool IsDebugBuild = false;
#endif
