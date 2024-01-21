/// Copyright (c) 2023 Kodeco Inc.
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import XCTest
import Combine
import SwiftUI
@testable import ColorCalc

class ColorCalcTests: XCTestCase {
	
	var viewModel: CalculatorViewModel!
	var subscriptions = Set<AnyCancellable>()
	
	override func setUp() {
		viewModel = CalculatorViewModel()
	}
	
	override func tearDown() {
		subscriptions = []
	}
	
	func test_correctNameReceived() {
		// Given
		let expected = "rwGreen 66%"
		var result = ""
		
		viewModel.$name.sink { result = $0 }
			.store(in: &subscriptions)
		
		// When
		viewModel.hexText = "006636AA"
		
		// Then
		XCTAssertEqual(result, expected, "Name expected to be \(expected) but was \(result)")
	}
	
	func test_processBackspaceDeleteLastCharacter() {
		// Given
		let expected = "#0080F"
		var result = ""
		
		viewModel.$hexText.dropFirst().sink { result = $0 }.store(in: &subscriptions)
		
		// When
		viewModel.process(CalculatorViewModel.Constant.backspace)
		
		// Then
		XCTAssertEqual(result, expected, "Hex was expected to be \(expected) but was \(result)")
	}
	
	func test_correctColorReceived() {
		// Given
		let expected = Color(hex: ColorName.rwGreen.rawValue)!
		var result: Color = .clear
		
		viewModel.$color.sink { result = $0 }.store(in: &subscriptions)
		
		// When
		viewModel.hexText = ColorName.rwGreen.rawValue
		
		// Then
		XCTAssertEqual(result, expected, "Hex was expected to be \(expected) but was \(result)")
	}
	
	func test_processBackspaceReceivesCorrectColor() {
		// Given
		let expected = Color.white
		var result: Color = .white
		
		viewModel.$color.sink { result = $0 }.store(in: &subscriptions)
		
		// When
		viewModel.process(CalculatorViewModel.Constant.backspace)
		
		// Then
		XCTAssertEqual(result, expected, "Hex was expected to be \(expected) but was \(result)")
	}
	
	func test_whiteColorReceivedForBadData() {
		// Given
		let expected = Color.white
		var result = Color.clear
		viewModel.$color
			.sink(receiveValue: { result = $0 })
			.store(in: &subscriptions)
		// When
		viewModel.hexText = "abc"
		// Then
		XCTAssert(
			result == expected,
			"Color expected to be \(expected) but was \(result)"
		)
	}
	
	func test_processClearSetHexToHashtag() {
		// Given
		let expected = "#"
		var result = ""
		
		viewModel.$hexText.sink { result = $0 }.store(in: &subscriptions)
		
		// When
		viewModel.process(CalculatorViewModel.Constant.clear)
		
		// Then
		XCTAssertEqual(result, expected, "Hex was expected to be \(expected) but was \(result)")
	}
	
	func test_correctRGBOTextReceived() {
		// Given
		let expected = "0, 0, 255, 255"
		var result = ""
		
		viewModel.$rgboText.sink { result = $0 }.store(in: &subscriptions)
		
		// When
		viewModel.hexText = ColorName.blue.rawValue
		
		// Then
		XCTAssertEqual(result, expected, "Hex was expected to be \(expected) but was \(result)")
	}
}
