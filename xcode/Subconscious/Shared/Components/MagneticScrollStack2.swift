//
//  MagneticScrollStack2.swift
//  Subconscious
//
//  Created by Ben Follington on 10/7/2023.
//

import Foundation
import SwiftUI

struct TikTokSwipingBehavior: View {
    let text = "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum."
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(0..<100) { i in
                    ScrollView {
                        ZStack(alignment: .top) {
                            Rectangle()
                                .fill(i % 2 == 0 ? Color.gray : Color.white)
                                .cornerRadius(AppTheme.cornerRadius)
                                
                            VStack(spacing: 8) {
                                Text("Post \(i+1)")
                                    .font(.title)
                                    .bold()
                                Text(text)
                                Text(text)
                                Text(text)
                                Text(text)
                                
                                Button(action: {}, label: {
                                    Text("Fork")
                                })
                            }
                            .padding()
                            .padding(.top, 32)
                            .padding(.bottom, 32)
                            .safeAreaPadding()
                        }
                        .frame(maxHeight: .infinity)
                    }
                    .containerRelativeFrame([.horizontal, .vertical])
                }
                .scrollTransition { content, phase in
                    content
                        .scaleEffect(phase.isIdentity ? 1 : 0.9)
                        .blur(radius: phase.isIdentity ? 0 : 8)
//                        .rotation3D(.degrees(phase.isIdentity ? 0 : 16), axis: (1, 0, 0))
//                        .offset(y: phase.isIdentity ? 0 : 128)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .springLoadingBehavior(.enabled)
        .ignoresSafeArea()
    }
    
}

#Preview {
    TikTokSwipingBehavior()
}
