
#import <Foundation/NSData.h>

@interface NSData (Utils)

@property(nonatomic,readonly,getter=isNroffData) BOOL nroffData;
@property(nonatomic,readonly,getter=isRTFData) BOOL RTFData;
@property(nonatomic,readonly,getter=isGzipData) BOOL gzipData;
@property(nonatomic,readonly,getter=isBinaryData) BOOL binaryData;

@end

#import <Foundation/NSFileHandle.h>

@interface NSFileHandle (Utils)

- (NSData *)readDataToEndOfFileIgnoreInterrupt;

@end

