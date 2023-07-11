//
//  ProfilePic.swift
//  Subconscious
//
//  Created by Gordon Brander on 1/11/23.
//

import SwiftUI

enum ProfilePicVariant: Equatable, Codable, Hashable {
    case none(Did)
    case image(String)
}

enum ProfilePicSize {
    case small
    case medium
    case large
}

struct ProfilePic: View {
    var pfp: ProfilePicVariant
    var size: ProfilePicSize

    private var imageSize: CGFloat {
        switch (size) {
        case .small:
            return AppTheme.smPfpSize
        case .medium:
            return AppTheme.mdPfpSize
        case .large:
            return AppTheme.lgPfpSize
        }
    }
    
    private var lineWidth: CGFloat {
        switch (size) {
        case .small:
            return 1
        case .medium:
            return 0.75
        case .large:
            return 0.5
        }
    }

    var body: some View {
        switch pfp {
        case .none(let did):
            GenerativeProfilePic(did: did, size: imageSize)
                .profilePicFrame(size: imageSize, lineWidth: lineWidth)
        case .image(let img):
            Image(img)
                .resizable()
                .profilePicFrame(size: imageSize, lineWidth: lineWidth)
        }
    }
}

struct ProfilePic_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ProfilePic(
                pfp: .none(Did.dummyData()),
                size: .small
            )
            ProfilePic(
                pfp: .image("pfp-dog"),
                size: .large
            )
        }
    }
}
