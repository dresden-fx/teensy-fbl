#ifndef DLCF_C
#define DLCF_C
#endif /* DLCF_C */

#include "bsp.h"
#include "trace_pub.h"
#include <stdio.h>
#include "libc.h"

#include "uart.h"
#include "pdu.h"
#include "dlcf.h"


#if (TRC_FEAT_DLCF_ENA == STD_ON)
#define TRACE_DLCF_API(...)   TRACE_FEATURE(TRC_FEAT_ID_eDLCF, TRACE_FEATURE_CLASS3, __VA_ARGS__)
#define TRACE_DLCF_INFO(...)  TRACE_FEATURE(TRC_FEAT_ID_eDLCF, TRACE_FEATURE_CLASS2, __VA_ARGS__)
#define TRACE_DLCF_ERROR(...) TRACE_FEATURE(TRC_FEAT_ID_eDLCF, TRACE_FEATURE_CLASS0, __VA_ARGS__)
#define TRACE_DLCF_STATE(...) TRACE_FEATURE(TRC_FEAT_ID_eDLCF, TRACE_FEATURE_CLASS1, __VA_ARGS__)
#else /* (TRC_FEAT_DLCF_ENA != STD_ON) */
#define TRACE_DLCF_API(...)   /* empty */
#define TRACE_DLCF_INFO(...)  /* empty */
#define TRACE_DLCF_ERROR(...) /* empty */
#define TRACE_DLCF_STATE(...) /* empty */
#endif /* (TRC_FEAT_DLCF_ENA) */


/*
 * Data Link Control Framing
 */

/* The callbacks shall be used to transmit or receive single characters to
 * or from real or virtual devices.
 * The underlaying device normally needs a device ID or context pointer to
 * be given to the driver function. As the driver API may vary depending on
 * the device type. So a generic callback with a static prototype might need
 * an adaption unit for every device type and maybe for every distinct device.
 *
 * So instead of using callbacks a better way might be to define a DLCF
 * function which calls an adapter function as it is done in trace_flex and
 * debug_flex.
 *
 * The advantage is, that the adapter functions are project specific part of
 * DLCF instead of the underlaying device.
 *
 * There is currently no device or channel management, so the adapter
 * functions can be static. If a channel management is demanded, the adapter
 * functions need to be setup at compile time in the channel's configuration
 * or dynamically at runtime by related functions.
 *
 * uart_sendByte(uint32 devID, uint8 byte);
 * uart_recvByte(uint32 devID, uint8* byte);
 *
 * Return UART specific result
 *
 *
 * rbuf_wrByte(T_RBUF_DESC* bufInfo, uint8 byte);
 * rbuf_rdByte(T_RBUF_DESC* bufInfo, uint8* byte);
 *
 * Return RBUF specific result 
 *
 *
 * boolean dlcf_flex_sendByte(T_DLCF_CTX* ctx, const uint8 byte)
 * {
 *   boolean result;
 *   uint32 devID = ctx->devID;
 *
 *   if(UART_OK != uart_sendByte(devID, byte))
 *   {
 *     result = FALSE;
 *   }
 *   else
 *   {
 *     result = !FALSE;
 *   }
 *   return result;
 * }
 *
 *
 * boolean dlcf_flex_recvByte(T_DLCF_CTX* ctx, uint8* byte)
 * {
 *   boolean result;
 *   uint32 devID = ctx->devID;
 *
 *   if(UART_OK != uart_recvByte(devID, byte))
 *   {
 *     result = FALSE;
 *   }
 *   else
 *   {
 *     result = !FALSE;
 *   }
 *   return result;
 * }
 *
 *
 */

/*
 ******************************************************************************
 *
 ******************************************************************************
 *
 *
 ******************************************************************************
 */

static boolean dlcf_sendByte(T_DLCF_CTX* ctx, uint8 byte)
{
  const T_DLCF_DEV_INFO* devInfo = ctx->devInfo;
  return devInfo->wrByte(devInfo->devData, byte);
}


/*
 ******************************************************************************
 *
 ******************************************************************************
 * @brief 
 *
 ******************************************************************************
 */

static boolean dlcf_recvByte(T_DLCF_CTX* ctx, uint8* byte)
{
  const T_DLCF_DEV_INFO* devInfo = ctx->devInfo;
  return devInfo->rdByte(devInfo->devData, byte);
}


/*
 ******************************************************************************
 * Function: dlcf_configCtx
 ******************************************************************************
 * @brief Configure the given DLCF context
 *
 * @param [out] ctx - DLCF context
 * @param [in] cfg - The configuration for the DLCF channel
 *
 ******************************************************************************
 */
 
void dlcf_configCtx(T_DLCF_CTX* ctx, T_DLCF_CFG* cfg)
{
  TRACE_DLCF_API("dlcf_configCtx()\n");
  ctx->cfg = cfg;
  ctx->txCbk = NULL;
  ctx->rxCbk = NULL;
  ctx->txState = DLCF_TX_STATE_eCONFIG;
  ctx->rxState = DLCF_RX_STATE_eIDLE;
  ctx->devInfo = NULL;
  TRACE_DLCF_STATE("DLCF RX: RESET -> IDLE\n");
  TRACE_DLCF_STATE("DLCF TX: RESET -> CONFIG\n");  
}


/*
 ******************************************************************************
 * Function: dlcf_setupDevInfo
 ******************************************************************************
 * @brief Setup underlaying device info
 *
 ******************************************************************************
 */

T_STATUS dlcf_setDevInfo(T_DLCF_CTX* ctx, const T_DLCF_DEV_INFO* devInfo)
{
  T_STATUS result;
  
  TRACE_DLCF_API("dlcf_setDevInfo()\n");
  switch(ctx->txState)
  {
  case DLCF_TX_STATE_eCONFIG:
  case DLCF_TX_STATE_eIDLE:
  case DLCF_TX_STATE_eFINISHED:
    /* Device setup is not allowed when active */
    ctx->txState = DLCF_TX_STATE_eIDLE;
    ctx->devInfo = devInfo;
    result = DLCF_OK;
    TRACE_DLCF_STATE("DLCF TX: CONFIG -> IDLE\n");
    break;

  default:
    result = DLCF_ERROR_INVALID;
    break;
  }
  return result;
}


/*
 ******************************************************************************
 * Function: dlcf_sendPdu
 ******************************************************************************
 * @brief Submit a PDU to be sent
 *
 * @param [out] ctx - DLCF context
 * @param [in] txPdu - PDU to be sent
 *
 ******************************************************************************
 */
 
T_STATUS dlcf_sendPdu(T_DLCF_CTX* ctx, T_PDU* txPdu)
{
  T_STATUS result = DLCF_FRAME_PENDING;

  switch(ctx->txState)
  {
  case DLCF_TX_STATE_eIDLE:
  case DLCF_TX_STATE_eFINISHED:
    if(txPdu == NULL)
    {
      /* Invalid PDU */
      result = DLCF_ERROR_INVALID;
    }
    else if(txPdu->data == NULL)
    {
      /* Invalid data */
      result = DLCF_ERROR_INVALID;
    }
    else if(txPdu->len == 0)
    {
      /* Invalid length */
      result = DLCF_ERROR_INVALID;
    }
    else if(NULL == ctx->devInfo)
    {
      /* Invalid write callback */
      result = DLCF_ERROR_INVALID;
    }
    else if(NULL == ctx->devInfo->wrByte)
    {
      /* Invalid write callback */
      result = DLCF_ERROR_INVALID;
    }
    else
    {
      /* Lock context */
      ctx->txState = DLCF_TX_STATE_eSOF;
      ctx->txData = txPdu->data;
      ctx->txLen = txPdu->len;
      ctx->txPos = 0u;
      // TODO: Here we might execute the first transmission
      result = DLCF_OK;
    }
    break;

  default:
    break;
  }
  return result;
}


/*
 ******************************************************************************
 * Function: dlcf_recvPdu
 ******************************************************************************
 * @brief Supply a PDU to receive to
 *
 * @param [out] ctx - DLCF context
 * @param [in] rxPdu - PDU to be received
 *
 ******************************************************************************
 */
 
T_STATUS dlcf_recvPdu(T_DLCF_CTX* ctx, T_PDU* rxPdu)
{
  T_STATUS result = DLCF_FRAME_PENDING;

  TRACE_DLCF_API("dlcf_recvPdu()\n");
  switch(ctx->rxState)
  {
  case DLCF_RX_STATE_eIDLE:
  case DLCF_RX_STATE_eFINISHED:
    if(rxPdu == NULL)
    {
      /* Invalid PDU */
      result = DLCF_ERROR_INVALID;
    }
    else if(rxPdu->data == NULL)
    {
      /* Invalid data */
      result = DLCF_ERROR_INVALID;
    }
    else if(rxPdu->size == 0)
    {
      /* Invalid size */
      result = DLCF_ERROR_INVALID;
    }
    else if(NULL == ctx->devInfo)
    {
      /* Invalid write callback */
      result = DLCF_ERROR_INVALID;
    }
    else if(NULL == ctx->devInfo->rdByte)
    {
      /* Invalid read callback */
      result = DLCF_ERROR_INVALID;
    }
    else
    {
      /* Lock context */
      ctx->rxState = DLCF_RX_STATE_eSOF; /* Wait for reception of SOF */
      ctx->rxPdu = rxPdu;
      ctx->rxPos = 0u;
      // TODO: Here we might execute the first reception
      result = DLCF_OK;
      TRACE_DLCF_STATE("DLCF RX: IDLE -> SOF\n");
    }
    break;

  default:
    break;
  }
  return result;
}


/*
 ******************************************************************************
 * Function: dlcf_getRxStatus
 ******************************************************************************
 * @brief Retrieve receive status
 *
 * @param [in] ctx - DLCF context
 *
 ******************************************************************************
 */
 
T_DLCF_STATUS dlcf_getRxStatus(T_DLCF_CTX* ctx)
{
  T_DLCF_STATUS result = DLCF_STATUS_eFRAME_PENDING;
  
  switch(ctx->rxState)
  {
  case DLCF_RX_STATE_eFINISHED:
    result = DLCF_STATUS_eFRAME_FINISHED;
    break;

  case DLCF_RX_STATE_eIDLE:
    result = DLCF_STATUS_eOK;
    break;

  default:
    /* Reception not finished,
     * keep result.
     */
    break;
  }
  return result;
}


/*
 ******************************************************************************
 * Function: dlcf_clrRxStatus
 ******************************************************************************
 * @brief Clear receive status
 *
 * @param [in] ctx - DLCF context
 *
 ******************************************************************************
 */

void dlcf_clrRxStatus(T_DLCF_CTX* ctx)
{
  switch(ctx->rxState)
  {
  case DLCF_RX_STATE_eFINISHED:
    ctx->rxState = DLCF_RX_STATE_eIDLE;
    break;

  default:
    /* Reception not finished or still idle,
     * keep state.
     */
    break;
  }
}


/*
 ******************************************************************************
 * Function: dlcf_getTxStatus
 ******************************************************************************
 * @brief Retrieve transmit status
 *
 * @param [out] ctx - DLCF context
 *
 ******************************************************************************
 */
 
T_DLCF_STATUS dlcf_getTxStatus(T_DLCF_CTX* ctx)
{
  T_DLCF_STATUS result = DLCF_STATUS_eFRAME_PENDING;
  
  switch(ctx->txState)
  {
  case DLCF_TX_STATE_eFINISHED:
  case DLCF_TX_STATE_eIDLE:
    result = DLCF_STATUS_eFRAME_FINISHED;
    break;

  case DLCF_TX_STATE_eSOF:
  case DLCF_TX_STATE_eDATA:
  case DLCF_TX_STATE_eESC:
  case DLCF_TX_STATE_eEOF:
    /* Transmission still in progress,
     * keep result.
     */
    break;

  default:
    break;
  }
  return result;
}


/*
 ******************************************************************************
 * Function: dlcf_clrTxStatus
 ******************************************************************************
 * @brief Clear transmit status
 *
 * @param [in] ctx - DLCF context
 *
 ******************************************************************************
 */

void dlcf_clrTxStatus(T_DLCF_CTX* ctx)
{
  switch(ctx->txState)
  {
  case DLCF_TX_STATE_eFINISHED:
    ctx->txState = DLCF_TX_STATE_eIDLE;
    break;

  default:
    /* Transmission not finished or still idle,
     * keep state.
     */
    break;
  }
}


T_STATUS dlcf_procTxByte(T_DLCF_CTX* ctx, uint8* txByte)
{
  T_STATUS result = DLCF_OK;

  /* Check if any data has to be sent */
  switch(ctx->txState)
  {
  case DLCF_TX_STATE_eSOF:
    /* Send start of frame */
    *txByte = ctx->cfg->ctlBytes[DLCF_CTL_BYTE_ID_eSOF];
    ctx->txState = DLCF_TX_STATE_eDATA;
    TRACE_DLCF_INFO("DLCF ENC: SOF=%02x\n", *txByte);
    break;

  case DLCF_TX_STATE_eDATA:
    /* Send data */
    do
    {
      if(ctx->txPos < ctx->txLen)
      {
        /* There are further bytes to be transmitted. */
        uint8 ctrlID;

        *txByte = ctx->txData[ctx->txPos++];
        for(ctrlID = 0; ctrlID < ctx->cfg->numCtlEscBytes; ctrlID++)
        {
          if(*txByte != ctx->cfg->ctlBytes[ctrlID])
          {
            /* Try next defined control byte */
          }
          else
          {
            /* Detected control character, so DLE followed by
             * the detected control character's escape character
             * needs to be written.
             */
            *txByte = ctx->cfg->ctlBytes[DLCF_CTL_BYTE_ID_eESC];
            /* Remember the control character's ID */
            ctx->ctlID = ctrlID;
            ctx->txState = DLCF_TX_STATE_eESC;
            /* Leave the for-loop. */
            break;
          }
        }
      }
      else 
      {
        /* No more bytes to be transmitted. */
        ctx->txState = DLCF_TX_STATE_eEOF;

        /* If registered execute callback function */
        if(NULL != ctx->txCbk)
        {
          /* The callback might continue the transmission */
          ctx->txCbk();
        }

        /* Check whether transfer continues */
        if(ctx->txState != DLCF_TX_STATE_eEOF)
        {
          /* Transfer continues */
          continue;
        }
        else
        {
          /* Transfer definately finished, so send end of frame */
          *txByte = ctx->cfg->ctlBytes[DLCF_CTL_BYTE_ID_eEOF];
          TRACE_DLCF_INFO("DLCF ENC: EOF=%02x\n", *txByte);
          ctx->txState = DLCF_TX_STATE_eFINISHED;
        }
      }
    }while(0);
    break;

  case DLCF_TX_STATE_eESC:
    *txByte = ctx->cfg->escBytes[ctx->ctlID];
    TRACE_DLCF_INFO("DLCF ENC: XCHR (%02x -> %02x)\n", ctx->cfg->ctlBytes[ctx->ctlID], *txByte);
    ctx->txState = DLCF_TX_STATE_eDATA;
    break;

  default:
    result = DLCF_FRAME_PENDING;
    break;
  }
  return result;
}




/* gets a character or a STX - DLE encapsulated block from the RX queue
 * ATTENTION: non blocking function
 *
 * if the first received character is NOT a STX it returns with a length of 1
 * if the first received character is a STX this function leaves the idle state
 * and waits for a ETX in subsequent calls.
 * the leading DLE prefixes are removed and the net data is stored to the
 * buffer regarding the buffer length.
 * the function returns the type of received data (single char or block)
 *
 * CRC16 is calculated during reception, the calling instance has to take care
 * of this.
 *
 * ATTENTION: the control structure shall be initialized in advance
 */

T_STATUS dlcf_procRxByte(T_DLCF_CTX* ctx, uint8 rxByte)
{
  /* Assume receiver pending */
  T_STATUS result = DLCF_FRAME_PENDING;

  switch(ctx->rxState)
  {
  case DLCF_RX_STATE_eSOF:
    /* Receiver is waiting for SOF */
    if(ctx->cfg->ctlBytes[DLCF_CTL_BYTE_ID_eSOF] == rxByte)
    {
      TRACE_DLCF_INFO("DLCF DEC: SOF=%02x\n", rxByte);
      /* Start of frame detetcted */
      ctx->rxPos = 0u;
      /* Switch to data receive state */
      ctx->rxState = DLCF_RX_STATE_eDATA;
      
      TRACE_DLCF_STATE("DLCF RxState: SOF -> DATA\n");
    }
    else
    {
      /* Ignore any other character */
      TRACE_DLCF_INFO("DLCF DEC: IGN=%02x\n", rxByte);
      result = DLCF_BYTE_RECEIVED;
    }
    break;

  case DLCF_RX_STATE_eDATA:
    /* Check for frame restart */
    if(ctx->cfg->ctlBytes[DLCF_CTL_BYTE_ID_eSOF] == rxByte)
    {
      /* Restart of frame detetcted */
      TRACE_DLCF_INFO("DLCF DEC: RSOF=%02x\n", rxByte);
      ctx->rxPos = 0u;
      TRACE_DLCF_INFO("DLCF RxState: RSOF -> DATA\n");
    }
    /* Check for DLE character */
    else if(ctx->cfg->ctlBytes[DLCF_CTL_BYTE_ID_eESC] == rxByte)
    {
      /* DLE detected, so switch to ESC state */
      TRACE_DLCF_INFO("DLCF DEC: DLE=%02x\n", rxByte);
      ctx->rxState = DLCF_RX_STATE_eESC;
      TRACE_DLCF_STATE("DLCF RxState: DATA -> ESC\n");
    }
    /* Check for end of frame */
    else if(ctx->cfg->ctlBytes[DLCF_CTL_BYTE_ID_eEOF] == rxByte)
    {
      /* End of frame received */
      TRACE_DLCF_INFO("DLCF DEC: EOF=%02x\n", rxByte);
      ctx->rxPdu->len = ctx->rxPos;
      ctx->rxState = DLCF_RX_STATE_eFINISHED;
      
      /* Leave function with frame received */
      result = DLCF_FRAME_FINISHED;
      
      TRACE_DLCF_STATE("DLCF RxState: DATA -> FIN\n");
    }
    /* Any non-control-caracter received
     * Check for enough remaining space
     */
    else if(ctx->rxPos < ctx->rxPdu->size)
    {
      /* Enough space left */
      TRACE_DLCF_INFO("DLCF DEC: CHR=%02x\n", rxByte);
      ctx->rxPdu->data[ctx->rxPos] = rxByte;
      ctx->rxPos++;
    }
    else
    {
      /* Buffer overflow - switch to error state */
      TRACE_DLCF_INFO("DLCF ERR: OVL=%02x\n", rxByte);
      ctx->rxState = DLCF_RX_STATE_eERROR;
      
      TRACE_DLCF_STATE("DLCF RxState: DATA -> ERR\n");
    }
    break;

  case DLCF_RX_STATE_eESC:
    /* Check for space in buffer - otherwise ignore data */
    if(ctx->rxPos < ctx->rxPdu->size)
    {
      uint8 ctrlID;
       
      /* Enough space left,
       * iterate over escaped control bytes and compare with received character.
       */
      for(ctrlID = 0; ctrlID < ctx->cfg->numCtlEscBytes; ctrlID++)
      {
        if(rxByte != ctx->cfg->escBytes[ctrlID])
        {
          /* Try next defined control byte */
        }
        else
        {
          /* Detected escaped control character, so the unescaped
           * control character needs to be written.
           */
          rxByte = ctx->cfg->ctlBytes[ctrlID];
          TRACE_DLCF_INFO("DLCF DEC: XCHR (%02x -> %02x)\n", ctx->cfg->escBytes[ctrlID], rxByte);
          ctx->rxState = DLCF_RX_STATE_eDATA;

          TRACE_DLCF_STATE("DLCF RxState: ESC -> DATA\n");
          /* Leave the loop. */
          break;
        }
      }
      // TODO: What if the received charater is not a escaped control character?
      ctx->rxPdu->data[ctx->rxPos] = rxByte;
      ctx->rxPos++;
    }
    else
    {
      /* Buffer overflow - switch to error state */
      TRACE_DLCF_INFO("DLCF ERR: OVL=%02x\n", rxByte);
      ctx->rxState = DLCF_RX_STATE_eERROR;
      
      TRACE_DLCF_STATE("DLCF RxState: ESC -> ERR\n");
    }
    break;

  case DLCF_RX_STATE_eERROR:
    /* Wait for end of frame */
    if(ctx->cfg->ctlBytes[DLCF_CTL_BYTE_ID_eEOF] == rxByte)
    {
      TRACE_DLCF_INFO("DLCF DEC: EOF=%02x\n", rxByte);
      ctx->rxPos = 0u;
      ctx->rxState = DLCF_RX_STATE_eIDLE;
      result = DLCF_FRAME_FINISHED; // TODO: ???
    }
    else
    {
      TRACE_DLCF_INFO("DLCF DEC: ERR=%02x\n", rxByte);
    }
    break;

  default:
    /* Not in frame reception */
    ctx->rxState = DLCF_RX_STATE_eIDLE;
    result = DLCF_BYTE_RECEIVED;
    break;
  }
  return result;
}


/*
 ******************************************************************************
 * Function: dlcf_run
 ******************************************************************************
 * @brief DLCF's cyclic function
 *
 * @param [out] ctx - DLCF context
 *
 ******************************************************************************
 */
 
void dlcf_run(T_DLCF_CTX* ctx)
{
  T_DLCF_STATUS rxStat = DLCF_STATUS_eFRAME_PENDING;
  uint8 byte;

  /* Execute transmission path:
   * Try to process next byte of the tansmit PDU.
   */
  if(DLCF_OK != dlcf_procTxByte(ctx, &byte))
  {
    /* Nothing to transmit */
  }
  else
  {
    /* We got a byte to be transmitted */
    TRACE_DLCF_INFO("DLCF TX: %02x ('%1c')\n", byte, byte);
    /* Send it to the next lower layer */
    dlcf_sendByte(ctx, byte);
    // TODO: What to do if it fails?
  }

  if(DLCF_RX_STATE_eIDLE == ctx->rxState)
  {
    /* No RX PDU set.
     * If we do nothing here, we cannot deliver non-frame bytes either.
     * If we try to receive something, we will latest get stuck, if
     * SOF is received. If we really expect framing, we should never see
     * the SOF unintended.
     */
  }
  /* Execute reception path */
  else if(FALSE != dlcf_recvByte(ctx, &byte))
  {
    /* Byte received */
    TRACE_DLCF_INFO("DLCF RX: %02x ('%1c')\n", byte, byte);
    /* Process the received byte into the receive PDU */
    rxStat = dlcf_procRxByte(ctx, byte);
  }
  else
  {
    /* Nothing received */
  }

  /* Examine the receiver status */
  switch(rxStat)
  {
  case DLCF_STATUS_eFRAME_PENDING:
    /* Frame not yet finished */
    break;
    
  case DLCF_STATUS_eBYTE_RECEIVED:
    /* Single character received */
    break;

  case DLCF_STATUS_eFRAME_FINISHED:
    /* Complete frame received */
    break;

  default:
    break;
  }
}
