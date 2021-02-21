
#import "SystemType.h"
#import <AppKit/AppKit.h>

@class NSMutableArray, NSMutableDictionary;
@class ManTextView;
@class NSTextField, NSText, NSButton, NSPopUpButton;

@interface ManDocument : NSDocument <NSWindowDelegate>
{
    NSData *taskData;
    BOOL hasLoaded;
    NSURL *copyURL;
    NSMutableArray *sections;
    NSMutableArray *sectionRanges;
    NSMutableDictionary *restoreData;

    IBOutlet ManTextView *textView;
    IBOutlet NSTextField *titleStringField;
    IBOutlet NSButton    *openSelectionButton;
    IBOutlet NSPopUpButton *sectionPopup;
}

- (instancetype)initWithName:(NSString *)name section:(NSString *)section manPath:(NSString *)manPath title:(NSString *)title;

@property(nonatomic,retain) NSString *shortTitle;

- (NSText *)textView;

- (void)loadCommand:(NSString *)command;

- (IBAction)saveCurrentWindowSize:(id)sender;
- (IBAction)openSelection:(id)sender;
- (IBAction)displaySection:(id)sender;
- (IBAction)copyURL:(id)sender;

@end
