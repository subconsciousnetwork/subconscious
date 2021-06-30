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

        func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            representable.onCancel()
        }

        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            representable.onSubmit(searchBar.text ?? "")
            UIApplication.shared.endEditing()
        }
    }

    @Binding var text: String
    var placeholder: String
    var showsCancelButton: Bool
    var onCommit: (String) -> Void
    var onSubmit: (String) -> Void
    var onCancel: () -> Void

    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar()
        searchBar.placeholder = placeholder
        searchBar.showsCancelButton = showsCancelButton
        searchBar.delegate = context.coordinator
        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = text
    }

    func makeCoordinator() -> SearchBarRepresentable.Coordinator {
        Coordinator(self)
    }
}

struct SearchBarRepresentablePreview: PreviewProvider {
    static var previews: some View {
        SearchBarRepresentable(
            text: .constant("Text"),
            placeholder: "Placeholder",
            showsCancelButton: false,
            onCommit: { text in },
            onSubmit: { text in },
            onCancel: {}
        )
    }
}
