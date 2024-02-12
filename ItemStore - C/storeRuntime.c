//
//  isRuntime.c
//  Sonicaster4
//
//  Created by Alexander Obenauer on 12/27/23.
//

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <uuid/uuid.h>

#include "storeRuntime.h"
#include "itemstore.h"
#include "object.h"
#include "vm.h"

static char* generateUUIDString(void) {
    uuid_t uuid;
    uuid_generate(uuid);
    
    char* uuid_str = (char*)malloc(37); // UUIDs are 36 characters long, plus a null terminator
    uuid_unparse(uuid, uuid_str);
    
    return uuid_str;
}

static Value getDeviceIdFn(int argCount, Value* args) {
    return getDeviceId();
}

static Value createFn(int argCount, Value* args) {
    if (argCount != 2 && argCount != 3) {
        vm.printErr("Wrong number of arguments for create.");
        return NIL_VAL;
    }
    
    char* itemId;
    char* factId = generateUUIDString();
    
    if (IS_STRING(args[0])) {
        itemId = AS_STRING(args[0])->chars;
    }
    else if (IS_NIL(args[0])) {
        itemId = generateUUIDString();
    }
    else {
        vm.printErr("Item ID must be a string.");
        return NIL_VAL;
    }
    
    Value type = args[1];
    
    if (!IS_STRING(type)) {
        vm.printErr("Item type must be a string.");
        return NIL_VAL;
    }
    
    void* db = itemStore.userDrive;
    
    if (argCount > 2 && IS_NUMBER(args[2]) && AS_NUMBER(args[2]) == -1) {
        db = itemStore.systemDrive;
    }
    
    insertFact(db,
               factId,
                      itemId,
                      "created",
                      "",
                      0,
                      "",
                      0,
                      getCurrentDateTime());
    
    insertFact(db,
               factId,
                      itemId,
                      "type",
                      AS_STRING(type)->chars,
                      0,
                      "string",
                      0,
                      getCurrentDateTime());
    
    return OBJ_VAL(allocateString(itemId, 36, hashString(itemId, 36)));
}

static Value defineFn(int argCount, Value* args) {
    if (argCount != 3 && argCount != 4) {
        vm.printErr("Wrong number of arguments for define.");
        return NIL_VAL;
    }
    
    Value itemId = args[0];
    Value attribute = args[1];
    Value value = args[2];
    Value numericalValue = NUMBER_VAL(0);
    
    char* type = "string";
    
    if (IS_NIL(itemId)) {
        char* uuid = generateUUIDString();
        itemId = OBJ_VAL(allocateString(uuid, 36, hashString(uuid, 36)));
    }
    
    if (!IS_STRING(itemId)) {
        vm.printErr("Item ID must be a string.");
        return NIL_VAL;
    }
    
    if (!IS_STRING(attribute)) {
        vm.printErr("Attribute must be a string.");
        return NIL_VAL;
    }
    
    if (IS_NUMBER(value)) {
        type = "number";
        numericalValue = value;
        value = OBJ_VAL(allocateString("", 0, hashString("", 0)));
    }
    
    if (!IS_STRING(value)) {
        vm.printErr("Value must be a string or number.");
        return NIL_VAL;
    }
    
    void* db = itemStore.userDrive;
    
    if (argCount > 3 && IS_NUMBER(args[3]) && AS_NUMBER(args[3]) == -1) {
        db = itemStore.systemDrive;
    }
    
    char* factId = generateUUIDString();
    
    insertFact(db,
               factId,
                      AS_STRING(itemId)->chars,
                      AS_STRING(attribute)->chars,
                      AS_STRING(value)->chars,
                      AS_NUMBER(numericalValue),
                      type, // type
                      0, // flags
                      getCurrentDateTime()); // timestamp
    
    return itemId;
}

static Value relateFn(int argCount, Value* args) {
    if (argCount != 3 && argCount != 4) {
        vm.printErr("Wrong number of arguments for relate.");
        return NIL_VAL;
    }
    
    Value fromItemId = args[0];
    Value toItemId = args[1];
    Value relationshipType = args[2];
    
    if (!IS_STRING(fromItemId) || !IS_STRING(toItemId)) {
        vm.printErr("Item IDs must be strings.");
        return NIL_VAL;
    }
    
    if (!IS_STRING(relationshipType)) {
        vm.printErr("Relationship type must be a string.");
        return NIL_VAL;
    }
    
    void* db = itemStore.userDrive;
    
    if (argCount > 3 && IS_NUMBER(args[3]) && AS_NUMBER(args[3]) == -1) {
        db = itemStore.systemDrive;
    }
    
    char* rItemId = generateUUIDString();
    int rItemIdLength = 36;
    
    char* timestamp = getCurrentDateTime();
    
    char* factId = generateUUIDString();
    
    insertFact(db,
               factId,
                      rItemId,
                      "created",
                      "",
                      0, "", 0, timestamp);
    
    insertFact(db,
               factId,
                      rItemId,
                      "type",
                      "relationship",
                      0, "string", 0, timestamp);
    
    insertFact(db,
               factId,
                      rItemId,
                      "relationshipType",
                      AS_STRING(relationshipType)->chars,
                      0, "string", 0, timestamp);
    
    insertFact(db,
               factId,
                      rItemId,
                      "fromItemId",
                      AS_STRING(fromItemId)->chars,
                      0, // numerical
                      "itemId", // type
                      0, // flags
                      timestamp); // timestamp
    
    insertFact(db,
               factId,
                      rItemId,
                      "toItemId",
                      AS_STRING(toItemId)->chars,
                      0, // numerical
                      "itemId", // type
                      0, // flags
                      timestamp); // timestamp
    
    return OBJ_VAL(allocateString(rItemId, rItemIdLength, hashString(rItemId, rItemIdLength)));
}

static Value findFn(int argCount, Value* args) {
    if (argCount != 3) {
        vm.printErr("Wrong number of arguments for find.");
        return NIL_VAL;
    }
    
    Value itemId = args[0];
    Value attribute = args[1];
    Value value = args[2];
    
    if (!IS_STRING(itemId) && !IS_NIL(itemId)) {
        vm.printErr("Item ID must be a string.");
        return NIL_VAL;
    }
    
    if (!IS_STRING(attribute) && !IS_NIL(attribute)) {
        vm.printErr("Attribute must be a string.");
        return NIL_VAL;
    }
    
    if (!IS_STRING(value) && !IS_NUMBER(value) && !IS_NIL(value)) {
        vm.printErr("Value must be a string or number.");
        return NIL_VAL;
    }
    
    CFactsQuery query;
    initFactsQuery(&query);
    
    if (IS_STRING(itemId)) {
        query.itemId = AS_STRING(itemId)->chars;
    }
    
    if (IS_STRING(attribute)) {
        query.attribute = AS_STRING(attribute)->chars;
    }
    
    if (IS_STRING(value)) {
        query.value = AS_STRING(value)->chars;
    }
    else if (IS_NUMBER(value)) {
        // TODO: Support
        fprintf(stderr, "Numerical values not yet supported in queries.");
        exit(EXIT_FAILURE);
    }
    
    CFactsCollection* facts = fetchFacts(query);
    
    ObjArray* result = newArray();
    
    ObjString* itemIdKey = copyString("itemId", 6);
    ObjString* attributeKey = copyString("attribute", 9);
    ObjString* valueKey = copyString("value", 5);
    
    for (int i = 0; i < facts->count; i++) {
        ObjDictionary* fact = newDictionary();
        
        Value itemId = OBJ_VAL(copyString(facts->facts[i].itemId, (int)strlen(facts->facts[i].itemId)));
        Value attribute = OBJ_VAL(copyString(facts->facts[i].attribute, (int)strlen(facts->facts[i].attribute)));
        Value value = OBJ_VAL(copyString(facts->facts[i].value, (int)strlen(facts->facts[i].value)));
        
        tableSet(&fact->items, itemIdKey, itemId);
        tableSet(&fact->items, attributeKey, attribute);
        tableSet(&fact->items, valueKey, value);
        
        appendToArray(result, OBJ_VAL(fact));
    }
    
    return OBJ_VAL(result);
}

Value findRel(char* fromItemId, char* toItemId, char* relationshipType) {
    CFactsCollection* facts1 = NULL;
    CFactsCollection* facts2 = NULL;
    CFactsCollection* facts3 = NULL;
    
    if (fromItemId != NULL) {
        CFactsQuery query;
        initFactsQuery(&query);
        query.attribute = "fromItemId";
        query.value = fromItemId;
        facts1 = fetchFacts(query);
    }
    
    if (toItemId != NULL) {
        CFactsQuery query;
        initFactsQuery(&query);
        query.attribute = "toItemId";
        query.value = toItemId;
        facts2 = fetchFacts(query);
    }
    
    if (relationshipType != NULL) {
        CFactsQuery query;
        initFactsQuery(&query);
        query.attribute = "relationshipType";
        query.value = relationshipType;
        facts3 = fetchFacts(query);
    }
    
    ObjArray* result = newArray();
    
    CFactsCollection* loopCollection = facts1;
    if (facts1 != NULL) {
        loopCollection = facts1;
        facts1 = NULL;
    }
    else if (facts2 != NULL) {
        loopCollection = facts2;
        facts2 = NULL;
    }
    else if (facts3 != NULL) {
        loopCollection = facts3;
        facts3 = NULL;
    }
    
    // Starting with a bad impl here; rewrite in env
    for (int i = 0; i < loopCollection->count; i++) {
        char* itemId = loopCollection->facts[i].itemId;
        int found = 0;
        
        if (facts1 == NULL) {
            found++;
        }
        else {
            for (int a = 0; a < facts1->count; a++) {
                if (strcmp(itemId, facts1->facts[a].itemId) == 0) {
                    found++;
                    break;
                }
            }
        }
        
        if (facts2 == NULL) {
            found++;
        }
        else {
            for (int a = 0; a < facts2->count; a++) {
                if (strcmp(itemId, facts2->facts[a].itemId) == 0) {
                    found++;
                    break;
                }
            }
        }
        
        if (facts3 == NULL) {
            found++;
        }
        else {
            for (int a = 0; a < facts3->count; a++) {
                if (strcmp(itemId, facts3->facts[a].itemId) == 0) {
                    found++;
                    break;
                }
            }
        }
        
        if (found == 3) {
            appendToArray(result, NUMBER_VAL(0)); // TODO: Create fact objects
        }
    }
    
    // TODO: NEXT need to perform a fetch on the desired field...
    
    freeFactsCollection(facts1);
    freeFactsCollection(facts2);
    freeFactsCollection(facts3);
    freeFactsCollection(loopCollection);
    
    return OBJ_VAL(result);
}

static Value findRelFn(int argCount, Value* args) {
    if (argCount != 3) {
        vm.printErr("Wrong number of arguments for find.");
        return NIL_VAL;
    }
    
    Value fromItemId = args[0];
    Value toItemId = args[1];
    Value relationshipType = args[2];
    
    char* _fromItemId = NULL;
    char* _toItemId = NULL;
    char* _relationshipType = NULL;
    
    if (IS_STRING(fromItemId)) {
        _fromItemId = AS_STRING(fromItemId)->chars;
    }
    else if (!IS_NIL(fromItemId)) {
        vm.printErr("Item ID must be a string or nil.");
        return NIL_VAL;
    }
    
    if (IS_STRING(toItemId)) {
        _toItemId = AS_STRING(toItemId)->chars;
    }
    else if (!IS_NIL(toItemId)) {
        vm.printErr("Item ID must be a string or nil.");
        return NIL_VAL;
    }
    
    if (IS_STRING(relationshipType)) {
        _relationshipType = AS_STRING(relationshipType)->chars;
    }
    else if (!IS_NIL(relationshipType)) {
        vm.printErr("Relationship type must be a string or nil.");
        return NIL_VAL;
    }
    
    return findRel(_fromItemId, _toItemId, _relationshipType);
}

static Value insertFactNative(int argCount, Value* args) {
    if (argCount != 8) {
        vm.printErr("Wrong number of arguments for insertFact");
        return BOOL_VAL(false);
    }
    
    Value database       = args[0];
    Value itemId         = args[1];
    Value attribute      = args[2];
    Value value          = args[3];
    Value numericalValue = args[4];
    Value type           = args[5];
    Value flags          = args[6];
    Value timestamp      = args[7];
    
    char* _timestamp = NULL;
    
    if (!IS_STRING(itemId))         return BOOL_VAL(false);
    if (!IS_STRING(attribute))      return BOOL_VAL(false);
    if (!IS_STRING(value))          return BOOL_VAL(false);
    if (!IS_NUMBER(numericalValue)) return BOOL_VAL(false);
    if (!IS_STRING(type))           return BOOL_VAL(false);
    if (!IS_NUMBER(flags))          return BOOL_VAL(false);
    
    if (IS_STRING(timestamp)) {
        _timestamp = AS_STRING(timestamp)->chars;
    }
    else {
        _timestamp = getCurrentDateTime();
    }
    
    void* db = itemStore.userDrive;
    
    if (IS_NUMBER(database) && AS_NUMBER(database) == -1) {
        db = itemStore.systemDrive;
    }
    
    insertFact(db,
                      AS_STRING(itemId)->chars,
                      AS_STRING(attribute)->chars,
                      AS_STRING(value)->chars,
                      AS_NUMBER(numericalValue),
                      AS_STRING(type)->chars,
                      AS_NUMBER(flags),
                      _timestamp);
    
    return BOOL_VAL(true);
}

static Value fetchFactsByItemIdNative(int argCount, Value* args) {
    if (argCount != 1) return BOOL_VAL(false);
    
    Value itemId = args[0];
    
    if (!IS_STRING(itemId)) return BOOL_VAL(false);
    
    CFactsQuery query;
    initFactsQuery(&query);
    query.itemId = AS_STRING(itemId)->chars;
    CFactsCollection* collection = fetchFacts(query);
    
    Value result = OBJ_VAL(copyString(collection->facts[0].value, (int)strlen(collection->facts[0].value)));
    
    freeFactsCollection(collection);
    
    return result;
}

static Value getRelId2(int argCount, Value* args) {
    ObjString* attr1 = AS_STRING(args[0]);
    ObjString* val1 = AS_STRING(args[1]);
    
    ObjString* attr2 = AS_STRING(args[2]);
    ObjString* val2 = AS_STRING(args[3]);
    
    CFactsQuery query;
    initFactsQuery(&query);
    query.attribute = attr1->chars;
    query.value = val1->chars;
    
    CFactsCollection* facts1 = fetchFacts(query);
    
    query.attribute = attr2->chars;
    query.value = val2->chars;
    
    CFactsCollection* facts2 = fetchFacts(query);
    
    // oof...
    for (int i = 0; i < facts1->count; i++) {
        for (int j = 0; j < facts2->count; j++) {
            if (strcmp(facts1->facts[i].itemId, facts2->facts[j].itemId) == 0) {
                return OBJ_VAL(copyString(facts1->facts[i].itemId, (int)strlen(facts1->facts[i].itemId)));
            }
        }
    }
    
    freeFactsCollection(facts1);
    freeFactsCollection(facts2);
    
    return NIL_VAL;
}

void store_loadVMBindings(void) {
    defineNative("getDeviceId", getDeviceIdFn);
    
    defineNative("create", createFn);
    defineNative("define", defineFn);
    defineNative("relate", relateFn);
    defineNative("find", findFn);
    defineNative("findRel", findRelFn);
    // Can we build on top of these fact-based functions in-environment with item- and relationship-based funcs?
    
    defineNative("store_insertFact", insertFactNative);
    defineNative("store_fetchFactsByItemId", fetchFactsByItemIdNative);
    
    defineNative("store_getRelId2", getRelId2);
}
