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
    var height: CGFloat
    var containerSize: CGSize
    var content: Content
    var background: Color = Color.background
    var snapRatio: CGFloat = 0.5
    /// Added to the offset to make sure that sheet is fully offscreen
    var approximateSafeAreaBottomHeight: CGFloat = 50
    @GestureState private var drag: CGFloat = 0

    private var offsetY: CGFloat {
        if isPresented {
            return max(drag, 0)
        } else {
            return height + approximateSafeAreaBottomHeight
        }
    }

    var body: some View {
        ZStack {
            if isPresented {
                ScrimView()
                    .transition(
                        .opacity.animation(
                            .easeOutCubic(duration: Duration.fast)
                        )
                    )
                    .zIndex(1)
                    .edgesIgnoringSafeArea(.top)
                    .onTapGesture {
                        self.isPresented = false
                    }
            }
            VStack {
                Spacer()
                VStack {
                    content
                }
                .frame(
                    width: containerSize.width,
                    height: height
                )
                .background(background)
                .cornerRadius(
                    AppTheme.cornerRadiusLg,
                    corners: [.topLeft, .topRight]
                )
                // This modifier is a hack/workaround to prevent a bug in
                // SwiftUI animations where the `content` of the bottom sheet
                // was incorrectly being animated.
                //
                // The list view and search view of the search interface
                // in `content` were being animated separately, using the
                // same implicit animations defined on `VStack` here.
                // However, disabling the implicit animations on `content`
                // would cause the content to remain in place, while the
                // sheet would animate offset, cropping content.
                //
                // Setting `.scaleEffect(1)` does nothing visually, but
                // causes the contents of the sheet to animate correctly
                // with the sheet.
                //
                // I got the idea from this SO post
                // https://stackoverflow.com/questions/65544581/swiftui-how-to-override-nested-offset-position-animations
                //
                // I suspect the mechanism by which this works is "snapshotting"
                // the rendered contents of the sheet, causing SwiftUI
                // animations to apply to that snapshot, rather than the
                // individual layers.
                //
                // 2022-03-16 Gordon Brander
                .scaleEffect(1)
                .offset(
                    x: 0,
                    y: offsetY
                )
                .animation(
                    .interactiveSpring(
                        response: 0.5,
                        dampingFraction: 0.86,
                        blendDuration: 0.25
                    ),
                    value: self.isPresented
                )
                .animation(.interactiveSpring(), value: self.drag)
                .gesture(
                    DragGesture()
                        .updating(self.$drag) { value, state, transaction in
                            state = value.translation.height
                        }
                        .onEnded { value in
                            let snapDistance = self.height * self.snapRatio
                            guard abs(value.translation.height) > snapDistance else {
                                return
                            }
                            self.isPresented = value.translation.height < 0
                        }
                )
            }
            .shadow(style: .lv1)
            .zIndex(2)
        }
        .frame(
            width: containerSize.width,
            height: containerSize.height
        )
    }
}

struct BottomSheetView_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReader { geometry in
            BottomSheetView(
                isPresented: .constant(true),
                height: geometry.size.height - 50,
                containerSize: geometry.size,
                content: Text("Hello")
            )
        }
    }
}
