#ifndef DCP_C
#define DCP_C
#endif /* DCP_C */


#include "bsp.h"
#include "reg.h"
#include "libc.h"
#include "trace_pub.h"
#include "ccm.h"
#include "dcp.h"


const uint32 dcp_chBaseTbl[4] =
{
  [0] = (DCP_BASE + DCP_CH0_OFFS),
  [1] = (DCP_BASE + DCP_CH1_OFFS),
  [2] = (DCP_BASE + DCP_CH2_OFFS),
  [3] = (DCP_BASE + DCP_CH3_OFFS),
};


/*! @brief DCP's job data. */
typedef struct
{
  uint32 nxtCmdAddr;
  uint32 ctrl0;
  uint32 ctrl1;
  uint32 srcMemAddr;
  uint32 dstMemAddr;
  uint32 bufSize;
  uint32 payloadPtr;
  uint32 status;
}T_DCP_JOB_DATA;


#define DCP_CTRL0_TAG_BF            24, 8 /*!< Paket Tag */
#define DCP_CTRL0_OUT_WORD_SWAP_BF  23, 1 /*!< Configures whether the DCP engine word-swaps the output data (BE) */
#define DCP_CTRL0_OUT_BYTE_SWAP_BF  22, 1 /*!< Configures whether the DCP engine byte-swaps the output data (BE) */
#define DCP_CTRL0_IN_WORD_SWAP_BF   21, 1 /*!< Configures whether the DCP engine word-swaps the input data (BE)*/
#define DCP_CTRL0_IN_BYTE_SWAP_BF   20, 1 /*!< Configures whether the DCP engine byte-swaps the input data (BE)*/
#define DCP_CTRL0_KEY_WORD_SWAP_BF  19, 1 /*!< Configures whether the DCP engine swaps the key words (BE) */
#define DCP_CTRL0_KEY_BYTE_SWAP_BF  18, 1 /*!< Configures whether the DCP engine swaps the key bytes (BE) */
#define DCP_CTRL0_SWAP_CONFIG_BF    18, 6 /*!< Configures the swapping features */
#define DCP_CTRL0_TEST_SEMA_IRQ_BF  17, 1 /*!< */
#define DCP_CTRL0_CONST_FILL_BF     16, 1 /*!< When set (MEMCPY and BLIT only), DCP fills dst with value found in src */
#define DCP_CTRL0_HASH_OUT_BF       15, 1 /*!< When HASH is enabled this controls whether input or output is hashed */
#define DCP_CTRL0_HASH_CHK_BF       14, 1 /*!< Controls whether calculated hash is compared to value found in payload */
#define DCP_CTRL0_HASH_TERM_BF      13, 1 /*!< Controls whether current block is the final block */
#define DCP_CTRL0_HASH_INIT_BF      12, 1 /*!< Controls whether current block is the initial block */
#define DCP_CTRL0_PAYLOAD_KEY_BF    11, 1 
#define DCP_CTRL0_OCOTP_KEY_BF      10, 1
#define DCP_CTRL0_CYPHER_INIT_BF     9, 1
#define DCP_CTRL0_CYPHER_ENC_BF      8, 1
#define DCP_CTRL0_ENA_BLIT_BF        7, 1
#define DCP_CTRL0_ENA_HASH_BF        6, 1
#define DCP_CTRL0_ENA_CYPHER_BF      5, 1
#define DCP_CTRL0_ENA_MEMCPY_BF      4, 1
#define DCP_CTRL0_CHAIN_CONT_BF      3, 1
#define DCP_CTRL0_CHAIN_BF           2, 1
#define DCP_CTRL0_DEC_SEMA_BF        1, 1
#define DCP_CTRL0_INT_ENA_BF         0, 1


#define DCP_CTRL1_CYPHER_CFG_BF     24, 8
#define DCP_CTRL1_HASH_SEL_BF       16, 4
#define DCP_CTRL1_KEY_SEL_BF         8, 8
#define DCP_CTRL1_CYPHER_MODE_BF     4, 4
#define DCP_CTRL1_CYPHER_SEL_BF      0, 4


typedef struct
{
  uint32 key[4]; /* Key value used in cipher operation (only used when keyID=payload) */
  uint32 iv[4];  /* Initial vector used in cipher operation (only used in CBC-mode) */
}T_DCP_CIPHER_PAYLOAD;


typedef struct
{
  uint8 digest[DCP_DIGEST_SIZE]; /* Resulting digest form hash operation or reference digest for hash-check */
}T_DCP_HASH_PAYLOAD;


typedef struct
{
  T_DCP_OPC opc;       /* What kind of operation to perform */
  uint8  swapCfg;
  uint8  algoSelect;   /* Cipher / hash algorithm */
  uint8  keyID;        /* Key ID used in cipher operation */
  uint8  cipherMode;   /* Mode used in cipher operation (only used for cipher operation) */
  union
  {
    T_DCP_CIPHER_PAYLOAD cipherPayload;
    T_DCP_HASH_PAYLOAD hashPayload;
  };
}T_DCP_CHAN_DATA;


typedef struct
{
  uint32 cipherCtx[4];
  uint32 hashCtx[9];
}T_DCP_CHAN_CTX;


/*! @brief DCP's context buffer, used by DCP for context switching between channels. */
typedef union
{
  T_DCP_CHAN_CTX ctxArray[4];
  uint32 words[208 / sizeof(uint32)];
  uint8  bytes[208];
}T_DCP_CTX;


typedef struct
{
  uint8  channel;
  uint8  keySlot;
  uint32 swapCfg;
  uint32 keyWord[4];
  uint32 iv[4];
  T_DCP_CTX ctx;
}T_DCP_DATA;

static T_DCP_DATA dcp_devDataTbl[1];
static T_DCP_CHAN_DATA dcp_chanDataTbl[4];

const T_CCM_CLK_CFG dcp_clkCfg[] =
{
  CLK_CNF_DEF(CCM_CCGR0_OFFS, DCP_CLK_ENA_BF, CCM_CG_eCLK_ON_ALW), /* CG on */
  CLK_CNF_END(),
};


const uint8 dcp_digestLenTbl[] =
{
  [DCP_HASH_ALGO_eSHA1] = 20,
  [DCP_HASH_ALGO_eCRC32] = 4,
  [DCP_HASH_ALGO_eSHA256] = 32,
};


T_DCP_DATA* dcp_getDevData(void)
{
  T_DCP_DATA* result = &dcp_devDataTbl[0];
  return result;
}


T_DCP_CHAN_DATA* dcp_getChanData(uint32 chanID)
{
  T_DCP_CHAN_DATA* result = &dcp_chanDataTbl[chanID];
  return result;
}



static void dcp_clrStatus(uint32 base)
{
  uint32 statReg;
  
  REG32_WRBF_BASE_OFFS(0xF, base, DCP_STAT_CLR_OFFS, DCP_STAT_IRQ_BF);
  do
  {
    REG32_RD_BASE_OFFS(statReg, base, DCP_STAT_OFFS);
  }while(0 != BF_GET(statReg, DCP_STAT_IRQ_BF));
}


static void dcp_clrChStatus(uint32 chBase)
{
  REG32_WR_BASE_OFFS(0xFF, chBase, DCP_CHx_STAT_CLR_OFFS);
}


/*
 ******************************************************************************
 *
 ******************************************************************************
 *
 *
 ******************************************************************************
 */

static T_STATUS dcp_waitForChannelComplete(uint32 chanID)
{
  T_STATUS result = STATUS_eNOK;
  uint32 statReg;
  uint32 chMap = (1 << chanID);
  uint32 chBase = dcp_chBaseTbl[chanID];

  do
  {
    /* Check whether our channel is active */
    REG32_RD_BASE_OFFS(statReg, DCP_BASE, DCP_STAT_OFFS);
  }while(0 != (BF_GET(statReg, DCP_STAT_READY_CHANNELS_BF) & chMap));

  REG32_RD_BASE_OFFS(statReg, chBase, DCP_CHx_STAT_OFFS);
  if(0 != (statReg & ~(BF_MASK(DCP_CH_STAT_TAG_BF))))
  {
    /* Aborted due to an error */
    dcp_clrStatus(DCP_BASE);
    dcp_clrChStatus(chBase);
    TRACE_ERROR("DCP: Error: 0x%08x\n", statReg);
  }
  else
  {
    result = STATUS_eOK;
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

static T_STATUS dcp_scheduleJob(uint32 chanID, T_DCP_JOB_DATA* dcpJob)
{
  T_STATUS result = STATUS_eNOK;
  uint32 statReg;
  uint32 chMap = (1 << chanID);

  /* Check whether our channel is active */
  REG32_RD_BASE_OFFS(statReg, DCP_BASE, DCP_STAT_OFFS);
  if(0 != (BF_GET(statReg, DCP_STAT_READY_CHANNELS_BF) & chMap))
  {
    result = STATUS_ePENDING;
  }
  else
  {
    uint32 chBase = dcp_chBaseTbl[chanID];

    REG32_WR_BASE_OFFS((uint32)dcpJob, chBase, DCP_CHx_CMD_SET_OFFS);
    CPU_DSB(0);
    CPU_ISB(0);
    REG32_WR_BASE_OFFS(1, chBase, DCP_CHx_SEMA_SET_OFFS);
    result = STATUS_eOK;
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

void dcp_initDev(uint32 devID)
{
  T_DCP_DATA* dcpData = dcp_getDevData();

  (void)devID;

  ccm_setupMultipleClkProps(dcp_clkCfg);

  /* Reset value */
  REG32_WR_BASE_OFFS(0xF0800000, DCP_BASE, DCP_CTRL_OFFS);
  /* Default value */
  REG32_WR_BASE_OFFS(0x30800000, DCP_BASE, DCP_CTRL_OFFS);

  dcp_clrStatus(DCP_BASE);

  for(int chanID = 0; chanID < 4; chanID++)
  {
    uint32 chBase = dcp_chBaseTbl[chanID];
    dcp_clrChStatus(chBase);
  }

  /* Set context switching buffer */
  REG32_WR_BASE_OFFS((uint32)(void*)&dcpData->ctx, DCP_BASE, DCP_CONTEXT_OFFS);  
}


/*
 ******************************************************************************
 *
 ******************************************************************************
 *
 *
 ******************************************************************************
 */

void dcp_deinitDev(uint32 devID)
{
  T_DCP_DATA* dcpData = dcp_getDevData();

  /* Reset value */
  REG32_WR_BASE_OFFS(0xF0800000, DCP_BASE, DCP_CTRL_OFFS);
  /* Clear context storage */
  libc_memset(&dcpData->ctx, 0, sizeof(dcpData->ctx));

  // TODO: Possibly disable clocks
}


/*
 ******************************************************************************
 *
 ******************************************************************************
 *
 *
 ******************************************************************************
 */

void dcp_configDev(uint32 devID, T_DCP_CFG* devCfg)
{
  uint32 ctrlReg;

  ctrlReg = ( 0
            | BF_SET(devCfg->enableContextCaching, DCP_CTRL_CONTEXT_CACHE_ENA_BF)
            | BF_SET(devCfg->enableContextSwitching, DCP_CTRL_CONTEXT_SWITH_ENA_BF)
            | BF_SET(devCfg->gatherResidualWrites, DCP_CTRL_GATHER_RESIDUAL_WR_BF)
            );
  REG32_WR_BASE_OFFS(ctrlReg, DCP_BASE, DCP_CTRL_OFFS);

  /* Enable DCP channels */
  REG32_WR_BASE_OFFS(devCfg->enableChannel, DCP_BASE, DCP_CHANNEL_CTRL_OFFS);
}


/*
 ******************************************************************************
 *
 ******************************************************************************
 *
 *
 ******************************************************************************
 */

void dcp_configChannel(uint32 chanID, T_DCP_CHAN_CFG* chCfg)
{
  T_DCP_CHAN_DATA* chData = dcp_getChanData(chanID);

  chData->opc = chCfg->opc;
  chData->swapCfg = chCfg->swapCfg;
  switch(chCfg->opc)
  {
  case DCP_OPC_eCIPHER:
    chData->algoSelect = chCfg->algo;
    chData->keyID = chCfg->keyID;
    chData->cipherMode = chCfg->mode;
    break;
  case DCP_OPC_eHASH:
    chData->algoSelect = chCfg->algo;
    break;
  default:
    break;
  }
}


/*!
 ******************************************************************************
 *
 ******************************************************************************
 * @brief Hashes arbitrary length data.
 *
 * @param chanID - channel ID
 * @param digest - pointer to output digest
 * @param outSize - Size of output data in bytes.
 * @param msgText - pointer to input message
 * @param msgLen - Size of input message in bytes.
 *
 * @return Status of hash operation
 *
 ******************************************************************************
 */

T_STATUS dcp_hash(uint32 chanID, uint8* digest, uint8* outSize, const uint8* msgText, uint16 msgLen)
{
  T_STATUS result = STATUS_eINVALID_ARG;

  T_DCP_CHAN_DATA* chData = dcp_getChanData(chanID);
  T_DCP_JOB_DATA dcpJobData = {0};
  T_DCP_JOB_DATA* dcpJob = &dcpJobData;
  uint8 algDigLen = dcp_digestLenTbl[chData->algoSelect];

  dcpJob->srcMemAddr = (uint32)(void*)msgText;
  dcpJob->dstMemAddr = (uint32)NULL;
  dcpJob->bufSize = msgLen;
  dcpJob->payloadPtr = (uint32)(void*)chData->hashPayload.digest;

  dcpJob->ctrl0 = ( 0
                  | BF_SET(0xC3, DCP_CTRL0_TAG_BF)
                  | BF_MASK(DCP_CTRL0_ENA_HASH_BF)
                  | BF_MASK(DCP_CTRL0_HASH_INIT_BF)
                  | BF_MASK(DCP_CTRL0_HASH_TERM_BF)
                  | BF_MASK(DCP_CTRL0_DEC_SEMA_BF)
                  | BF_SET(chData->swapCfg, DCP_CTRL0_SWAP_CONFIG_BF)
                  );

  dcpJob->ctrl1 = ( 0
                  | BF_SET(chData->algoSelect, DCP_CTRL1_HASH_SEL_BF)
                  );

  result = dcp_scheduleJob(chanID, dcpJob);

  if(STATUS_eOK != result)
  {
    /* Previous error */
  }
  else
  {
    result = dcp_waitForChannelComplete(chanID);
  }

  if(STATUS_eOK != result)
  {
    /* Previous error */
  }
  else
  {
    uint16 bytesToCopy = algDigLen;
    if(outSize == NULL)
    {
      /* No output size given */
    }
    else if(*outSize < bytesToCopy)
    {
      bytesToCopy = *outSize;
    }
    else
    {
      *outSize = algDigLen;
    }

    /* Copy in reverse order */
    for(int i = 0; i < bytesToCopy; i++)
    {
      digest[i] = chData->hashPayload.digest[algDigLen - i - 1];
    }
  }
  return result;
}

