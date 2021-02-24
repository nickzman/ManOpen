//
//  ManWindowController.h
//  ManOpen (Application)
//
//  Created by Nick Zitzmann on 2/23/21.
//

#import <Cocoa/Cocoa.h>

@interface ManTextView : NSTextView
- (void)scrollRangeToTop:(NSRange)charRange;
@end

NS_ASSUME_NONNULL_BEGIN

@interface ManWindowController : NSWindowController <NSMenuDelegate, NSTextViewDelegate, NSToolbarDelegate, NSWindowDelegate>
@property(nonatomic,retain) IBOutlet ManTextView *textView;

- (IBAction)saveCurrentWindowSize:(id)sender;
- (IBAction)openSelection:(id)sender;
- (IBAction)displaySection:(id)sender;
- (IBAction)copyURL:(id)sender;
@end

NS_ASSUME_NONNULL_END
