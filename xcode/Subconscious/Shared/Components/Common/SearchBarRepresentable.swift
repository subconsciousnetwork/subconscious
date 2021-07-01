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
            _ searchBar: UISearchBar,
            textDidChange searchText: String
        ) {
            representable.text = searchText
        }
        
        func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
            representable.onFocus()
        }
        
        func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            representable.onCancel()
        }

        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            representable.onCommit(searchBar.text ?? "")
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
        let searchBar = UISearchBar()
        searchBar.searchTextField.clearButtonMode = .whileEditing
        searchBar.placeholder = placeholder
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = context.coordinator
        if isFocused {
            searchBar.becomeFirstResponder()
        } else {
            searchBar.resignFirstResponder()
        }
        searchBar.setShowsCancelButton(showsCancelButton, animated: false)
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
        searchBar.setShowsCancelButton(showsCancelButton, animated: true)
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
