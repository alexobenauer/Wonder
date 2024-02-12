//
//  itemstore.c
//  Sonicaster4
//
//  Created by Alexander Obenauer on 12/29/23.
//

#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "itemstore.h"
#include "sldrive.h"

ItemStore itemStore;

void initItemStore(bool inMemory) {
    itemStore.userDrive = openDatabase("userDrive", inMemory);
    itemStore.systemDrive = openDatabase("systemDrive", inMemory);
    
    itemStore.update = NULL;
}

void freeItemStore(void) {
    closeDatabase(itemStore.userDrive);
    closeDatabase(itemStore.systemDrive);
}

//void insertFact(CFact* fact);
//void insertFacts(CFactsCollection* facts);
//
//char* createItem(char* type, CSLDatabase* drive);
//char* createReference(char* fromItemId, char* toItemId, char* referenceType, CSLDatabase* drive);

void insertFact(void* drive, const char *factId, const char *itemId, const char *attribute, const char *value, double numericalValue, const char *type, int flags, const char *timestamp) {
    csl_insertFact(drive, factId, itemId, attribute, value, numericalValue, type, flags, timestamp);
    
    if (itemStore.update != NULL) {
        itemStore.update();
    }
}

CFactsCollection* fetchFacts(const char* itemId,
                             const char* attribute,
                             const char* value) {
    CFactsCollection* res1 = csl_fetchFacts(itemStore.userDrive, itemId, attribute, value);
    CFactsCollection* res2 = csl_fetchFacts(itemStore.systemDrive, itemId, attribute, value);
    
    return combineFactsCollections(res1, res2);
}

CFactsCollection* fetchFactsByDate(const char* createdAtOrAfter,
                                   const char* createdAtOrBefore) {
    CFactsCollection* res1 = csl_fetchFactsByDate(itemStore.userDrive, createdAtOrAfter, createdAtOrBefore);
    CFactsCollection* res2 = csl_fetchFactsByDate(itemStore.systemDrive, createdAtOrAfter, createdAtOrBefore);
    
    return combineFactsCollections(res1, res2);
}

// MARK: Helpers

/// @brief Generates the timestamp string formatted for use in the item store's SQLite db
/// @return ISO8601 strings ("YYYY-MM-DD HH:MM:SS.SSS").
char* getCurrentDateTime(void) {
    time_t rawTime;
    struct tm* timeInfo;
    char* dateTimeString = malloc(24 * sizeof(char)); // Allocate memory for the string
    if (dateTimeString == NULL) {
        fprintf(stderr, "Failed to allocate memory\n");
        exit(1);
    }
    
    time(&rawTime);                     // Get the current time
    timeInfo = localtime(&rawTime);     // Convert the time to local time
    
    strftime(dateTimeString, 24, "%Y-%m-%d %H:%M:%S", timeInfo); // Format the time string
    
    return dateTimeString;
}
