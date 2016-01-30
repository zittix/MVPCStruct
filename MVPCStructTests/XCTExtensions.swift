//
//  XCTExtensions.swift
//  MVPCStruct
//
//  Created by Riley Avron on 1/29/16.
//  Copyright © 2016 ravron. All rights reserved.
//

import Foundation
import XCTest

// From http://jernejstrasner.com/2015/07/08/testing-throwable-methods-in-swift-2.html

func XCTAssertThrows<T>(@autoclosure expression: () throws -> T, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    do {
        try expression()
        var append = " - \(message)"
        if message.isEmpty {
            append = ""
        }
        XCTFail("No error to catch!\(append)", file: file, line: line)
    } catch {
    }
}

func XCTAssertNoThrow<T>(@autoclosure expression: () throws -> T, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    do {
        try expression()
    } catch let error {
        var append = " - \(message)"
        if message.isEmpty {
            append = ""
        }
        XCTFail("Caught error: \(error)\(append)", file: file, line: line)
    }
}

func XCTAssertNoThrowEqual<T : Equatable>(@autoclosure expression1: () -> T, @autoclosure _ expression2: () throws -> T, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    do {
        let result1 = expression1()
        let result2 = try expression2()
        XCTAssertEqual(result1, result2, message, file: file, line: line)
    } catch let error {
        var append = " - \(message)"
        if message.isEmpty {
            append = ""
        }
        XCTFail("Caught error: \(error)\(append)", file: file, line: line)
    }
}