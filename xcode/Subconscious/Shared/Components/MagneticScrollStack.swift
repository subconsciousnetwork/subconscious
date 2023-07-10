//
//  MagneticScrollStack.swift
//  Subconscious
//
//  Created by Ben Follington on 10/7/2023.
//

import Foundation
import SwiftUI

struct VerticalPager<Content: View>: View {
    let pageCount: Int
    @Binding var currentIndex: Int
    let content: Content

    init(pageCount: Int, currentIndex: Binding<Int>, @ViewBuilder content: () -> Content) {
        self.pageCount = pageCount
        self._currentIndex = currentIndex
        self.content = content()
    }

    @GestureState private var translation: CGFloat = 0
    
    func sign(_ n: CGFloat) -> CGFloat {
        guard n != 0 else {
            return 1
        }
        
        return n/abs(n)
    }

    var body: some View {
        GeometryReader { geometry in
            LazyVStack(spacing: 0) {
                self.content.frame(width: geometry.size.width, height: geometry.size.height)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.primary.opacity(0.000000001))
            .offset(y: -CGFloat(self.currentIndex) * geometry.size.height)
            .offset(y: sign(self.translation) * sqrt(abs(self.translation)))
            .animation(.interactiveSpring(response: 0.3), value: currentIndex)
            .animation(.interactiveSpring(), value: translation)
//            .gesture(
//                DragGesture(minimumDistance: 1, coordinateSpace: .global).updating(self.$translation) { value, state, _ in
//                    state = value.translation.height
//                }.onEnded { value in
//                    let offset = -Int(value.translation.height)
//                    if abs(offset) > 80 {
//                        let newIndex = currentIndex + min(max(offset, -1), 1)
//                        if newIndex >= 0 && newIndex < pageCount {
//                            self.currentIndex = newIndex
//                        }
//                    }
//                }
//            )
        }
    }
}

struct PageView: View {
    @GestureState private var translation: CGFloat = 0
    var onNextPage: () -> Void = {}
    
    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                ForEach(0..<64) { index in
                    Text("testing")
                }
                .frame(maxWidth: .infinity)
                
            }
            
            
            Text("ok")
        }
        .frame(maxWidth: .infinity)
        .containerRelativeFrame([.horizontal, .vertical])
        
    }
}

struct SizePreferenceKey: PreferenceKey {
  typealias Value = CGSize
  static var defaultValue: Value = .zero

  static func reduce(value _: inout Value, nextValue: () -> Value) {
    _ = nextValue()
  }
}

struct ChildSizeReader<Content: View>: View {
  @Binding var size: CGSize

  let content: () -> Content
  var body: some View {
    ZStack {
      content().background(
        GeometryReader { proxy in
          Color.clear.preference(
            key: SizePreferenceKey.self,
            value: proxy.size
          )
        }
      )
    }
    .onPreferenceChange(SizePreferenceKey.self) { preferences in
      self.size = preferences
    }
  }
}

struct ViewOffsetKey: PreferenceKey {
  typealias Value = CGFloat
  static var defaultValue = CGFloat.zero
  static func reduce(value: inout Value, nextValue: () -> Value) {
    value += nextValue()
  }
}

let text = "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum."

struct ContentView: View {
    let spaceName = "scroll"

    @State var wholeSize: CGSize = .zero
    @State var scrollViewSize: CGSize = .zero
    
    var onNextPage: () -> Void = {}
    @State var finished: Bool = false

    var body: some View {
        ChildSizeReader(size: $wholeSize) {
            ScrollView {
                ChildSizeReader(size: $scrollViewSize) {
                    VStack {
                        ForEach(0..<10) { i in
                            Text(text)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        GeometryReader { proxy in
                            Color.clear.preference(
                                key: ViewOffsetKey.self,
                                value: -1 * proxy.frame(in: .named(spaceName)).origin.y
                            )
                        }
                    )
                    .onPreferenceChange(
                        ViewOffsetKey.self,
                        perform: { value in
                            print("offset: \(value)") // offset: 1270.3333333333333 when User has reached the bottom
                            print("height: \(scrollViewSize.height)") // height: 2033.3333333333333

                            if value >= (scrollViewSize.height - wholeSize.height + 128) {
                                print("User has reached the bottom of the ScrollView.")
                                if !finished {
                                    onNextPage()
                                    finished = true
                                }
                            } else {
                                print("not reached.")
                                finished = false
                            }
                        }
                    )
                }
            }
            .containerRelativeFrame([.horizontal, .vertical])
            .coordinateSpace(name: spaceName)
        }
        .onChange(
            of: scrollViewSize,
            perform: { value in
                print(value)
            }
        )
    }
}

struct MagneticPreviewView: View {
    @State private var currentPage = 0

    let colors: [Color] = [.red, .green, .blue]

    var body: some View {
        VerticalPager(pageCount: colors.count, currentIndex: $currentPage) {
            ForEach(0..<3) { index in
                ContentView(onNextPage: {
                    currentPage += 1
                })
//                    .background(colors[index])
            }
        }
    }
}

struct VerticalPager_Previews: PreviewProvider {
    static var previews: some View {
        MagneticPreviewView()
    }
}

