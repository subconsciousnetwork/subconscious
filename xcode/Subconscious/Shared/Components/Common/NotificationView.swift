//
//  NotificationView.swift
//  Subconscious
//
//  Created by Ben Follington on 12/6/2023.
//

import SwiftUI

enum NotificationAction {
    case none
    case action(_ label: String, _ action: () -> Void)
}

struct NotificationView: View {
    @Environment(\.colorScheme) var colorScheme
    var message: String
    var action: NotificationAction = .none
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .fill(.background)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .strokeBorder(Color.separator, lineWidth: 0.5)
                )
                .frame(maxHeight: 64)
            
            HStack {
                Text(message)
                Spacer()
                switch (action) {
                case .action(let label, let action):
                    Button(label, action: action)
                case _:
                    EmptyView()
                }
            }
            .font(.callout)
            .padding(AppTheme.padding)
        }
        .shadow(
            color: Color.brandDropShadow(colorScheme).opacity(0.5),
            radius: 8,
            x: 0,
            y: 4
        )
    }
}

struct NotificationView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            NotificationView(message: "Gateway created")
            NotificationView(message: "Request timed out", action: .action("Retry", { }))
        }
        .padding(AppTheme.padding)
    }
}
