////
////  ReportDescriptor.swift
////  RemasterHelperHID
////
////  Created by Mario Del Gaudio on 16/06/23.
////
//
//// Maybe it was worth to use something by https://github.com/pqrs-org/, if c++ wasn't a pain to use with swift
//
//// FML i can read this from IORegistry i'm a noob
//
//import Foundation
//
//protocol ItemTag : RawRepresentable where RawValue == UInt8 { }
//
//struct RDItem {
//    enum TagType : Equatable {
//        case Main(_ tag: MainItem)
//        case Global(_ tag: GlobalItem)
//        case Local(_ tag: LocalItem)
//        case Long(_ tag: LongItem)
//
//        static func ==(lhs: TagType, rhs: some ItemTag) -> Bool {
//            switch lhs {
//            case .Main(_):
//                return rhs.self is MainItem
//            case .Global(_):
//                return rhs is GlobalItem
//            case .Local(_):
//                return rhs is LocalItem
//            case .Long(_):
//                return rhs is LongItem
//            }
//        }
//
//        // Suitable only for not long reports
//        init?(withByte b: UInt8) {
//            let typeRaw = (b & 0x0C) >> 2
//            let tagRaw = b >> 4
//            switch typeRaw {
//            case 0:
//                guard let t = MainItem(rawValue: tagRaw) else { return nil }
//                self = TagType.Main(t)
//            case 1:
//                guard let t = GlobalItem(rawValue: tagRaw) else { return nil }
//                self = TagType.Global(t)
//            case 2:
//                guard let t = LocalItem(rawValue: tagRaw) else { return nil }
//                self = TagType.Local(t)
//            default: abort()
//            }
//        }
//    }
//
//    enum MainItem: UInt8, ItemTag {
//        case Input = 8
//        case Output = 9
//        case Feature = 11
//        case Collection = 10
//        case EndCollection = 12
//    }
//
//    enum GlobalItem: UInt8, ItemTag {
//        case UsagePage = 0
//        case ReportSize = 7
//        case ReportID = 8
//        case ReportCount = 9
//        case Push = 10
//        case Pop = 11
//    }
//
//    enum LocalItem: UInt8, ItemTag {
//        case Usage = 0
//        case UsageMinimum = 1
//        case UsageMaximum = 2
//        case Delimiter = 10
//    }
//
//    typealias LongItem = UInt8
//
//
//    let type: TagType
//    let content: [UInt8]
//
//    init?(withData d: Data){
//        if (d.byteAt(0) == 0xFE) { // Long record, not implemented
//            if d.count < 2 { return nil }
//            if d.count < d.byteAt(1) + 3 { return nil }
//
//            let size = d.byteAt(1)
//            self.type = .Long(d.byteAt(2))
//            guard let dx = d.sliceAt(3, 3 + size) else { return nil }
//            self.content = dx
//            print("I'm scared")
//        } else {
//            let size = 1 << (d.byteAt(0) & 0x03)
//            guard let tx: TagType = .init(withByte: d.byteAt(0)) else { return nil }
//            self.type = tx
//            guard let dx = d.sliceAt(1, 1 + size) else { return nil }
//            self.content = dx
//        }
//    }
//}
//
//struct RDUsage {
//    let page: UInt16
//    let usage: UInt16
//
//    init(from32 val: UInt32) {
//        page = UInt16(val >> 16)
//        usage = UInt16(val & 0xffff)
//    }
//}
//
//struct RDReport {
//    struct Field {
//        struct Flags {
//            let Data: Bool
//            let Array: Bool
//            let Absolute: Bool
//            let Wrap: Bool
//            let Linear: Bool
//            let Preferred: Bool
//            let NullState: Bool
//            let Volatile: Bool
//            let BitField: Bool
//            let BufferedBytes: Bool
//            // do initWithBits
//        }
//        let Count: UInt
//        let Size: UInt
//        let UsageRange: (RDUsage, RDUsage)
//    }
//
//    let id: RDItem.MainItem
//    let field: Field
//}
//
//struct ReportDescriptor {
//    struct Collection {
//        enum CType : Int {
//            case Physical = 0
//            case Application = 1
//            case Logical = 2
//            case Report = 3
//            case NamedArray = 4
//            case UsageSwitch = 5
//            case UsageModifier = 6
//        }
//
//        let type: CType
//        let usage: RDUsage
//        let reports: [RDReport]
//    }
//
//
//
//    let Collections: [Collection]
//
//    init?(fromData: Data) {
//        var wData = fromData
//        func nextItem() -> RDItem? {
//            guard let i = RDItem(withData: wData) else { return nil }
//            var l = false
//            if case .Long(_) = i.type { l = true } // wtf is this syntax
//            let iSize = i.content.count + (l ? 3 : 1)
//            wData = wData.advanced(by: iSize)
//            return i
//        }
//        while wData.count > 0 {
//            guard let currentItem = nextItem() else { return nil }
//
//            switch currentItem.type {
//            case .Main(let tag):
//                switch tag {
//                case .Input: fallthrough
//                case .Output: fallthrough
//                case .Feature: break
////                    RDReport(id: tag, )
//                case .Collection:
//                    <#code#>
//                case .EndCollection:
//                    <#code#>
//                }
//            case .Global: break
//            case .Local: break
//            case .Long: break
//            }
//        }
//        return nil
//    }
//}
//
//extension Data {
//    private var cursor: UInt  { 0 }
//    private var left: UInt { UInt(self.count) }
////    mutating func advance<I:BinaryInteger>(_ n: I) {
////        self = self.suffix(from: Int(n))
////    }
//
//    func byteAt<I:BinaryInteger>(_ n: I) -> UInt8 {
//        if left > 0 {
//            return self[Int(cursor + UInt(n))]
//        } else {
//            return 0x00
//        }
//    }
//
//    func sliceAt<I:BinaryInteger>(_ l: I, _ u: I) -> [UInt8]? {
//        let boundLo = Int(l + I(cursor))
//        let boundUp = Int(u + I(cursor))
//
//        if left < boundUp { return nil }
//        return .init(self[boundLo..<boundUp])
//    }
//}
