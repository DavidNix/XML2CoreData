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
	
    charactersArray = [NSMutableArray array];
    
    NSSet *charactersSet = [self.selectedMovie valueForKey:@"characters"];
    NSArray *unsortedCharacters = [charactersSet allObjects];
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"characterName" ascending:YES];
	NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    charactersArray = (NSMutableArray*)[unsortedCharacters sortedArrayUsingDescriptors:sortDescriptors];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark Table View Datasource Delegate
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"characterCell"];
    NSManagedObject *character = [charactersArray objectAtIndex:indexPath.row];
    cell.textLabel.text = [character valueForKey:@"characterName"];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [charactersArray count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

@end
