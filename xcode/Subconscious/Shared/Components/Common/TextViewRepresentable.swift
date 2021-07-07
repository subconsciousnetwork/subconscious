//
//  TextViewRepresentable.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 7/6/21.
//

import SwiftUI

struct TextViewRepresentable: UIViewRepresentable {
    class Coordinator: NSObject, UITextViewDelegate {
        var representable: TextViewRepresentable

        init(_ representable: TextViewRepresentable) {
            self.representable = representable
        }
        
        func textViewDidChange(_ view: UITextView) {
            representable.text = view.text
            representable.onChange()
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            representable.onFocus()
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            representable.onBlur()
        }
    }

    private var isFocused = false
    private var intrinsicSize: CGSize?
    @Binding var text: String
    var onChange: () -> Void
    var onFocus: () -> Void
    var onBlur: () -> Void

    init(
        text: Binding<String>,
        onChange: @escaping () -> Void,
        onFocus: @escaping () -> Void,
        onBlur: @escaping () -> Void
    ) {
        self._text = text
        self.onChange = onChange
        self.onFocus = onFocus
        self.onBlur = onBlur
    }
    
    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.text = text
        view.font = UIFont.preferredFont(forTextStyle: .body)
        view.isUserInteractionEnabled = true
        view.isEditable = true
        // Zero out inner padding
        view.textContainerInset = .zero
        // Remove that last bit of inner padding.
        // Text in view should now be flush with view edge.
        // This puts you in full control of view padding.
        view.textContainer.lineFragmentPadding = 0
        view.backgroundColor = .clear
        
        view.backgroundColor = UIColor.lightGray
        
        view.isScrollEnabled = false
        view.showsVerticalScrollIndicator = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.textContainer.maximumNumberOfLines = 0
        view.textContainer.lineBreakMode = .byWordWrapping
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        if isFocused {
            view.becomeFirstResponder()
        } else {
            view.resignFirstResponder()
        }
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        if isFocused {
            view.becomeFirstResponder()
        } else {
            view.resignFirstResponder()
        }
    }

    func makeCoordinator() -> TextViewRepresentable.Coordinator {
        Coordinator(self)
    }

    /// Focus view
    func focused(_ isFocused: Bool) -> Self {
        var view = self
        view.isFocused = isFocused
        return view
    }
}

struct TextViewRepresentablePreview: PreviewProvider {
    static var previews: some View {
        VStack {
            GeometryReader { geometry in
                VStack {
                TextViewRepresentable(
                    text: .constant("Text"),
                    onChange: { },
                    onFocus: {  },
                    onBlur: {  }
                )
                .focused(true)
                .frame(width: geometry.size.width)
                .fixedSize()
                .border(Color.red, width: 1)

                    TextViewRepresentable(
                        text: .constant("Text"),
                        onChange: { },
                        onFocus: {  },
                        onBlur: {  }
                    )
                    .focused(true)
                    .frame(width: geometry.size.width)
                    .fixedSize()
                    .border(Color.red, width: 1)
                }
            }
            Spacer()
        }
    }
}
