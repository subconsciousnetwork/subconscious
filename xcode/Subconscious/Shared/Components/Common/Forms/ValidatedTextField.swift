//
//  ValidatedTextField.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/7/23.
//

import SwiftUI
import Combine
import ObservableStore

struct ValidatedFormField<T: Equatable, Model: ModelProtocol>: View {
    var alignment: HorizontalAlignment = .leading
    var placeholder: String
    var field: FormField<String, T>
    var send: (Model.Action) -> Void
    var tag: (FormFieldAction<String>) -> Model.Action
    var caption: String
    var axis: Axis = .horizontal
    var autoFocus: Bool = false
    var submitLabel: SubmitLabel = .done
    var onSubmit: () -> Void = {}
    
    
    var body: some View {
        ValidatedTextField(
            alignment: alignment,
            placeholder: placeholder,
            text: Binding(
                get: { field.value },
                send: send,
                tag: { v in tag(.setValue(input: v))}
            ),
            onFocusChanged: { focused in
                send(tag(.focusChange(focused: focused)))
            },
            caption: caption,
            axis: axis,
            autoFocus: autoFocus,
            isValid: !field.hasError,
            submitLabel: submitLabel,
            onSubmit: onSubmit
        )
        .formField()
    }
}

/// A text field that comes with help text and a validation flag
struct ValidatedTextField: View {
    @State var innerText: String = ""
    
    var alignment: HorizontalAlignment = .leading
    var placeholder: String
    @Binding var text: String
    var onFocusChanged: (Bool) -> Void = { _ in}
    var onTextChanged: () -> Void = {}
    var caption: String
    var axis: Axis = .horizontal
    var autoFocus: Bool = false
    var isValid: Bool = true
    @FocusState var focused: Bool
    
    var submitLabel: SubmitLabel = .return
    var onSubmit: () -> Void = { }
    
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
                    .opacity(isValid ? 0 : 1)
                    .animation(.default, value: isValid)
                }
                .onChange(of: focused) { _ in
                    onFocusChanged(focused)
                }
                .onChange(of: innerText, perform: { innerText in
                    text = innerText
                })
                .submitLabel(submitLabel)
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
                    isValid ? Color.secondary : Color.red
                )
                .animation(.default, value: isValid)
                .font(.caption)
        }
        .onAppear {
            innerText = text
        }
    }
}

struct ValidatedTextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ValidatedTextField(
                placeholder: "nickname",
                text: .constant(""),
                caption: "Lowercase letters and numbers only."
            )
            ValidatedTextField(
                placeholder: "nickname",
                text: .constant(""),
                caption: "Lowercase letters and numbers only.",
                isValid: false
            )
            ValidatedTextField(
                placeholder: "nickname",
                text: .constant(""),
                caption: "Lowercase letters and numbers only."
            )
            .textFieldStyle(.roundedBorder)
            ValidatedTextField(
                placeholder: "nickname",
                text: .constant("A very long run of text to test how this interacts with the icon"),
                caption: "Lowercase letters and numbers only.",
                isValid: false
            )
            .textFieldStyle(.roundedBorder)
            
            
            Spacer()
            
            Form {
                ValidatedTextField(
                    placeholder: "nickname",
                    text: .constant(""),
                    caption: "Lowercase letters and numbers only.",
                    autoFocus: true
                )
                .formField()
                ValidatedTextField(
                    placeholder: "nickname",
                    text: .constant(""),
                    caption: "Lowercase letters and numbers only.",
                    isValid: false
                )
                .formField()
            }
        }
        .padding()
    }
}
