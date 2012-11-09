# XML to Core Data
When an XML schema and Core Data schema are mirrored:  Parses an XML file, creates NSManagedObjects, and adds them to your Core Data store.

A visual explanation of the XML Schema.

    <?xml version= "1.0" encoding="UTF8"?>
    <root>
    	<ParentEntity>
    		<attribute>attribute data</attribute>
    		<anotherAttribute>attribute data</anotherAttribute>
            // add an arbitrary number of attributes
    		<relationshipToChildEntities>
    			<ChildEntity>
    				<childAttribute>child attribute data</childAttribute>
                        <relationshipToGranchildEntities>
                            <GrandchildEntity>
                                <grandchildAttribute>grandchild attribute data</grandchildAttribute>
                                    <relationshipToGreatGranchildEntities>
                                        // go as deep as you'd like
                                    </relationshipToGreatGranchildEntities>
                            </GrandchildEntity>
                            // add an arbitrary number of <GrandchildEntity>'s
                        </relationshipToGranchildEntities>
    			</ChildEntity>
                <ChildEntity>
                    // add an arbitrary number of <ChildEntity>'s
                </ChildObject>
            </relationshipToChildEntities>
        </ParentEntity>
        // add an arbitrary number of <ParentEntity>'s
    </root>

View the "Schema_Illustration.pdf" for another visual example.

## Features
* Parses XML data and saves Core Data objects in the background, thus minimally affecting the UI.
* Can handle large XML files (uses SAX instead of DOM).
* Can handle an arbitrary number of objects and 1-to-many relationships as long as the schemas match.
* Will traverse your object graph an arbitrary number of levels deep.  (i.e. Parent objects with relationships of child objects with relationships of grandchild objects, etc.)

## How to Use
Add the DNXMLParseOperation header and implementation files to your project.  (You can find them in the sample app.)

### 1. To start parsing:
    
    NSData *xmlData = // load the xml file via a method of your choice

    DNXMLParseOperation *parser = [[DNXMLParseOperation alloc] initWithData:xmlData];
    parser.batchSize = 5;  // optional, defaults to 10
    
    // Let an observer know to save and merge the managed object context
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mergeChanges:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:nil];

    // Let an observer know if a parse error ocurred (optional, but recommended)                                        
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(handleParseError:) 
                                                 name:kParseOperationErrorNotif 
                                               object:nil];
    [parseQue addOperation:parser];

### 2. To cancel/abort parsing:

    [parser cancel];

### 3. IMPORTANT, to save parsed objects to your Core Data store: 

    // Invoked by observing "NSManagedObjectContextDidSaveNotification" from our Parse Operation
    - (void)mergeChanges:(NSNotification *)notification {
        NSManagedObjectContext *mainContext = [self managedObjectContext];
        
        if ([notification object] == mainContext) {
            // main context save, no need to perform the merge
            return;
        }
        [self performSelectorOnMainThread:@selector(updateContext:) withObject:notification waitUntilDone:YES];
    }

    // Invoked from mergeChanges: method,
    // Must be on the main thread so we can update our table with our new objects
    //
    - (void)updateContext:(NSNotification *)notification
    {
        NSManagedObjectContext *mainContext = [self managedObjectContext];
        [mainContext mergeChangesFromContextDidSaveNotification:notification];
        
        [self reloadTableView];
    }

    // Optional, but especially if using a table view, you must update the UI somehow
    - (void)reloadTableView {
        // Force the fetchedResultsController to reload, then force the table view to reload.
        self.fetchedResultsController = nil;
        [self fetchedResultsController];
        [self.tableView reloadData];
    }

### 4. Optional (but recommended), implement a method to handle notification `kParseOperationErrorNotif` 

    -(void)handleParseError:(NSNotification *)notification {
        NSError *parseError = [[notification userInfo] objectForKey:kParseOperationMsgErrorKey];
        NSString *errorMsg = [NSString stringWithFormat:@"Malformed data present. Unable to import new data. (Error Code: %i)", [parseError code]];
        // do something with the errorMsg such as show a UIAlertView
    }

## Limitations
* It does not sync or delete any objects.  Only adds them.  You will need to add this functionality.
* Assumes the XML file is downloaded locally.
* Currently, only works with 1-to-many relationships.
* Use camel case for XML tags.  They must match the exact names of your Core Data entities, relationships, and attributes.

# To Do
* Make debug NSLogs in parse operation more useful ex:  "[NSManagedObject addValue:value forKey:key]""
* Test when NSManagedObjects are subclassed.
* Test 1-to-1 relationships.