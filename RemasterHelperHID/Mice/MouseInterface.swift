//
//  MouseInterface.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 15/06/23.
//

import Foundation
import Combine

// Class for interfacing with #.*.*.# a mouse #.*.*.# :)
//
// the `mainMouse` should always try to represent a connected mouse
// this means that it's going to be mutating without telling anyone
// (or maybe send a notification, but it's better for most of the
//      data to not be targeted at one specific device)
// Also, devices are expected to disconnect/reconnect at random,
//      especially for Bluetooth, so we might need to be a bit
//      clever in the way we reapply settings etc.

protocol Mouse : AnyObject, ObservableObject, Identifiable {
    var name: String { get }
    var transport: TransportType { get }
    var thumbnailName: String { get }
    var hid: HIDDevice { get }
    var index: UInt8 { get }
    
    var Ratchet: Bool? { get set }
    var SmartShift: UInt? { get set }
    var WheelInvert: Bool? { get set }
    var WheelHiRes: Bool? { get set }
    var WheelDiversion: Bool? { get set }
    
    var Battery: Battery? { get }
    
    var DPI: UInt { get set }
    var SupportedDPI: DPISupport { get }
    
    func refreshData()
    
    init?(withHIDDevice d: HIDDevice, index i: UInt8)
}

extension Mouse {
    func onUpdate(_ clause: @escaping () -> () ) -> AnyCancellable? {
        return objectWillChange.sink { _ in clause() }
    }
}

// Since actors don't support inheritance I guess we'll try and keep it clean manually, by using Mouse-conforming classes only here
// Also this gives the chance to refactor the Mouse protocol more easily

actor MouseInterface : ObservableObject, Hashable {
    static func == (lhs: MouseInterface, rhs: MouseInterface) -> Bool {
        lhs.hid == rhs.hid && lhs.index == rhs.index
    }
    
    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(hid)
        hasher.combine(index)
    }
    
    private let mouse: any Mouse
    private var mouseSink: AnyCancellable? = nil
    
    nonisolated let name: String
    nonisolated let transport: TransportType
    nonisolated let thumbnailName: String
    nonisolated let hid: HIDDevice
    nonisolated let index: UInt8
    
    nonisolated let SupportedDPI: DPISupport
    nonisolated var Battery: Battery? { mouse.Battery }
    
    nonisolated var Ratchet: Bool? { mouse.Ratchet }
    nonisolated var SmartShift: UInt? { mouse.SmartShift }
    nonisolated var WheelInvert: Bool? { mouse.WheelInvert }
    nonisolated var WheelHiRes: Bool? { mouse.WheelHiRes }
    nonisolated var WheelDiversion: Bool? { mouse.WheelDiversion }
    nonisolated var DPI: UInt { mouse.DPI }
    
    func toggleRatchet() { mouse.Ratchet?.toggle() }
    func toggleWheelInvert() { mouse.WheelInvert?.toggle() }
    func toggleWheelHiRes() { mouse.WheelHiRes?.toggle() }
    
    func setDPI(_ n: UInt) { mouse.DPI = n }
    func setSmartShift(_ n: UInt) { mouse.SmartShift = n }
    
    func refreshData() {
        mouse.refreshData()
    }
    
    nonisolated func onUpdate(_ clause: @escaping () -> () ) -> AnyCancellable? {
        return objectWillChange.sink { _ in clause() }
    }
    
    private func setSink(_ sink: AnyCancellable?) {mouseSink = sink}
    init?(driver: any Mouse.Type, device: HIDDevice, index: UInt8) {
        guard let m = driver.init(withHIDDevice: device, index: index) else { return nil }
        mouse = m
        name = mouse.name
        hid = mouse.hid
        self.index = mouse.index
        transport = mouse.transport
        thumbnailName = mouse.thumbnailName
        SupportedDPI = mouse.SupportedDPI

        Task {
            let sink = m.onUpdate { self.objectWillChange.send() }
            await setSink(sink)
            await refreshData()
        }
    }
}

class MouseTracker : ObservableObject {
    @MainActor @Published private(set) var mice: [MouseInterface] = []
    @MainActor @Published private(set) var receivers: [Receiver] = []
    
    @MainActor var mainMouse: MouseInterface? { mice.first }
    var sinks: [MouseInterface:AnyCancellable?] = [:] //TODO: change to dict
    
    @MainActor private func notifyChange() async {
        await MainActor.run { self.objectWillChange.send() }
    }
    
    @MainActor func addMouse(_ m: MouseInterface) {
        mice.append(m)
        sinks[m] = (m.onUpdate { Task { await self.notifyChange() }})
    }
    @MainActor func addReceiver(_ r: Receiver) { receivers.append(r) }
    
    @MainActor func removeMouse(withHid hid: HIDDevice, index: UInt8) {
        mice.removeAll { m in
            m.hid == hid && m.index == index
        }
    }
    
    @MainActor func removeReceiver(withHid hid: HIDDevice) {
        receivers.removeAll { r in
            r.hid == hid
        }
    }
    
    // This is not marked MainActor for performance reasons
    private func deviceConnectedHandler(_ n: Notification) async {
        let device = n.object as! HIDDevice
        guard let deviceDescriptor = RemasterDevice(fromMonitorData: device.idPair) else { return }
        if case .Receiver(let type) = deviceDescriptor {
            if let receiver = type.getDriver().init(withHIDDevice: device) {
                print("Receiver: \(receiver.Serial)")
                await addReceiver(receiver)
            }
        } else {
            guard let driver = deviceDescriptor.getDriver() else { return }
            guard let iMouse = MouseInterface(driver: driver, device: device, index: 0xff) else { return }
            print("Device \(iMouse.name) is here!")
            await addMouse(iMouse)
        }
    }
    
    private func deviceDisconnectedHandler(_ n: Notification) async {
        let device = n.object as! HIDDevice
        await MainActor.run { mice.removeAll { m in m.hid == device } }
        await MainActor.run { receivers.removeAll { r in r.hid == device } }
    }
    
    
    static let global: MouseTracker = MouseTracker()
    
    private init() {
        
        Task {
            let i = NotificationCenter.default.notifications(named: .HIDDeviceConnected).makeAsyncIterator()
            while let n = await i.next() {
                await self.deviceConnectedHandler(n)
            }
        }
        Task {
            let i = NotificationCenter.default.notifications(named: .HIDDeviceDisconnected).makeAsyncIterator()
            while let n = await i.next() {
                await self.deviceDisconnectedHandler(n)
            }
        }
    }
}
