//
//  Comp_Stock_List.swift
//  SuperPreview
//
//  Created by PeterZ on 2020/10/18.
//  Copyright © 2020 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_Watchlist_Item: View {
    var stock: Stock = stocks[1]
    var normal_text_size = 15
    var nameLength: Int {
        
        if (stock.name.count > 16) {
            return 12
        }else{
            return normal_text_size
        }
    }
    
    var body: some View {
        
            HStack(alignment: .center, spacing: 0.0) {
                    VStack(alignment: .leading, spacing: 4.0) {
                        HStack(alignment: .center, spacing: 2.0) {
                            
                            Image(stock.type_icon)
                            Text(stock.name)
                                .multilineTextAlignment(.trailing)
                                .lineLimit(1)
                                .font(.system(size: CGFloat(nameLength), weight: .medium))
                                .foregroundColor(Color("color-text-30"))
                                

                        }
                
                        HStack(alignment: .center, spacing: 2.0) {
                            
                            Text(stock.symbol)
                                .modifier(CustomFontModifier(size: 12, font: .medium))
                                .foregroundColor(Color("color-text-60"))
                                .padding(.leading, 15)
                            Image(stock.alert ? "price_alert" : "no_any_watchlist_mark_icon")
                            
                        }
                    }
                
                Spacer()
                
                
                HStack(spacing: 15){
                HStack(spacing:0){
                    
                    // MARK: 迷你K线图
                    
                    ZStack{
                        Fill_Mini_LineGraph(dataPoints: ChartMockData.miniChart_50_point.normalized, bottomBuffer: 0)
                            .fill(LinearGradient(gradient: Gradient(colors: [Color(stock.direction).opacity(0.2), Color(stock.direction).opacity(0.0)]), startPoint: .top, endPoint: .bottom))
                            .frame(width: 55, height: 40)
                        
                        Mini_LineGraph(dataPoints: ChartMockData.miniChart_50_point.normalized)
                            .stroke(Color(stock.direction), style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
                            .frame(width: 55, height: 40)
                        
                    }
     
                
                    Text(stock.price)
                        .multilineTextAlignment(.trailing)
                        .modifier(CustomFontModifier(size: 15, font: .medium))
    //                    .foregroundColor(Color(stock.direction))
                        .foregroundColor(Color("color-text-30"))
                        .frame(width: 76, alignment: .trailing)
                }
                    
                    Rectangle()
                        .foregroundColor(Color(stock.direction))
                        .frame(width:80, height: 24)
                        .cornerRadius(4)
                        .overlay(
                            Text(stock.rate)
                                .modifier(CustomFontModifier(size: 15, font: .medium))
                                .foregroundColor(.white)
                        )
                    .padding(.trailing, 10)
                    
                }
                        
        }
        .frame(minHeight: 60, maxHeight: 60)
        .background(Color("color-base-1"))
        .overlay(
            Comp_Separator_Leading()
        )
    }
    
}

struct Comp_Stock_List_Previews: PreviewProvider {
    static var previews: some View {
        Comp_Watchlist_Item().previewLayout(.sizeThatFits)
    }
}


