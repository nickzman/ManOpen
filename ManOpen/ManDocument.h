
#import "SystemType.h"
#import <AppKit/AppKit.h>

@class NSMutableArray, NSMutableDictionary;
@class ManTextView;
@class NSTextField, NSText, NSButton, NSPopUpButton;

@interface ManDocument : NSDocument <NSMenuDelegate, NSToolbarDelegate, NSWindowDelegate>
{
    NSData *taskData;
    BOOL hasLoaded;
    NSURL *copyURL;
    NSMutableArray<NSString *> *sections;
    NSMutableArray<NSValue *> *sectionRanges;
    NSMutableDictionary *restoreData;
}

- (instancetype)initWithName:(NSString *)name section:(NSString *)section manPath:(NSString *)manPath title:(NSString *)title;

@property(nonatomic,retain) NSString *shortTitle;

@property(nonatomic,retain) IBOutlet ManTextView *textView;

- (void)loadCommand:(NSString *)command;

- (IBAction)saveCurrentWindowSize:(id)sender;
- (IBAction)openSelection:(id)sender;
- (IBAction)displaySection:(id)sender;
- (IBAction)copyURL:(id)sender;

@end
