//
//  BottomSheetView.swift
//  Subconscious
//
//  Created by Gordon Brander on 3/15/22.
//

import SwiftUI

struct BottomSheetView<Content>: View
where Content: View {
    @Binding var isOpen: Bool
    var maxHeight: CGFloat
    var minHeight: CGFloat
    var content: Content
    var snapRatio: CGFloat = 0.3
    var background: Color = Color.background
    @GestureState private var drag: CGFloat = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrimView()
                .zIndex(1)
                .edgesIgnoringSafeArea(.top)
                .onTapGesture {
                    self.isOpen = false
                }
            VStack {
                DragHandleView()
                    .padding(AppTheme.unit2)
                content
            }
            .frame(
                maxWidth: .infinity,
                minHeight: minHeight,
                idealHeight: minHeight,
                maxHeight: maxHeight,
                alignment: .top
            )
            .background(self.background)
            .cornerRadius(AppTheme.cornerRadius)
            .offset(
                x: 0,
                y: self.drag
            )
            .animation(.interactiveSpring(), value: self.isOpen)
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
                        self.isOpen = value.translation.height < 0
                    }
            )
        }
    }
}

struct BottomSheetView_Previews: PreviewProvider {
    static var previews: some View {
        BottomSheetView(
            isOpen: .constant(true),
            maxHeight: 200,
            minHeight: 100,
            content: Text("Hello")
        )
    }
}
