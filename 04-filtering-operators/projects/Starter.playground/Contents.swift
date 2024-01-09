import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()

example(of: "prefix(untilOutputFrom") {
	let isReady = PassthroughSubject<Void, Never>()
	
	let taps = PassthroughSubject<Int, Never>()
	
	taps.prefix(untilOutputFrom: isReady).sink {
		print("Received completion", $0)
	} receiveValue: {
		print("Received value", $0)
	}.store(in: &subscriptions)
	
	(1...5).forEach {
		taps.send($0)
		if $0 == 2 {
			isReady.send()
		}
	}
}

example(of: "prefix(while:)") {
	let number = (1...10).publisher
	
	number.prefix(while: { $0 < 3 }).sink {
		print("Received completion", $0)
	} receiveValue: {
		print("Received value", $0)
	}.store(in: &subscriptions)
}

example(of: "prefix") {
	let number = (1...10).publisher
	
	number.prefix(2).sink {
		print("Received completion", $0)
	} receiveValue: {
		print("Received value", $0)
	}.store(in: &subscriptions)
}

example(of: "filter") {
	let numbers = (1...10).publisher
	
	numbers.filter({
		$0.isMultiple(of: 3)
	}).sink {
		print("Received completion", $0)
	} receiveValue: {
		print("Received value", $0)
	}.store(in: &subscriptions)
}

example(of: "Removed Duplicate") {
	let words = "hey hey there! want to listen to mister mister ?".components(separatedBy: " ").publisher
	words.removeDuplicates().sink {
		print("Received completion", $0)
	} receiveValue: {
		print("Received value", $0)
	}.store(in: &subscriptions)
}

example(of: "compactMap") {
	let strings = ["a", "1.24", "3", "def", "45", "0.23"].publisher
	strings.compactMap { Float($0) }.sink {
		print("Received completion", $0)
	} receiveValue: {
		print("Received value", $0)
	}.store(in: &subscriptions)
}

example(of: "ignoreOutput") {
	let numbers = (1...10_000).publisher
	
	numbers.ignoreOutput().sink {
		print("Received completion", $0)
	} receiveValue: {
		print("Received value", $0)
	}.store(in: &subscriptions)
}


example(of: "first(where)") {
	let numbers = (1...9).publisher
	
	numbers.print("numbers").first(where: { $0 % 2 == 0 }).sink {
		print("Received completion", $0)
	} receiveValue: {
		print("Received value", $0)
	}.store(in: &subscriptions)
}

example(of: "last(where") {
	let numbers = (1...9).publisher
	
	numbers.last(where: {$0 % 2 == 0}).sink {
		print("Received completion", $0)
	} receiveValue: {
		print("Received value", $0)
	}.store(in: &subscriptions)
}

example(of: "last(where)") {
	let numbers = PassthroughSubject<Int, Never>()
	
	numbers.last(where: { $0 % 2 == 0 }).sink {
		print("Received completion", $0)
	} receiveValue: {
		print("Received value", $0)
	}.store(in: &subscriptions)
	
	numbers.send(1)
	numbers.send(2)
	numbers.send(3)
	numbers.send(4)
	numbers.send(5)
	
	numbers.send(completion: .finished)
}

example(of: "dropFirst") {
	let numbers = (1...10).publisher
	
	numbers.dropFirst(8).sink {
		print("Received completion", $0)
	} receiveValue: {
		print("Received value", $0)
	}.store(in: &subscriptions)
}

example(of: "drop(while)") {
	let numbers = (1...10).publisher
	
	numbers.drop(while: { $0 % 5 != 0 }).sink {
		print("Received completion", $0)
	} receiveValue: {
		print("Received value", $0)
	}.store(in: &subscriptions)
}

example(of: "drop(untilOutputFrom") {
	let isReady = PassthroughSubject<Void, Never>()
	
	let taps = PassthroughSubject<Int, Never>()
	taps.drop(untilOutputFrom: isReady).sink {
		print("Received completion", $0)
	} receiveValue: {
		print("Received value", $0)
	}.store(in: &subscriptions)
	
	(1...5).forEach {
		taps.send($0)
		if $0 == 3 {
			isReady.send()
		}
	}
}

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
