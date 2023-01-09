//
//  Comp_MiniChart.swift
//  SuperPreview
//
//  Created by admin on 2021/10/20.
//  Copyright © 2021 PeterZ. All rights reserved.
//

import SwiftUI

// draw the line chart legend area

struct Mini_LineGraph: Shape{
    
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
struct Fill_Mini_LineGraph: Shape{

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

struct Comp_MiniChart: View {
    
    var body: some View {
        VStack(spacing: 100.0) {
            ZStack{
                Fill_Mini_LineGraph(dataPoints: ChartMockData.miniChart_100_point.normalized, bottomBuffer: 0)
                    .fill(LinearGradient(gradient: Gradient(colors: [.red.opacity(0.2), .red.opacity(0.0)]), startPoint: .top, endPoint: .bottom))
                    .frame(width: 55, height: 40)
                
                Mini_LineGraph(dataPoints: ChartMockData.miniChart_100_point.normalized)
                    .stroke(Color("color-utility-red"), style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
                    .frame(width: 55, height: 40)
                
                Text("采样数据总数量：\(ChartMockData.miniChart_100_point.normalized.count)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .opacity(1)
            }
            
            ZStack{
                Fill_Mini_LineGraph(dataPoints: ChartMockData.miniChart_50_point.normalized, bottomBuffer: 0)
                    .fill(LinearGradient(gradient: Gradient(colors: [.red.opacity(0.2), .red.opacity(0.0)]), startPoint: .top, endPoint: .bottom))
                    .frame(width: 55, height: 40)
                
                Mini_LineGraph(dataPoints: ChartMockData.miniChart_50_point.normalized)
                    .stroke(Color("color-utility-red"), style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
                    .frame(width: 55, height: 40)
                
                Text("采样数据总数量：\(ChartMockData.miniChart_50_point.normalized.count)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .opacity(1)
                
            }
            
            ZStack{
                Fill_Mini_LineGraph(dataPoints: ChartMockData.miniChart_30_point.normalized, bottomBuffer: 0)
                    .fill(LinearGradient(gradient: Gradient(colors: [.red.opacity(0.2), .red.opacity(0.0)]), startPoint: .top, endPoint: .bottom))
                    .frame(width: 55, height: 40)
                
                Mini_LineGraph(dataPoints: ChartMockData.miniChart_30_point.normalized)
                    .stroke(Color("color-utility-red"), style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
                    .frame(width: 55, height: 40)
                
                Text("采样数据总数量：\(ChartMockData.miniChart_30_point.normalized.count)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .opacity(1)
                
            }
        }
            
    }
}

struct Comp_Mini_Previews: PreviewProvider {
    static var previews: some View {
        Comp_MiniChart()
    }
}
