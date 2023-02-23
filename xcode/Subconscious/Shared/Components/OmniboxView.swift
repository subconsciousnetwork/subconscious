//
//  OmniboxView.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/11/23.
//

import SwiftUI

struct OmniboxView: View {
    var icon: Image
    var title: String

    var body: some View {
        HStack(spacing: 8) {
            icon
                .resizable()
                .frame(width: 17, height: 17)
                .foregroundColor(.accentColor)
            HStack(spacing: 0) {
                Spacer()
                Text(verbatim: title)
                    .foregroundColor(.accentColor)
                Spacer()
            }
        }
        .padding(.leading, 8)
        .padding(.trailing, 12)
        .frame(height: 36)
        .background(Color.secondaryBackground)
        .cornerRadius(12)
    }
}

extension OmniboxView {
    init(
        address: MemoAddress?
    ) {
        let audience = address?.toAudience() ?? .local
        let title = address?.slug.description ?? ""
        self.init(
            icon: Image(audience: audience),
            title: title
        )
    }
}

struct OmniboxView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            OmniboxView(
                icon: Image(systemName: "network"),
                title: "Permissionless creation is where value comes from"
            )
            OmniboxView(
                icon: Image(systemName: "network"),
                title: "X"
            )
        }
    }
}
