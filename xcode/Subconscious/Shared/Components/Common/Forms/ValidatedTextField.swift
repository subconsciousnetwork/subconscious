//
//  ValidatedTextField.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/7/23.
//

import SwiftUI
import Combine
import ObservableStore

struct ValidatedFormField<T: Equatable>: View {
    @State private var innerText: String = ""
    @FocusState private var focused: Bool
    
    var alignment: HorizontalAlignment = .leading
    var placeholder: String
    var field: FormField<String, T>
    var send: (FormFieldAction<String>) -> Void
    var caption: String
    var axis: Axis = .horizontal
    var autoFocus: Bool = false
    var submitLabel: SubmitLabel = .done
    var onSubmit: () -> Void = {}
    var onFocusChanged: (_ focused: Bool) -> Void = { _ in }
    
    var backgroundColor = Color.background
    
    /// When appearing in a form the background colour of a should change
    func formField() -> Self {
        var this = self
        this.backgroundColor = Color.formFieldBackground
        return this
    }
    
    var body: some View {
        VStack(alignment: alignment, spacing: AppTheme.unit2) {
            HStack {
                TextField(
                    placeholder,
                    text: $innerText,
                    axis: axis
                )
                .focused($focused)
                .overlay(alignment: .trailing) {
                    VStack {
                        Image(systemName: "exclamationmark.circle")
                            .frame(width: 24, height: 22)
                            .padding(.horizontal, 8)
                            .foregroundColor(.red)
                            .background(backgroundColor)
                    }
                    .padding(.trailing, 1)
                    .opacity(field.shouldPresentAsInvalid ? 1 : 0)
                    .animation(.default, value: field.shouldPresentAsInvalid)
                }
                .onChange(of: focused) { focused in
                    send(.focusChange(focused: focused))
                    onFocusChanged(focused)
                }
                .onChange(of: innerText) { innerText in
                    send(.setValue(input: innerText))
                }
                .onChange(of: field) { field in
                    // The has been reset, sync inner value
                    if !field.touched && innerText != field.value {
                        innerText = field.value
                    }
                }
                .onSubmit {
                    onSubmit()
                }
                .task {
                    if autoFocus {
                        self.focused = true
                    }
                }
            }
            Text(caption)
                .foregroundColor(
                    field.shouldPresentAsInvalid ? Color.red : Color.secondary
                )
                .animation(.default, value: field.shouldPresentAsInvalid)
                .font(.caption)
        }
        .onAppear {
            innerText = field.value
        }
    }
}

struct ValidatedTextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ValidatedFormField(
                placeholder: "nickname",
                field: FormField(value: "", validate: { _ in "" }),
                send: { _ in },
                caption: "Lowercase letters and numbers only."
            )
            ValidatedFormField(
                placeholder: "nickname",
                field: FormField(value: "", validate: { _ in nil as String? }),
                send: { _ in },
                caption: "Lowercase letters and numbers only."
            )
            ValidatedFormField(
                placeholder: "nickname",
                field: FormField(value: "", validate: { _ in "" }),
                send: { _ in },
                caption: "Lowercase letters and numbers only."
            )
            .textFieldStyle(.roundedBorder)
            ValidatedFormField(
                placeholder: "nickname",
                field: FormField(value: "A very long run of text to test how this interacts with the icon", validate: { _ in nil as String? }),
                send: { _ in },
                caption: "Lowercase letters and numbers only."
            )
            .textFieldStyle(.roundedBorder)
            
            
            Spacer()
            
            Form {
                ValidatedFormField(
                    placeholder: "nickname",
                    field: FormField(value: "", validate: { _ in "" }),
                    send: { _ in },
                    caption: "Lowercase letters and numbers only.",
                    autoFocus: true
                )
                .formField()
                ValidatedFormField(
                    placeholder: "nickname",
                    field: FormField(value: "", validate: { _ in nil as String? }),
                    send: { _ in },
                    caption: "Lowercase letters and numbers only."
                )
                .formField()
            }
        }
        .padding()
    }
}
