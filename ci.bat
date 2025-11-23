@echo off
setlocal

set "BUILD_DIR=build"
set "PUSHED=0"

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%" || goto :fail
pushd "%BUILD_DIR%" || goto :fail
set "PUSHED=1"

cmake .. || goto :fail
cmake --build . || goto :fail
ctest || goto :fail

echo SUCCESS
if "%PUSHED%"=="1" popd
exit /b 0

:fail
echo FAILED
if "%PUSHED%"=="1" popd
exit /b 1
