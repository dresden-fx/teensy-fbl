@echo off
rem ##### DRIVE #####
set DRIVE=%~d0

rem ##### BASE DIR #####
set BASE_DIR=%~dp1

rem ##### PROJECT DIR #####
set PROJECT_DIR=%BASE_DIR%


rem # Used by the perl script for signing the binary image
set CST_HOME=<path-to-cst-tool>/cst-3.3.1
rem # Used by the perl script for signing the binary image
set CST_BIN=%CST_HOME%/linux64/bin

rem ##### MINGW DIR #####
rem  Used for objcopy
set MINGW_DIR=%DRIVE%\dvpt\tools\MinGW
set PATH=%MINGW_DIR%\bin;%PATH%

rem ##### MSYS DIR #####
rem # Used for make
set MSYS_DIR=%TOOLS_DIR%\MinGW\msys\1.0
set PATH=%MSYS_DIR%\bin;%PATH%
rem # Set proper time-zone
set TZ=CET-1CEST

rem ##### GIT ENV #####
set GIT_ROOT=<path-to-your-git-bin-dir>
set PATH=%GIT_ROOT%;%PATH%
set GIT=git

set PLATFORM=IMXRT
set CROSSCOMPILE=<path-to-your-cross-toolchain>/bin/<cross-compiler-prefix>-
