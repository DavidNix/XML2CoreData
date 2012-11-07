All it does is insert core data objects into the managed object context.  It does not sync or delete objects.  You will need to code that yourself.

When the XML schema matches your Core Data Object model.

Assumes the XML file is downloaded locally first.

Can handle very large XML files because NSXMLParser is a SAX parser.

Limitations - only works with 1 to many relationships.