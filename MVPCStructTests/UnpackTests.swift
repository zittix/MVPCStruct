//
//  UnpackTests.swift
//  MVPCStruct
//
//  Created by Per Olofsson on 2014-06-13.
//  Copyright (c) 2014 AutoMac. All rights reserved.
//

import XCTest
import MVPCStruct

class UnpackTests: XCTestCase {
    var packer: CStruct = CStruct()

    override func setUp() {
        packer = CStruct()
    }

    func testHello() {
        let stringArray = "Hello".characters.map { String($0) }
        let toUnpack = "Hello".dataUsingEncoding(NSASCIIStringEncoding, allowLossyConversion: false)!

        let result = XCTAssertNoThrow(try packer.unpack(toUnpack, format: "ccccc"))
        XCTAssertNotNil(result)
        XCTAssertTrue(result is [String])
        if let result = result as? [String] {
            XCTAssertEqual(stringArray, result)
        }

        let result2 = XCTAssertNoThrow(try packer.unpack(toUnpack, format: "5c"))
        XCTAssertNotNil(result)
        XCTAssertTrue(result is [String])
        if let result2 = result2 as? [String] {
            XCTAssertEqual(stringArray, result2)
        }
    }

    func testBigEndian() {
        let dataArray: [UInt] = [0x0102, 0x03040506, 0x0708090a0b0c0d0e]
        let toUnpack = NSData(bytes: [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e] as [UInt8], length: 14)

        let result = XCTAssertNoThrow(try packer.unpack(toUnpack, format: ">HIQ"))
        XCTAssertNotNil(result)
        XCTAssertTrue(result is [UInt])
        if let result = result as? [UInt] {
            XCTAssertEqual(dataArray, result)
        }
    }
}
