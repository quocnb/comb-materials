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

import UIKit
import Combine
import SwiftUI

public final class JokesViewModel: ObservableObject {
	
	@Published public var fetching = false
	@Published public var joke = Joke.starter
	@Published public var backgroundColor = Color("Gray")
	@Published public var decisionState = DecisionState.undecided
	
	private let jokesService: JokeServiceDataPublisher
	
  public enum DecisionState {
    case disliked, undecided, liked
  }
  
  private static let decoder = JSONDecoder()
  
  public init(jokesService: JokeServiceDataPublisher = JokesService()) {
		self.jokesService = jokesService
		$joke.map { _ in
			false
		}.assign(to: &$fetching)
  }
  
  public func fetchJoke() {
    fetching = true
		jokesService.publisher()
			.retry(1)
			.decode(type: Joke.self, decoder: Self.decoder)
			.replaceError(with: Joke.error)
			.receive(on: DispatchQueue.main)
			.assign(to: &$joke)
  }
  
  public func updateBackgroundColorForTranslation(_ translation: Double) {
		switch translation {
			case ...(-0.5):
				backgroundColor = Color("Red")
			case 0.5...:
				backgroundColor = Color("Green")
			default:
				backgroundColor = Color("Gray")
		}
  }
  
  public func updateDecisionStateForTranslation(
  _ translation: Double,
  andPredictedEndLocationX x: CGFloat,
  inBounds bounds: CGRect) {
		switch (translation, x) {
			case (...(-0.6), ..<0):
				decisionState = .disliked
			case (0.6..., bounds.width...):
				decisionState = .liked
			default:
				decisionState = .undecided
		}
  }
  
  public func reset() {
    backgroundColor = Color("Gray")
  }
}
