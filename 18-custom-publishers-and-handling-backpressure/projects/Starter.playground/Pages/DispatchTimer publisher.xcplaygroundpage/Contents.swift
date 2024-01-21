import Foundation
import Combine

struct DispatchTimerConfiguration {
	/// The queue that the timer will fire on
	let queue: DispatchQueue?
	/// The interval at which the timer fires, starting from the subscription time
	let interval: DispatchTimeInterval
	/// The maximum of time after the deadline that the system may delay the delivery of the timer event
	let leeway: DispatchTimeInterval
	/// the number of events you want to receive
	let times: Subscribers.Demand
}

extension Publishers {
	struct DispatchTimer: Publisher {
		typealias Output = DispatchTime
		typealias Failure = Never
		
		let configuration: DispatchTimerConfiguration
		
		init(configuration: DispatchTimerConfiguration) {
			self.configuration = configuration
		}
		
		func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Output == S.Input {
			let subscription = DispatchTimerSubscription(subscriber: subscriber, configuration: configuration)
			subscriber.receive(subscription: subscription)
		}
	}
}

private final class DispatchTimerSubscription<S: Subscriber>: Subscription where S.Input == DispatchTime {
	/// The configuration that the subscriber passed.
	let configuration: DispatchTimerConfiguration
	/// The maximum number of times the timer will fire
	var times: Subscribers.Demand
	/// The current demand; e.g., the number of values the subscriber requested — you decrement it every time you send a value.
	var requested: Subscribers.Demand = .none
	/// The internal DispatchSourceTimer that will generate the timer events.
	var source: DispatchSourceTimer?
	/// The subscriber. This makes it clear that the subscription is responsible for retaining the subscriber for as long as it doesn’t complete, fail or cancel.
	var subscriber: S?
	
	init(subscriber: S, configuration: DispatchTimerConfiguration) {
		self.configuration = configuration
		self.subscriber = subscriber
		self.times = configuration.times
	}
	
	func request(_ demand: Subscribers.Demand) {
		guard times > .none else {
			subscriber?.receive(completion: .finished)
			return
		}
		requested += demand
		
		if source == nil, requested > .none {
			let source = DispatchSource.makeTimerSource(queue: configuration.queue)
			source.schedule(deadline: .now() + configuration.interval, repeating: configuration.interval, leeway: configuration.leeway)
			source.setEventHandler { [weak self] in
				guard let self = self, self.requested > .none else { return }
				self.requested -= .max(1)
				self.times -= .max(1)
				_ = self.subscriber?.receive(.now())
				
				if self.times == .none {
					self.subscriber?.receive(completion: .finished)
				}
			}
			self.source = source
			source.activate()
		}
	}
	
	func cancel() {
		source = nil
		subscriber = nil
	}
}

extension Publishers {
	static func timer(queue: DispatchQueue? = nil, inteval: DispatchTimeInterval, leeway: DispatchTimeInterval = .nanoseconds(0), times: Subscribers.Demand = .unlimited) -> Publishers.DispatchTimer {
		return Publishers.DispatchTimer(configuration: .init(queue: queue, interval: inteval, leeway: leeway, times: times))
	}
}

var logger = TimeLogger(sinceOrigin: true)

let publisher = Publishers.timer(inteval: .seconds(1), times: .max(6))

let subscription = publisher.sink { time in
	print("Timer emits: \(time)", to: &logger)
}

DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
	subscription.cancel()
}

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
