
#import "SystemType.h"
#import <Cocoa/Cocoa.h>

@interface ManDocument : NSDocument

- (instancetype)initWithName:(NSString *)name section:(NSString *)section manPath:(NSString *)manPath title:(NSString *)title;

@property(nonatomic,retain) NSString *shortTitle;
@property(nonatomic,retain) NSData *taskData;
@property(nonatomic,assign) BOOL hasLoaded;
@property(nonatomic,retain) NSURL *xManPageURL;
@property(nonatomic,retain) NSMutableArray<NSString *> *sections;
@property(nonatomic,retain) NSMutableArray<NSValue *> *sectionRanges;
@property(nonatomic,retain) NSMutableDictionary<NSString *, NSString *> *restoreData;

- (void)loadCommand:(NSString *)command;

- (void)showData;

@end
