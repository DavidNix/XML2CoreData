//
//  CharactersController.m
//  XML to Core Data
//
//  Created by David on 11/7/12.
//  Copyright (c) 2012 David Nix. All rights reserved.
//

#import "CharactersController.h"

@interface CharactersController ()

@end

@implementation CharactersController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

@end
