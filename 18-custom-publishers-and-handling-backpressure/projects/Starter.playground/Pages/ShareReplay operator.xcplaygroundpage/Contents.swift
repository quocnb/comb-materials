import Foundation
import Combine

fileprivate final class ShareReplaySubscription<Output, Failure: Error>: Subscription {
	/// The replay buffer's maximum capacity
	let capacity: Int
	/// Keep a reference of to the subscriber for the duration of the subscription
	var subscriber: AnySubscriber<Output, Failure>? = nil
	/// Tracks the accumulated demands the publisher receives from the subscriber so
	/// that you can deliver exactly the requested number of values.
	var demand: Subscribers.Demand = .none
	/// Stores pending values in a buffer until they are either delivered to the subscriber or thrown away.
	var buffer: [Output]
	/// This keeps the potential completion event around, so that it’s ready to deliver to new subscribers as soon as they begin requesting values.
	var completion: Subscribers.Completion<Failure>? = nil
	
	
	init<S>(subscriber: S, replay: [Output], capacity: Int, completion: Subscribers.Completion<Failure>?) where S: Subscriber, Failure == S.Failure, Output == S.Input {
		self.subscriber = AnySubscriber(subscriber)
		self.buffer = replay
		self.capacity = capacity
		self.completion = completion
	}

	private func complete(with completion: Subscribers.Completion<Failure>) {
		guard let subscriber = self.subscriber else { return }
		self.subscriber = nil
		self.completion = nil
		self.buffer.removeAll()
		subscriber.receive(completion: completion)
	}
	
	private func emitAsNeeded() {
		guard let subscriber = self.subscriber else { return }
		while self.demand > .none && !buffer.isEmpty {
			self.demand -= .max(1)
			let nextDemand = subscriber.receive(buffer.removeFirst())
			if nextDemand != .none {
				self.demand += nextDemand
			}
		}
		if let completion = self.completion {
			complete(with: completion)
		}
	}
	
	func request(_ demand: Subscribers.Demand) {
		if demand != .none {
			self.demand += demand
		}
		emitAsNeeded()
	}
	
	func cancel() {
		complete(with: .finished)
	}
	
	func receive(_ input: Output) {
		guard self.subscriber != nil else {
			return
		}
		buffer.append(input)
		if buffer.count > capacity {
			buffer.removeFirst()
		}
		emitAsNeeded()
	}
	
	func receive(completion: Subscribers.Completion<Failure>) {
		guard let subscriber = self.subscriber else { return }
		self.subscriber = nil
		self.buffer.removeAll()
		subscriber.receive(completion: completion)
	}
}

extension Publishers {
	final class ShareReplay<Upstream: Publisher>: Publisher {
		typealias Output = Upstream.Output
		typealias Failure = Upstream.Failure
		
		private let lock = NSRecursiveLock()
		
		private let upstream: Upstream
		
		private let capacity: Int
		
		private var replay = [Output]()
		
		private var subscriptions = [ShareReplaySubscription<Output, Failure>]()
		
		private var completion: Subscribers.Completion<Failure>? = nil
		
		init(upstream: Upstream, capacity: Int) {
			self.upstream = upstream
			self.capacity = capacity
		}
		
		func receive<S>(subscriber: S) where S : Subscriber, Upstream.Failure == S.Failure, Upstream.Output == S.Input {
			lock.lock()
			defer {
				lock.unlock()
			}
			let subscription = ShareReplaySubscription(subscriber: subscriber, replay: self.replay, capacity: self.capacity, completion: self.completion)
			self.subscriptions.append(subscription)
			subscriber.receive(subscription: subscription)
			
			guard self.subscriptions.count == 1 else {
				return
			}
			
			let sink = AnySubscriber { subscription in
				subscription.request(.unlimited)
			} receiveValue: { [weak self] (value: Output) in
				self?.replay(value)
				return .none
			} receiveCompletion: { [weak self] completion in
				self?.complete(completion)
			}
			upstream.subscribe(sink)
		}
		
		private func replay(_ value: Output) {
			lock.lock()
			defer {
				lock.unlock()
			}
			guard self.completion == nil else {
				return
			}
			
			replay.append(value)
			if replay.count > capacity {
				replay.removeFirst()
			}
			
			self.subscriptions.forEach { subscription in
				subscription.receive(value)
			}
		}
		
		private func complete(_ completion: Subscribers.Completion<Failure>) {
			lock.lock()
			defer {
				lock.unlock()
			}
			self.completion = completion
			self.subscriptions.forEach { subscription in
				subscription.receive(completion: completion)
			}
		}
	}
}

extension Publisher {
	func shareReplay(capacity: Int = .max) -> Publishers.ShareReplay<Self> {
		return Publishers.ShareReplay(upstream: self, capacity: capacity)
	}
}

var logger = TimeLogger(sinceOrigin: true)
let subject = PassthroughSubject<Int,Never>()
let publisher = subject
	.print("shareReplay")
	.shareReplay(capacity: 2)
subject.send(0)

let subscription1 = publisher.sink(
	receiveCompletion: {
		print("subscription1 completed: \($0)", to: &logger)
	},
	receiveValue: {
		print("subscription1 received \($0)", to: &logger)
	}
)
subject.send(1)
subject.send(2)
subject.send(3)

let subscription2 = publisher.sink(
	receiveCompletion: {
		print("subscription2 completed: \($0)", to: &logger)
	},
	receiveValue: {
		print("subscription2 received \($0)", to: &logger)
	}
)
subject.send(4)
subject.send(5)
subject.send(completion: .finished)

var subscription3: Cancellable? = nil
DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
	print("Subscribing to shareReplay after upstream completed")
	subscription3 = publisher.sink(
		receiveCompletion: {
			print("subscription3 completed: \($0)", to: &logger)
		},
		receiveValue: {
			print("subscription3 received \($0)", to: &logger)
		}
) }
//: [Next](@next)
/*:
 Copyright (c) 2023 Kodeco Inc.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 distribute, sublicense, create a derivative work, and/or sell copies of the
 Software in any work that is designed, intended, or marketed for pedagogical or
 instructional purposes related to programming, coding, application development,
 or information technology.  Permission for such use, copying, modification,
 merger, publication, distribution, sublicensing, creation of derivative works,
 or sale is expressly withheld.

 This project and source code may use libraries or frameworks that are
 released under various Open-Source licenses. Use of those libraries and
 frameworks are governed by their own individual licenses.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */
