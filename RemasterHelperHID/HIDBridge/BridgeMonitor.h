//
//  BridgeMonitor.h
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 13/06/23.
//

#ifndef BridgeMonitor_h
#define BridgeMonitor_h

#import "misc/Log.h"
#import "hid/DeviceMonitor.h"
#import "hidpp/SimpleDispatcher.h"
#import "hidpp/Device.h"
#import "hidpp10/Error.h"
#import "hidpp20/Error.h"

// TODO: unify this in a common header
typedef void (^ DeviceActionBlock)(const char*, int);

class BridgeMonitor : public HID::DeviceMonitor {
private:
    DeviceActionBlock addHandler;
    DeviceActionBlock removeHandler;
protected:
    void removeDevice(const char *path);
    void addDevice(const char *path);
public:
    void setAddHandler(DeviceActionBlock delegate);
    void setRemoveHandler(DeviceActionBlock delegate);
};

#endif /* BridgeMonitor_h */
