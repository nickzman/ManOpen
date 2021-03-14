/* PrefPanelController.h created by lindberg on Fri 08-Oct-1999 */

#import <AppKit/AppKit.h>

@interface PrefPanelController : NSWindowController <NSFontChanging, NSMenuItemValidation>
{
    NSMutableArray *manPathArray;
    IBOutlet NSArrayController *manPathController;
    IBOutlet NSTableView *manPathTableView;
    IBOutlet NSTextField *fontField;
    IBOutlet NSMatrix *generalSwitchMatrix;
    IBOutlet NSPopUpButton *appPopup;
}

+ (id)sharedInstance;
+ (void)registerManDefaults;

- (IBAction)openFontPanel:(id)sender;

@end

@interface PrefPanelController (ManPath)
- (IBAction)addPathFromPanel:(id)sender;
@end
@interface PrefPanelController (DefaultManApp)
- (IBAction)chooseNewApp:(id)sender;
@end

@interface NSUserDefaults (ManOpenPreferences)
- (NSFont *)manFont;
- (NSString *)manPath;
- (NSColor *)manTextColor;
- (NSColor *)manLinkColor;
- (NSColor *)manBackgroundColor;
@end

// This needs to be in the header so IB can find it
@interface DisplayPathFormatter : NSFormatter
@end

@interface ManOpenColorDataTransformer : NSValueTransformer
@end
