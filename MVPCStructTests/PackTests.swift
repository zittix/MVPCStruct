//
//  PackTests.swift
//  MVPCStruct
//
//  Created by Per Olofsson on 2014-06-13.
//  Copyright (c) 2014 AutoMac. All rights reserved.
//

import XCTest
import MVPCStruct

class PackTests: XCTestCase {
    var packer: CStruct = CStruct()
    override func setUp() {
        packer = CStruct()
    }

    func testBooleanPack() {
        let boolData = NSData(bytes: [0x01, 0x01, 0x00, 0x01] as [UInt8], length: 4)
        let toPack = [true, true, false, true]
        XCTAssertNoThrowEqual(boolData, try packer.pack(toPack, format: "????"))
    }

    func testString() {
        let asciiData = "Hello".dataUsingEncoding(NSASCIIStringEncoding, allowLossyConversion: false)!
        let toPack = "Hello".characters.map { String($0) }
        XCTAssertNoThrowEqual(asciiData, try packer.pack(toPack, format: "ccccc"))
        XCTAssertNoThrowEqual(asciiData, try packer.pack(toPack, format: "5c"))
    }

    func testSignedInts() {
        let signedIntData = NSData(bytes: [0xff, 0xfe, 0xff, 0xfd, 0xff, 0xff, 0xff, 0xfc, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff] as [UInt8], length: 15)
        let toPack = [-1, -2, -3, -4]
        XCTAssertNoThrowEqual(signedIntData, try packer.pack(toPack, format: "<bhiq"))
    }

    func testUnsignedInts() {
        let unsignedIntData = NSData(bytes: [0x01, 0x02, 0x00, 0x03, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00] as [UInt8], length: 15)
        let toPack = [1, 2, 3, 4]
        XCTAssertNoThrowEqual(unsignedIntData, try packer.pack(toPack, format: "<BHIQ"))
    }

    func testAlignment() {
        // Because the @ directive uses the native byte ordering, need to check system byte order
        let (firstStoredByte, lastStoredByte): (UInt8, UInt8) = {
            if CFByteOrderGetCurrent() == Int(CFByteOrderBigEndian.rawValue) {
                return (0x00, 0x02)
            }
            return (0x02, 0x00)
        }()

        let signedInt16Data = NSData(bytes: [0x01, 0x00, firstStoredByte, lastStoredByte] as [UInt8], length: 4)
        let toPack = [1, 2]
        XCTAssertNoThrowEqual(signedInt16Data, try packer.pack(toPack, format: "@BH"))

        let signedInt32Data = NSData(bytes: [0x01, 0x00, 0x00, 0x00, firstStoredByte, 0x00, 0x00, lastStoredByte] as [UInt8], length: 8)
        XCTAssertNoThrowEqual(signedInt32Data, try packer.pack(toPack, format: "@BI"))

        let signedInt64Data = NSData(bytes: [0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, firstStoredByte, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, lastStoredByte] as [UInt8], length: 16)
        XCTAssertNoThrowEqual(signedInt64Data, try packer.pack(toPack, format: "@BQ"))
    }

    func testBigEndian() {
        let bigEndianData = NSData(bytes: [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e] as [UInt8], length: 14)
        let toPack = [0x0102, 0x03040506, 0x0708090a0b0c0d0e]
        XCTAssertNoThrowEqual(bigEndianData, try packer.pack(toPack, format: ">HIQ"))
    }

    func testBadFormat() {
        XCTAssertThrows(try packer.pack([], format: "4@"))
        XCTAssertThrows(try packer.pack([1], format: "1 i"))
        XCTAssertThrows(try packer.pack([], format:"i"))
        XCTAssertThrows(try packer.pack([1, 2], format:"i"))
    }
}
