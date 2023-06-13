//
//  HIDBridge.m
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 13/06/23.
//

#import "HIDBridge.h"
#import "BridgeMonitor.h"

@implementation HIDBridge

static BridgeMonitor* monitor;

+ (void)initialize {
    monitor = new BridgeMonitor();
}

- (void)bringup {
    monitor->run();
}

- (void)setDeviceAddedHandler:(DeviceActionBlock)delegate {
    monitor->setAddHandler(delegate);
}

- (void)setDeviceRemovedHandler:(DeviceActionBlock)delegate {
    monitor->setRemoveHandler(delegate);
}
   
@end

