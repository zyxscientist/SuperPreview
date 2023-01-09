//
//  LineChart.swift
//  SuperPreview
//
//  Created by PeterZ on 2021/8/25.
//  Copyright © 2021 PeterZ. All rights reserved.
//

import SwiftUI

// draw the line chart legend area

struct LineGraph: Shape{
    
    // data points
    var dataPoints:[CGFloat]
    
    func path(in rect: CGRect) -> Path {
        
        func point(at ix: Int) -> CGPoint{
            let point = dataPoints[ix]
            let x = rect.width * CGFloat(ix)/CGFloat(dataPoints.count - 1)
            let y = (1 - point) * rect.height
            
            return CGPoint(x:x, y:y)
        }
        
        return Path {p in
            guard dataPoints.count > 1 else { return }
            let start = dataPoints[0]
            p.move(to: CGPoint(x:0, y: (1 - start) * rect.height))
            
            for idx in dataPoints.indices{
                p.addLine(to: point(at: idx))
            }
        }
    }
    
}

    // fill the line chart legend area
struct Fill_LineGraph: Shape{

    var dataPoints:[CGFloat]
    var bottomBuffer: CGFloat
    
    func path(in rect: CGRect) -> Path {
        
        func point(at ix: Int) -> CGPoint{
            let point = dataPoints[ix]
            let x = rect.width * CGFloat(ix)/CGFloat(dataPoints.count - 1)
            let y = (1 - point) * rect.height
            
            return CGPoint(x:x, y:y)
        }
        
        return Path {p in
            guard dataPoints.count > 1 else { return }
            p.move(to: CGPoint(x:0, y: rect.height+bottomBuffer)) // 起始点
            
            for idx in dataPoints.indices{
                p.addLine(to: point(at: idx))
            }
                p.addLine(to: CGPoint(x: rect.width, y: (rect.height+bottomBuffer))) // 再手动加一个终点
                p.closeSubpath()
        }
    }
    
}

struct Comp_LineChart: View {
    
    var body: some View {
        ZStack {
            VStack{
                Divider()
                Spacer()
                Divider()
                Spacer()
                Divider()
                Spacer()
                Divider()
                Spacer()
                Divider()
            }.frame(height: 240, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)

            Fill_LineGraph(dataPoints: ChartMockData.oneMonth.normalized, bottomBuffer: 20)
                .foregroundColor(Color("color-brand-blue").opacity(0.15))
                .frame(width: 390, height: 200)
            
            LineGraph(dataPoints: ChartMockData.oneMonth.normalized)
                .stroke(Color("color-brand-blue"), lineWidth: 1)
                .frame(width: 390, height: 200)
            
            Text("返回数据总数量：\(ChartMockData.oneMonth.normalized.count)")
                .font(.caption)
                .foregroundColor(.gray)
            
        }
    }
}

extension Array where Element == CGFloat {
    // 返回正常值
    var normalized: [CGFloat] {
        if
            let min = self.min(),let max = self.max()
        {
            return self.map { ($0 - min) / (max - min) }
        }
        return []
    }
}

struct Comp_LineChart_Previews: PreviewProvider {
    static var previews: some View {
        Comp_LineChart()
    }
}
