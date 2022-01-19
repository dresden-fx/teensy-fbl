#ifndef HAB_API_H
#define HAB_API_H

#include "hab.h"


#define be32ToCpu(x)        \
  ( 0                       \
  | (((char*)&x)[0] << 24)  \
  | (((char*)&x)[1] << 16)  \
  | (((char*)&x)[2] <<  8)  \
  | (((char*)&x)[3] <<  0))

#define be16ToCpu(x)        \
  ( 0                       \
  | (((char*)&x)[0] <<  8)  \
  | (((char*)&x)[1] <<  0))

extern T_STATUS hab_init(void);
extern T_STATUS hab_deinit(void);
extern T_STATUS hab_getStatus(void);
extern T_STATUS hab_checkTargetMem(void* startAddr, uint32 length);
extern T_STATUS hab_authImage(uint32 imageAddr, uint32 imageSize, uint32 ivtOffs);

extern boolean hab_isIvtValid(const void* ivtAddr);
extern const void* hab_getOwnIvtAddr(void);
extern const void* hab_getOwnDcdAddr(void);
extern uint32 hab_getOwnDcdSize(void);
extern const void* hab_getOwnCsfAddr(void);


extern const void* hab_getCsfAddrFromIvt(const void* ivtAddr);
extern const void* hab_getDcdAddrFromIvt(const void* ivtAddr);
extern const void* hab_getBootAddrFromIvt(const void* ivtAddr);
extern const void* hab_getEntryAddrFromIvt(const void* ivtAddr);
extern const void* hab_getPayloadAddrFromIvt(const void* ivtAddr);
extern uint32 hab_getPayloadSizeFromIvt(const void* ivtAddr);
extern uint32 hab_getImageSizeFromIvt(const void* ivtAddr);

extern void* hab_getDcdSizeFromIvt(void* dcdAddr);

extern const void* hab_getSrkTblAddrFromCsf(const void* csfAddr);

extern T_STATUS hab_getSrkTblInfoFromSrkTblAddr(T_SRK_TBL_INFO* srkTblInfo, const void* srkTblAddr);
extern void hab_provisionSrkHash(void);

#endif /* HAB_API_H */

