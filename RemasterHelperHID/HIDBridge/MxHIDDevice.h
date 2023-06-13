//
//  MxHIDDevice.h
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 13/06/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MxHIDDevice : NSObject

- (BOOL)initializeWithDevpath:(NSString*)devpath index:(int)index;


/// DPI
- (void)setDPI:(unsigned int)val;
- (unsigned int)getDPI;

@end

NS_ASSUME_NONNULL_END
