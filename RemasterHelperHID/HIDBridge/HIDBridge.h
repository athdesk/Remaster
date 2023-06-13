//
//  HIDBridge.h
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 13/06/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ DeviceActionBlock)(const char*, int);

@interface HIDBridge : NSObject

/// Monitor
// TODO: figure out why it only works once
- (void)bringup;
- (void)setDeviceAddedHandler:(DeviceActionBlock)delegate;
- (void)setDeviceRemovedHandler:(DeviceActionBlock)delegate;

@end

NS_ASSUME_NONNULL_END
