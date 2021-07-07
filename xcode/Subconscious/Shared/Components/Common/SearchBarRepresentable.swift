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
            representable.onFocus()
        }
        
        func searchBarCancelButtonClicked(_ view: UISearchBar) {
            representable.onCancel()
        }

        func searchBarSearchButtonClicked(_ view: UISearchBar) {
            representable.onCommit(view.text ?? "")
        }
    }

    private var isFocused = false
    private var showsCancelButton = false
    // TODO a LocalizedStringKey would be preferrable here.
    // Figure out how to get LocalizeStringKey to place nicely with
    // UIViewRepresentable-wrapped UIKit views.
    var placeholder: String
    @Binding var text: String
    var onFocus: () -> Void
    var onCommit: (String) -> Void
    var onCancel: () -> Void

    init(
        placeholder: String,
        text: Binding<String>,
        onFocus: @escaping () -> Void,
        onCommit: @escaping (String) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onFocus = onFocus
        self.onCommit = onCommit
        self.onCancel = onCancel
    }
    
    func makeUIView(context: Context) -> UISearchBar {
        let view = UISearchBar(frame: .zero)
        view.searchTextField.clearButtonMode = .whileEditing
        view.placeholder = placeholder
        view.searchBarStyle = .minimal
        view.delegate = context.coordinator
        if isFocused {
            view.becomeFirstResponder()
        } else {
            view.resignFirstResponder()
        }
        view.setShowsCancelButton(showsCancelButton, animated: false)
        return view
    }

    func updateUIView(_ view: UISearchBar, context: Context) {
        view.text = text
        view.placeholder = placeholder
        if isFocused {
            view.becomeFirstResponder()
        } else {
            view.resignFirstResponder()
        }
        view.setShowsCancelButton(showsCancelButton, animated: true)
    }

    func makeCoordinator() -> SearchBarRepresentable.Coordinator {
        Coordinator(self)
    }

    func focused(_ isFocused: Bool) -> Self {
        var view = self
        view.isFocused = isFocused
        return view
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
            onFocus: {},
            onCommit: { text in },
            onCancel: {}
        )
    }
}
