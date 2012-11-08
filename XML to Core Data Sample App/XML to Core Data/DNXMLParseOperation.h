/*

Copyright (C) 2012 David Nix

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

 */

#import <CoreData/CoreData.h>

extern NSString *kDidBeginParsing;
extern NSString *kDidFinishParsing;

extern NSString *kParseOperationErrorNotif;
extern NSString *kParseOperationMsgErrorKey;

@interface DNXMLParseOperation : NSOperation {
    NSData *parseData;

@private
    
    // these variables are used during parsing
    NSMutableString *currentParsedCharacterData;
    
    int parsedObjectCounter;
    
    BOOL accumulatingParsedCharacterData;
    
    NSManagedObjectContext *managedObjectContext;
    
    NSMutableArray *objectHierarchy;
    
    NSArray *entities;
    
    NSXMLParser *xmlParser;
    
    BOOL abortSaving;
}

@property (copy, readonly) NSData *parseData;

@property (retain) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, retain) NSMutableArray *allInsertedObjects;

@property (nonatomic) NSUInteger batchSize;

- (id)initWithData:(NSData *)data;

@end
