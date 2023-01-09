//
//  Graph_GradientLineChart_DOWN.swift
//  SuperPreview
//
//  Created by PeterZ on 2020/9/26.
//  Copyright © 2020 PeterZ. All rights reserved.
//

import SwiftUI

struct Graph_GradientLineChart_DOWN: View {
    var body: some View {
        ZStack {
            Path() { path in
                path.move(to: CGPoint(x: 0, y: 1))
                path.addLine(to: CGPoint(x: 22, y: 12))
                path.addLine(to: CGPoint(x: 33, y: 6))
                path.addLine(to: CGPoint(x: 51, y: 14))
                path.addLine(to: CGPoint(x: 63, y: 10))
                path.addLine(to: CGPoint(x: 76, y: 13))
                path.addLine(to: CGPoint(x: 85, y: 9))
                path.addLine(to: CGPoint(x: 90, y: 12))
                path.addLine(to: CGPoint(x: 100, y: 24))
                path.addLine(to: CGPoint(x: 100, y: 24))
                path.addLine(to: CGPoint(x: 0, y: 24))
                path.closeSubpath()
                }.fill(LinearGradient(gradient: Gradient(colors: [Color("color-utility-green").opacity(0.8), Color("color-utility-green").opacity(0.01)]), startPoint: .top, endPoint: .bottom)).frame(width: 100, height: 24)
            
            Path() { path in
                path.move(to: CGPoint(x: 0, y: 1))
                path.addLine(to: CGPoint(x: 22, y: 12))
                path.addLine(to: CGPoint(x: 33, y: 6))
                path.addLine(to: CGPoint(x: 51, y: 14))
                path.addLine(to: CGPoint(x: 63, y: 10))
                path.addLine(to: CGPoint(x: 76, y: 13))
                path.addLine(to: CGPoint(x: 85, y: 9))
                path.addLine(to: CGPoint(x: 90, y: 12))
                path.addLine(to: CGPoint(x: 100, y: 24))
                }.stroke(Color("color-utility-green"), lineWidth: 2).frame(width: 100, height: 24)
        }
    }
}
struct Graph_GradientLineChart_DOWN_Previews: PreviewProvider {
    static var previews: some View {
        Graph_GradientLineChart_DOWN()
    }
}
