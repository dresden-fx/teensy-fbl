#ifndef NOINIT_H
#define NOINIT_H

/* Data structure to hold the boot strap request from the application.
 * it is intended to be located to a RAM section which is not initialized
 * by the startup
 */

typedef struct
{
   uint32 entryReqLo;
   uint32 entryReqHi;
   uint8  reserved[8];
}T_NOINIT_DATA;

T_NOINIT_DATA* noinit_getData(void);

#endif /* NOINIT_H */
