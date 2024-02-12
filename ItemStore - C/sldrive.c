//
//  ItemStore.c
//  WonderPlayground
//
//  Created by Alexander Obenauer on 6/20/23.
//

#include <stdlib.h>
#include <string.h>

#include "sldrive.h"

// MARK: - SQLite Setup

UpdateFnPtr updateFn;

void setUpdateFn(UpdateFnPtr newUpdateFn) {
    updateFn = newUpdateFn;
}

CSLDatabase *currentDatabase = NULL;

CSLDatabase* openDatabase(const char *sourceId, bool inMemory) {
    CSLDatabase *dbInfo = malloc(sizeof(CSLDatabase));
    if (!dbInfo) {
        fprintf(stderr, "Memory allocation error\n");
        return NULL;
    }
    
    currentDatabase = dbInfo;
    
    char filename[255];
    
    if (inMemory || sourceId == NULL) {
        printf("Opening in-memory database\n");
        strcpy(filename, ":memory:");
    }
    else {
        strcpy(filename, sourceId);
        strcat(filename, ".sqlite");
        printf("Opening on-disk database: %s\n", filename);
    }
    
    int rc = sqlite3_open(filename, &currentDatabase->db);
    if (rc) {
        fprintf(stderr, "Cannot open database: %s\n", sqlite3_errmsg(currentDatabase->db));
        return NULL;
    }
    
    char *create_table_sql = "CREATE TABLE IF NOT EXISTS facts ("
    "id INTEGER PRIMARY KEY AUTOINCREMENT,"
    "factId TEXT NOT NULL,"
    "itemId TEXT NOT NULL,"
    "attribute TEXT NOT NULL,"
    "value TEXT NOT NULL,"
    "numericalValue REAL NOT NULL,"
    "type TEXT NOT NULL,"
    "flags INTEGER NOT NULL," // bit 0 = 1 for "removed"; none others used atm.
    "timestamp TEXT NOT NULL" // ISO8601 strings ("YYYY-MM-DD HH:MM:SS.SSS")
    ");";
    
    rc = sqlite3_exec(currentDatabase->db, create_table_sql, 0, 0, &currentDatabase->error_message);
    
    if (rc) {
        fprintf(stderr, "SQL error: %s\n", currentDatabase->error_message);
        sqlite3_free(currentDatabase->error_message);
        return NULL;
    }
    
    // Create the indexes
    
    char *create_index_sql_1 = "CREATE INDEX IF NOT EXISTS idx_timestamp ON facts (timestamp DESC);";
    
    rc = sqlite3_exec(currentDatabase->db, create_index_sql_1, 0, 0, &currentDatabase->error_message);
    
    if (rc) {
        fprintf(stderr, "SQL error: %s\n", currentDatabase->error_message);
        sqlite3_free(currentDatabase->error_message);
        return NULL;
    }
    
    char *create_index_sql_2 = "CREATE INDEX IF NOT EXISTS idx_item_attr_timestamp ON facts (itemId, attribute, timestamp DESC);";
    
    rc = sqlite3_exec(currentDatabase->db, create_index_sql_2, 0, 0, &currentDatabase->error_message);
    
    if (rc) {
        fprintf(stderr, "SQL error: %s\n", currentDatabase->error_message);
        sqlite3_free(currentDatabase->error_message);
        return NULL;
    }
    
    char *create_index_sql_3 = "CREATE INDEX IF NOT EXISTS idx_item_id ON facts (itemId);";
    
    rc = sqlite3_exec(currentDatabase->db, create_index_sql_3, 0, 0, &currentDatabase->error_message);
    
    if (rc) {
        fprintf(stderr, "SQL error: %s\n", currentDatabase->error_message);
        sqlite3_free(currentDatabase->error_message);
        return NULL;
    }
    
    // TODO: Add an index for attribute + value?
    
    // Prepare the statements
    
    const char *insert_data_sql = "INSERT INTO facts (factId, itemId, attribute, value, numericalValue, type, flags, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?, ?);";
    rc = sqlite3_prepare_v2(currentDatabase->db, insert_data_sql, -1, &currentDatabase->stmt_insert_fact, NULL);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "SQL error: %s\n", sqlite3_errmsg(currentDatabase->db));
        return NULL;
    }
    
    const char *fetch_by_date_range_sql = "SELECT * FROM facts WHERE timestamp BETWEEN ? AND ?;";
    rc = sqlite3_prepare_v2(currentDatabase->db, fetch_by_date_range_sql, -1, &currentDatabase->stmt_fetch_facts_by_date_range, NULL);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "SQL error: %s\n", sqlite3_errmsg(currentDatabase->db));
        return NULL;
    }
    
    const char *fetch_by_item_id_sql = "SELECT * FROM facts WHERE itemId = ? ORDER BY timestamp DESC;";
    rc = sqlite3_prepare_v2(currentDatabase->db, fetch_by_item_id_sql, -1, &currentDatabase->stmt_fetch_facts_by_item_id, NULL);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "SQL error: %s\n", sqlite3_errmsg(currentDatabase->db));
        return NULL;
    }
    
    const char *fetch_by_attribute_sql = "SELECT * FROM facts WHERE attribute = ? ORDER BY timestamp DESC;";
    rc = sqlite3_prepare_v2(currentDatabase->db, fetch_by_attribute_sql, -1, &currentDatabase->stmt_fetch_facts_by_attribute, NULL);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "SQL error: %s\n", sqlite3_errmsg(currentDatabase->db));
        return NULL;
    }
    
    const char *fetch_by_value_sql = "SELECT * FROM facts WHERE value = ? ORDER BY timestamp DESC;";
    rc = sqlite3_prepare_v2(currentDatabase->db, fetch_by_value_sql, -1, &currentDatabase->stmt_fetch_facts_by_value, NULL);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "SQL error: %s\n", sqlite3_errmsg(currentDatabase->db));
        return NULL;
    }
    
    const char *fetch_by_item_id_attribute_sql = "SELECT * FROM facts WHERE itemId = ? AND attribute = ? ORDER BY timestamp DESC;";
    rc = sqlite3_prepare_v2(currentDatabase->db, fetch_by_item_id_attribute_sql, -1, &currentDatabase->stmt_fetch_facts_by_item_id_attribute, NULL);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "SQL error: %s\n", sqlite3_errmsg(currentDatabase->db));
        return NULL;
    }
    
    const char *fetch_by_attribute_value_sql = "SELECT * FROM facts WHERE attribute = ? AND value = ? ORDER BY timestamp DESC;";
    rc = sqlite3_prepare_v2(currentDatabase->db, fetch_by_attribute_value_sql, -1, &currentDatabase->stmt_fetch_facts_by_attribute_value, NULL);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "SQL error: %s\n", sqlite3_errmsg(currentDatabase->db));
        return NULL;
    }
    
    const char *fetch_by_item_id_attribute_value_sql = "SELECT * FROM facts WHERE itemId = ? AND attribute = ? AND value = ? ORDER BY timestamp DESC;";
    rc = sqlite3_prepare_v2(currentDatabase->db, fetch_by_item_id_attribute_value_sql, -1, &currentDatabase->stmt_fetch_facts_by_item_id_attribute_value, NULL);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "SQL error: %s\n", sqlite3_errmsg(currentDatabase->db));
        return NULL;
    }
    
    const char *fetch_by_value_range_sql = "SELECT * FROM facts WHERE numericalValue >= ? AND numericalValue <= ? ORDER BY timestamp DESC;";
    rc = sqlite3_prepare_v2(currentDatabase->db, fetch_by_value_range_sql, -1, &currentDatabase->stmt_fetch_facts_by_value_range, NULL);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "SQL error: %s\n", sqlite3_errmsg(currentDatabase->db));
        return NULL;
    }
    
    const char *fetch_by_attribute_value_range_sql = "SELECT * FROM facts WHERE attribute = ? AND numericalValue >= ? AND numericalValue <= ? ORDER BY timestamp DESC;";
    rc = sqlite3_prepare_v2(currentDatabase->db, fetch_by_attribute_value_range_sql, -1, &currentDatabase->stmt_fetch_facts_by_attribute_value_range, NULL);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "SQL error: %s\n", sqlite3_errmsg(currentDatabase->db));
        return NULL;
    }
    
    const char *fetch_by_item_id_attribute_value_range_sql = "SELECT * FROM facts WHERE itemId = ? AND attribute = ? AND numericalValue >= ? AND numericalValue <= ? ORDER BY timestamp DESC;";
    rc = sqlite3_prepare_v2(currentDatabase->db, fetch_by_item_id_attribute_value_range_sql, -1, &currentDatabase->stmt_fetch_facts_by_item_id_attribute_value_range, NULL);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "SQL error: %s\n", sqlite3_errmsg(currentDatabase->db));
        return NULL;
    }
    
    const char *fetch_most_recent_fact_sql = "SELECT * FROM facts WHERE itemId = ? AND attribute = ?;";
    rc = sqlite3_prepare_v2(currentDatabase->db, fetch_most_recent_fact_sql, -1, &currentDatabase->stmt_fetch_most_recent_fact, NULL);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "SQL error: %s\n", sqlite3_errmsg(currentDatabase->db));
        return NULL;
    }
    
    if (updateFn != NULL) {
        updateFn();
    }
    
    return dbInfo;
}

void closeDatabase(CSLDatabase *dbInfo) {
    // Finalize prepared statements
    sqlite3_finalize(dbInfo->stmt_insert_fact);
    sqlite3_finalize(dbInfo->stmt_fetch_facts_by_date_range);
    sqlite3_finalize(dbInfo->stmt_fetch_facts_by_item_id);
    sqlite3_finalize(dbInfo->stmt_fetch_facts_by_attribute);
    sqlite3_finalize(dbInfo->stmt_fetch_facts_by_value);
    sqlite3_finalize(dbInfo->stmt_fetch_facts_by_item_id_attribute);
    sqlite3_finalize(dbInfo->stmt_fetch_facts_by_attribute_value);
    sqlite3_finalize(dbInfo->stmt_fetch_facts_by_item_id_attribute_value);
    sqlite3_finalize(dbInfo->stmt_fetch_facts_by_value_range);
    sqlite3_finalize(dbInfo->stmt_fetch_facts_by_attribute_value_range);
    sqlite3_finalize(dbInfo->stmt_fetch_facts_by_item_id_attribute_value_range);
    sqlite3_finalize(dbInfo->stmt_fetch_most_recent_fact);
    
    // Close the database
    sqlite3_close(dbInfo->db);
    
    // Free allocated memory
    free(dbInfo);
}

static void switchDatabase(CSLDatabase *dbInfo) {
    if (!dbInfo) {
        fprintf(stderr, "Invalid database information\n");
        return;
    }
    
    currentDatabase = dbInfo;
}

// MARK: - SQLite Queries

void runQuery(sqlite3_stmt *stmt, CFactsCollection *collection) {
    int rc;
    
    while ((rc = sqlite3_step(stmt)) == SQLITE_ROW) {
        CFact fact;
        
        fact.uid = sqlite3_column_int(stmt, 0);
        
        const char* factIdText = (const char*)sqlite3_column_text(stmt, 1);
        fact.factId = malloc(strlen(factIdText) + 1);
        strcpy(fact.factId, factIdText);
        
        const char* itemIdText = (const char*)sqlite3_column_text(stmt, 2);
        fact.itemId = malloc(strlen(itemIdText) + 1);
        strcpy(fact.itemId, itemIdText);
        
        const char* attributeText = (const char*)sqlite3_column_text(stmt, 3);
        fact.attribute = malloc(strlen(attributeText) + 1);
        strcpy(fact.attribute, attributeText);
        
        const char* valueText = (const char*)sqlite3_column_text(stmt, 4);
        fact.value = malloc(strlen(valueText) + 1);
        strcpy(fact.value, valueText);
        
        fact.numericalValue = sqlite3_column_double(stmt, 5);
        
        const char* typeText = (const char*)sqlite3_column_text(stmt, 6);
        fact.type = malloc(strlen(typeText) + 1);
        strcpy(fact.type, typeText);
        
        fact.flags = sqlite3_column_int(stmt, 7);
        
        const char* timestampText = (const char*)sqlite3_column_text(stmt, 8);
        fact.timestamp = malloc(strlen(timestampText) + 1);
        strcpy(fact.timestamp, timestampText);
        
        collection->facts = realloc(collection->facts, (collection->count + 1) * sizeof(CFact));
        collection->facts[collection->count++] = fact;
    }
    
#ifdef STORE_LOG
    printf("Fetched %d facts\n", collection->count);
    
    for (int x = 0; x < collection->count; x++) {
        printf("  %s %s %s %f\n", collection->facts[x].itemId, collection->facts[x].attribute, collection->facts[x].value, collection->facts[x].numericalValue);
    }
#endif
    
    if (rc != SQLITE_DONE)
        fprintf(stderr, "SQL error: %s\n", sqlite3_errmsg(currentDatabase->db));
}

CFactsCollection* fetchFactsByDateRange(const char *startDate, const char *endDate) {
    int rc = sqlite3_reset(currentDatabase->stmt_fetch_facts_by_date_range);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "SQL error: %s\n", sqlite3_errmsg(currentDatabase->db));
        return NULL;
    }
    
    sqlite3_bind_text(currentDatabase->stmt_fetch_facts_by_date_range, 1, startDate, -1, SQLITE_STATIC);
    sqlite3_bind_text(currentDatabase->stmt_fetch_facts_by_date_range, 2, endDate, -1, SQLITE_STATIC);
    
    CFactsCollection* collection = malloc(sizeof(CFactsCollection));
    collection->count = 0;
    collection->facts = NULL;
    
    runQuery(currentDatabase->stmt_fetch_facts_by_date_range, collection);
    
    return collection;
}

CFactsCollection* fetchFactsByItemId(const char *itemId) {
    int rc = sqlite3_reset(currentDatabase->stmt_fetch_facts_by_item_id);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "SQL error: %s\n", sqlite3_errmsg(currentDatabase->db));
        return NULL;
    }
    
    sqlite3_bind_text(currentDatabase->stmt_fetch_facts_by_item_id, 1, itemId, -1, SQLITE_STATIC);
    
    CFactsCollection* collection = malloc(sizeof(CFactsCollection));
    collection->count = 0;
    collection->facts = NULL;
    
    runQuery(currentDatabase->stmt_fetch_facts_by_item_id, collection);
    
    return collection;
}

CFactsCollection* fetchFactsByAttribute(const char *attribute) {
    int rc = sqlite3_reset(currentDatabase->stmt_fetch_facts_by_attribute);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "SQL error: %s\n", sqlite3_errmsg(currentDatabase->db));
        return NULL;
    }
    
    sqlite3_bind_text(currentDatabase->stmt_fetch_facts_by_attribute, 1, attribute, -1, SQLITE_STATIC);
    
    CFactsCollection* collection = malloc(sizeof(CFactsCollection));
    collection->count = 0;
    collection->facts = NULL;
    
    runQuery(currentDatabase->stmt_fetch_facts_by_attribute, collection);
    
    return collection;
}

CFactsCollection* fetchFactsByValue(const char *value) {
    int rc = sqlite3_reset(currentDatabase->stmt_fetch_facts_by_value);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "SQL error: %s\n", sqlite3_errmsg(currentDatabase->db));
        return NULL;
    }
    
    sqlite3_bind_text(currentDatabase->stmt_fetch_facts_by_value, 1, value, -1, SQLITE_STATIC);
    
    CFactsCollection* collection = malloc(sizeof(CFactsCollection));
    collection->count = 0;
    collection->facts = NULL;
    
    runQuery(currentDatabase->stmt_fetch_facts_by_value, collection);
    
    return collection;
}

CFactsCollection* fetchFactsByItemIdAttribute(const char *itemId, const char *attribute) {
    int rc = sqlite3_reset(currentDatabase->stmt_fetch_facts_by_item_id_attribute);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "SQL error: %s\n", sqlite3_errmsg(currentDatabase->db));
        return NULL;
    }
    
    sqlite3_bind_text(currentDatabase->stmt_fetch_facts_by_item_id_attribute, 1, itemId, -1, SQLITE_STATIC);
    sqlite3_bind_text(currentDatabase->stmt_fetch_facts_by_item_id_attribute, 2, attribute, -1, SQLITE_STATIC);
    
    CFactsCollection* collection = malloc(sizeof(CFactsCollection));
    collection->count = 0;
    collection->facts = NULL;
    
    runQuery(currentDatabase->stmt_fetch_facts_by_item_id_attribute, collection);
    
    return collection;
}

CFactsCollection* fetchFactsByAttributeAndValue(const char *attribute, const char *value) {
    int rc = sqlite3_reset(currentDatabase->stmt_fetch_facts_by_attribute_value);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "SQL error: %s\n", sqlite3_errmsg(currentDatabase->db));
        return NULL;
    }
    
    sqlite3_bind_text(currentDatabase->stmt_fetch_facts_by_attribute_value, 1, attribute, -1, SQLITE_STATIC);
    sqlite3_bind_text(currentDatabase->stmt_fetch_facts_by_attribute_value, 2, value, -1, SQLITE_STATIC);
    
    CFactsCollection* collection = malloc(sizeof(CFactsCollection));
    collection->count = 0;
    collection->facts = NULL;
    
    runQuery(currentDatabase->stmt_fetch_facts_by_attribute_value, collection);
    
    return collection;
}

CFactsCollection* fetchFactsByItemIdAttributeAndValue(const char *itemId, const char *attribute, const char *value) {
    int rc = sqlite3_reset(currentDatabase->stmt_fetch_facts_by_item_id_attribute_value);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "SQL error: %s\n", sqlite3_errmsg(currentDatabase->db));
        return NULL;
    }
    
    sqlite3_bind_text(currentDatabase->stmt_fetch_facts_by_item_id_attribute_value, 1, itemId, -1, SQLITE_STATIC);
    sqlite3_bind_text(currentDatabase->stmt_fetch_facts_by_item_id_attribute_value, 2, attribute, -1, SQLITE_STATIC);
    sqlite3_bind_text(currentDatabase->stmt_fetch_facts_by_item_id_attribute_value, 3, value, -1, SQLITE_STATIC);
    
    CFactsCollection* collection = malloc(sizeof(CFactsCollection));
    collection->count = 0;
    collection->facts = NULL;
    
    runQuery(currentDatabase->stmt_fetch_facts_by_item_id_attribute_value, collection);
    
    return collection;
}

CFactsCollection* fetchFactsByValueRange(double startValue, double endValue) {
    int rc = sqlite3_reset(currentDatabase->stmt_fetch_facts_by_value_range);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "SQL error: %s\n", sqlite3_errmsg(currentDatabase->db));
        return NULL;
    }
    
    sqlite3_bind_double(currentDatabase->stmt_fetch_facts_by_value_range, 1, startValue);
    sqlite3_bind_double(currentDatabase->stmt_fetch_facts_by_value_range, 2, endValue);
    
    CFactsCollection* collection = malloc(sizeof(CFactsCollection));
    collection->count = 0;
    collection->facts = NULL;
    
    runQuery(currentDatabase->stmt_fetch_facts_by_value_range, collection);
    
    return collection;
}

CFactsCollection* fetchFactsByAttributeAndValueRange(const char *attribute, double startValue, double endValue) {
    int rc = sqlite3_reset(currentDatabase->stmt_fetch_facts_by_attribute_value_range);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "SQL error: %s\n", sqlite3_errmsg(currentDatabase->db));
        return NULL;
    }
    
    sqlite3_bind_text(currentDatabase->stmt_fetch_facts_by_attribute_value_range, 1, attribute, -1, SQLITE_STATIC);
    sqlite3_bind_double(currentDatabase->stmt_fetch_facts_by_attribute_value_range, 2, startValue);
    sqlite3_bind_double(currentDatabase->stmt_fetch_facts_by_attribute_value_range, 3, endValue);
    
    CFactsCollection* collection = malloc(sizeof(CFactsCollection));
    collection->count = 0;
    collection->facts = NULL;
    
    runQuery(currentDatabase->stmt_fetch_facts_by_attribute_value_range, collection);
    
    return collection;
}

CFactsCollection* fetchFactsByItemIdAttributeAndValueRange(const char *itemId, const char *attribute, double startValue, double endValue) {
    int rc = sqlite3_reset(currentDatabase->stmt_fetch_facts_by_item_id_attribute_value_range);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "SQL error: %s\n", sqlite3_errmsg(currentDatabase->db));
        return NULL;
    }
    
    sqlite3_bind_text(currentDatabase->stmt_fetch_facts_by_item_id_attribute_value_range, 1, itemId, -1, SQLITE_STATIC);
    sqlite3_bind_text(currentDatabase->stmt_fetch_facts_by_item_id_attribute_value_range, 2, attribute, -1, SQLITE_STATIC);
    sqlite3_bind_double(currentDatabase->stmt_fetch_facts_by_item_id_attribute_value_range, 3, startValue);
    sqlite3_bind_double(currentDatabase->stmt_fetch_facts_by_item_id_attribute_value_range, 4, endValue);
    
    CFactsCollection* collection = malloc(sizeof(CFactsCollection));
    collection->count = 0;
    collection->facts = NULL;
    
    runQuery(currentDatabase->stmt_fetch_facts_by_item_id_attribute_value_range, collection);
    
    return collection;
}

CFact* fetchMostRecentFact(const char *itemId, const char *attribute) {
    int rc = sqlite3_reset(currentDatabase->stmt_fetch_most_recent_fact);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "SQL error: %s\n", sqlite3_errmsg(currentDatabase->db));
        return NULL;
    }
    
    sqlite3_bind_text(currentDatabase->stmt_fetch_most_recent_fact, 1, itemId, -1, SQLITE_STATIC);
    sqlite3_bind_text(currentDatabase->stmt_fetch_most_recent_fact, 2, attribute, -1, SQLITE_STATIC);
    
    CFact* fact = NULL;
    
    if (sqlite3_step(currentDatabase->stmt_fetch_most_recent_fact) == SQLITE_ROW) {
        fact = malloc(sizeof(CFact));
        
        fact->uid = sqlite3_column_int(currentDatabase->stmt_fetch_most_recent_fact, 0);
        
        const char* factIdText = (const char*)sqlite3_column_text(currentDatabase->stmt_fetch_most_recent_fact, 1);
        fact->factId = malloc(strlen(factIdText) + 1);
        strcpy(fact->factId, factIdText);
        
        const char* itemIdText = (const char*)sqlite3_column_text(currentDatabase->stmt_fetch_most_recent_fact, 2);
        fact->itemId = malloc(strlen(itemIdText) + 1);
        strcpy(fact->itemId, itemIdText);
        
        const char* attributeText = (const char*)sqlite3_column_text(currentDatabase->stmt_fetch_most_recent_fact, 3);
        fact->attribute = malloc(strlen(attributeText) + 1);
        strcpy(fact->attribute, attributeText);
        
        const char* valueText = (const char*)sqlite3_column_text(currentDatabase->stmt_fetch_most_recent_fact, 4);
        fact->value = malloc(strlen(valueText) + 1);
        strcpy(fact->value, valueText);
        
        fact->numericalValue = sqlite3_column_double(currentDatabase->stmt_fetch_most_recent_fact, 5);
        
        const char* typeText = (const char*)sqlite3_column_text(currentDatabase->stmt_fetch_most_recent_fact, 6);
        fact->type = malloc(strlen(typeText) + 1);
        strcpy(fact->type, typeText);
        
        fact->flags = sqlite3_column_int(currentDatabase->stmt_fetch_most_recent_fact, 7);
        
        const char* timestampText = (const char*)sqlite3_column_text(currentDatabase->stmt_fetch_most_recent_fact, 8);
        fact->timestamp = malloc(strlen(timestampText) + 1);
        strcpy(fact->timestamp, timestampText);
    }
    
    return fact;
}

// MARK: - Insert

void csl_insertFact(CSLDatabase *db,
                    const char *factId,
                    const char *itemId,
                    const char *attribute,
                    const char *value,
                    double numericalValue,
                    const char *type,
                    int flags,
                    const char *timestamp) {
    switchDatabase(db);
    
    int rc = sqlite3_reset(currentDatabase->stmt_insert_fact);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "SQL error: %s\n", sqlite3_errmsg(currentDatabase->db));
        return;
    }
    
#ifdef STORE_LOG
    printf("Insert fact %s %s %s %f\n", itemId, attribute, value, numericalValue);
#endif
    
    sqlite3_bind_text(currentDatabase->stmt_insert_fact, 1, factId, -1, SQLITE_STATIC);
    sqlite3_bind_text(currentDatabase->stmt_insert_fact, 2, itemId, -1, SQLITE_STATIC);
    sqlite3_bind_text(currentDatabase->stmt_insert_fact, 3, attribute, -1, SQLITE_STATIC);
    sqlite3_bind_text(currentDatabase->stmt_insert_fact, 4, value, -1, SQLITE_STATIC);
    sqlite3_bind_double(currentDatabase->stmt_insert_fact, 5, numericalValue);
    
    if (type != NULL)
        sqlite3_bind_text(currentDatabase->stmt_insert_fact, 6, type, -1, SQLITE_STATIC);
    else
        sqlite3_bind_text(currentDatabase->stmt_insert_fact, 6, "string", -1, SQLITE_STATIC);
    
    sqlite3_bind_int(currentDatabase->stmt_insert_fact, 7, flags);
    
    if (timestamp != NULL)
        sqlite3_bind_text(currentDatabase->stmt_insert_fact, 8, timestamp, -1, SQLITE_STATIC);
    else {
        char *currentDateTime = getCurrentDateTime();
        sqlite3_bind_text(currentDatabase->stmt_insert_fact, 8, currentDateTime, -1, SQLITE_TRANSIENT);
        free(currentDateTime);
    }
    
    rc = sqlite3_step(currentDatabase->stmt_insert_fact);
    if (rc != SQLITE_DONE)
        fprintf(stderr, "SQL error: %s\n", sqlite3_errmsg(currentDatabase->db));
    
    if (updateFn != NULL) {
        updateFn();
    }
}


// MARK: - Fetch

CFactsCollection* csl_fetchFacts(CSLDatabase* db,
                                 const char* itemId,
                                 const char* attribute,
                                 const char* value) {
    switchDatabase(db);
    
    CFactsCollection* results = NULL;
    
    if (itemId != NULL && attribute != NULL && value != NULL) {
        results = fetchFactsByItemIdAttributeAndValue(itemId, attribute, value);
    }
    else if (itemId != NULL && attribute != NULL) {
        results = fetchFactsByItemIdAttribute(itemId, attribute);
    }
    else if (itemId != NULL && value != NULL) {
        printf("sldrive does not currently support getting item id and value"); // TODO
        exit(EXIT_FAILURE);
    }
    else if (attribute != NULL && value != NULL) {
        results = fetchFactsByAttributeAndValue(attribute, value);
    }
    else if (itemId != NULL) {
        results = fetchFactsByItemId(itemId);
    }
    else if (attribute != NULL) {
        results = fetchFactsByAttribute(attribute);
    }
    else if (value != NULL) {
        results = fetchFactsByValue(value);
    }
    else {
        results = __csl_getAllFacts();
    }
    
    return results;
}

CFactsCollection* csl_fetchFactsByValueRange(CSLDatabase* db,
                                             const char* itemId,
                                             const char* attribute,
                                             double valueAtOrAbove,
                                             double valueAtOrBelow) {
    switchDatabase(db);
    
    CFactsCollection* results = NULL;
    
    if (itemId != NULL && attribute != NULL) {
        results = fetchFactsByItemIdAttributeAndValueRange(itemId, attribute, valueAtOrAbove, valueAtOrBelow);
    }
    else if (itemId != NULL) {
        printf("sldrive does not currently support getting item id and value in range"); // TODO
        exit(EXIT_FAILURE);
    }
    else if (attribute != NULL) {
        results = fetchFactsByAttributeAndValueRange(attribute, valueAtOrAbove, valueAtOrBelow);
    }
    else {
        results = fetchFactsByValueRange(valueAtOrAbove, valueAtOrBelow);
    }
    
    return results;
}

CFactsCollection* csl_fetchFactsByDate(CSLDatabase *db,
                                       const char* createdAtOrAfter,
                                       const char* createdAtOrBefore) {
    switchDatabase(db);
    
    CFactsCollection* results = NULL;
    
    if (createdAtOrAfter != NULL && createdAtOrBefore != NULL) {
        results = fetchFactsByDateRange(createdAtOrAfter, createdAtOrBefore);
    }
    else if (createdAtOrAfter != NULL) {
        printf("Currently unsupported date query."); // TODO
    }
    else if (createdAtOrBefore != NULL) {
        printf("Currently unsupported date query."); // TODO
    }
    
    return results;
}

// MARK: - Debug
//  Generally not to be used in production

CFactsCollection* __csl_getAllFacts(void) {
    const char query[] = "SELECT * FROM facts ORDER BY id DESC;";
    sqlite3_stmt* stmt;
    
    int rc = sqlite3_prepare_v2(currentDatabase->db, query, -1, &stmt, NULL);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "SQL error: %s\n", sqlite3_errmsg(currentDatabase->db));
        return NULL;
    }
    
    CFactsCollection* collection = malloc(sizeof(CFactsCollection));
    collection->count = 0;
    collection->facts = NULL;
    
    runQuery(stmt, collection);
    
    sqlite3_finalize(stmt);
    
    return collection;
}

void __csl_removeFact(int uid) {
    const char *sql = "DELETE FROM facts WHERE id = ?";
    sqlite3_stmt* stmt;
    
    int rc = sqlite3_prepare_v2(currentDatabase->db, sql, -1, &stmt, NULL);
    if (rc != SQLITE_OK) {
        fprintf(stderr, "SQL error: %s\n", sqlite3_errmsg(currentDatabase->db));
        return;
    }
    
    sqlite3_bind_int(stmt, 1, uid);
    
    rc = sqlite3_step(stmt);
    if (rc != SQLITE_DONE)
        fprintf(stderr, "SQL error: %s\n", sqlite3_errmsg(currentDatabase->db));
    
    if (updateFn != NULL) {
        updateFn();
    }
}
