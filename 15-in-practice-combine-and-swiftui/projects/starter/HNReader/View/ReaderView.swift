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

import SwiftUI
import Combine

struct ReaderView: View {
	
	@Environment(\.colorScheme) var colorScheme: ColorScheme
  @ObservedObject var model: ReaderViewModel
  @State var presentingSettingsSheet = false

  @State var currentDate = Date()
	
	private let timer = Timer.publish(every: 10, on: .main, in: .common)
		.autoconnect()
		.eraseToAnyPublisher()
	
  init(model: ReaderViewModel) {
    self.model = model
  }
  
  var body: some View {
    let filter = "Showing all stories"
    
    return NavigationView {
      List {
				Section(header: Text(self.model.filter.count > 0 ? "Filter: \(self.model.filter.joined(separator: ", "))" : filter).padding(.leading, -10)) {
          ForEach(self.model.stories) { story in
            VStack(alignment: .leading, spacing: 10) {
              TimeBadge(time: story.time)
              
              Text(story.title)
                .frame(minHeight: 0, maxHeight: 100)
                .font(.title)
              
              PostedBy(time: story.time, user: story.by, currentDate: self.currentDate)
              
              Button(story.url) {
                print(story)
              }
              .font(.subheadline)
							.foregroundColor(self.colorScheme == .light ? Color.blue : .orange)
              .padding(.top, 6)
            }
            .padding()
          }
          // Add timer here
					.onReceive(timer, perform: { time in
						self.currentDate = time
					})
        }.padding()
      }
      .listStyle(PlainListStyle())
      // Present the Settings sheet here
			.sheet(isPresented: $presentingSettingsSheet, content: {
				SettingsView()
			})
      // Display errors here
			.alert(item: $model.error, content: { error in
				Alert(title: Text("Network Error"), message: Text(error.localizedDescription), dismissButton: .cancel())
			})
      .navigationBarTitle(Text("\(self.model.stories.count) Stories"))
      .navigationBarItems(trailing:
        Button("Settings") {
          // Set presentingSettingsSheet to true here
				self.presentingSettingsSheet = true
        }
      )
    }
  }
}

#if DEBUG
struct ReaderView_Previews: PreviewProvider {
  static var previews: some View {
    ReaderView(model: ReaderViewModel())
  }
}
#endif
