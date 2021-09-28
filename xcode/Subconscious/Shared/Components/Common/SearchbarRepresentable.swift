//
//  SearchBarRepresentable.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/12/21.
//

import SwiftUI

struct SearchBarRepresentable: UIViewRepresentable {
    class Coordinator: NSObject, UISearchBarDelegate {
        var representable: SearchBarRepresentable

        init(_ representable: SearchBarRepresentable) {
            self.representable = representable
        }

        func searchBar(
            _ view: UISearchBar,
            textDidChange text: String
        ) {
            representable.text = text
        }

        func searchBarTextDidBeginEditing(_ view: UISearchBar) {
            representable.isFocused = true
        }

        func searchBarTextDidEndEditing(_ view: UISearchBar) {
            representable.isFocused = false
        }

        func searchBarCancelButtonClicked(_ view: UISearchBar) {
            representable.isFocused = false
            representable.text = ""
            representable.onCancel()
        }

        func searchBarSearchButtonClicked(_ view: UISearchBar) {
            representable.onCommit(view.text ?? "")
        }
    }

    private static func onCancelDefault() {}

    private var showsCancelButton = false
    var placeholder: String
    @Binding var text: String
    @Binding var isFocused: Bool
    var onCommit: (String) -> Void
    var onCancel: () -> Void

    init(
        placeholder: String,
        text: Binding<String>,
        isFocused: Binding<Bool>,
        onCommit: @escaping (String) -> Void,
        onCancel: @escaping () -> Void = onCancelDefault
    ) {
        self._text = text
        self._isFocused = isFocused
        self.placeholder = placeholder
        self.onCommit = onCommit
        self.onCancel = onCancel
    }

    func makeUIView(context: Context) -> UISearchBar {
        let view = UISearchBar(frame: .zero)
        view.searchTextField.clearButtonMode = .whileEditing
        view.placeholder = placeholder
        view.searchBarStyle = .minimal
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ view: UISearchBar, context: Context) {
        if view.text != text {
            view.text = text
        }

        if view.isFirstResponder != isFocused {
            // We dispatch async to prevent AttributeGraph cycle warnings
            if isFocused {
                DispatchQueue.main.async {
                    view.becomeFirstResponder()
                }
            } else {
                DispatchQueue.main.async {
                    view.resignFirstResponder()
                }
            }
        }

        if showsCancelButton && view.showsCancelButton != isFocused {
            view.setShowsCancelButton(isFocused, animated: true)
        }
    }

    func makeCoordinator() -> SearchBarRepresentable.Coordinator {
        Coordinator(self)
    }

    func showCancel(_ showsCancelButton: Bool) -> Self {
        var view = self
        view.showsCancelButton = showsCancelButton
        return view
    }
}

struct SearchBarRepresentablePreview: PreviewProvider {
    static var previews: some View {
        SearchBarRepresentable(
            placeholder: "Placeholder",
            text: .constant("Text"),
            isFocused: .constant(true),
            onCommit: { text in },
            onCancel: {}
        ).showCancel(true)
    }
}
