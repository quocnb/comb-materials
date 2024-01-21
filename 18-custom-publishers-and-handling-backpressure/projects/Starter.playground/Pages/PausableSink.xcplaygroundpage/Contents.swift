import Foundation
import Combine

protocol Pausable {
	var paused: Bool { get }
	func resume()
}

final class PausableSubscriber<Input, Failure: Error>: Subscriber, Pausable, Cancellable {
	let combineIdentifier = CombineIdentifier()
	
	/// true = may receive more values
	/// false = the subscription should pause
	let receiveValue: (Input) -> Bool
	
	let receiveCompletion: (Subscribers.Completion<Failure>) -> Void
	/// keep the subscription around so that it can request more values after a pause
	/// Need to set to nil when you don't need it anymore to avoid a retain cycle
	private var subscription: Subscription? = nil
	
	var paused = false
	
	init(receiveValue: @escaping (Input) -> Bool, receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> Void) {
		self.receiveValue = receiveValue
		self.receiveCompletion = receiveCompletion
	}
	
	func cancel() {
		subscription?.cancel()
		subscription = nil
	}
	
	func receive(subscription: Subscription) {
		self.subscription = subscription
		self.subscription?.request(.max(1))
	}
	
	func receive(_ input: Input) -> Subscribers.Demand {
		paused = receiveValue(input) == false
		return paused ? .none : .max(1)
	}
	
	func receive(completion: Subscribers.Completion<Failure>) {
		receiveCompletion(completion)
		subscription = nil
	}
	
	func resume() {
		guard paused else {
			return
		}
		paused = false
		subscription?.request(.max(1))
	}
}

extension Publisher {
	func pausableSink(receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> Void, receiveValue: @escaping (Output) -> Bool) -> Pausable & Cancellable {
		let pausable = PausableSubscriber(receiveValue: receiveValue, receiveCompletion: receiveCompletion)
		self.subscribe(pausable)
		return pausable
	}
}

let subscription = Array(1...6).publisher
	.pausableSink(receiveCompletion: { completion in
		print("Pausable subscription completed: \(completion)")
	}) { value -> Bool in
		print("Receive value: \(value)")
		if value % 2 == 1 {
			print("Pausing")
			return false
		}
		return true
}

let timer = Timer.publish(every: 1, on: .main, in: .common)
	.autoconnect()
	.sink { _ in
		guard subscription.paused else {
			return
		}
		print("Subscription is paused, resuming")
		subscription.resume()
	}
