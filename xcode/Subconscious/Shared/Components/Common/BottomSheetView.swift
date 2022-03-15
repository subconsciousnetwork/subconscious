//
//  BottomSheetView.swift
//  Subconscious
//
//  Created by Gordon Brander on 3/15/22.
//

import SwiftUI

struct BottomSheetView<Content>: View
where Content: View {
    @Binding var isPresented: Bool
    var maxHeight: CGFloat = .infinity
    var content: Content
    var background: Color = Color.background
    var snapRatio: CGFloat = 0.25
    /// Added to the offset to make sure that sheet is fully offscreen
    var approximateSafeAreaBottomHeight: CGFloat = 50
    @GestureState private var drag: CGFloat = 0

    private var offsetY: CGFloat {
        if isPresented {
            return max(drag, 0)
        } else {
            return maxHeight + approximateSafeAreaBottomHeight
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if isPresented {
                ScrimView()
                    .transition(
                        .opacity.animation(.default)
                    )
                    .zIndex(1)
                    .edgesIgnoringSafeArea(.top)
                    .onTapGesture {
                        self.isPresented = false
                    }
            }
            VStack {
                content
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: maxHeight,
                alignment: .top
            )
            .background(self.background)
            .cornerRadius(AppTheme.cornerRadiusLg)
            .offset(
                x: 0,
                y: offsetY
            )
            .animation(.interactiveSpring(), value: self.isPresented)
            .animation(.interactiveSpring(), value: self.drag)
            .zIndex(2)
            .gesture(
                DragGesture()
                    .updating(self.$drag) { value, state, transaction in
                        state = value.translation.height
                    }
                    .onEnded { value in
                        let snapDistance = self.maxHeight * self.snapRatio
                        guard abs(value.translation.height) > snapDistance else {
                            return
                        }
                        self.isPresented = value.translation.height < 0
                    }
            )
        }
    }
}

struct BottomSheetView_Previews: PreviewProvider {
    static var previews: some View {
        BottomSheetView(
            isPresented: .constant(true),
            content: Text("Hello")
        )
        BottomSheetView(
            isPresented: .constant(true),
            maxHeight: 200,
            content: Text("Hello")
        )
    }
}
