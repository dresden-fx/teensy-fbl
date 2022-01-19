#ifndef DCP_H
#define DCP_H


typedef enum DCP_KEY_SELECT
{
  DCP_KEY_SELECT_eSOFTWARE_KEY = 0U, /* set key using software */
  DCP_KEY_SELECT_eSNVS_KEY_LO,       /* Use [127:0] from snvs key as dcp key */
  DCP_KEY_SELECT_eSNVS_KEY_HI,       /* Use [255:128] from snvs key as dcp key */
  DCP_KEY_SELECT_eOCOTP_KEY_LO,      /* Use [127:0] from ocotp key as dcp key */
  DCP_KEY_SELECT_eOCOTP_KEY_HI,      /* Use [255:128] from ocotp key as dcp key */
}T_DCP_KEY_SELECT;


typedef enum DCP_KEY_SLOT
{
  DCP_KEY_SLOT_eSLOT0 = 0U,
  DCP_KEY_SLOT_eSLOT1,
  DCP_KEY_SLOT_eSLOT2,
  DCP_KEY_SLOT_eSLOT3,
  DCP_KEY_SLOT_eOCOTP,
  DCP_KEY_SLOT_eUNIQUE_OTP,
  DCP_KEY_SLOT_ePAYLOAD_KEY,
}T_DCP_KEY_SLOT;


typedef enum DCP_OPC
{
  DCP_OPC_eMEMCPY = 1,
  DCP_OPC_eBLIT = 2,
  DCP_OPC_eCIPHER = 4,
  DCP_OPC_eHASH = 8,
}T_DCP_OPC;


typedef enum DCP_CIPHER_ALGO
{
  DCP_CIPHER_ALGO_eAES128 = 0,
}T_DCP_CIPHER_ALGO;


typedef enum DCP_CIPHER_MODE
{
  DCP_CIPHER_MODE_eECB = 0,
  DCP_CIPHER_MODE_eCBC,
}T_DCP_CIPHER_MODE;


typedef enum DCP_HASH_ALGO
{
  DCP_HASH_ALGO_eSHA1 = 0,
  DCP_HASH_ALGO_eCRC32,
  DCP_HASH_ALGO_eSHA256,
}T_DCP_HASH_ALGO;


/*! @brief DCP's configuration structure. */
typedef struct
{
  boolean gatherResidualWrites;   /*!< Enable the ragged writes to the unaligned buffers. */
  boolean enableContextCaching;   /*!< Enable the caching of contexts between the operations. */
  boolean enableContextSwitching; /*!< Enable automatic context switching for the channels. */
  uint8   enableChannel;          /*!< DCP channel enable. */
  uint8   enableChannelInterrupt; /*!< Per-channel interrupt enable. */
}T_DCP_CFG;


typedef struct
{
  T_DCP_OPC opc;
  uint8 swapCfg;
  uint8 algo;
  uint8 keyID;
  uint8 mode;
}T_DCP_CHAN_CFG;


#define DCP_DIGEST_SIZE 32

typedef union
{
  uint32 words[DCP_DIGEST_SIZE / 4];
  uint8  bytes[DCP_DIGEST_SIZE];
}T_DCP_DIGEST;


extern void dcp_deinitDev(uint32 devID);
extern void dcp_initDev(uint32 devID);
extern void dcp_configDev(uint32 devID, T_DCP_CFG* devCfg);
extern void dcp_configChannel(uint32 chanID, T_DCP_CHAN_CFG* chCfg);

extern T_STATUS dcp_hash(uint32 chanID, uint8* digest, uint8* outSize, const uint8* msgText, uint16 msgLen);

#endif /* DCP_H */

