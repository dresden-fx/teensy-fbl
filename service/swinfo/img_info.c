#ifndef IMG_INFO_C
#define IMG_INFO_C
#endif /* IMG_INFO_C */

#include "bsp.h"

#include "trace_pub.h"
#include "swinfo.h"
#include "sw_release.h"

#include "img_info.h"


void imginfo_dumpSwInfo(const T_SWINFO* swInfo)
{
  const T_SW_REL_INFO* swRelInfo = NULL;
  uint16 layoutID;
  
  TRACE_INFO("Software Info:\n");
  TRACE_INFO("  ImgAddr:  %08x\n", swInfo->imgAddr);
  TRACE_INFO("  ImgSize:  %08x (%d Bytes)\n", swInfo->imgSize, swInfo->imgSize);
  TRACE_INFO("  ImgCRC:   %08x\n", swInfo->crc);
  TRACE_INFO("  ImgIdent: %s\n", (char*)swInfo->reserved);

  swRelInfo = (const T_SW_REL_INFO*)swInfo->versionAddr;
  if(NULL == swRelInfo)
  {
    /* Invalid SW release info */
  }
  else if(swInfo->versionLen != sizeof(T_SW_REL_INFO))
  {
    /* Invalid SW release info */
  }
  else if(0 != (layoutID = BYTES_TO_UINT16(swRelInfo->layoutID[0], swRelInfo->layoutID[1])) )
  {
    /* Invalid layout ID */
  }
  else
  {
    /* Everything OK */
    uint16 major = BYTES_TO_UINT16(swRelInfo->major[0], swRelInfo->major[1]);
    uint16 minor = BYTES_TO_UINT16(swRelInfo->minor[0], swRelInfo->minor[1]);
    uint16 patch = BYTES_TO_UINT16(swRelInfo->patch[0], swRelInfo->patch[1]);
    uint32 rev = BYTES_TO_UINT32(swRelInfo->revision[0], swRelInfo->revision[1], swRelInfo->revision[2], swRelInfo->revision[3]);

    TRACE_INFO("Release Info:\n");
    TRACE_INFO("  Version:  %d.%d.%d\n", major, minor, patch);
    TRACE_INFO("  Revision: %d\n", rev);
    TRACE_INFO("  Commit:   %s\n", swRelInfo->shortHash);
    TRACE_INFO("  Release:  %s %s\n", swRelInfo->relDate, swRelInfo->relTime);
    TRACE_INFO("  Built:    %s %s\n", swRelInfo->buildDate, swRelInfo->buildTime);
  }
}
