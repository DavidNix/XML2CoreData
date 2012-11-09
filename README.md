# XML 2 Core Data
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

## Setup
1. Add the DNXMLParseOperation header and implementation files to your project.  (You can find them in the sample app.)

2. To start parsing:

3. To cancel/abort parsing:

4. IMPORTANT, to save parsed objects to your Core Data store: 

5. Optional (but recommended), to catch parser errors:

## Limitations
* It does not sync or delete any objects.  Only adds them.  You will need to add this functionality.
* Assumes the XML file is downloaded locally.
* Currently, only works with 1-to-many relationships.
* Use camel case for XML tags.  They must match the exact names of your Core Data entities, relationships, and attributes.

# To Do
* Make debug NSLogs in parse operation more useful ex:  "[NSManagedObject addValue:value forKey:key]""
* Test when NSManagedObjects are subclassed.
* Test 1-to-1 relationships.