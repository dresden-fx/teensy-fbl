#ifndef HAB_API_C
#define HAB_API_C
#endif /* HAB_API_C */

#include "bsp.h"
#include "reg.h"
#include "trace_pub.h"
#include "hab.h"
#include "hab_prv.h"
#include "hab_api.h"


typedef struct
{
  T_HAB_RVT* rvt;
}T_HAB_DATA;


static T_HAB_DATA hab_data =
{
  .rvt = (void*)(HAB_RVT_BASE),
};


/*
 ******************************************************************************
 *
 ******************************************************************************
 *
 *
 ******************************************************************************
 */

const T_HAB_RVT* hab_getRvt(void)
{
  return hab_data.rvt;
}


/*
 ******************************************************************************
 *
 ******************************************************************************
 * @brief Get the address of the image's image vector table (IVT) as
 *   defined by the linker
 *
 ******************************************************************************
 */

const void* hab_getOwnIvtAddr(void)
{
  return &ivt;
}


/*
 ******************************************************************************
 *
 ******************************************************************************
 * @brief Get the address of the image's command sequence file (CSF) as
 *   defined by the linker
 *
 ******************************************************************************
 */

const void* hab_getOwnCsfAddr(void)
{
  return &csf;
}


/*
 ******************************************************************************
 *
 ******************************************************************************
 * @brief Get the address of the image's device configuration data (DCD) as
 *   defined by the linker
 *
 ******************************************************************************
 */

const void* hab_getOwnDcdAddr(void)
{
  return __dcd_start;
}


/*
 ******************************************************************************
 *
 ******************************************************************************
 *
 *
 ******************************************************************************
 */

uint32 hab_getOwnDcdSize(void)
{
  return __dcd_end - __dcd_start;
}


/*
 ******************************************************************************
 *
 ******************************************************************************
 *
 *
 ******************************************************************************
 */

T_STATUS hab_getStatus(void)
{
  T_HAB_STATUS status;
  T_STATUS result;

  status = hab_data.rvt->reportStatus(NULL, NULL);
  switch(status)
  {
  case HAB_STATUS_SUCCESS:
    result = STATUS_eOK;
    break;
  case HAB_STATUS_WARN:
    result = STATUS_eNOK;
    break;
  case HAB_STATUS_FAIL:
    result = STATUS_eNOK;
    break;
  default:
    result = STATUS_eNOK;
    break;
  }
  return result;
}


/*
 ******************************************************************************
 *
 ******************************************************************************
 *
 *
 ******************************************************************************
 */

T_STATUS hab_init(void)
{
  T_HAB_STATUS status;
  T_STATUS result = STATUS_eOK;

  status = hab_data.rvt->entry();
  if(HAB_STATUS_SUCCESS != status)
  {
    result = STATUS_eNOK;
    TRACE_INFO("Failed to enter HAB!\n");
  }
  else
  {
    TRACE_INFO("Successfully entered HAB!\n");
  }
  return result;
}


/*
 ******************************************************************************
 *
 ******************************************************************************
 *
 *
 ******************************************************************************
 */

T_STATUS hab_deinit(void)
{
  T_HAB_STATUS status;
  T_STATUS result = STATUS_eOK;

  status = hab_data.rvt->exit();
  if(HAB_STATUS_SUCCESS != status)
  {
    TRACE_INFO("Failed to exit HAB!\n");
    result = STATUS_eNOK;
  }
  else
  {
    TRACE_INFO("Successfully exited HAB!\n");
  }
  return result;
}


/*
 ******************************************************************************
 *
 ******************************************************************************
 *
 *
 ******************************************************************************
 */

T_STATUS hab_checkTargetMem(void* startAddr, uint32 length)
{
  T_HAB_STATUS status;
  T_STATUS result = STATUS_eOK;

  status = hab_data.rvt->checkTarget(HAB_TRG_MEM, startAddr, length);
  if(status != HAB_STATUS_SUCCESS)
  {
    result = STATUS_eNOK;
  }
  return result;
}


/*
 ******************************************************************************
 *
 ******************************************************************************
 *
 *
 ******************************************************************************
 */

boolean hab_isIvtValid(const void* ivtAddr)
{
  boolean result = !FALSE;
  T_HAB_IVT* ivt = (void*)ivtAddr;
  
  if(HAB_TAG_IVT != ivt->hdr.tag)
  {
    /* Invalid tag */
    result = FALSE;
  }
  else if( sizeof(T_HAB_IVT) != HAB_GET_STRUCT_SIZE(ivt->hdr) )
  {
    /* Invalid size */
    result = FALSE;
  }
  else if(HAB_MAJOR_VERSION != HAB_GET_MAJOR_VERSION(ivt->hdr.par))
  {
    /* Invalid major version */
    result = FALSE;
  }
  else
  {
    /* Looks like a valid IVT header */
  }
  return result;
}


/*
 ******************************************************************************
 *
 ******************************************************************************
 *
 *
 ******************************************************************************
 */
#define IVT_ALIGNMENT 0x1000
#define CSF_PAD_SIZE  0x2000

T_STATUS hab_authImage(uint32 imageAddr, uint32 imageSize, uint32 ivtOffs)
{
  T_HAB_STATUS status;
  T_HAB_ENTRY entry;
  T_STATUS result = STATUS_eNOK;

  /* Enable clocks of CAAM module */
//  caam_enableClocks();
  
  TRACE_INFO("Authenicate image at address %08X\n", imageAddr);
  status = hab_data.rvt->entry();
  if( HAB_STATUS_SUCCESS == status )
  {
    /* r0: cid
     * r1: ivt_offset
     * r2: sp + 0C &start
     * r3: sp + 08 &length
     * 
     * [sp + 0C] start
     * [sp + 08] length
     * [sp + 00] callback
     */
    TRACE_INFO("Authenticating image...");
    entry = hab_data.rvt->authenticate_image(1, ivtOffs, (void**)&imageAddr, (uint32*)&imageSize, NULL);
    if(entry == NULL)
    {
      /* Note that on failed authentication NULL is only returned
       * in closed configuration.
       * So in open configuration the authImage function will return the entry
       * even if the authentication failed.
       */
      result = STATUS_eNOK;
      TRACE_INFO("failed\n");
    }
    else if(STATUS_eOK != hab_getStatus())
    {
      result = STATUS_eNOK;
      TRACE_INFO("failed\n");
    }
    else
    {
      result = STATUS_eOK;
      TRACE_INFO("success\n");
      TRACE_INFO("Entry: 0x%08X\n", entry);
    }
  }

  if(HAB_STATUS_SUCCESS != status)
  {
    TRACE_INFO("HAB: Failed to enter!\n");
  }
  else if(HAB_STATUS_SUCCESS != hab_data.rvt->exit())
  {
    TRACE_INFO("HAB: Failed to exit!\n");
  }
  return result;
}

