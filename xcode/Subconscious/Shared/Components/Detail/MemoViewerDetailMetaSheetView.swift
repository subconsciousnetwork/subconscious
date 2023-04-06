//
//  MemoViewerDetailMetaSheetView.swift
//  Subconscious (iOS)
//
//  Created by Gordon Brander on 4/6/23.
//

import SwiftUI

struct MemoViewerDetailMetaSheetView: View {
    @Environment(\.dismiss) private var dismiss
    var state: MemoEditorDetailMetaSheetModel
    var send: (MemoEditorDetailMetaSheetAction) -> Void

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct MemoViewerDetailMetaSheetView_Previews: PreviewProvider {
    static var previews: some View {
        MemoViewerDetailMetaSheetView()
    }
}
