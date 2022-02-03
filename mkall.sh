#!/bin/bash

source mk/setenv.sh

echo "######## Report of MKALL.SH #########"                       2>&1 | tee    report.txt
echo ""                                                            2>&1 | tee -a report.txt

echo "#### Building startup\flash-boot ####"                       2>&1 | tee -a report.txt
echo ""                                                            2>&1 | tee -a report.txt
make -j -C ./demo/startup/imxrt/flash-boot PLATFORM=IMXRT clean    2>&1 | tee -a report.txt
make -j -C ./demo/startup/imxrt/flash-boot PLATFORM=IMXRT version  2>&1 | tee -a report.txt
make -j -C ./demo/startup/imxrt/flash-boot PLATFORM=IMXRT hex      2>&1 | tee -a report.txt
make -j -C ./demo/startup/imxrt/flash-boot PLATFORM=IMXRT postlink 2>&1 | tee -a report.txt
echo ""                                                            2>&1 | tee -a report.txt
echo ""                                                            2>&1 | tee -a report.txt

