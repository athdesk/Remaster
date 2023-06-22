//
//  Receiver.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 22/06/23.
//

import Foundation



enum ReceiverType : CaseIterable {
    case Bolt
    case Unifying
    
    func getDriver() -> (any Receiver.Type) {
        switch self {
        case .Bolt:
            return BoltReceiver.self
        case .Unifying:
            return UnifyingReceiver.self
        }
    }
}

protocol Receiver {
    var type: ReceiverType { get }
    var Serial: String { get }
    
    init?(withHIDDevice d: HIDDevice)
}

class UnifyingReceiver : Receiver {
    let backingDevice: HIDPP.Device
    let type = ReceiverType.Bolt
    
    var Serial: String { abort() }
    
    required init?(withHIDDevice d: HIDDevice) {
        guard let dev = HIDPP.Device(dev: d, devIndex: 0xff) else { return nil }
        self.backingDevice = dev
    }
}
    
class BoltReceiver : Receiver {
    typealias Proto = HIDPP.v10
    let type = ReceiverType.Bolt
    let backingDevice: HIDPP.Device
    
    lazy var Serial: String = {
        let r = Proto.Register.BoltUID.Read(onDevice: backingDevice)
        guard let p = r?.parameters else { return "Unknown" }
        return String(bytes: p, encoding: .utf8) ?? "Unknown"
    }()
    
    required init?(withHIDDevice d: HIDDevice) {
        guard let dev = HIDPP.Device(dev: d, devIndex: 0xff) else { return nil }
        self.backingDevice = dev
    }
}
