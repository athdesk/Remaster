//
//  BridgeMonitor.m
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 13/06/23.
//

#import <Foundation/Foundation.h>
#import "BridgeMonitor.h"

void BridgeMonitor::setAddHandler(DeviceActionBlock delegate) {
    addHandler = delegate;
}

void BridgeMonitor::setRemoveHandler(DeviceActionBlock delegate) {
    removeHandler = delegate;
}

void BridgeMonitor::removeDevice (const char *path) {
    if (removeHandler != NULL) {
        removeHandler(path, 0);
    }
}

// all this code just makes sure that only hidpp devices are passed through to the handler
void BridgeMonitor::addDevice (const char *path)
{
    try {
        HIDPP::SimpleDispatcher dispatcher (path);
        bool has_receiver_index = false;
        for (HIDPP::DeviceIndex index: {
                HIDPP::DefaultDevice,
                HIDPP::CordedDevice,
                HIDPP::WirelessDevice1,
                HIDPP::WirelessDevice2,
                HIDPP::WirelessDevice3,
                HIDPP::WirelessDevice4,
                HIDPP::WirelessDevice5,
                HIDPP::WirelessDevice6 }) {
            if (!has_receiver_index && index == HIDPP::WirelessDevice1)
                break;
            try {
                HIDPP::Device dev (&dispatcher, index);
                auto version = dev.protocolVersion ();
                if (index == HIDPP::DefaultDevice && version == std::make_tuple (1, 0))
                    has_receiver_index = true;
                if (addHandler != NULL) {
                    addHandler(path, index);
                }
            }
            catch (HIDPP10::Error &e) {
                if (e.errorCode () != HIDPP10::Error::UnknownDevice && e.errorCode () != HIDPP10::Error::InvalidSubID) {
                    Log::error ().printf ("Error while querying %s wireless device %d: %s\n",
                                  path, index, e.what ());
                }
            }
            catch (HIDPP20::Error &e) {
                if (e.errorCode () != HIDPP20::Error::UnknownDevice) {
                    Log::error ().printf ("Error while querying %s device %d: %s\n",
                                  path, index, e.what ());
                }
            }
            catch (HIDPP::Dispatcher::TimeoutError &e) {
                Log::warning ().printf ("Device %s (index %d) timed out\n",
                            path, index);
            }
        }

    }
    catch (HIDPP::Dispatcher::NoHIDPPReportException &e) {
    }
    catch (std::system_error &e) {
        Log::warning ().printf ("Failed to open %s: %s\n", path, e.what ());
    }
}
