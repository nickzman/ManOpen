//
//  ManWindowController.m
//  ManOpen (Application)
//
//  Created by Nick Zitzmann on 2/23/21.
//

#import "ManWindowController.h"
#import "PrefPanelController.h"
#import "ManDocument.h"
#import "ManDocumentController.h"
#import "NSData+Utils.h"

@interface ManWindowController ()

@end

@implementation ManWindowController

- (void)windowDidLoad
{
    NSString *sizeString = [[NSUserDefaults standardUserDefaults] stringForKey:@"ManWindowSize"];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [super windowDidLoad];

    self.textView.editable = NO;
    self.textView.selectable = YES;
    self.textView.importsGraphics = NO;
    self.textView.richText = YES;
    self.textView.usesFindBar = YES;
    self.textView.incrementalSearchingEnabled = YES;

    if (sizeString != nil)
    {
        NSSize windowSize = NSSizeFromString(sizeString);
        NSWindow *window = self.window;
        NSRect frame = [window frame];

        if (windowSize.width > 30.0 && windowSize.height > 30.0) {
            frame.size = windowSize;
            [window setFrame:frame display:NO];
        }
    }

    self.textView.textStorage.mutableString.string = NSLocalizedString(@"Loading…", @"Displayed in the text view while the text is loading");
    self.textView.backgroundColor = defaults.manBackgroundColor;
    self.textView.textColor = defaults.manTextColor;
    [self.document performSelector:@selector(showData) withObject:nil afterDelay:0.0];

    [self.window makeFirstResponder:self.textView];
    [self.window setDelegate:self];
}


#pragma mark -


- (IBAction)openSelection:(id)sender
{
    NSRange selectedRange = self.textView.selectedRange;

    if (selectedRange.length > 0)
    {
        NSString *selectedString = [self.textView.string substringWithRange:selectedRange];
        [[ManDocumentController sharedDocumentController] openString:selectedString];
    }
    [self.window makeFirstResponder:self.textView];
}

- (IBAction)displaySection:(id)sender
{
    ManDocument *document = self.document;
    NSUInteger section = [document.sections indexOfObject:[sender title]];
    
    if (section != NSNotFound && section < document.sectionRanges.count)
    {
        NSRange range = document.sectionRanges[section].rangeValue;
        
        [self.textView scrollRangeToTop:range];
    }
}

- (IBAction)copyURL:(id)sender
{
    ManDocument *document = self.document;
    
    if (document.xManPageURL != nil)
    {
        NSPasteboard *pb = [NSPasteboard generalPasteboard];
        
        [pb clearContents];
        [pb setData:[document.xManPageURL.absoluteString dataUsingEncoding:NSUTF8StringEncoding] forType:document.xManPageURL.fileURL ? (NSString *)kUTTypeFileURL : (NSString *)kUTTypeURL];
        [pb setData:[[NSString stringWithFormat:@"<%@>", [document.xManPageURL absoluteString]] dataUsingEncoding:NSUTF8StringEncoding] forType:(NSString *)kUTTypeUTF8PlainText];
    }
}

- (IBAction)saveCurrentWindowSize:(id)sender
{
    CGSize size = self.window.frame.size;
    
    [[NSUserDefaults standardUserDefaults] setObject:NSStringFromSize(size) forKey:@"ManWindowSize"];
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
    if ([item action] == @selector(copyURL:))
        return ((ManDocument *)self.document).xManPageURL != nil;
    return YES;
}


- (BOOL)validateToolbarItem:(NSToolbarItem *)item
{
    if ([item.itemIdentifier isEqualToString:@"MDSectionIdentifier"])
    {
        return ((ManDocument *)self.document).sections.count > 0UL;
    }
    else if ([item.itemIdentifier isEqualToString:@"MDOpenSelectionIdentifier"])
    {
        return self.textView.selectedRange.length > 0UL;
    }
    return YES;
}

#pragma mark -

- (NSArray<NSToolbarItemIdentifier> *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    // MDSectionIdentifier is an NSMenuToolbarItem. As of Xcode 12.4, these items cannot be created in xibs, and if we try to coerce an NSToolbarItem into an NSMenuToolbarItem, then the AppKit throws an exception decoding the object. So we'll have to construct it manually...
    return @[@"MDSectionIdentifier"];
}


- (NSArray<NSToolbarItemIdentifier> *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    return @[NSToolbarFlexibleSpaceItemIdentifier, @"MDSectionIdentifier"];
}


- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
     itemForItemIdentifier:(NSToolbarItemIdentifier)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag
{
    if ([itemIdentifier isEqualToString:@"MDSectionIdentifier"])
    {
        if (@available(macOS 10.15, *))
        {
            NSMenuToolbarItem *menuItem = [[NSMenuToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
            
            menuItem.title = NSLocalizedString(@"Section", @"Section");
            menuItem.label = menuItem.title;
            menuItem.menu = [[NSMenu alloc] initWithTitle:menuItem.title];
            menuItem.menu.delegate = self;
            return menuItem;
        }
        else
        {
            NSToolbarItem *menuItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
            NSPopUpButton *pullDown = [[NSPopUpButton alloc] initWithFrame:CGRectZero pullsDown:YES];
            
            menuItem.label = NSLocalizedString(@"Section", @"Section");
            menuItem.view = pullDown;
            [pullDown insertItemWithTitle:menuItem.label atIndex:0L];
            pullDown.menu.delegate = self;
            return menuItem;
        }
    }
    return nil;
}

#pragma mark -

- (void)menuNeedsUpdate:(NSMenu *)menu
{
    // Here we assume this menu is the section pull-down menu.
    [menu removeAllItems];
    // In an NSMenuToolbarItem, the first item in a pull-down is never actually displayed. In an NSPopUpButton, the first item in a pull-down is the pull-down's title. Either way, we need a first menu item that doesn't do anything.
    [menu addItemWithTitle:NSLocalizedString(@"Section", @"Section") action:nil keyEquivalent:@""];
    // Add an item for each section.
    [((ManDocument *)self.document).sections enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [menu addItemWithTitle:obj action:@selector(displaySection:) keyEquivalent:@""];
    }];
    // For some reason, we lose the title if this gets called again. But since the sections are static, we have served our purpose.
    menu.delegate = nil;
}

#pragma mark -

- (BOOL)textView:(NSTextView *)aTextView clickedOnLink:(id)link atIndex:(NSUInteger)charIndex
{
    NSString *page = nil;

    /* On Tiger, NSURL, Panther and before, NSString */
    if ([link isKindOfClass:[NSString class]] && [link hasPrefix:@"manpage:"])
        page = [link substringFromIndex:8];
    if ([link isKindOfClass:[NSURL class]])
        page = [link resourceSpecifier];

    if (page == nil)
        return NO;
    [[ManDocumentController sharedDocumentController] openString:page];
    return YES;
}

- (void)textView:(NSTextView *)textView clickedOnCell:(id <NSTextAttachmentCell>)cell inRect:(NSRect)cellFrame atIndex:(NSUInteger)charIndex
{
    NSString *filename = nil;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    /* NSHelpAttachment stores the string in the fileName variable */
    if ([[cell attachment] respondsToSelector:@selector(fileName)])
        filename = [(id)[cell attachment] fileName];
#pragma clang diagnostic pop

    if ([filename hasPrefix:@"manpage:"]) {
        filename = [filename substringFromIndex:8];
        [[ManDocumentController sharedDocumentController] openString:filename];
    }
}

#pragma mark -

- (void)windowDidUpdate:(NSNotification *)notification
{
    /* Disable the Open Selection button if there's no selection to work on */
    [self.window.toolbar validateVisibleItems];
}

- (BOOL)windowShouldZoom:(NSWindow *)window toFrame:(NSRect)newFrame
{
    return YES;
}

- (NSRect)windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)newFrame
{
    NSScrollView *scrollView = [self.textView enclosingScrollView];
    NSRect currentFrame = [window frame];
    NSRect desiredFrame;
    NSSize textSize;
    NSRect scrollRect;
    NSRect contentRect;

    /* Get the text's natural size */
    textSize = self.textView.textStorage.size;
    textSize.width += (self.textView.textContainerInset.width * 2) + 10; //add a little extra padding
    [self.textView sizeToFit];
    textSize.height = NSHeight(self.textView.frame); //this seems to be more accurate

    /* Get the size the scrollView should be based on that */
    scrollRect.origin = NSZeroPoint;
    scrollRect.size = [NSScrollView frameSizeForContentSize:textSize horizontalScrollerClass:scrollView.horizontalScroller.class verticalScrollerClass:scrollView.verticalScroller.class borderType:scrollView.borderType controlSize:scrollView.verticalScroller.controlSize scrollerStyle:scrollView.verticalScroller.scrollerStyle];

    /* Get the window's content size -- basically the scrollView size plus our title area */
    contentRect = scrollRect;
    contentRect.size.height += NSHeight([[window contentView] frame]) - NSHeight([scrollView frame]);

    /* Get the desired window frame size */
    desiredFrame = [NSWindow frameRectForContentRect:contentRect styleMask:[window styleMask]];

    /* Set the origin based on window's current location */
    desiredFrame.origin.x = currentFrame.origin.x;
    desiredFrame.origin.y = NSMaxY(currentFrame) - NSHeight(desiredFrame);

    /* NSWindow will clip this rect to the actual available screen area */
    return desiredFrame;
}

@end

@implementation ManTextView

- (void)scrollRangeToTop:(NSRange)charRange
{
    NSLayoutManager *layout = [self layoutManager];
    NSRange glyphRange = [layout glyphRangeForCharacterRange:charRange actualCharacterRange:NULL];
    NSRect rect = [layout boundingRectForGlyphRange:glyphRange inTextContainer:[self textContainer]];
    CGFloat height = NSHeight([self visibleRect]);

    if (height > 0)
        rect.size.height = height;

    [self scrollRectToVisible:rect];
}

/* Make space page down (and shift/alt-space page up) */
- (void)keyDown:(NSEvent *)event
{
    if ([[event charactersIgnoringModifiers] isEqual:@" "])
    {
        if ([event modifierFlags] & (NSEventModifierFlagShift|NSEventModifierFlagOption))
            [self pageUp:self];
        else
            [self pageDown:self];
    }
    else
    {
        [super keyDown:event];
    }
}

/*
 * Draw page numbers when printing. Under early versions of MacOS X... the normal
 * NSString drawing methods don't work in the context of this method. So, I fell back on
 * CoreGraphics primitives, which did. However, I'm now just supporting Tiger (10.4) and up,
 * and it looks like the bugs have been fixed, so we can just use the higher-level
 * NSStringDrawing now, thankfully.
 */
- (void)drawPageBorderWithSize:(NSSize)size
{
    NSFont *font = [[NSUserDefaults standardUserDefaults] manFont];
    NSInteger currPage = [[NSPrintOperation currentOperation] currentPage];
    NSString *pageString = [NSString stringWithFormat:@"%d", (int)currPage];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    NSMutableDictionary *drawAttribs = [NSMutableDictionary dictionary];
    NSRect drawRect = NSMakeRect(0.0f, 0.0f, size.width, 20.0f + [font ascender]);

    [style setAlignment:NSTextAlignmentCenter];
    [drawAttribs setObject:style forKey:NSParagraphStyleAttributeName];
    [drawAttribs setObject:font forKey:NSFontAttributeName];

    [pageString drawInRect:drawRect withAttributes:drawAttribs];
    
//    CGFloat strWidth = [str sizeWithAttributes:attribs].width;
//    NSPoint point = NSMakePoint(size.width/2 - strWidth/2, 20.0f);
//    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
//
//    CGContextSaveGState(context);
//    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
//    CGContextSetTextDrawingMode(context, kCGTextFill);  //needed?
//    CGContextSetGrayFillColor(context, 0.0f, 1.0f);
//    CGContextSelectFont(context, [[font fontName] cStringUsingEncoding:NSMacOSRomanStringEncoding], [font pointSize], kCGEncodingMacRoman);
//    CGContextShowTextAtPoint(context, point.x, point.y, [str cStringUsingEncoding:NSMacOSRomanStringEncoding], [str lengthOfBytesUsingEncoding:NSMacOSRomanStringEncoding]);
//    CGContextRestoreGState(context);
}

@end
