//
//  CharactersController.h
//  XML to Core Data
//
//  Created by David on 11/7/12.
//  Copyright (c) 2012 David Nix. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface CharactersController : UITableViewController <UITableViewDataSource> {
    @private
    NSMutableArray *charactersArray;
}

@property (strong, nonatomic) NSManagedObject *selectedMovie;

@end
