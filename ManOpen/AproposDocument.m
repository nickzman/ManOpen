/* AproposDocument.m created by lindberg on Tue 10-Oct-2000 */

#import "AproposDocument.h"
#import <AppKit/AppKit.h>
#import "ManDocumentController.h"
#import "PrefPanelController.h"

@interface NSDocument (LionRestorationMethods)
- (void)encodeRestorableStateWithCoder:(NSCoder *)coder;
- (void)restoreStateWithCoder:(NSCoder *)coder;
@end

@interface AproposDocument ()
@property(nonatomic,retain) NSString *searchString;
@property(nonatomic,retain) NSString *title;
@property(nonatomic,retain) NSMutableOrderedSet<NSDictionary<NSString *, NSString *> *> *titlesAndDescriptions; // this is an ordered set, rather than an array, because ordered sets will automatically filter duplicate results
@end

@implementation AproposDocument

+ (BOOL)canConcurrentlyReadDocumentsOfType:(NSString *)typeName
{
    return YES;
}

- (void)_loadWithString:(NSString *)apropos manPath:(NSString *)manPath title:(NSString *)aTitle
{
    ManDocumentController *docController = [ManDocumentController sharedDocumentController];
    NSMutableString *command = [docController manCommandWithManPath:manPath];
    NSData *output;
    
    self.titlesAndDescriptions = [[NSMutableOrderedSet alloc] init];
	self.title = aTitle;
    [self setFileType:@"apropos"];

    /* Searching for a blank string doesn't work anymore... use a catchall regex */
    if ([apropos length] == 0)
        apropos = @".";
	self.searchString = apropos;

    /*
     * Starting on Tiger, man -k doesn't quite work the same as apropos directly.
     * Use apropos then, even on Panther.  Panther/Tiger no longer accept the -M
     * argument, so don't try... we set the MANPATH environment variable, which
     * gives a warning on Panther (stderr; ignored) but not on Tiger.
     */
//    [command appendString:@" -k"];
    [command setString:@"/usr/bin/apropos"];
    
    [command appendFormat:@" %@", EscapePath(apropos, YES)];
    output = [docController dataByExecutingCommand:command manPath:manPath];
    /* The whatis database appears to not be UTF8 -- at least, UTF8 can fail, even on 10.7 */
	[self parseOutput:[[NSString alloc] initWithData:output encoding:NSASCIIStringEncoding]];
}

- (instancetype)initWithString:(NSString *)apropos manPath:(NSString *)manPath title:(NSString *)aTitle
{
	self = [super init];
	if (self)
	{
		[self _loadWithString:apropos manPath:manPath title:aTitle];
		
        if (self.titlesAndDescriptions.count == 0)
        {
            NSAlert *nothingFoundAlert = [[NSAlert alloc] init];
            
            nothingFoundAlert.messageText = NSLocalizedString(@"Nothing found", @"Title of an unsuccessful apropos search");
            nothingFoundAlert.informativeText = [NSString stringWithFormat:NSLocalizedString(@"No pages related to '%@' found", @"Body of an unsuccessful apropos search"), apropos];
            (void)[nothingFoundAlert runModal];
			return nil;
		}
	}
    return self;
}


- (NSString *)windowNibName
{
    return @"Apropos";
}

- (NSString *)displayName
{
    return self.title;
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController
{
    NSString *sizeString = [[NSUserDefaults standardUserDefaults] stringForKey:@"AproposWindowSize"];

    [super windowControllerDidLoadNib:windowController];

    if (sizeString != nil)
    {
        NSSize windowSize = NSSizeFromString(sizeString);
        NSWindow *window = self.tableView.window;
        NSRect frame = [window frame];

        if (windowSize.width > 30.0 && windowSize.height > 30.0) {
            frame.size = windowSize;
            [window setFrame:frame display:NO];
        }
    }

    self.tableView.target = self;
    self.tableView.doubleAction = @selector(openManPages:);
    [self.tableView sizeLastColumnToFit];
}

- (void)parseOutput:(NSString *)output
{
    NSArray *lines = [output componentsSeparatedByString:@"\n"];
    NSUInteger i, count = [lines count];

    if ([output length] == 0) return;

    lines = [lines sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    for (i=0; i<count; i++)
    {
        NSString *line = [lines objectAtIndex:i];
        NSRange dashRange;

        if ([line length] == 0) continue;

        dashRange = [line rangeOfString:@"\t\t- "]; //OPENSTEP
        if (dashRange.length == 0)
            dashRange = [line rangeOfString:@"\t- "]; //OPENSTEP
        if (dashRange.length == 0)
            dashRange = [line rangeOfString:@"\t-" options:NSBackwardsSearch|NSAnchoredSearch];
        if (dashRange.length == 0)
            dashRange = [line rangeOfString:@" - "]; //MacOSX
        if (dashRange.length == 0)
            dashRange = [line rangeOfString:@" -" options:NSBackwardsSearch|NSAnchoredSearch];

        if (dashRange.length == 0) continue;

        [self.titlesAndDescriptions addObject:@{@"titles": [line substringToIndex:dashRange.location], @"descriptions": [line substringFromIndex:NSMaxRange(dashRange)]}];  // the keys must be synchronized with the table column identifiers, or the table data source will fail
    }
}

- (IBAction)saveCurrentWindowSize:(id)sender
{
    NSSize size = self.tableView.window.frame.size;
    [[NSUserDefaults standardUserDefaults] setObject:NSStringFromSize(size) forKey:@"AproposWindowSize"];
}

- (IBAction)openManPages:(id)sender
{
    if (sender == self.tableView)
    {
        NSInteger clickedRow = self.tableView.clickedRow;
        
        if (clickedRow >= 0L)
        {
            NSDictionary *titleAndDescription = self.titlesAndDescriptions[clickedRow];
            NSString *manPage = titleAndDescription[@"titles"];
            
            [[ManDocumentController sharedDocumentController] openString:manPage oneWordOnly:YES];
        }
    }
}

- (void)printDocumentWithSettings:(NSDictionary<NSPrintInfoAttributeKey,id> *)printSettings showPrintPanel:(BOOL)showPrintPanel delegate:(id)delegate didPrintSelector:(SEL)didPrintSelector contextInfo:(void *)contextInfo
{
    NSPrintOperation *op = [NSPrintOperation printOperationWithView:self.tableView];
    [op setShowsPrintPanel:showPrintPanel];
    [op setShowsProgressPanel:showPrintPanel];
    [op runOperationModalForWindow:self.tableView.window delegate:nil didRunSelector:NULL contextInfo:NULL];
}

/* NSTableView dataSource */
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.titlesAndDescriptions.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return self.titlesAndDescriptions[row][tableColumn.identifier];
}

/* Document restoration */
#define RestoreSearchString @"SearchString"
#define RestoreTitle @"Title"

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    [coder encodeObject:self.searchString forKey:RestoreSearchString];
    [coder encodeObject:self.title forKey:RestoreTitle];
}

- (void)restoreStateWithCoder:(NSCoder *)coder
{
    [super restoreStateWithCoder:coder];
    
    if (![coder containsValueForKey:RestoreSearchString])
        return;
    
    NSString *search = [coder decodeObjectForKey:RestoreSearchString];
    NSString *theTitle = [coder decodeObjectForKey:RestoreTitle];
    NSString *manPath = [[NSUserDefaults standardUserDefaults] manPath];
    
    [self _loadWithString:search manPath:manPath title:theTitle];
    [[self windowControllers] makeObjectsPerformSelector:@selector(synchronizeWindowTitleWithDocumentName)];
    [self.tableView reloadData];
}

@end
