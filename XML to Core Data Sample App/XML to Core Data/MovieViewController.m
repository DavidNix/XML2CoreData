//
//  DNViewController.m
//  XML to Core Data
/*
 
 Copyright (C) 2012 David Nix
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import "MovieViewController.h"
#import "CharactersController.h"

@class AppDelegate;
@interface MovieViewController ()

@end

@implementation MovieViewController

@synthesize fetchedResultsController=fetchedResultsController_;

- (void)viewDidLoad
{
    self.appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    self.managedObjectContext = self.appDelegate.managedObjectContext;
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    CharactersController *dest = (CharactersController*)[segue destinationViewController];
    UITableViewCell *cell = (UITableViewCell*)sender;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    dest.selectedMovie = [self.fetchedResultsController objectAtIndexPath:indexPath];
}

#pragma mark -
#pragma mark Parse Operation
-(void)startXMLParseOperation {
    // spawn an NSOperation to parse data in the background without affecting main thread
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"xml1" ofType:@"xml"];
    NSData *xmlData = [NSData dataWithContentsOfFile:filePath options:NSDataReadingUncached error:nil];
    parser = [[DNXMLParseOperation alloc] initWithData:xmlData];
    
    // notifications to let this view controller know to save managed object context
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mergeChanges:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:nil];
    
    [parseQue addOperation:parser];
}


#pragma mark -
#pragma mark Table View Datasource Delegate
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"movieCell"];
    NSManagedObject *movie = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = [movie valueForKey:@"title"];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Starring: %@", [movie valueForKey:@"starActor"]];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.fetchedResultsController.fetchedObjects count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

#pragma mark -
#pragma mark Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController {
    
    if (fetchedResultsController_ != nil) {
        return fetchedResultsController_;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Movie" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number, 0 = no limit
    [fetchRequest setFetchBatchSize:0];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc]
															 initWithFetchRequest:fetchRequest
															 managedObjectContext:self.managedObjectContext
															 sectionNameKeyPath:nil
															 cacheName:@"XML2CoreDataFetchedResultsCache"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
    NSError *error = nil;
    
    if (![fetchedResultsController_ performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", [error localizedDescription], [error userInfo]);
        
#ifdef DEBUG
        abort();
#endif
    }
    
    return fetchedResultsController_;
}

@end
