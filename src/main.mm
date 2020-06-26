#include <iostream>

#include "Core/Engine.hpp"
#include "Core/ImmutableConfig.hpp"

const int WIDTH = 1600, HEIGHT = 1200;

int main(int argc, char* argv[])
{
    mcw::ImmutableConfig engineConfig = { WIDTH, HEIGHT, {} };
    for (size_t i = 0; i < static_cast<size_t>(argc); i++) {
        engineConfig.args.push_back(argv[i]);
    };

    mcw::Engine engine = { engineConfig };

    int execResult;
    try {
        engine.Run();
        execResult = EXIT_SUCCESS;
    } catch (const std::runtime_error& e) {
        std::cerr << e.what() << std::endl;
        execResult = EXIT_FAILURE;
    }
    return execResult;
}
