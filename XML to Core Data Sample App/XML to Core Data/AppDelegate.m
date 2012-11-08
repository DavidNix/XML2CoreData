//
//  DNAppDelegate.m
//  XML to Core Data
//
/*
 
 Copyright (C) 2012 David Nix
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [self eraseAllData];
    [self addTestData];
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


#pragma mark -
#pragma mark Test Data (for debugging of core data logic)

-(void)addTestData {
    NSManagedObject *movie = [NSEntityDescription insertNewObjectForEntityForName:@"Movie" inManagedObjectContext:self.managedObjectContext];
    [movie setValue:@"Jerry Maguire" forKey:@"title"];
    [movie setValue:@"Tom Cruise" forKey:@"starActor"];
    
    // add a character to the movie
    NSMutableSet *characters = [movie mutableSetValueForKey:@"characters"];
    [self saveContextWithMOC:self.managedObjectContext];
    NSManagedObject *character = [NSEntityDescription insertNewObjectForEntityForName:@"Character" inManagedObjectContext:self.managedObjectContext];
    [character setValue:@"Rod Tidwell" forKey:@"characterName"];
    [characters addObject:character];
    
    // add a character note to the character
    NSMutableSet *charNotes = [character mutableSetValueForKey:@"characterNotes"];
    NSManagedObject *charNote = [NSEntityDescription insertNewObjectForEntityForName:@"CharacterNote" inManagedObjectContext:self.managedObjectContext];
    [charNote setValue:@"Nobody football player turned famous.  Jerry Maguire's last client.  The one who ends up saving him." forKey:@"noteDescription"];
    [charNotes addObject:charNote];
    charNote = [NSEntityDescription insertNewObjectForEntityForName:@"CharacterNote" inManagedObjectContext:self.managedObjectContext];
    [charNote setValue:@"Just another character note.  He's very loud and sometimes abrasive." forKey:@"noteDescription"];
    [charNotes addObject:charNote];
}

#pragma mark -
#pragma mark Core Data stack and methods

- (void)saveContextWithMOC:(NSManagedObjectContext *)moc {
    
    NSError *error = nil;
    if (moc != nil) {
        if ([moc hasChanges] && ![moc save:&error]) {
            
            NSLog(@"%@ unable to save with error:  %@", NSStringFromClass([self class]), error);
            
#ifdef DEBUG
            abort();
#endif
        }
    }
}

-(void)eraseAllData {
    NSFetchRequest *fetch = [[NSFetchRequest alloc] init];
    [fetch setEntity:[NSEntityDescription entityForName:@"Movie" inManagedObjectContext:self.managedObjectContext]];
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetch error:nil];
    for (NSManagedObject *movie in results)
        [self.managedObjectContext deleteObject:movie];
}

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext {
#ifdef DEBUG
    NSLog(@"ManagedObjectContext Called.");
#endif
    
    if (managedObjectContext_ != nil) {
        return managedObjectContext_;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext_ = [[NSManagedObjectContext alloc] init];
        [managedObjectContext_ setPersistentStoreCoordinator:coordinator];
    }
    return managedObjectContext_;
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel {
#ifdef DEBUG
    NSLog(@"ManagedObjectModel Called.");
#endif
    
    if (managedObjectModel_ != nil) {
        return managedObjectModel_;
    }
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"XML2CoreData" ofType:@"momd"];
    NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
    managedObjectModel_ = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return managedObjectModel_;
}


- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    
    if (persistentStoreCoordinator_ != nil) {
        return persistentStoreCoordinator_;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"XML2CoreData.sqlite"];
    
    NSError *error = nil;
    persistentStoreCoordinator_ = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator_ addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        
        // handle error here
    }
    
    
    return persistentStoreCoordinator_;
}


#pragma mark -
#pragma mark Application's Documents directory

/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


@end
