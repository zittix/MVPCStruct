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
	
	func testHello() {
		let helloData = "Hello".data(using: String.Encoding.utf8, allowLossyConversion: false)
		let facit = ["H", "e", "l", "l", "o"]
		let packer = CStruct()
		if let r = try? packer.unpack(helloData!, format: "ccccc"), let result = r as? [String] {
			for i in 0..<facit.count {
				XCTAssertEqual(result[i], facit[i])
			}
		}
		if let r = try? packer.unpack(helloData!, format: "5c"), let result = r as? [String] {
			for i in 0..<facit.count {
				XCTAssertEqual(result[i], facit[i])
			}
		}
	}
	
	func testBigEndian() {
		
		let data = Data(bytes: UnsafePointer<UInt8>([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e] as [UInt8]), count: 14)
		let facit: [UInt] = [0x0102, 0x03040506, 0x0708090a0b0c0d0e]
		
		let packer = CStruct()
		if let r = try? packer.unpack(data, format: ">HIQ"), let result = r as? [UInt] {
			for i in 0..<facit.count {
				XCTAssertEqual(facit[i], result[i])
			}
		} else {
			XCTFail("result is nil")
		}
	}
	
}
