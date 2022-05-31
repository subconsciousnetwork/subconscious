//
//  Editor.swift
//  Subconscious
//
//  Created by Gordon Brander on 5/27/22.
//

import Foundation

/// Holds supporting metadata for entry.
/// Basically anything that is not the content or selection.
struct EditorEntryInfo: Hashable, Identifiable {
    var slug: Slug
    var headers: HeaderIndex = .empty
    var backlinks: [EntryStub] = []

    var id: Slug { slug }

    var title: String {
        if let title = headers["Title"] {
            return title
        }
        return slug.toTitle()
    }

    /// Sets standard headers.
    mutating func mendHeaders() {
        self.headers["Content-Type"] = "text/subtext"

        let link = EntryLink(
            slug: slug,
            title: headers["Title"] ?? ""
        )
        self.headers["Title"] = link.toLinkableTitle()

        let now = Date.now.ISO8601Format()
        self.headers["Modified"] = now
        self.headers.setDefault(name: "Created", value: now)
    }
}

/// Holds the state for an editor
struct Editor: Hashable {
    /// Current slug editor is set to, if any
    var entryInfo: EditorEntryInfo?

    /// Is editor saved?
    var saveState = SaveState.saved

    /// Is editor in loading state?
    var isLoading = true

    /// Text of editor
    var text: String = ""

    /// Current user text selection
    var selection = NSMakeRange(0, 0)

    /// The entry link within the text
    var selectedEntryLinkMarkup: Subtext.EntryLinkMarkup?

    /// Given a particular entry value, does the editor's state
    /// currently match it, such that we could say the editor is
    /// displaying that entry?
    func stateMatches(entry: SubtextFile) -> Bool {
        guard let entryInfo = self.entryInfo else {
            return false
        }
        return (
            entryInfo.slug == entry.slug &&
            text == entry.content
        )
    }
}

extension Editor {
    init(_ detail: EntryDetail) {
        self.entryInfo = EditorEntryInfo(
            slug: detail.entry.slug,
            headers: detail.entry.headers,
            backlinks: detail.backlinks
        )
        self.text = detail.entry.content
        self.saveState = .saved
        self.isLoading = false
    }
}

extension SubtextFile {
    /// Construct a SubtextFile from an Editor model
    init?(_ editor: Editor) {
        guard let info = editor.entryInfo else {
            return nil
        }
        self.slug = info.slug
        self.headers = info.headers
        self.content = editor.text
    }
}
