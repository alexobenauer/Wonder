//
//  itemstore.h
//  Sonicaster4
//
//  Created by Alexander Obenauer on 12/29/23.
//

#ifndef itemstore_h
#define itemstore_h

#include <stdbool.h>
#include <sqlite3.h>

#include "istypes.h"

// #define STORE_LOG // enable to see logs from the item store in c

typedef struct {
    void* userDrive;
    void* systemDrive;
    // Future: resourceDrives...
    
    UpdateFunction update;
} ItemStore;

extern ItemStore itemStore;

void initItemStore(bool inMemory);
void freeItemStore(void);

void insertFact(void* drive,
                const char *itemId,
                const char *factId,
                const char *attribute,
                const char *value,
                double numericalValue,
                const char *type,
                int flags,
                const char *timestamp);

CFactsCollection* fetchFacts(const char* itemId,
                             const char* attribute,
                             const char* value);

CFactsCollection* fetchFactsByDate(const char* createdAtOrAfter,
                                   const char* createdAtOrBefore);

//void insertFact(CFact* fact);
//void insertFacts(CFactsCollection* facts);
//
//char* createItem(char* type, CSLDatabase* drive);
//char* createReference(char* fromItemId, char* toItemId, char* referenceType, CSLDatabase* drive);

void freeFact(CFact* fact);
void freeFactsCollection(CFactsCollection* collection);
char* getCurrentDateTime(void);

#endif /* itemstore_h */
