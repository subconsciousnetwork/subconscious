//
//  ToastView.swift
//  Subconscious (iOS)
//
//  Created by Ben Follington on 30/10/2023.
//

import Foundation
import SwiftUI

struct ToastView: View {
    var message: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Spacer()
            Text(message)
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
                    withAnimation(.easeInOut(duration: 1.0)) {
                        toggled = !toggled
                    }
                }, label: {
                    Text("Toggle")
                })
                
                Spacer()
                
                if (self.toggled) {
                    ToastView(message: "An alert!")
                }
            }
        }
    }
    
    
    static var previews: some View {
        TestView()
    }
}
