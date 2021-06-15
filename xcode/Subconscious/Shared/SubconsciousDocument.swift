//
//  SubconsciousDocument.swift
//  Shared
//
//  Created by Gordon Brander on 4/4/21.
//
import Foundation

/// Subtext + a title
struct SubconsciousDocument: Identifiable, Hashable, Equatable {
    let title: String
    let content: Subtext
    
    var id: Int {
        self.title.hashValue
    }
    
    init(title: String, content: Subtext) {
        self.title = title
        self.content = content
    }

    init(title: String, markup: String) {
        self.init(title: title, content: Subtext(markup))
    }
}

extension SubconsciousDocument: CustomStringConvertible {
    var description: String {
        return """
        SubconsciousDocument("\(title)")
        """
    }
}

/// A simple struct that holds a `SubconsciousDocument`, plus details necessary to write
/// to the file system.
struct SubconsciousFileWrapper {
    let url: URL
    let document: SubconsciousDocument
}

// TODO: in future we may extend SubconsciousDocument to conform to
// FileDocument. However, right now I'm not clear if this is only used by
// DocumentGroup or if this protocol is used elsewhere.
//
//extension UTType {
//    static var subtext: UTType {
//        UTType(exportedAs: "com.subconscious.subtext", conformingTo: .text)
//    }
//}
//
//extension SubconsciousDocument: FileDocument {
//
//    static var readableContentTypes: [UTType] { [.subtext, .text] }
//    static var writableContentTypes: [UTType] { [.subtext, .text] }
//
//    init(configuration: ReadConfiguration) throws {
//        guard let data = configuration.file.regularFileContents,
//              let string = String(data: data, encoding: .utf8)
//        else {
//            throw CocoaError(.fileReadCorruptFile)
//        }
//        self.init(markup: string)
//    }
//
//    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
//        let data = content.description.data(using: .utf8)!
//        return .init(regularFileWithContents: data)
//    }
//}
