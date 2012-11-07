//
//  CharacterNoteController.h
//  XML to Core Data
//
//  Created by David on 11/7/12.
//  Copyright (c) 2012 David Nix. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface CharacterNoteController : UITableViewController <UITableViewDataSource> {
    @private
    NSMutableArray *notesArray;
}

@property (strong, nonatomic) NSManagedObject *selectedCharacter;

@end
