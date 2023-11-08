//
//  ValidatedTextField.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 2/7/23.
//

import SwiftUI
import Combine
import ObservableStore

struct ValidatedFormField<Output: Equatable>: View {
    @State private var innerText: String = ""
    @FocusState private var focused: Bool
    
    var alignment: HorizontalAlignment = .leading
    var placeholder: String
    var field: ViewStore<FormField<String, Output>>
    
    var caption: String? = nil
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
    
    var invalidBadge: some View {
        Image(systemName: "exclamationmark.circle")
            .frame(width: 24, height: 22)
            .foregroundColor(.red)
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
                .onChange(of: focused) { focused in
                    field.send(.focusChange(focused: focused))
                    onFocusChanged(focused)
                }
                .onChange(of: innerText) { innerText in
                    var text = innerText
                    let isSubstring = text.contains(field.state.value) || field.state.value.contains(text)
                    let lengthDelta = abs(text.count - field.state.value.count)
                    // Trim whitespace from pasted values only
                    // We detect a "paste" when the text changes substantially
                    if !isSubstring && text.count > 0 && lengthDelta > 1 {
                        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    
                    field.send(.setValue(input: text))
                }
                .onChange(of: field.state) { field in
                    // The store value has been reset via side-effect
                    // we must re-sync our inner value
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
                
                // In the multiline scenario we want to reserve space for the badge
                // this avoids the text suddenly wrapping when the validation status changes
                if axis == .vertical {
                    invalidBadge
                        .opacity(field.state.shouldPresentAsInvalid ? 1 : 0)
                } else if field.state.shouldPresentAsInvalid {
                    // Actually add/remove badge from layout in the axis == .horizontal case
                    invalidBadge
                }
            }
            if let caption = caption {
                Text(verbatim: caption)
                    .lineLimit(1)
                    .foregroundColor(
                        field.state.shouldPresentAsInvalid ? Color.red : Color.secondary
                    )
                    .animation(.default, value: field.state.shouldPresentAsInvalid)
                    .font(.caption)
            }
        }
        .onAppear {
            innerText = field.state.value
        }
    }
}

struct ValidatedTextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ValidatedFormField(
                placeholder: "nickname",
                field: Store(
                    state: FormField(value: "", validate: { _ in "" }),
                    environment: FormFieldEnvironment()
                ).toViewStoreForSwiftUIPreview(),
                caption: String(localized: "Lowercase letters and numbers only.")
            )
            ValidatedFormField(
                placeholder: "nickname",
                field: Store(
                    state: FormField(value: "", validate: { _ in nil as String? }),
                    environment: FormFieldEnvironment()
                ).toViewStoreForSwiftUIPreview(),
                caption: String(localized: "Lowercase letters and numbers only.")
            )
            ValidatedFormField(
                placeholder: "nickname",
                field: Store(
                    state: FormField(value: "", validate: { _ in "" }),
                    environment: FormFieldEnvironment()
                ).toViewStoreForSwiftUIPreview(),
                caption: String(localized: "Lowercase letters and numbers only.")
            )
            .textFieldStyle(.roundedBorder)
            ValidatedFormField(
                placeholder: "nickname",
                field: Store(
                    state: FormField(value: "A very long run of text to test how this interacts with the icon", validate: { _ in nil as String? }),
                    environment: FormFieldEnvironment()
                ).toViewStoreForSwiftUIPreview(),
                caption: String(localized: "Lowercase letters and numbers only.")
            )
            .textFieldStyle(.roundedBorder)
            
            
            Spacer()
            
            Form {
                ValidatedFormField(
                    placeholder: "nickname",
                    field: Store(
                        state: FormField(value: "", validate: { _ in "" }),
                        environment: FormFieldEnvironment()
                    ).toViewStoreForSwiftUIPreview(),
                    caption: String(localized: "Lowercase letters and numbers only."),
                    autoFocus: true
                )
                .formField()
                ValidatedFormField(
                    placeholder: "nickname",
                    field: Store(
                        state: FormField(value: "", validate: { _ in nil as String? }),
                        environment: FormFieldEnvironment()
                    ).toViewStoreForSwiftUIPreview(),
                    caption: String(localized: "Lowercase letters and numbers only.")
                )
                .formField()
            }
        }
        .padding()
    }
}
