# macaw-engine
Metal PBR IBL engine

### How to build?
This project supports only Macos platform.

### Macos

First, you need to make sure that SDL2 installed on your mac. This project uses SDL2 version 2.0.12, but it may work with older or newer ones. You can download it [here](https://www.libsdl.org/download-2.0.php). Then you have to drag 'SDL2.framework' folder into '/Library/Frameworks' folder.

```
$ mkdir build
$ cd build
$ CMake -G Xcode ..
```

And then you can select engine scheme via `Product`->`Scheme`->`Choose scheme`
