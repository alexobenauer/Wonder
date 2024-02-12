//
//  istypes.c
//  Wonder
//
//  Created by Alexander Obenauer on 1/30/24.
//

#include <stdlib.h>
#include <string.h>

#include "istypes.h"

void initFact(CFact* fact) {
    fact->uid = -1;
    fact->factId = NULL;
    fact->itemId = NULL;
    fact->attribute = NULL;
    fact->value = NULL;
    fact->numericalValue = -1;
    fact->type = NULL;
    fact->flags = -1;
    fact->timestamp = NULL;
}

void freeFact(CFact* fact) {
    free(fact->itemId);
    free(fact->attribute);
    free(fact->value);
    free(fact->type);
    free(fact->timestamp);
}


void initFactsCollection(CFactsCollection* collection) {
    collection->facts = NULL;
    collection->count = 0;
}

void freeFactsCollection(CFactsCollection* collection) {
    if (collection == NULL) {
        return;
    }
    
    // Free the facts array
    if (collection->facts != NULL) {
        for (int i = 0; i < collection->count; i++) {
            CFact* fact = &(collection->facts[i]);
            freeFact(fact);
        }
        
        free(collection->facts);
    }
    
    // Free the collection itself
    free(collection);
}

CFactsCollection* combineFactsCollections(CFactsCollection* a, CFactsCollection* b) {
    if (a->count == 0 && b->count == 0) {
        freeFactsCollection(b);
        return a;
    }
    else if (a->count == 0) {
        freeFactsCollection(a);
        return b;
    }
    else if (b->count == 0) {
        freeFactsCollection(b);
        return a;
    }
    
    CFactsCollection* result = malloc(sizeof(CFactsCollection));
    result->count = a->count + b->count;
    result->facts = realloc(result->facts, result->count * sizeof(CFact));
    
    memcpy(result->facts, a->facts, a->count * sizeof(CFact));
    memcpy(result->facts + a->count, b->facts, b->count * sizeof(CFact));
    
    // TODO: Sort by created date desc
    
    freeFactsCollection(a);
    freeFactsCollection(b);
    
    return result;
}
