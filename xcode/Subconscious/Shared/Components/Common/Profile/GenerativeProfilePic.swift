//
//  GenerativeProfilePic.swift
//  Subconscious
//
//  Created by Ben Follington on 25/4/2023.
//

import SwiftUI

struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let angle: CGFloat = 360 / 5
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius / 2
        
        var path = Path()
        path.move(to: CGPoint(x: center.x + outerRadius * cos(0), y: center.y + outerRadius * sin(0)))
        
        for i in 1..<10 {
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let x = center.x + radius * cos(CGFloat(i) * angle * CGFloat.pi / 180)
            let y = center.y + radius * sin(CGFloat(i) * angle * CGFloat.pi / 180)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.closeSubpath()
        return path
    }
}

struct GenerativeProfilePic: View {
   @State private var animate = false
   @Environment(\.colorScheme) var colorScheme
    
    let size: CGFloat = 64
    
    func randomMoonPhase() -> String? {
        [
            "moonphase.waxing.crescent",
            "moonphase.first.quarter",
            "moonphase.waxing.gibbous",
            "moonphase.waning.gibbous",
            "moonphase.last.quarter",
            "moonphase.waning.crescent",
            "moonphase.waxing.crescent.inverse",
            "moonphase.first.quarter.inverse",
            "moonphase.waxing.gibbous.inverse",
            "moonphase.waning.gibbous.inverse",
            "moonphase.last.quarter.inverse",
            "moonphase.waning.crescent.inverse",
        ]
        .randomElement()
    }
    
    func randomIcon() -> String? {
        [
            "moon.stars.fill",
            "sparkle",
            "sparkles",
            "moon.fill",
            "star.fill",
            "staroflife.fill",
        ]
        .randomElement()
    }
    
    func randomStarSign() -> String? {
        [
            "♊︎",
            "♑︎",
            "♎︎",
            "♋︎",
            "♒︎",
            "♌︎",
            "♓︎",
            "♐︎",
            "♉︎",
            "♈︎",
            "♍︎",
            "♏︎",
        ]
        .randomElement()
    }
    
    func randomSigil() -> String? {
        [
            "✶",
            "✴︎",
            "⚘",
            "✸",
            "✺",
            "❈",
            "✢",
        ]
        .randomElement()
    }
    
    func randomColor() -> Color? {
        [
            Color.blue,
//            Color.purple,
            Color.red,
//            Color.brandBgBlush,
            Color.brandMarkRed,
//            Color.brandMarkCyan,
//            Color.brandBgPurple,
            Color.brandMarkViolet,
//            Color.brandMarkPink,
            Color.brandMarkPurple,
//            Color.brandBgSlate
        ]
        .randomElement()
    }
    
    func randomGradient() -> [Gradient.Stop]? {
        guard let (a, b, c) = Color.brandColorTrios.randomElement() else {
            return nil
        }
        
        return Color.brandGradient(a: a, b: b, c: c)
    }
    
    func randomBlendMode() -> BlendMode? {
        [
            BlendMode.colorDodge,
            BlendMode.colorBurn,
//            BlendMode.screen,
            .plusDarker,
        ]
        .randomElement()
    }
       
   var body: some View {
       ZStack(alignment: .center) {
           if let gradient = randomGradient() {
           Circle()
               .foregroundStyle(
                   .radialGradient(
                       stops: gradient,
                       center: .init(x: 0.5, y: 0.25), // Calculated from brandmark
                       startRadius: 0,
                       endRadius: size * 0.75 // Calculated from brandmark
                   )
                   .shadow(
                       // Eyeballed from brandmark
                       .inner(
                           color: Color.brandInnerShadow(colorScheme).opacity(0.5),
                           radius: 5,
                           x: 0,
                           y: 0
                       )
                   )
               )
               .frame(
                   width: size,
                   height: size,
                   alignment: .center
               )
//               .shadow(
//                   color: Color.brandDropShadow(colorScheme).opacity(0.5),
//                   radius: 8,
//                   x: 0,
//                   y: 4
//               )
           }
           
           if let icon = randomIcon(),
              let color = randomColor(),
              let blend = randomBlendMode(),
              let sign = randomSigil() {
//               Text(sign)
//                   .font(.system(size: 55, weight: .heavy))
//                   .frame(width: size, height: size)
//                   .foregroundColor(Color.brandBgSlate)
//                   .blendMode(.hardLight)
//                   .opacity(0.2)
//                   .blur(radius: 3.0)
//
//               Text(sign)
//                   .font(.system(size: 55, weight: .heavy))
//                   .frame(width: size, height: size)
//                   .foregroundColor(color)
//                   .blendMode(blend)
//                   .opacity(0.9)
               Image(systemName: icon)
                   .resizable()
                   .frame(width: size / 2, height: size / 2)
                   .foregroundColor(Color.brandBgSlate)
                   .blendMode(.hardLight)
                   .opacity(0.2)
                   .blur(radius: 3.0)

               Image(systemName: icon)
                   .resizable()
                   .frame(width: size / 2, height: size / 2)
                   .foregroundColor(color)
                   .blendMode(blend)
                   .opacity(0.9)
           }
           
//           Image(systemName: "sparkles")
//           Image(systemName: "moon.fill")
           
//           if let phase = randomMoonPhase() {
//               Image(systemName: phase)
//                   .resizable()
//                   .frame(width: size + 4, height: size + 4)
//                   .foregroundColor(.brandBgSlate)
//                   .blendMode(.plusDarker)
//                   .opacity(0.6)
//           }
           
//           ForEach(0..<8) { _ in
//               let size = Double.random(in: 4..<16)
//               StarShape()
//                   .fill(Color.white)
//                   .frame(width: size, height: size)
//                   .offset(randomPosition())
//                   .rotationEffect(Angle(degrees: Double.random(in: 0..<360)))
//                   .opacity(animate ? 1 : 0)
//                   .animation(Animation.easeInOut(duration: 1).repeatForever().speed(Double.random(in: 0.1...0.6)), value: animate)
//           }
       }
       .onAppear {
           self.animate = true
       }
   }
   
   func randomPosition() -> CGSize {
       let radius: CGFloat = Double.random(in: 0..<size)
       let angle = Double.random(in: 0 ..< 360)
       let x = 0 + radius * cos(angle * .pi / 180)
       let y = 0 + radius * sin(angle * .pi / 180)
       return CGSize(width: x, height: y)
   }
}

struct GenerativeProfilePic_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            VStack {
                GenerativeProfilePic()
                GenerativeProfilePic()
                GenerativeProfilePic()
                GenerativeProfilePic()
                GenerativeProfilePic()
                GenerativeProfilePic()
                GenerativeProfilePic()
                GenerativeProfilePic()
                GenerativeProfilePic()
            }
            VStack {
                GenerativeProfilePic()
                GenerativeProfilePic()
                GenerativeProfilePic()
                GenerativeProfilePic()
                GenerativeProfilePic()
                GenerativeProfilePic()
                GenerativeProfilePic()
                GenerativeProfilePic()
                GenerativeProfilePic()
            }
            VStack {
                GenerativeProfilePic()
                GenerativeProfilePic()
                GenerativeProfilePic()
                GenerativeProfilePic()
                GenerativeProfilePic()
                GenerativeProfilePic()
                GenerativeProfilePic()
                GenerativeProfilePic()
                GenerativeProfilePic()
            }
            VStack {
                GenerativeProfilePic()
                GenerativeProfilePic()
                GenerativeProfilePic()
                GenerativeProfilePic()
                GenerativeProfilePic()
                GenerativeProfilePic()
                GenerativeProfilePic()
                GenerativeProfilePic()
                GenerativeProfilePic()
            }
        }
    }
}
