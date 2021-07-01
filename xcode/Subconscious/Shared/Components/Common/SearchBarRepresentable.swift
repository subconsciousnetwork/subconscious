//
//  SearchBarRepresentable.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/12/21.
//

import SwiftUI

extension UIApplication {
    func endEditing() {
        sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

struct SearchBarRepresentable: UIViewRepresentable {    
    class Coordinator: NSObject, UISearchBarDelegate {
        var representable: SearchBarRepresentable

        init(_ representable: SearchBarRepresentable) {
            self.representable = representable
        }
        
        func searchBar(
            _ searchBar: UISearchBar,
            textDidChange searchText: String
        ) {
            representable.text = searchText
            representable.onCommit(searchText)
        }
        
        func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
            searchBar.setShowsCancelButton(true, animated: true)
            representable.isFocused = true
            representable.onFocus()
        }
        
        func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
            searchBar.setShowsCancelButton(false, animated: true)
            searchBar.text = representable.initial
            representable.isFocused = false
            representable.onCancel()
        }

        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
            searchBar.setShowsCancelButton(false, animated: true)
            representable.isFocused = false
            representable.onSubmit(searchBar.text ?? "")
        }
    }

    private var isFocused = false
    var text: String
    var initial: String
    var placeholder: String
    var onCommit: (String) -> Void
    var onSubmit: (String) -> Void
    var onFocus: () -> Void
    var onCancel: () -> Void

    init(
        text: String,
        initial: String,
        placeholder: String,
        onFocus: @escaping () -> Void,
        onCommit: @escaping (String) -> Void,
        onSubmit: @escaping (String) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.text = text
        self.initial = initial
        self.placeholder = placeholder
        self.onFocus = onFocus
        self.onCommit = onCommit
        self.onSubmit = onSubmit
        self.onCancel = onCancel
    }
    
    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar()
        searchBar.placeholder = placeholder
        searchBar.showsCancelButton = false
        searchBar.delegate = context.coordinator
        return searchBar
    }

    func updateUIView(_ searchBar: UISearchBar, context: Context) {
        searchBar.text = text
        searchBar.placeholder = placeholder
        if isFocused {
            searchBar.becomeFirstResponder()
        } else {
            searchBar.resignFirstResponder()
        }
    }

    func makeCoordinator() -> SearchBarRepresentable.Coordinator {
        Coordinator(self)
    }

    func focused(_ isFocused: Bool) -> some View {
        var view = self
        view.isFocused = isFocused
        return view
    }
}

struct SearchBarRepresentablePreview: PreviewProvider {
    static var previews: some View {
        SearchBarRepresentable(
            text: "Text",
            initial: "",
            placeholder: "Placeholder",
            onFocus: {},
            onCommit: { text in },
            onSubmit: { text in },
            onCancel: {}
        )
    }
}
