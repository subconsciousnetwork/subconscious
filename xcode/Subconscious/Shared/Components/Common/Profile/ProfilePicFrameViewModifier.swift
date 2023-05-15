//
//  ProfilePicFrameViewModifier.swift
//  Subconscious
//
//  Created by Ben Follington on 16/5/2023.
//

import SwiftUI

struct ProfilePicFrameViewModifier: ViewModifier {
    let size: CGFloat
    let lineWidth: CGFloat

    func body(content: Content) -> some View {
        content
            .aspectRatio(contentMode: .fill)
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.separator, lineWidth: lineWidth))
    }
}

extension View {
    func profilePicFrame(size: CGFloat, lineWidth: CGFloat) -> some View {
        self.modifier(ProfilePicFrameViewModifier(size: size, lineWidth: lineWidth))
    }
}
