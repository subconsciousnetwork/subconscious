//
//  AppIcon.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 20/4/2023.
//

import SwiftUI

enum AppIcon {
    case you
    case following
    case edit
    case user
}

extension AppIcon {
    var systemName: String {
        switch (self) {
        case .you:
            return "face.smiling"
        case .following:
            return "person.fill.checkmark"
        case .edit:
            return "pencil"
        case .user:
            return "person.circle"
        }
    }
}

extension Image {
    static func from(appIcon: AppIcon) -> Image {
        Image(systemName: appIcon.systemName)
    }
}
