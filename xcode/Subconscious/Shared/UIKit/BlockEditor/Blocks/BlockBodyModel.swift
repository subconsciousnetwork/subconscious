//
//  BlockBodyModel.swift
//  BlockEditor
//
//  Created by Gordon Brander on 7/17/23.
//

import Foundation

extension BlockEditor {
    /// Represents the various possible select states
    struct BlockSelectionModel: Hashable {
        static let normal = BlockSelectionModel()

        /// Is the text editor focused and editing?
        private(set) var isEditing: Bool
        /// Is select mode enabled in the editor?
        /// Our collection view is data-driven, so we set this flag for every
        /// block.
        private(set) var isBlockSelectMode: Bool
        /// Is this particular block selected?
        private(set) var isBlockSelected: Bool

        init(
            isBlockSelectMode: Bool = false,
            isEditing: Bool = false,
            isBlockSelected: Bool = false
        ) {
            if !isBlockSelectMode {
                // Not in block select mode
                self.isBlockSelectMode = false
                self.isEditing = isEditing
                self.isBlockSelected = false
                return
            }
            // In block select mode
            self.isBlockSelectMode = true
            self.isEditing = false
            self.isBlockSelected = isBlockSelected
        }

        mutating func setEditing(_ isEditing: Bool) {
            if self.isBlockSelectMode {
                self.isEditing = false
                return
            }
            self.isEditing = isEditing
            return
        }

        mutating func setBlockSelectMode(
            isBlockSelectMode: Bool,
            isBlockSelected: Bool = false
        ) {
            if !isBlockSelectMode {
                // Not in block select mode
                self.isBlockSelectMode = false
                self.isBlockSelected = false
                return
            }
            self.isBlockSelectMode = true
            self.isEditing = false
            self.isBlockSelected = isBlockSelected
            return
        }

        mutating func setBlockSelected(
            _ isBlockSelected: Bool
        ) {
            setBlockSelectMode(
                isBlockSelectMode: isBlockSelectMode,
                isBlockSelected: isBlockSelected
            )
        }
    }

    struct BlockBodyModel: Hashable {
        /// The text portion of the block. For some blocks this may not be
        /// rendered.
        private(set) var dom = Subtext.empty
        /// The text selection/text cursor position
        private(set) var textSelection: NSRange = NSMakeRange(0, 0)
        var blockSelection = BlockSelectionModel()
        var transcludes: [EntryStub] = []
        
        /// Set text, updating selection
        mutating func setText(
            dom: Subtext,
            textSelection: NSRange
        ) {
            self.dom = dom
            self.textSelection = textSelection
        }
        
        /// Set text, updating selection
        mutating func setTextSelection(
            _ textSelection: NSRange
        ) {
            self.textSelection = textSelection
        }

        mutating func updateTranscludes(
            index: [Slashlink: EntryStub]
        ) {
            self.transcludes = dom.parsedSlashlinks
                .uniquing()
                .compactMap({ slashlink in
                    index[slashlink]
                })
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
