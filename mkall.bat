@echo off

call mk\setenv.bat %0
rem set CROSSCOMPILE=C:\dvpt\tools\SourceryARM-EABI-2014.05\bin\arm-none-eabi-
rem set CROSSCOMPILE=C:\dvpt\tools\arduino-1.8.10\hardware\tools\arm\bin\arm-none-eabi-
set CROSSCOMPILE=C:\dvpt\tools\gcc-linaro-7.5.0-2019.12-i686-mingw32_arm-eabi\bin\arm-eabi-

echo ######## Report of MKALL.BAT ########                           2>&1 | tee    report.txt
echo;                                                                2>&1 | tee -a report.txt

echo #### Building startup\flash-boot ####                           2>&1 | tee -a report.txt
echo;                                                                2>&1 | tee -a report.txt
make -j -C .\driver\startup\imxrt\flash-boot PLATFORM=IMXRT clean    2>&1 | tee -a report.txt
make -j -C .\driver\startup\imxrt\flash-boot PLATFORM=IMXRT version  2>&1 | tee -a report.txt
make -j -C .\driver\startup\imxrt\flash-boot PLATFORM=IMXRT hex      2>&1 | tee -a report.txt
rem make -j -C .\driver\startup\imxrt\flash-boot PLATFORM=IMXRT postlink 2>&1 | tee -a report.txt
echo;                                                                2>&1 | tee -a report.txt
echo;                                                                2>&1 | tee -a report.txt

pause