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
	
	override func setUp() {
		super.setUp()
	}
	
	override func tearDown() {
		super.tearDown()
	}
	
	func testBooleanPack() {
		
		let packer = CStruct()
		let booleanFacit = NSData(bytes: [0x01, 0x01, 0x00, 0x01] as [UInt8], length: 4)
		do {
			let result = try packer.pack([true, true, false, true], format: "????")
			XCTAssertEqual(result, booleanFacit)
		} catch {
			XCTFail("result is nil")
		}
	}
	
	func testHello() {
		let facit = "Hello".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
		
		let packer = CStruct()
		do {
			let result = try packer.pack(["H", "e", "l", "l", "o"], format: "ccccc")
			XCTAssertEqual(result, facit!)
		} catch {
			XCTFail("result is nil")
		}
		do {
			let result = try packer.pack(["H", "e", "l", "l", "o"], format: "5c")
			XCTAssertEqual(result, facit!)
		} catch {
			XCTFail("result is nil")
		}
	}
	
	func testInts() {
		let signedFacit = NSData(bytes: [0xff, 0xfe, 0xff, 0xfd, 0xff, 0xff, 0xff, 0xfc, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff] as [UInt8], length: 15)
		let packer = CStruct()
		do {
			let result = try packer.pack([-1, -2, -3, -4], format: "<bhiq")
			XCTAssertEqual(signedFacit, result)
		} catch {
			XCTFail("result is nil")
		}
		let unsignedFacit = NSData(bytes: [0x01, 0x02, 0x00, 0x03, 0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00] as [UInt8], length: 15)
		do {
			let result = try packer.pack([1, 2, 3, 4], format: "<BHIQ")
			XCTAssertEqual(unsignedFacit, result)
		} catch {
			XCTFail("result is nil")
		}
	}
	
	func testAlignment() {
		// This test will fail on bigendian platforms.
		
		let packer = CStruct()
		
		let signedFacit16 = NSData(bytes: [0x01, 0x00, 0x02, 0x00] as [UInt8], length: 4)
		do {
			let result = try packer.pack([1, 2], format: "@BH")
			XCTAssertEqual(signedFacit16, result)
		} catch {
			XCTFail("result is nil")
		}
		
		let signedFacit32 = NSData(bytes: [0x01, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00] as [UInt8], length: 8)
		do {
			let result = try packer.pack([1, 2], format: "@BI")
			XCTAssertEqual(signedFacit32, result)
		} catch {
			XCTFail("result is nil")
		}
		
		let signedFacit64 = NSData(bytes: [0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00] as [UInt8], length: 16)
		do {
			let result = try packer.pack([1, 2], format: "@BQ")
			XCTAssertEqual(signedFacit64, result)
		} catch {
			XCTFail("result is nil")
		}
	}
	
	func testBigEndian() {
		
		let facit = NSData(bytes: [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e] as [UInt8], length: 14)
		
		let packer = CStruct()
		
		do {
			let result = try packer.pack([0x0102, 0x03040506, 0x0708090a0b0c0d0e], format: ">HIQ")
			XCTAssertEqual(facit, result)
		} catch {
			XCTFail("result is nil")
		}
	}
	
	func testBadFormat() {
		
		let packer = CStruct()
		
		do {
			let _ = try packer.pack([], format: "4@")
			XCTFail("bad format should throw")
		} catch {
		}
		do {
			let _ = try packer.pack([1], format:"1 i")
			XCTFail("bad format should format")
		} catch {
		}
		do {
			let _ = try packer.pack([], format:"i")
			XCTFail("bad format should format")
		} catch {
		}
		do {
			let _ = try packer.pack([1, 2], format:"i")
			XCTFail("bad format should format")
		} catch {
		}
	}
}
