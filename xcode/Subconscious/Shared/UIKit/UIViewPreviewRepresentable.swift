//
//  UIViewPreviewRepresentable.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 9/7/23.
//

import SwiftUI

/// Embed a UIView in a SwiftUI View, without exposing any state to
/// SwiftUI. Useful for previewing UIViews in the canvas.
struct UIViewPreviewRepresentable: UIViewRepresentable {
    private var view: UIView

    init(_ makeView: () -> UIView) {
        self.view = makeView()
    }

    func makeUIView(context: Context) -> UIView {
        view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct UIViewPreviewRepresentable_Previews: PreviewProvider {
    static var previews: some View {
        UIViewPreviewRepresentable {
            let view = UILabel()
            view.text = "Example"
            return view
        }
    }
}
