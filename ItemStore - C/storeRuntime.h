//
//  storeRuntime.h
//  Sonicaster4
//
//  Created by Alexander Obenauer on 12/27/23.
//

#ifndef storeRuntime_h
#define storeRuntime_h

#include "value.h"

void store_loadVMBindings(void);

Value findRel(char* fromItemId, char* toItemId, char* relationshipType);

#endif /* storeRuntime_h */
