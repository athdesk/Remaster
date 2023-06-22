//
//  Event.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 18/06/23.
//

import Foundation

extension HIDPP {
    enum EType : TextOutputStreamable {
        func write<Target>(to target: inout Target) where Target : TextOutputStream {
            switch self {
            case .Device20(let arg):
                target.write("Device20[\(arg)]")
            case .Device10(let arg):
                target.write("Device10[\(arg)]")
            }
        }
        
        case Device20(UInt8)
        case Device10(UInt8)
        
        init?(fromReport r: CustomReport) {
            let fIndex = r.subID
            if fIndex == 0x00 {
                return nil
            } else if fIndex < 0x40 { // 2.0
                let e = Self.Device20(fIndex)
                self = e
            } else if fIndex < 0x80 { // 1.0 (Receivers)
                let e = Self.Device10(fIndex)
                self = e
            } else { // Not an event
                return nil
            }
            
        }
    }
}

typealias EventCallback = (Notification) -> (Void)

extension HIDPP.Device {
    class EventNotifier: Equatable  {
        private let basename: Notification.Name
        private let observer: NSObjectProtocol
        
        static func == (lhs: HIDPP.Device.EventNotifier, rhs: HIDPP.Device.EventNotifier) -> Bool {
            return lhs.observer === rhs.observer
        }

        func newObserver(forSubID i: HIDPP.v10.SubID, using block: @escaping EventCallback) -> NSObjectProtocol {
            let t = HIDPP.EType.Device10(i.rawValue)
            print("Adding observer for index \(i)")
            return newObserver(forType: t, using: block)
        }
        
        func newObserver(forIndex i: FeatureIndex, using block: @escaping EventCallback) -> NSObjectProtocol {
            let t = HIDPP.EType.Device20(i.rawValue)
            print("Adding observer for index \(i)")
            return newObserver(forType: t, using: block)
        }
        
        func newObserver(forType t: HIDPP.EType, using block: @escaping EventCallback) -> NSObjectProtocol {
            NotificationCenter.default.addObserver(forName: HIDPP.Device.EventNotifier.name(forType: t, forBaseName: basename),
                                                   object: nil,
                                                   queue: nil, using: block)
        }
        
        private static func name(forType t: HIDPP.EType, forBaseName baseName: Notification.Name) -> Notification.Name {
            return Notification.Name("\(baseName.rawValue)@\(t)")
        }

        
        private let notificationHandler: (Notification) -> ()
        
        init(forHID hid: HIDDevice, forIndex i: UInt8) {
            // random slug added to avoid double notifications when both mice and receivers register events on the same physical hid device
            let slug = "-" + String(describing: arc4random())
            
            notificationHandler = { n in
                DispatchQueue.global().async {
                    let recv = n.object as! HIDDevice.Report
                    let ppReport = HIDPP.CustomReport(withData: recv.reportData)
                    // TODO: make this not suck ( 255 catches all, for receivers )
                    if i != 255 { guard ppReport.deviceIndex == i else { return } }
                    guard let type = HIDPP.EType(fromReport: ppReport) else {
                        return
                    }
                    NotificationCenter.default.post(name: EventNotifier.name(forType: type, forBaseName: Notification.Name(hid.notificationNameExtra.rawValue + slug)), object: ppReport)
                }
            }
            
            
            basename = Notification.Name(hid.notificationNameExtra.rawValue + slug)
            observer = NotificationCenter.default.addObserver(forName: hid.notificationNameExtra,
                                                                   object: nil,
                                                                   queue: nil,
                                                                   using: notificationHandler)
        }
        
        deinit {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
}
