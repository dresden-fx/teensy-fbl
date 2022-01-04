@echo off
set PROJECT_NAME=teensy-fbl

call mk\setenv.bat %0

%DRIVE%
cd %PROJECT_DIR%
start "%PROJECT_NAME% Build Environment" bash
