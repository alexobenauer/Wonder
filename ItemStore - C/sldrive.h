//
//  sldrive.h
//  WonderPlayground
//
//  Created by Alexander Obenauer on 6/20/23.
//

#ifndef sldrive_h
#define sldrive_h

#include <stdbool.h>
#include <stdio.h>

#include "istypes.h"
#include "itemstore.h"

typedef struct {
    sqlite3 *db;
    char *error_message;
    
    sqlite3_stmt *stmt_insert_fact;
    sqlite3_stmt *stmt_fetch_facts_by_date_range;
    sqlite3_stmt *stmt_fetch_facts_by_item_id;
    sqlite3_stmt *stmt_fetch_facts_by_attribute;
    sqlite3_stmt *stmt_fetch_facts_by_value;
    sqlite3_stmt *stmt_fetch_facts_by_item_id_attribute;
    sqlite3_stmt *stmt_fetch_facts_by_attribute_value;
    sqlite3_stmt *stmt_fetch_facts_by_item_id_attribute_value;
    sqlite3_stmt *stmt_fetch_facts_by_value_range;
    sqlite3_stmt *stmt_fetch_facts_by_attribute_value_range;
    sqlite3_stmt *stmt_fetch_facts_by_item_id_attribute_value_range;
    sqlite3_stmt *stmt_fetch_most_recent_fact;
} CSLDatabase;

typedef void (*UpdateFnPtr)(void);
void setUpdateFn(UpdateFnPtr newUpdateFn);

CSLDatabase* openDatabase(const char *sourceId, bool inMemory);
void closeDatabase(CSLDatabase *dbInfo);

void csl_insertFact(CSLDatabase *db,
                    const char *factId,
                    const char *itemId,
                    const char *attribute,
                    const char *value,
                    double numericalValue,
                    const char *type,
                    int flags,
                    const char *timestamp);

CFactsCollection* csl_fetchFacts(CSLDatabase* db,
                                 const char* itemId,
                                 const char* attribute,
                                 const char* value);

CFactsCollection* csl_fetchFactsByValueRange(CSLDatabase* db,
                                             const char* itemId,
                                             const char* attribute,
                                             double valueAtOrAbove,
                                             double valueAtOrBelow);

CFactsCollection* csl_fetchFactsByDate(CSLDatabase* db,
                                       const char* createdAtOrAfter,
                                       const char* createdAtOrBefore);

// For debug; generally not to be used in production
CFactsCollection* __csl_getAllFacts(void);
void __csl_removeFact(int uid);

#endif /* sldrive_h */
