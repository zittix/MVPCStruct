//
//  CStruct.swift
//  MVPCStruct
//
//  Created by Per Olofsson on 2014-06-13.
//  Copyright (c) 2014 AutoMac. All rights reserved.
//

import Foundation

//      BYTE ORDER      SIZE            ALIGNMENT
//  @   native          native          native
//  =   native          standard        none
//  <   little-endian   standard        none
//  >   big-endian      standard        none
//  !   network (BE)    standard        none


//      FORMAT  C TYPE                  SWIFT TYPE              SIZE
//      x       pad byte                no value
//      c       char                    String of length 1      1
//      b       signed char             Int                     1
//      B       unsigned char           UInt                    1
//      ?       _Bool                   Bool                    1
//      h       short                   Int                     2
//      H       unsigned short          UInt                    2
//      i       int                     Int                     4
//      I       unsigned int            UInt                    4
//      l       long                    Int                     4
//      L       unsigned long           UInt                    4
//      q       long long               Int                     8
//      Q       unsigned long long      UInt                    8
//      f       float                   Float                   4
//      d       double                  Double                  8
//      s       char[]                  String
//      p       char[]                  String
//      P       void *                  UInt                    4/8
//
//      Floats and doubles are packed with IEEE 754 binary32 or binary64 format.


// Split a large integer into bytes.
extension Int {
    func splitBytes(_ endianness: CStruct.Endianness, size: Int) -> [UInt8] {
        var bytes = [UInt8]()
        var shift: Int
        var step: Int
        if endianness == .littleEndian {
            shift = 0
            step = 8
        } else {
            shift = (size - 1) * 8
            step = -8
        }
        for _ in 0..<size {
            bytes.append(UInt8((self >> shift) & 0xff))
            shift += step
        }
        return bytes
    }
}
extension UInt {
    func splitBytes(_ endianness: CStruct.Endianness, size: Int) -> [UInt8] {
        var bytes = [UInt8]()
        var shift: Int
        var step: Int
        if endianness == .littleEndian {
            shift = 0
            step = 8
        } else {
            shift = Int((size - 1) * 8)
            step = -8
        }
        for _ in 0..<size {
            bytes.append(UInt8((self >> UInt(shift)) & 0xff))
            shift = shift + step
        }
        return bytes
    }
}


open class CStruct {
	
	
	
    public enum ErrorCStruct: Error {
        case parsing(reason: String)
        case packing(reason: String)
		case unpacking(reason: String)
    }
	
    enum Endianness {
        case littleEndian
        case bigEndian
    }
    
    // Packing format strings are parsed to a stream of ops.
    enum Ops {
        // Stop packing.
        case stop
        
        // Control endianness.
        case setNativeEndian
        case setLittleEndian
        case setBigEndian
        
        // Control alignment.
        case setAlign
        case unsetAlign
        
        // Pad bytes.
        case skipByte
        
        // Packed values.
        case packChar
        case packInt8
        case packUInt8
        case packBool
        case packInt16
        case packUInt16
        case packInt32
        case packUInt32
        case packInt64
        case packUInt64
        case packFloat
        case packDouble
        case packCString
        case packPString
        case packPointer
    }
    
    var opStream = [Ops]()
    
    let bytesForValue = [
        Ops.skipByte:       1,
        Ops.packChar:       1,
        Ops.packInt8:       1,
        Ops.packUInt8:      1,
        Ops.packBool:       1,
        Ops.packInt16:      2,
        Ops.packUInt16:     2,
        Ops.packInt32:      4,
        Ops.packUInt32:     4,
        Ops.packInt64:      8,
        Ops.packUInt64:     8,
        Ops.packFloat:      4,
        Ops.packDouble:     8,
        Ops.packPointer:    MemoryLayout<UnsafePointer<UInt>>.size,
    ]
    
    let PAD_BYTE = UInt8(0)
    
    var platformEndianness: Endianness {
    return .littleEndian
    }
    
    public convenience init(format: String) throws {
        self.init()
		
		try self.parseFormat(format)
    }
    
    
    // Unpacking.
    
    open func unpack(_ data: Data, format: String) throws -> [Any] {
        try self.parseFormat(format)
        return try self.unpack(data)
    }

    open func unpack(_ data: Data) throws -> [Any] {
        var values = [Any]()
        var index = 0
        var alignment = true
        var endianness = self.platformEndianness

        
        // If alignment is requested, skip pad bytes until alignment is
        // satisfied.
        func skipAlignment(_ size: Int) {
            if alignment {
                let mask = size - 1
                while (index & mask) != 0 {
                    index += 1
                }
            }
        }
        
        // Read UInt8 values from data.
        func readBytes(_ count: Int) -> [UInt8]? {
            var bytes = [UInt8]()
            if index + count > data.count {
                return nil
            }
            let ptr = (data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count)
            let unsafeBytes = UnsafeBufferPointer<UInt8>(start:ptr + index, count:count)
            index += count
            for byte in unsafeBytes {
                bytes.append(byte)
            }
            return bytes
        }
        
        // Create integer from bytes.
        func intFromBytes(_ bytes: [UInt8]) -> Int {
            var i: Int = 0
            for byte in endianness == .littleEndian ? Array(bytes.reversed()) : bytes {
                i <<= 8
                i |= Int(byte)
            }
            return i
        }
        func uintFromBytes(_ bytes: [UInt8]) -> UInt {
            var i: UInt = 0
            for byte in endianness == .littleEndian ? Array(bytes.reversed()) : bytes {
                i <<= 8
                i |= UInt(byte)
            }
            return i
        }
        
        //var psize = sizeof(Int32)
        
        for op in self.opStream {
            // First check ops that don't consume data.
            switch op {
                
            case .stop:
                return values
                
            case .setNativeEndian:
                endianness = self.platformEndianness
            case .setLittleEndian:
                endianness = .littleEndian
            case .setBigEndian:
                endianness = .bigEndian
                
            case .setAlign:
                alignment = true
            case .unsetAlign:
                alignment = false
                
            case .packCString, .packPString:
                assert(false, "cstring/pstring unimplemented")
                
            case .skipByte:
                if let _ = readBytes(1) {
                    // Discard.
                } else {
                    throw ErrorCStruct.unpacking(reason: "not enough data for format")
                }
            default:
                let bytesToUnpack = bytesForValue[op]!
                if let bytes = readBytes(bytesToUnpack) {
                    
                    switch op {
                    
                    case .skipByte:
                        break
                    
                    case .packChar:
                        values.append(NSString(format: "%c", bytes[0]))
                        
                    case .packInt8:
                        values.append(Int(bytes[0]) as Any)
                        
                    case .packUInt8:
                        values.append(UInt(bytes[0]) as Any)
                        
                    case .packBool:
                        if bytes[0] == UInt8(0) {
                            values.append(false as Any)
                        } else {
                            values.append(true as Any)
                        }
                        
                    case .packInt16, .packInt32, .packInt64:
                        values.append(intFromBytes(bytes) as Any)
                        
                    case .packUInt16, .packUInt32, .packUInt64, .packPointer:
                        values.append(uintFromBytes(bytes) as Any)
                        
                    case .packFloat, .packDouble:
                        assert(false, "float/double unimplemented")
                        
                    case .packCString, .packPString:
                        assert(false, "cstring/pstring unimplemented")
                        
                    default:
                        assert(false, "bad op in stream")
                    }
                    
                } else {
                    throw ErrorCStruct.unpacking(reason: "not enough data for format")
                }
            }
            
        }
        
        return values
    }
    
    
    // Packing.
    
    open func pack(_ values: [Any], format: String) throws -> Data {
        try self.parseFormat(format)
        return try self.pack(values)
    }
    
    open func pack(_ values: [Any]) throws -> Data {
        var bytes = [UInt8]()
        var index = 0
        var alignment = true
        var endianness = self.platformEndianness
		
        // If alignment is requested, emit pad bytes until alignment is
        // satisfied.
        func padAlignment(_ size: Int) {
            if alignment {
                let mask = size - 1
                while (bytes.count & mask) != 0 {
                    bytes.append(PAD_BYTE)
                }
            }
        }
        
        for op in self.opStream {
            // First check ops that don't consume values.
            switch op {
                
            case .stop:
                if index != values.count {
                    throw ErrorCStruct.packing(reason: "expected \(index) items for packing, got \(values.count)")
                } else {
                    return Data(bytes: UnsafePointer<UInt8>(bytes), count: bytes.count)
                }
                
            case .setNativeEndian:
                endianness = self.platformEndianness
            case .setLittleEndian:
                endianness = .littleEndian
            case .setBigEndian:
                endianness = .bigEndian
                
            case .setAlign:
                alignment = true
            case .unsetAlign:
                alignment = false
                
            case .skipByte:
                bytes.append(PAD_BYTE)
                
            default:
                // No control op found so pop the next value.
                if index >= values.count {
                    throw ErrorCStruct.packing(reason: "expected at least \(index) items for packing, got \(values.count)")
				}
				
                let rawValue: Any = values[index]
                index+=1
				
                switch op {
                    
                case .packChar:
                    if let str = rawValue as? String {
                        let utf16view = str.utf16
                        let codePoint = Int(utf16view[utf16view.startIndex])
                        if codePoint < 128 {
                            bytes.append(UInt8(codePoint))
                        } else {
                            throw ErrorCStruct.packing(reason: "char format requires String of length 1")
                        }
                    } else {
                        throw ErrorCStruct.packing(reason: "char format requires String of length 1")
                    }
                    
                case .packInt8:
                    if let value = rawValue as? Int {
                        if value >= -0x80 && value <= 0x7f {
                            bytes.append(UInt8(value & 0xff))
                        } else {
                            throw ErrorCStruct.packing(reason: "value outside valid range of Int8")
                        }
                    } else {
                        throw ErrorCStruct.packing(reason: "cannot convert argument to Int")
                    }
                    
                case .packUInt8:
                    if let value = rawValue as? UInt {
                        if value > 0xff {
                            throw ErrorCStruct.packing(reason: "value outside valid range of UInt8")
                        } else {
                            bytes.append(UInt8(value))
                        }
                    } else {
                        throw ErrorCStruct.packing(reason: "cannot convert argument to UInt")
                    }
                    
                case .packBool:
                    if let value = rawValue as? Bool {
                        if value {
                            bytes.append(UInt8(1))
                        } else {
                            bytes.append(UInt8(0))
                        }
                    } else {
                        throw ErrorCStruct.packing(reason: "cannot convert argument to Bool")
                    }
                    
                case .packInt16:
                    if let value = rawValue as? Int {
                        if value >= -0x8000 && value <= 0x7fff {
                            padAlignment(2)
                            bytes.append(contentsOf: value.splitBytes(endianness, size: 2))
                        } else {
                            throw ErrorCStruct.packing(reason: "value outside valid range of Int16")
                        }
                    } else {
                        throw ErrorCStruct.packing(reason: "cannot convert argument to Int")
                    }
                    
                case .packUInt16:
                    if let value = rawValue as? UInt {
                        if value > 0xffff {
                            throw ErrorCStruct.packing(reason: "value outside valid range of UInt16")
                        } else {
                            padAlignment(2)
                            bytes.append(contentsOf: value.splitBytes(endianness, size: 2))
                        }
                    } else {
                        throw ErrorCStruct.packing(reason: "cannot convert argument to UInt")
					}
                    
                case .packInt32:
                    if let value = rawValue as? Int {
                        if value >= -0x80000000 && value <= 0x7fffffff {
                            padAlignment(4)
                            bytes.append(contentsOf: value.splitBytes(endianness, size: 4))
                        } else {
                            throw ErrorCStruct.packing(reason: "value outside valid range of Int32")
                        }
                    } else {
                        throw ErrorCStruct.packing(reason: "cannot convert argument to Int")
                    }
                    
                case .packUInt32:
		    if let value = rawValue as? UInt {
		        padAlignment(4)
		        bytes.append(contentsOf: value.splitBytes(endianness, size: 4))
                    } else {
                        throw ErrorCStruct.packing(reason: "cannot convert argument to UInt")
                    }
                    
                case .packInt64:
                    if let value = rawValue as? Int {
                        padAlignment(8)
                        bytes.append(contentsOf: value.splitBytes(endianness, size: 8))
                    } else {
                        throw ErrorCStruct.packing(reason: "cannot convert argument to Int")
                    }
                    
                case .packUInt64:
                    if let value = rawValue as? UInt {
                        padAlignment(8)
                        bytes.append(contentsOf: value.splitBytes(endianness, size: 8))
                    } else {
                        throw ErrorCStruct.packing(reason: "cannot convert argument to UInt")
                    }
                    
                case .packFloat, .packDouble:
                    assert(false, "float/double unimplemented")
                    
                case .packCString, .packPString:
                    assert(false, "cstring/pstring unimplemented")
                    
                case .packPointer:
                    if let value = rawValue as? UInt {
                        padAlignment(MemoryLayout<UnsafePointer<UInt>>.size)
                        bytes.append(contentsOf: value.splitBytes(endianness, size: MemoryLayout<UnsafePointer<UInt>>.size))
                    } else {
                        throw ErrorCStruct.packing(reason: "cannot convert argument to UInt")
                    }
                    
                default:
                    assert(false, "bad op in stream")
                }
                
            }
            
        }
        
        // This is actually never reached, we exit from .Stop.
        return Data(bytes: UnsafePointer<UInt8>(bytes), count: bytes.count)
    }
    
    func parseFormat(_ format: String) throws {
        var repeatCount = 0
        
        opStream.removeAll(keepingCapacity: false)
        
        for c in format.characters {
            // First test if the format string contains an integer. In that case
            // we feed it into the repeat counter and go to the next character.
            if let value = Int(String(c)) {
                repeatCount = repeatCount * 10 + value
                continue
            }
            // The next step depends on if we've accumulated a repeat count.
            if repeatCount == 0 {
                
                // With a repeat count of 0 we check for control characters.
                switch c {
                    
                    // Control endianness.
                case "@":
                    opStream.append(.setNativeEndian)
                    opStream.append(.setAlign)
                case "=":
                    opStream.append(.setNativeEndian)
                    opStream.append(.unsetAlign)
                case "<":
                    opStream.append(.setLittleEndian)
                    opStream.append(.unsetAlign)
                case ">", "!":
                    opStream.append(.setBigEndian)
                    opStream.append(.unsetAlign)
                    
                case " ":
                    // Whitespace is allowed between formats.
                    break
                    
                default:
                    // No control character found so set the repeat count to 1
                    // and evaluate format characters.
                    repeatCount = 1
                }
            }
            
            // If we have a repeat count we expect a format character.
            if repeatCount > 0 {
                // Add one op for each repeat count.
                for _ in 0..<repeatCount {
                    switch c {
                    case "x":       opStream.append(.skipByte)
                    case "c":       opStream.append(.packChar)
                    case "?":       opStream.append(.packBool)
                    case "b":       opStream.append(.packInt8)
                    case "B":       opStream.append(.packUInt8)
                    case "h":       opStream.append(.packInt16)
                    case "H":       opStream.append(.packUInt16)
                    case "i", "l":  opStream.append(.packInt32)
                    case "I", "L":  opStream.append(.packUInt32)
                    case "q":       opStream.append(.packInt64)
                    case "Q":       opStream.append(.packUInt64)
                    case "f":       opStream.append(.packFloat)
                    case "d":       opStream.append(.packDouble)
                    case "s":       opStream.append(.packCString)
                    case "p":       opStream.append(.packPString)
                    case "P":       opStream.append(.packPointer)
                    default:
						throw ErrorCStruct.parsing(reason: "bad character in format: \(c)")
                    }
                }
            }
            // Reset the repeat counter.
            repeatCount = 0
        }
        opStream.append(.stop)
    }
}
