# nim-webview

A Nim wrapper for the [webview](https://github.com/webview/webview) library.

Uses a submodule, so to clone you need to run `git clone --recurse-submodules https://github.com/daniel-j/nim-webview.git`

## Install dependencies

### Linux

Note: When deploying to Windows, don't forget the include the webview/dll/x64 dlls and the [OpenSSL dlls](https://bintray.com/vszakats/generic/openssl).

#### Ubuntu/Debian

`sudo apt install libgtk-3-dev libwebkit2gtk-4.0-dev`

Windows crosscompile: `sudo apt install g++-mingw-w64-x86-64`

#### Arch Linux

`sudo pacman -S gtk3 webkit2gtk`

Windows crosscompile: `sudo pacman -S mingw-w64-gcc`

