//
//  MxHIDDevice.m
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 13/06/23.
//

#import "MxHIDDevice.h"

#import "hidpp/Device.h"
#import "hidpp/SimpleDispatcher.h"
#import "hidpp20/Error.h"
#import "hidpp20/IAdjustableDPI.h"

@implementation MxHIDDevice

static HIDPP20::Device* internalDevice;

- (BOOL)initializeWithDevpath:(NSString*)devpath index:(int)index {
    
    auto pathCStr = [devpath UTF8String];
    
    try {
        HIDPP::SimpleDispatcher *d = new HIDPP::SimpleDispatcher(pathCStr);
        auto dev = HIDPP::Device(d, (HIDPP::DeviceIndex)index);
        internalDevice = new HIDPP20::Device(std::move(dev));
    } catch (HIDPP20::Error &e) {
        delete internalDevice->dispatcher();
        delete internalDevice;
        return false;
    }
    return true;
}

- (void)dealloc {
    if (internalDevice->dispatcher() != NULL) delete internalDevice->dispatcher();
    if (internalDevice != NULL) delete internalDevice;
}

/// DPI

- (unsigned int)getDPI {
    HIDPP20::IAdjustableDPI dpi = HIDPP20::IAdjustableDPI(internalDevice);
    unsigned int val = 0;
    std::tie(val, std::ignore) = dpi.getSensorDPI(0);
    return val;
}

- (void)setDPI:(unsigned int)val {
    try {
        HIDPP20::IAdjustableDPI dpi = HIDPP20::IAdjustableDPI(internalDevice);
        dpi.setSensorDPI(0, val);
    } catch (HIDPP20::Error e) {
        printf("Could not set DPI\n");
    }
}

@end
