#!/bin/bash

##### BASE DIR #####
export BASE_DIR=$(dirname $1)

##### PROJECT DIR #####
export PROJECT_DIR=${BASE_DIR}


export CST_HOME=<path-to-cst-tool>/cst-3.3.1 # Used by the perl script for signing the binary image
export CST_BIN=${CST_HOME}/linux64/bin       # Used by the perl script for signing the binary image

export PLATFORM=IMXRT
export CROSSCOMPILE=<path-to-your-cross-toolchain>/bin/<cross-compiler-prefix>-