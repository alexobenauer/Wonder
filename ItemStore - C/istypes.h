//
//  istypes.h
//  Wonder
//
//  Created by Alexander Obenauer on 1/30/24.
//

#ifndef istypes_h
#define istypes_h

typedef struct {
    int uid;
    char *factId;
    char *itemId;
    char *attribute;
    char *value;
    double numericalValue;
    char *type;
    int flags;
    char *timestamp;
} CFact;

typedef struct {
    CFact *facts;
    int count;
} CFactsCollection;

typedef void (*UpdateFunction)(void);

void initFact(CFact* fact);
void freeFact(CFact* fact);

void initFactsCollection(CFactsCollection* collection);
void freeFactsCollection(CFactsCollection* collection);
CFactsCollection* combineFactsCollections(CFactsCollection* a, CFactsCollection* b);

#endif /* istypes_h */
