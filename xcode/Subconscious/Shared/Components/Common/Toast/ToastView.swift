//
//  ToastView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 30/10/2023.
//

import Foundation
import SwiftUI

struct ToastView: View {
    var toast: Toast
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Text(toast.message)
        }
        .padding()
        .frame(
            height: AppTheme.minTouchSize,
            alignment: .center
        )
        .background(.background)
        .foregroundColor(.primary)
        .cornerRadius(100)
        .shadow(
            color: Color.brandDropShadow(colorScheme).opacity(0.25),
            radius: 2.5,
            x: 0,
            y: 2
        )
        .transition(
            .asymmetric(
                insertion: .push(
                    from: .top
                ),
                removal: .push(
                    from: .bottom
                )
            )
        )
    }
}

struct ToastView_Previews: PreviewProvider {
    struct TestView: View {
        @State var toggled = true
        
        var body: some View {
            VStack {
                Button(action: {
                    withAnimation() {
                        toggled = !toggled
                    }
                }, label: {
                    Text("Toggle")
                })
                
                Spacer()
                
                if (self.toggled) {
                    ToastView(toast: Toast(message: "An alert!"))
                }
            }
        }
    }
    
    
    static var previews: some View {
        TestView()
    }
}
