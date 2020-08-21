@echo off

echo Prepare directories...
set script_dir=%~dp0
set src_dir=%script_dir%..

cd /D %src_dir%

echo Project directory: %src_dir%

cd /D %src_dir%
set "PATH=%PATH%;%src_dir%\webview\dll\x64;%src_dir%\webview\dll\x86"

echo Running tests
nimble test || exit /B

echo Building examples
nimble examples || exit /B
