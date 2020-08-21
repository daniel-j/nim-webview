# nim-webview

A Nim wrapper for [webview](https://github.com/webview/webview) v0.10.0. Not yet ready for use, unstable and in development.

Uses a submodule, so to clone you need to run:

`git clone --recurse-submodules https://github.com/daniel-j/nim-webview.git`

## Install dependencies

Note: When deploying to Windows, don't forget the include the [webview dlls](https://github.com/webview/webview/tree/master/dll/x64) (are these up to date?).

### Linux

#### Ubuntu/Debian

`sudo apt install libwebkit2gtk-4.0-dev`

Windows crosscompile: `sudo apt install g++-mingw-w64-x86-64`

#### Arch Linux

`sudo pacman -S webkit2gtk`

Windows crosscompile: `sudo pacman -S mingw-w64-gcc`

