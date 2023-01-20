//
//  TextFieldLabel.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 1/20/23.
//

import SwiftUI

/// Wraps a TextField with a headline and optional caption
struct TextFieldLabel<Label: View>: View {
    var label: Text
    var caption: Text?
    var field: TextField<Label>
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.unit) {
            label
                .font(.headline)
            field
                .textFieldStyle(.roundedBorder)
            if let caption = caption {
                caption
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct LabeledTextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TextFieldLabel(
                label: Text("Label"),
                caption: Text("Some additional instructions."),
                field: TextField("Some instructions", text: Binding.constant(""))
            )
            TextFieldLabel(
                label: Text("Label"),
                field: TextField("Some instructions", text: Binding.constant(""))
            )
        }
        .padding()
    }
}
