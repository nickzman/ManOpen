
#import "ManDocument.h"
#import <AppKit/AppKit.h>
#import "ManDocumentController.h"
#import "PrefPanelController.h"
#import "NSData+Utils.h"
#import "ManWindowController.h"

#define RestoreWindowDict @"RestoreWindowInfo"
#define RestoreSection    @"Section"
#define RestoreTitle      @"Title"
#define RestoreName       @"Name"
#define RestoreFileURL    @"URL"
#define RestoreFileType   @"DocType"
@interface NSDocument (LionRestorationMethods)
- (void)encodeRestorableStateWithCoder:(NSCoder *)coder;
- (void)restoreStateWithCoder:(NSCoder *)coder;
@end


@implementation ManDocument

+ (BOOL)canConcurrentlyReadDocumentsOfType:(NSString *)typeName
{
    return YES;
}

- (void)_loadDocumentWithName:(NSString *)name
                      section:(NSString *)section
                      manPath:(NSString *)manPath
                        title:(NSString *)title
{
    ManDocumentController *docController = [ManDocumentController sharedDocumentController];
    NSMutableString *command = [docController manCommandWithManPath:manPath];
    
    [self setFileType:@"man"];
    [self setShortTitle:title];
    
    if (section && [section length] > 0)
    {
        [command appendFormat:@" %@", [section lowercaseString]];
        self.xManDocURL = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"x-man-doc://%@/%@", section, title]];
    }
    else
    {
        self.xManDocURL = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"x-man-doc://%@", title]];
    }
    
    self.restoreData = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                   name,    RestoreName,
                   title,   RestoreTitle,
                   section, RestoreSection,
                   nil];
    
    [command appendFormat:@" %@", name];
    
    [self loadCommand:command];
}

- (instancetype)initWithName:(NSString *)name
	section:(NSString *)section
	manPath:(NSString *)manPath
	title:(NSString *)title
{
    self = [super init];
	if (self)
		[self _loadDocumentWithName:name section:section manPath:manPath title:title];
    return self;
}


- (void)makeWindowControllers
{
    ManWindowController *controller = [[ManWindowController alloc] initWithWindowNibName:@"ManPage"];
    
    [self addWindowController:controller];
}

/*
 * Standard NSDocument method.  We only want to override if we aren't
 * representing an actual file.
 */
- (NSString *)displayName
{
    return ([self fileURL] != nil)? [super displayName] : [self shortTitle];
}

- (void)addSectionHeader:(NSString *)header range:(NSRange)range
{
    /* Make sure it is a header -- error text sometimes is not Courier, so it gets passed in here. */
    if ([header rangeOfCharacterFromSet:[NSCharacterSet uppercaseLetterCharacterSet]].length > 0 &&
        [header rangeOfCharacterFromSet:[NSCharacterSet lowercaseLetterCharacterSet]].length == 0)
    {
        NSString *label = header;
        int count = 1;

        /* Check for dups (e.g. lesskey(1) ) */
        while ([self.sections containsObject:label]) {
            count++;
            label = [NSString stringWithFormat:@"%@ [%d]", header, count];
        }

        [self.sections addObject:label];
        [self.sectionRanges addObject:[NSValue valueWithRange:range]];
    }
}

- (void)showData
{
	@autoreleasepool
	{
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSTextStorage *storage = nil;
		NSFont        *manFont = [defaults manFont];
		NSColor       *linkColor = [defaults manLinkColor];
		NSColor       *textColor = [defaults manTextColor];
		NSColor       *backgroundColor = [defaults manBackgroundColor];
        ManWindowController *manWC = self.windowControllers.firstObject;
		
		if (manWC.textView == nil || self.hasLoaded) return;
		
		if ([self.taskData isRTFData])
		{
			storage = [[NSTextStorage alloc] initWithRTF:self.taskData documentAttributes:NULL];
		}
		else if (self.taskData != nil)
		{
			storage = [[NSTextStorage alloc] initWithHTML:self.taskData documentAttributes:NULL];
		}
		
		if (storage == nil)
			storage = [[NSTextStorage alloc] init];
		
		if ([[storage string] rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]].length == 0)
		{
			[[storage mutableString] setString:@"\nNo manual entry."];
		}
		
		if (self.sections == nil) {
			self.sections = [[NSMutableArray alloc] init];
			self.sectionRanges = [[NSMutableArray alloc] init];
		}
		[self.sections removeAllObjects];
		[self.sectionRanges removeAllObjects];
		
		/* Convert the attributed string to use the user's chosen font and text color */
		if (storage != nil)
		{
			NSFontManager *manager = [NSFontManager sharedFontManager];
			NSString      *family = [manFont familyName];
			CGFloat       size    = [manFont pointSize];
			NSUInteger    currIndex = 0;
			
			@try
			{
				[storage beginEditing];
				
				while (currIndex < [storage length])
				{
					NSRange currRange;
					NSDictionary *attribs = [storage attributesAtIndex:currIndex effectiveRange:&currRange];
					NSFont       *font = [attribs objectForKey:NSFontAttributeName];
					BOOL isLink = NO;
					
					/* We mark "sections" with Helvetica fonts */
					if (font != nil && ![[font familyName] isEqualToString:@"Courier"]) {
						[self addSectionHeader:[[storage string] substringWithRange:currRange] range:currRange];
					}
					
					isLink = ([attribs objectForKey:NSLinkAttributeName] != nil);
					
					if (font != nil && ![[font familyName] isEqualToString:family])
						font = [manager convertFont:font toFamily:family];
					if (font != nil && [font pointSize] != size)
						font = [manager convertFont:font toSize:size];
					if (font != nil)
						[storage addAttribute:NSFontAttributeName value:font range:currRange];
					
					/*
					 * Starting in 10.3, there is a -setLinkTextAttributes: method to set these, without having to
					 * determine the ranges ourselves.  However, since we are already iterating all the ranges
					 * for other reasons, may as well keep the old way.
					 */
					if (isLink)
						[storage addAttribute:NSForegroundColorAttributeName value:linkColor range:currRange];
					else
						[storage addAttribute:NSForegroundColorAttributeName value:textColor range:currRange];
					
					currIndex = NSMaxRange(currRange);
				}
				
				[storage endEditing];
			}
			@catch (NSException *localException)
			{
				NSLog(@"Exception during formatting: %@", localException);
			}
			
			[manWC.textView.layoutManager replaceTextStorage:storage];
			[manWC.textView.window invalidateCursorRectsForView:manWC.textView];
		}
		
		[manWC.textView setBackgroundColor:backgroundColor];
        [manWC.textView.window.toolbar validateVisibleItems];
		
		/*
		 * The 10.7 document reloading stuff can cause the loading methods to be invoked more than
		 * once, and the second time through we have thrown away our raw data.  Probably indicates
		 * some overkill code elsewhere on my part, but putting in the hadLoaded guard to only
		 * avoid doing anything after we have loaded real data seems to help.
		 */
		if (self.taskData != nil)
			self.hasLoaded = YES;
		
		// no need to keep around rtf data
        self.taskData = nil;
	}
}

- (NSString *)filterCommand
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    /* HTML parser in tiger got slow... RTF is faster, and is usable now that it supports hyperlinks */
    //    NSString *tool = @"cat2html";
    NSString *tool = @"cat2rtf";
    NSString *command = [[NSBundle mainBundle] pathForResource:tool ofType:nil];

    command = EscapePath(command, YES);
    command = [command stringByAppendingString:@" -lH"]; // generate links, mark headers
    if ([defaults boolForKey:@"UseItalics"])
        command = [command stringByAppendingString:@" -i"];
    if (![defaults boolForKey:@"UseBold"])
        command = [command stringByAppendingString:@" -g"];

    return command;
}

- (void)loadCommand:(NSString *)command
{
    ManDocumentController *docController = [ManDocumentController sharedDocumentController];
    NSString *fullCommand = [NSString stringWithFormat:@"%@ | %@", command, [self filterCommand]];
	
    self.taskData = nil;
    self.taskData = [docController dataByExecutingCommand:fullCommand];

    [self showData];
}

- (void)loadManFile:(NSString *)filename isGzip:(BOOL)isGzip
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *nroffFormat = [defaults stringForKey:@"NroffCommand"];
    NSString *nroffCommand;
    BOOL     hasQuote = ([nroffFormat rangeOfString:@"'%@'"].length > 0);

    /* If Gzip, change the command into a filter of the output of gzcat.  I'm
       getting the feeling that the customizable nroff command is more trouble
       than it's worth, especially now that OSX uses the good version of gnroff */
    if (isGzip)
    {
        NSString *repl = hasQuote? @"'%@'" : @"%@";
        NSRange replRange = [nroffFormat rangeOfString:repl];
        if (replRange.length > 0) {
			NSMutableString *formatCopy = nroffFormat.mutableCopy;
            [formatCopy replaceCharactersInRange:replRange withString:@""];
            nroffFormat = [NSString stringWithFormat:@"/usr/bin/gzip -dc %@ | %@", repl, formatCopy];
        }
    }
    
    nroffCommand = [NSString stringWithFormat:nroffFormat, EscapePath(filename, !hasQuote)];
    [self loadCommand:nroffCommand];
}

- (void)loadCatFile:(NSString *)filename isGzip:(BOOL)isGzip
{
    NSString *binary = isGzip? @"/usr/bin/gzip -dc" : @"/bin/cat";
    [self loadCommand:[NSString stringWithFormat:@"%@ '%@'", binary, EscapePath(filename, NO)]];
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)type error:(NSError **)error
{
    if ([type isEqual:@"man"])
        [self loadManFile:[url path] isGzip:NO];
    else if ([type isEqual:@"mangz"])
        [self loadManFile:[url path] isGzip:YES];
    else if ([type isEqual:@"cat"])
        [self loadCatFile:[url path] isGzip:NO];
    else if ([type isEqual:@"catgz"])
        [self loadCatFile:[url path] isGzip:YES];
    else {
        NSDictionary *errorDetail = [NSDictionary dictionaryWithObject:@"Invalid document type" forKey:NSLocalizedDescriptionKey];
        if (error != NULL)
            *error = [NSError errorWithDomain:@"ManOpen" code:0 userInfo:errorDetail];
        return NO;
    }

    // strip extension twice in case it is a e.g. "1.gz" filename
    [self setShortTitle:[[[[url path] lastPathComponent] stringByDeletingPathExtension] stringByDeletingPathExtension]];
    self.xManDocURL = url;
    
    self.restoreData = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                   url,    RestoreFileURL,
                   type,   RestoreFileType,
                   nil];

    if (self.taskData == nil)
    {
        NSDictionary *errorDetail = [NSDictionary dictionaryWithObject:@"Could not read manual data" forKey:NSLocalizedDescriptionKey];
        if (error != NULL)
            *error = [NSError errorWithDomain:@"ManOpen" code:0 userInfo:errorDetail];
        return NO;
    }

    return YES;
}

/* Always use global page layout */
- (IBAction)runPageLayout:(id)sender
{
    [[NSApplication sharedApplication] runPageLayout:sender];
}

- (void)printDocumentWithSettings:(NSDictionary<NSPrintInfoAttributeKey,id> *)printSettings showPrintPanel:(BOOL)showPrintPanel delegate:(id)delegate didPrintSelector:(SEL)didPrintSelector contextInfo:(void *)contextInfo
{
    ManWindowController *manWC = self.windowControllers.firstObject;
    NSPrintOperation *operation = [NSPrintOperation printOperationWithView:manWC.textView];
    NSPrintInfo      *printInfo = [operation printInfo];

    [printInfo setVerticallyCentered:NO];
    [printInfo setHorizontallyCentered:YES];
    [printInfo setHorizontalPagination:NSFitPagination];
    [operation setShowsPrintPanel:showPrintPanel];
    [operation setShowsProgressPanel:showPrintPanel];

    [operation runOperationModalForWindow:manWC.window delegate:nil didRunSelector:NULL contextInfo:NULL];
}


- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    [coder encodeObject:self.restoreData forKey:RestoreWindowDict];
}

- (void)restoreStateWithCoder:(NSCoder *)coder
{
    [super restoreStateWithCoder:coder];

    if (![coder containsValueForKey:RestoreWindowDict])
        return;

    NSDictionary *restoreInfo = [coder decodeObjectForKey:RestoreWindowDict];
    if ([restoreInfo objectForKey:RestoreName] != nil)
    {
        NSString *name = [restoreInfo objectForKey:RestoreName];
        NSString *section = [restoreInfo objectForKey:RestoreSection];
        NSString *title = [restoreInfo objectForKey:RestoreTitle];
        NSString *manPath = [[NSUserDefaults standardUserDefaults] manPath];
        
        [self _loadDocumentWithName:name section:section manPath:manPath title:title];
    }
    /* Usually, URL-backed documents have been automatically restored already
       (the copyURL would be set), but just in case... */
    else if ([restoreInfo objectForKey:RestoreFileURL] != nil && self.xManDocURL == nil)
    {
        NSURL *url = [restoreInfo objectForKey:RestoreFileURL];
        NSString *type  = [restoreInfo objectForKey:RestoreFileType];
        [self readFromURL:url ofType:type error:NULL];
    }

    [[self windowControllers] makeObjectsPerformSelector:@selector(synchronizeWindowTitleWithDocumentName)];
}

@end
