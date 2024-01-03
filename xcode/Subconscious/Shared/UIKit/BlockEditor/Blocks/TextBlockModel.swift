//
//  TextBlockModel.swift
//  BlockEditor
//
//  Created by Gordon Brander on 7/17/23.
//

import Foundation

extension BlockEditor {
    struct TextBlockModel: Hashable, Identifiable {
        var id = UUID()
        var dom = Subtext.empty
        /// The selection/text cursor position
        var selection: NSRange = NSMakeRange(0, 0)
        /// Is the text editor focused?
        var isEditing = false
        /// Is select mode enabled in the editor?
        /// Our collection view is data-driven, so we set this flag for every
        /// block.
        private(set) var isBlockSelectMode = false
        /// Is this particular block selected?
        private(set) var isBlockSelected = false
        var transcludes: [EntryStub] = []
        
        /// Set text, updating selection
        func setText(
            dom: Subtext,
            selection: NSRange
        ) -> Self {
            var this = self
            this.dom = dom
            this.selection = selection
            return this
        }
        
        /// Set text, updating selection
        func setSelection(
            selection: NSRange
        ) -> Self {
            var this = self
            this.selection = selection
            return this
        }

        func updateTranscludes(
            index: [Slashlink: EntryStub]
        ) -> Self {
            var this = self
            this.transcludes = dom.parsedSlashlinks
                .uniquing()
                .compactMap({ slashlink in
                    index[slashlink]
                })
            return this
        }

        func setBlockSelectMode(
            isBlockSelectMode: Bool,
            isBlockSelected: Bool
        ) -> Self {
            var this = self
            this.isBlockSelectMode = isBlockSelectMode
            this.isBlockSelected = isBlockSelectMode && isBlockSelected
            return this
        }
    }
}

extension BlockEditor {
    enum TextBlockAction {
        case selectModePressed(id: UUID)
        case boldButtonPressed(id: UUID, text: String, selection: NSRange)
        case italicButtonPressed(id: UUID, text: String, selection: NSRange)
        case codeButtonPressed(id: UUID, text: String, selection: NSRange)
        case requestSplit(
            id: UUID,
            selection: NSRange,
            text: String
        )
        case requestMergeUp(id: UUID)
        case didChange(
            id: UUID,
            dom: Subtext,
            selection: NSRange
        )
        case didChangeSelection(
            id: UUID,
            selection: NSRange
        )
        case didBeginEditing(id: UUID)
        case didEndEditing(id: UUID)
        case upButtonPressed(id: UUID)
        case downButtonPressed(id: UUID)
        case dismissKeyboardButtonPressed(id: UUID)
        case activateLink(URL)
        case requestLink(EntryLink)
    }
}

extension BlockEditor.TextBlockAction {
    static func from(
        id: UUID,
        action: SubtextTextEditorAction
    ) -> Self {
        switch action {
        case .requestSplit(let text, let selection):
            return .requestSplit(id: id, selection: selection, text: text)
        case .requestMergeUp:
            return .requestMergeUp(id: id)
        case let .textDidChange(dom, selection):
            return .didChange(id: id, dom: dom, selection: selection)
        case .selectionDidChange(let selection):
            return .didChangeSelection(id: id, selection: selection)
        case .didBeginEditing:
            return .didBeginEditing(id: id)
        case .didEndEditing:
            return .didEndEditing(id: id)
        case .activateLink(let url):
            return .activateLink(url)
        case .selectModePressed:
            return .selectModePressed(id: id)
        case .upButtonPressed:
            return .upButtonPressed(id: id)
        case .downButtonPressed:
            return .downButtonPressed(id: id)
        case .dismissKeyboardButtonPressed:
            return .dismissKeyboardButtonPressed(id: id)
        case .boldButtonPressed(let text, let selection):
            return .boldButtonPressed(
                id: id,
                text: text,
                selection: selection
            )
        case .italicButtonPressed(let text, let selection):
            return .italicButtonPressed(
                id: id,
                text: text,
                selection: selection
            )
        case .codeButtonPressed(let text, let selection):
            return .codeButtonPressed(
                id: id,
                text: text,
                selection: selection
            )
        }
    }
}

extension BlockEditor.TextBlockAction {
    static func from(_ action: BlockEditor.TranscludeListAction) -> Self {
        switch action {
        case let .requestLink(link):
            return .requestLink(link)
        }
    }
}
