extern NSString *kDidBeginParsing;
extern NSString *kDidFinishParsing;

extern NSString *kParseOperationErrorNotif;
extern NSString *kParseOperationMsgErrorKey;

@interface ParseOperation : NSOperation {
    NSData *parseData;

@private
    
    // these variables are used during parsing
    NSMutableString *currentParsedCharacterData;
    
    int parsedObjectCounter;
    
    BOOL accumulatingParsedCharacterData;
    
    NSManagedObjectContext *managedObjectContext;
    
    NSMutableArray *objectHierarchy;
    
    NSArray *entities;
    
    NSXMLParser *operationParser;
    
    BOOL abortSaving;
}

@property (copy, readonly) NSData *parseData;

@property (retain) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, retain) NSMutableArray *allInsertedObjects;

- (id)initWithData:(NSData *)data;

@end
