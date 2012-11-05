/*

Copyright (C) 2012 David Nix

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

 */

#import "DNParseOperation.h"
#import "DNAppDelegate.h"

// NSNotifications
NSString *kDidBeginParsing = @"DidBeginParsing";
NSString *KDidFinishParsing = @"DidFinishParsing";


// NSNotification name for reporting errors
NSString *kParseOperationErrorNotif = @"ParseOperationErrorNotif";

// NSNotification userInfo key for obtaining the error message
NSString *kParseOperationMsgErrorKey = @"ParseOperationMsgErrorKey";


@interface ParseOperation () <NSXMLParserDelegate>
    
@property (nonatomic, retain) NSMutableString *currentParsedCharacterData;
@property (nonatomic, retain) NSMutableArray *objectHierarchy;
@property (nonatomic, retain) NSMutableArray *objectBatch;
   
-(BOOL)string:(NSString *)aString isInArrayOfEntities:(NSArray *)anArray;
-(BOOL)string:(NSString *)aString isRelationshipForManagedObject:(NSManagedObject *)anObject;
-(BOOL)string:(NSString *)aString isAttributeForManagedObject:(NSManagedObject *)anObject;
-(void)saveManagedObjectsToStore;
-(void)postNotificationOfParsingStatus:(NSString *)notificationName;

@end

@implementation ParseOperation

@synthesize parseData, currentParsedCharacterData, managedObjectContext, objectHierarchy, objectBatch, allInsertedObjects;

- (id)initWithData:(NSData *)data
{
    if ((self = [super init])) {    
        parseData = [data copy];
        
    }
    return self;
}

// a batch of managed objects are ready to be added
// should only be executed on the main thread
- (void)saveManagedObjectsToStore {
    assert([NSThread isMainThread]);
    
    NSPersistentStoreCoordinator *storeCoordinator = [self.managedObjectContext persistentStoreCoordinator];
    
    [storeCoordinator lock];
    
#ifdef DEBUG
    NSLog(@"SAVING managed object context");
#endif
        
    NSError *error = nil;
	NSManagedObjectContext *moc = self.managedObjectContext;
    if (moc != nil) {
        if ([moc hasChanges] && ![moc save:&error] && !abortSaving) {
            
            NSLog(@"%@ unable to save with error:  %@", NSStringFromClass([self class]), error);
            
            [[[[UIAlertView alloc]
               initWithTitle:@"Unable to Save" message:@"Unable to save downloaded data. Data you are viewing may be inaccurate. Try resetting the database in Settings." 
               delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
              autorelease]
             show];
            
            abortSaving = YES;
            
#ifdef DEBUG
            abort();
#endif
        } 
    }
    
    [storeCoordinator unlock];
    
    self.objectBatch = [NSMutableArray array];

}

-(void)postNotificationOfParsingStatus:(NSString *)notificationName {
    assert([NSThread isMainThread]);
    NSNotification *notification = [NSNotification notificationWithName:notificationName object:self];
    if (notificationName == kDidBeginParsing)
        [[NSNotificationCenter defaultCenter] postNotification:notification];
    else if (notificationName == KDidFinishParsing) {
        [[NSNotificationCenter defaultCenter] postNotificationName:KDidFinishParsing 
                                                            object:self];
    }
        
}
     
// the main function for this NSOperation, to start the parsing
- (void)main {
    
    if ([self isCancelled]) return;
    
    // used in the saveManagedObjectsToStore: method, prevents the error dialog from popping up more than once
    abortSaving = NO;
    
    [self performSelectorOnMainThread:@selector(postNotificationOfParsingStatus:)
                           withObject:kDidBeginParsing 
                        waitUntilDone:YES];
    
    // setup our Core Data scratch pad and persistent store
    // create it here to be thread safe, so we don't corrupt the managed object context on the main thread
    managedObjectContext = [[NSManagedObjectContext alloc] init];
    [self.managedObjectContext setUndoManager:nil];
    
    SSCHAppDelegate *appDelegate = (SSCHAppDelegate *)[[UIApplication sharedApplication] delegate];
    [self.managedObjectContext setPersistentStoreCoordinator:appDelegate.persistentStoreCoordinator];
    
    entities = [[appDelegate.managedObjectModel entities] retain];
    parsedObjectCounter = 0;
    self.currentParsedCharacterData = [NSMutableString string];
    self.objectHierarchy = [NSMutableArray array];
    
    accumulatingParsedCharacterData = NO;
    self.objectBatch = [NSMutableArray array];
    self.allInsertedObjects = [NSMutableArray array];
    
    // It's also possible to have NSXMLParser download the data, by passing it a URL, but this is
    // not desirable because it gives less control over the network, particularly in responding to
    // connection errors.
    //
    xmlParser = [[NSXMLParser alloc] initWithData:self.parseData];
    [xmlParser setDelegate:self];
    [xmlParser parse];
    
    // depending on the total number of objects parsed, the last batch might not have been a
    // "full" batch, and thus not been part of the regular batch transfer. So, we check the count of
    // the array and, if necessary, send it to the main thread.
    //
    // first check if the operation has been cancelled, proceed if not
    //
    if (![self isCancelled]) {
        if (parsedObjectCounter > 0) {
        [self performSelectorOnMainThread:@selector(saveManagedObjectsToStore)
                               withObject:nil
                            waitUntilDone:YES];
        }
    }
    
    self.currentParsedCharacterData = nil;
    
    if (![self isCancelled] && [xmlParser parserError] == nil)
        [self performSelectorOnMainThread:@selector(postNotificationOfParsingStatus:) withObject:KDidFinishParsing waitUntilDone:YES];
    
    [xmlParser release];
}

- (void)dealloc {
    [parseData release];
    
    [currentParsedCharacterData release];
    
    [managedObjectContext release];
    [objectHierarchy release];
    [entities release];
    [allInsertedObjects release];
    
    [super dealloc];
}


#pragma mark -
#pragma mark Parser constants


// When an object has been fully constructed, it must be passed to the main thread and
// the table view in RootViewController must be reloaded to display it. It is not efficient to do
// this for every object - the overhead in communicating between the threads and reloading
// the table exceed the benefit to the user. Instead, we pass the objects in batches, sized by the
// constant below. In your application, the optimal batch size will vary 
// depending on the amount of data in the object and other factors, as appropriate.
//
static NSUInteger const kBatchSizeMaximum = 10;
static NSString *kParentEntity = @"parent";
static NSString *kChildEntity = @"child";
static NSString *kRelationship = @"relationship";
static NSString *kNoRelationship = @"noRelationship";


#pragma mark -
#pragma mark NSXMLParser delegate methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
                                        namespaceURI:(NSString *)namespaceURI
                                       qualifiedName:(NSString *)qName
                                          attributes:(NSDictionary *)attributeDict {
    
    if ([self isCancelled]) [xmlParser abortParsing];
    
#ifdef DEBUG
    NSLog(@"starting element %@", elementName);
#endif
    
    
    NSManagedObject *currentManagedObject = nil;
    
    if ([self.objectHierarchy count] > 0) {
        currentManagedObject = [[self.objectHierarchy lastObject] valueForKey:kChildEntity];
    }
    
    // if the elementName of the XML matches a Core Data entity
    if ([self string:elementName isInArrayOfEntities:entities]) {
        
        // insert new entities as we discover them
        NSEntityDescription *ent = [NSEntityDescription entityForName:elementName inManagedObjectContext:self.managedObjectContext];
        
        NSManagedObject *newManagedObject = [[NSManagedObject alloc] initWithEntity:ent insertIntoManagedObjectContext:self.managedObjectContext];
        
        #ifdef DEBUG
        NSLog(@"CREATING new NSManagedObject %@", [[newManagedObject entity] name]);
        #endif
        
        assert(objectHierarchy);
        
        id parentObject;
        
        if ([objectHierarchy count] == 0) {
            //this is the root element
            parentObject = elementName;
        } else {
            //it's a child element
            parentObject = [[objectHierarchy lastObject] valueForKey:kChildEntity];
        }
        
        NSMutableDictionary *trackingDictionary = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:parentObject, newManagedObject, kNoRelationship, nil] 
                                                                           forKeys:[NSArray arrayWithObjects:kParentEntity, kChildEntity, kRelationship, nil]];
        [self.objectHierarchy addObject:trackingDictionary];
        
        [newManagedObject release];
    }
    
    // if the elementName of the XML matches a Core Data attribute
    // start accumulating the inner text of that XML element
    else if (currentManagedObject && [self string:elementName isAttributeForManagedObject:currentManagedObject]) {
    
        accumulatingParsedCharacterData = YES;
        [currentParsedCharacterData setString:@""];
    }
    
    
    // if the elementName of the XML matches a Core Data relationship
    else if (currentManagedObject && [self string:elementName isRelationshipForManagedObject:currentManagedObject]) {
        #ifdef DEBUG
        NSLog(@"CREATING NEW RELATIONSHIP:  setting currentRelationship to %@ mutableSetValueForKey %@.", [[currentManagedObject entity] name], elementName);
        #endif
        
        NSMutableSet *relationship = [currentManagedObject mutableSetValueForKey:elementName];
        [[self.objectHierarchy lastObject] setValue:relationship forKey:kRelationship];        
    }
    
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName
                                      namespaceURI:(NSString *)namespaceURI
                                     qualifiedName:(NSString *)qName {
    
    if ([self isCancelled]) [xmlParser abortParsing];
    
    // Stop accumulating parsed character data. We won't start again until specific elements begin.
    accumulatingParsedCharacterData = NO;

    //get the object we're currently modifying
    NSManagedObject *currentManagedObject = nil;
    if ([self.objectHierarchy count] > 0) {
        currentManagedObject = [[self.objectHierarchy lastObject] valueForKey:kChildEntity];
    }
    
    //if it's the root entity
    if ([self.objectHierarchy count] > 0 && [[self.objectHierarchy lastObject] valueForKey:kParentEntity] == elementName) {
#ifdef DEBUG
        NSLog(@"ADDING OBJECT to batch, root object is %@", currentManagedObject);
#endif
        // when saving the context later, we use this to take out duplicates and sync data
        [self.objectBatch addObject:currentManagedObject];
        
        // keeps track of all the added objects
        [self.allInsertedObjects addObject:currentManagedObject];
        
        parsedObjectCounter++;
        
        //call the selector to save the context, objects are already inserted into the context
        if (parsedObjectCounter >= kBatchSizeMaximum) {
            [self performSelectorOnMainThread:@selector(saveManagedObjectsToStore)
                                   withObject:nil
                                waitUntilDone:YES];
            parsedObjectCounter = 0;
        }
        
        //reset tracking
        self.objectHierarchy = nil;
        self.objectHierarchy = [NSMutableArray array];
    }
    
    //if it's not root entity it must be a child entity, and must be part of a relationship.
    else if ([self string:elementName isInArrayOfEntities:entities]) {
        
        //Set up for getting index of the second to last object (if one exists)
        int index = [self.objectHierarchy count] - 2;
        
        NSMutableSet *relationship = nil;
        
        if (index >= 0 && [[self.objectHierarchy objectAtIndex:index] valueForKey:kRelationship] != kNoRelationship) {
            relationship = [NSMutableSet set];
            relationship = [[self.objectHierarchy objectAtIndex:index] valueForKey:kRelationship];
        }
        
        assert(relationship);
#ifdef DEBUG
        NSLog(@"ADDING TO RELATIONSHP: addObject %@", [[currentManagedObject entity] name]);
        NSLog(@"relationship is %@", relationship);
#endif
        [relationship addObject:currentManagedObject];
        
        //pop it off the stack so we don't build up numerous child entities of the same type.  
        [self.objectHierarchy removeLastObject];
    }
    
    //if it's an attribute, add it to the current object
    else if ([self string:elementName isAttributeForManagedObject:currentManagedObject]) {
#ifdef DEBUG
        NSLog(@"SETTING ATTRIBUTE: %@ setValue:%@ forKey:%@", [[currentManagedObject entity] name], currentParsedCharacterData, elementName);
#endif
        
        [currentManagedObject setValue:[NSString stringWithString:self.currentParsedCharacterData] forKey:elementName];
    }
    
    //** TO DO ** move this to the top and return, if it is a relationship?
    //if ending a relationship
    else if ([self string:elementName isRelationshipForManagedObject:currentManagedObject]) {
#ifdef DEBUG
        NSLog(@"ENDING relationship");
#endif
        //no clean up work to do if it's a relationship
        return;
    }
    
}

// This method is called by the parser when it finds parsed character data in an element.
// The parser is not guaranteed to deliver all of the parsed character data for an element in a single
// invocation, so it is necessary to accumulate character data until the end of the element is reached.
//
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    
    if ([self isCancelled]) [xmlParser abortParsing];
    
    if (accumulatingParsedCharacterData) {
        // If the current element is one whose content we care about, append 'string'
        // to the property that holds the content of the current element.
        //
        [self.currentParsedCharacterData appendString:string];
    }
}

// an error occurred while parsing the data,
// post the error as an NSNotification to our app delegate.
- (void)handleParseError:(NSError *)parseError {
    [[NSNotificationCenter defaultCenter] postNotificationName:kParseOperationErrorNotif
                                                    object:self
                                                  userInfo:[NSDictionary dictionaryWithObject:parseError
                                                                                       forKey:kParseOperationMsgErrorKey]];
}

// an error occurred while parsing the data,
// pass the error to the main thread for handling.

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    NSLog(@"parser got error, Error:  %@", parseError);
    if ([parseError code] != NSXMLParserDelegateAbortedParseError)
    {
        [self performSelectorOnMainThread:@selector(handleParseError:)
                              withObject:parseError
                           waitUntilDone:NO];
    }
}

#pragma mark - String Comparision Methods

-(BOOL)string:(NSString *)aString isInArrayOfEntities:(NSArray *)anArray {
    
    for (NSEntityDescription *entity in anArray) {
        if ([[entity name] isEqualToString:aString])
            return YES;
    }
    
    return NO;
}

-(BOOL)string:(NSString *)aString isRelationshipForManagedObject:(NSManagedObject *)anObject {
    NSArray *relationships = [[[anObject entity] relationshipsByName] allKeys];
    for (NSString *relationship in relationships) {
        if ([relationship isEqualToString:aString])
            return YES;
    }
    
    return NO;
}

-(BOOL)string:(NSString *)aString isAttributeForManagedObject:(NSManagedObject *)anObject {
    NSArray *attributes = [[[anObject entity] attributesByName] allKeys];
    for (NSString *attribute in attributes) {
        if ([attribute isEqualToString:aString])
            return YES;
    }
    
    return NO;
}


@end
