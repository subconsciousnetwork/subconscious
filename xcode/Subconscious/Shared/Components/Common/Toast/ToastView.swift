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
            Spacer()
            Text(toast.message)
            Spacer()
        }
        .padding()
        .frame(
            height: AppTheme.fabSize,
            alignment: .center
        )
        .background(.background)
        .foregroundColor(.primary)
        .cornerRadius(AppTheme.cornerRadiusLg)
        .shadow(
            color: Color.brandDropShadow(colorScheme).opacity(0.5),
            radius: 8,
            x: 0,
            y: 4
        )
        .transition(.asymmetric(insertion: .push(from: .bottom), removal: .opacity))
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
