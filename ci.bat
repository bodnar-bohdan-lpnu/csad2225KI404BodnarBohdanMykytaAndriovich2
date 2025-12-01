@echo off
setlocal

set "BUILD_DIR=build"
set "CONFIG=Debug"
set "PUSHED=0"

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%" || goto :fail
pushd "%BUILD_DIR%" || goto :fail
set "PUSHED=1"

cmake .. -DCMAKE_BUILD_TYPE=%CONFIG% || goto :fail
cmake --build . --config %CONFIG% || goto :fail
ctest -C %CONFIG% --output-on-failure || goto :fail

echo SUCCESS
if "%PUSHED%"=="1" popd
exit /b 0

:fail
echo FAILED
if "%PUSHED%"=="1" popd
exit /b 1
