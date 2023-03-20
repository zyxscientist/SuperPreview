//
//  Page_Compare.swift
//  SuperPreview
//
//  Created by PeterZ on 2022/06/09.
//  Copyright © 2022 PeterZ. All rights reserved.
//

import SwiftUI


struct Page_Compare: View {
    var body: some View {
        VStack(spacing: 0.0) {
            Page_Compare_HeaderTabView()
        }
    }
}

struct Page_Compare_Previews: PreviewProvider {
static var previews: some View {
        ZStack {
            Color("color-base-0")
                .edgesIgnoringSafeArea(.all)
            Page_Compare()
        }
        .preferredColorScheme(.dark)
    }
}



struct Page_Compare_HeaderTabView: View {
    
    @State var index = 0
    
    var body: some View {
        
        HStack(spacing: 0.0){
            VStack(alignment: .center, spacing: 5.0)  {
                Text("对比")
                    .font(.system(size: 16))
                    .foregroundColor(self.index == 0 ? Color("color-text-30") : Color("color-text-60"))
                    .fontWeight(self.index == 0 ? .semibold : .regular)
                    .onTapGesture {
                        withAnimation(.none){
                            self.index = 0
                        }
                    }
                
                Capsule()
                    .frame(width:30  ,height: 2)
                    .foregroundColor(Color("color-brand-blue").opacity(self.index == 0 ? 1 : 0))
                
            }
            .fixedSize()
            .padding(.trailing, 20)
            .padding(.leading, 0)
            .padding(.top, 11)
            
            VStack(alignment: .center, spacing: 5.0)  {
                Text("全涨")
                    .font(.system(size: 16))
                    .foregroundColor(self.index == 1 ? Color("color-text-30") : Color("color-text-60"))
                    .fontWeight(self.index == 1 ? .semibold : .regular)
                    .onTapGesture {
                        withAnimation(.none){
                            self.index = 1
                        }
                    }
                
                Capsule()
                    .frame(height: 2)
                    .foregroundColor(Color("color-brand-blue").opacity(self.index == 1 ? 1 : 0))
                
            }
            .fixedSize()
            .padding(.trailing, 20)
            .padding(.leading, 0)
            .padding(.top, 11)
            
            
            VStack(alignment: .center, spacing: 5.0)  {
                Text("全跌")
                    .font(.system(size: 16))
                    .foregroundColor(self.index == 2 ? Color("color-text-30") : Color("color-text-60"))
                    .fontWeight(self.index == 2 ? .semibold : .regular)
                    .onTapGesture {
                        withAnimation(.none){
                            self.index = 2
                        }
                    }
                
                Capsule()
                    .frame(height: 2)
                    .foregroundColor(Color("color-brand-blue").opacity(self.index == 2 ? 1 : 0))
                
            }
            .fixedSize()
            .padding(.trailing, 20)
            .padding(.leading, 0)
            .padding(.top, 11)
            
            
            VStack(alignment: .center, spacing: 5.0)  {
                Text("涨跌")
                    .font(.system(size: 16))
                    .foregroundColor(self.index == 3 ? Color("color-text-30") : Color("color-text-60"))
                    .fontWeight(self.index == 3 ? .semibold : .regular)
                    .onTapGesture {
                        withAnimation(.none){
                            self.index = 3
                        }
                    }
                
                Capsule()
                .frame(height: 2)
                    .foregroundColor(Color("color-brand-blue").opacity(self.index == 3 ? 1 : 0))
                
            }
            .fixedSize()
            .padding(.trailing, 20)
            .padding(.leading, 0)
            .padding(.top, 11)
            
            
            VStack(alignment: .center, spacing: 5.0)  {
                Text("其他")
                    .font(.system(size: 16))
                    .foregroundColor(self.index == 4 ? Color("color-text-30") : Color("color-text-60"))
                    .fontWeight(self.index == 4 ? .semibold : .regular)
                    .onTapGesture {
                        withAnimation(.none){
                            self.index = 4
                        }
                    }
                
                Capsule()
                    .frame(height: 2)
                    .foregroundColor(Color("color-brand-blue").opacity(self.index == 4 ? 1 : 0))
                
            }
            .fixedSize()
            .padding(.trailing, 20)
            .padding(.leading, 0)
            .padding(.top, 11)
            
            Spacer()
            
            Image("headertab_sort")
                .padding(.top, 4)
        }
        .padding(.leading, 15)
        .padding(.trailing, 11)
        .background(Color("color-base-1"))
        .overlay(
            Comp_Separator_Full()
        )
        
        
        // The under view group by headertab
        
        if #available(iOS 14.0, *) {
            TabView(selection: self.$index){
                Tab_Compare_1().tag(0)
                Tab_Compare_2().tag(1)
                Tab_Compare_3().tag(2)
                Tab_Compare_4().tag(3)
                Tab_Compare_5().tag(4)
            }
            .edgesIgnoringSafeArea(.all)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        } else {
            // Fallback on earlier versions
        }
    }
}


struct Tab_Compare_1: View {
    var body: some View {

            ScrollView{
                VStack(spacing: 0.0){
                    Comp_TableHeader_Watchlist(key_col: "名称", first_col: "现价", second_col: "涨跌幅")
                    VStack(spacing: 0.0) {
                        ForEach(stocks_compare) { stock in
                            Comp_Watchlist_Item(stock: stock)
                        }
                    }
                }.background(Color("color-base-0"))
            }
        }
    }


struct Tab_Compare_2: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0.0){
                Comp_TableHeader_Watchlist(key_col: "名称", first_col: "现价", second_col: "涨跌幅")
                VStack(spacing: 0.0) {
                    ForEach(stocks_2) { stock in
                        Comp_Watchlist_Item(stock: stock)
                    }
                }
            }.background(Color("color-base-0"))
        }
    }
}


struct Tab_Compare_3: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0.0){
                Comp_TableHeader_Watchlist(key_col: "名称", first_col: "现价", second_col: "涨跌幅")
                VStack(spacing: 0.0) {
                    ForEach(stocks_4) { stock in
                        Comp_Watchlist_Item(stock: stock)
                    }
                }
            }.background(Color("color-base-0"))
        }
    }
}


struct Tab_Compare_4: View {
    var body: some View{
        ScrollView{
            VStack(spacing: 0.0){
                Comp_TableHeader_Watchlist(key_col: "名称", first_col: "现价", second_col: "涨跌幅")
                VStack(spacing: 0.0) {
                    ForEach(stocks_5) { stock in
                        Comp_Watchlist_Item(stock: stock)
                    }
                }
            }.background(Color("color-base-0"))
        }
    }
}

struct Tab_Compare_5: View {
    var body: some View{
        ScrollView{
            VStack(spacing: 20.0){
                
                Text("1234567890")
                    .lineLimit(1)
                    .modifier(CustomFontModifier(size: 32, font: .medium))
                    .foregroundColor(Color("color-utility3-red"))
                
                Text("1212121212")
                    .lineLimit(1)
                    .modifier(CustomFontModifier(size: 32, font: .medium))
                    .foregroundColor(Color("color-utility3-green"))
                
                Text("1234567890")
                    .lineLimit(1)
                    .modifier(CustomFontModifier(size: 20, font: .medium))
                    .foregroundColor(Color("color-utility3-red"))
                
                Text("1234567890")
                    .lineLimit(1)
                    .modifier(CustomFontModifier(size: 20, font: .medium))
                    .foregroundColor(Color("color-utility3-green"))
                
                Text("1234567890")
                    .lineLimit(1)
                    .modifier(CustomFontModifier(size: 12, font: .medium))
                    .foregroundColor(Color("color-utility3-red"))
                
                Text("1234567890")
                    .lineLimit(1)
                    .modifier(CustomFontModifier(size: 12, font: .medium))
                    .foregroundColor(Color("color-utility3-green"))
                
                
                VStack {
                    HStack(spacing: 10){
                        Rectangle()
                            .foregroundColor(Color("color-utility3-red"))
                            .frame(width:175, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
                            .overlay(
                                Text("买入")
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                            )
                        
                        Rectangle()
                            .foregroundColor(Color("color-utility3-green"))
                            .frame(width:175, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
                            .overlay(
                                Text("卖出")
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                            )
                        
                    }
                    
                        Rectangle()
                            .foregroundColor(Color("color-brand-blue"))
                            .frame(height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 10.0, style: .continuous))
                            .padding(.horizontal, 15)
                            .overlay(
                                Text("解锁交易")
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                            )
                }
                    
                
                HStack {
                    ExtractedView(index_name: "恒生指数",utility_color: "color-utility3-red")
                    ExtractedView(index_name: "国企指数",utility_color: "color-utility3-red")
                    ExtractedView(index_name: "红筹指数",utility_color: "color-utility3-green")
                }
                
                
                VStack(spacing: 10.0) {
                    VolumeCompare()
                    VStack(spacing: 0.0) {
                        Tape_First()
                        Tape_Other(tapeIndex: "2")
                        Tape_Other(tapeIndex: "3")
                        Tape_Other(tapeIndex: "4")
                        Tape_Other(tapeIndex: "5")
                        Tape_Other(tapeIndex: "6")
                        Tape_Other(tapeIndex: "7")
                        Tape_Other(tapeIndex: "8")
                        Tape_Other(tapeIndex: "9")
                        Tape_Other(tapeIndex: "10")
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 6.0, style: .continuous))
                }
                .background(Color("color-base-1"))

                
                
                
                
                
            }
            
            
        }
        .frame(width: 390) // 整个背景的宽度
        .background(Color("color-base-0"))
    }
}

struct ExtractedView: View {
    
    var index_name = "恒生指数"
    var utility_color = "color-utility3-red"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0.0){
            Text(index_name)
                .font(.system(size: 12))
                .fontWeight(.medium)
                .padding(.bottom, 2)
            
            Text("23308.99")
                .modifier(CustomFontModifier(size: 16, font: .medium))
                .foregroundColor(Color(utility_color))
                .padding(.bottom, 4)
            
            HStack(spacing: 10){
                Text("+195.77")
                    .modifier(CustomFontModifier(size: 12, font: .medium))
                    .foregroundColor(Color(utility_color))
                
                Text("+1.99%")
                    .modifier(CustomFontModifier(size: 12, font: .medium))
                    .foregroundColor(Color(utility_color))
            }.padding(.bottom, 10)
            
            ZStack{
                Fill_Mini_LineGraph(dataPoints: ChartMockData.miniChart_50_point.normalized, bottomBuffer: 0)
                    .fill(LinearGradient(gradient: Gradient(colors: [Color(utility_color).opacity(0.2), Color(utility_color).opacity(0.0)]), startPoint: .top, endPoint: .bottom))
                    .frame(width: 88, height: 44)
                
                Mini_LineGraph(dataPoints: ChartMockData.miniChart_50_point.normalized)
                    .stroke(Color(utility_color), style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
                    .frame(width: 88, height: 44)
                
            }
            
        }
        .padding(10)
        .frame(minHeight: 140)
        .background(Color("color-base-1"))
        .cornerRadius(10, antialiased: true)
    }
}

struct VolumeCompare: View {
    var body: some View {
        ZStack(alignment: .leading){
            Rectangle()
                .foregroundColor(Color("color-utility3-green"))
                .frame(width:390, height: 25)
            
            Rectangle()
                .foregroundColor(Color("color-utility3-red"))
                .frame(width:280, height: 25)
            
            HStack{
                
                Text("84.22%")
                    .foregroundColor(.white)
                    .modifier(CustomFontModifier(size: 12, font: .semibold))
                
                Spacer()
                
                Text("15.78%")
                    .foregroundColor(.white)
                    .modifier(CustomFontModifier(size: 12, font: .semibold))
                
                
            }
            .padding(.horizontal, 25)
            
        }
        .frame(width: 360)
        .cornerRadius(6)
    }
}

struct Tape_First: View {
    var body: some View {
        ZStack {
            
            HStack(spacing: 0.0){
                Rectangle()
                    .foregroundColor(Color("color-utility3-red").opacity(0.10))
                    .frame(width:180, height: 35)
                    .overlay(
                        HStack{
                            Text("799.980")
                                .foregroundColor(Color("color-utility3-red"))
                                .modifier(CustomFontModifier(size: 12, font: .semibold))
                                .padding(.leading, 10)
                            
                            Spacer()
                            
                            Text("100")
                                .foregroundColor(Color("color-text-30"))
                                .modifier(CustomFontModifier(size: 12, font: .semibold))
                                .padding(.trailing, 20)
                        }
                    )
                
                Rectangle()
                    .foregroundColor(Color("color-utility3-green").opacity(0.10))
                    .frame(width:180, height: 35)
                    .overlay(
                        HStack{
                            Text("799.980")
                                .foregroundColor(Color("color-utility3-green"))
                                .modifier(CustomFontModifier(size: 12, font: .semibold))
                                .padding(.leading, 20)
                            
                            Spacer()
                            
                            Text("100")
                                .foregroundColor(Color("color-text-30"))
                                .modifier(CustomFontModifier(size: 12, font: .semibold))
                                .padding(.trailing, 10)
                        }
                    )
            }
            
            Rectangle()
                .foregroundColor(.white)
                .frame(width:19, height: 19)
                .clipShape(RoundedRectangle(cornerRadius: 4.0, style: .continuous))
                .overlay(
                    Text("1")
                        .foregroundColor(.black)
                        .modifier(CustomFontModifier(size: 12, font: .medium))
                )
        }
    }
}


struct Tape_Other: View {
    var tapeIndex = "1"
    
    var body: some View {
        ZStack {
            
            HStack(spacing: 0.0){
                Rectangle()
                    .foregroundColor(Color("color-utility3-red").opacity(0.05))
                    .frame(width:180, height: 35)
                    .overlay(
                        HStack{
                            Text("799.980")
                                .foregroundColor(Color("color-utility3-red"))
                                .modifier(CustomFontModifier(size: 12, font: .semibold))
                                .padding(.leading, 10)
                            
                            Spacer()
                            
                            Text("100")
                                .foregroundColor(Color("color-text-30"))
                                .modifier(CustomFontModifier(size: 12, font: .semibold))
                                .padding(.trailing, 20)
                        }
                    )
                
                Rectangle()
                    .foregroundColor(Color("color-utility3-green").opacity(0.05))
                    .frame(width:180, height: 35)
                    .overlay(
                        HStack{
                            Text("799.980")
                                .foregroundColor(Color("color-utility3-green"))
                                .modifier(CustomFontModifier(size: 12, font: .semibold))
                                .padding(.leading, 20)
                            
                            Spacer()
                            
                            Text("100")
                                .foregroundColor(Color("color-text-30"))
                                .modifier(CustomFontModifier(size: 12, font: .semibold))
                                .padding(.trailing, 10)
                        }
                    )
            }
            
            Rectangle()
                .foregroundColor(.white)
                .frame(width:19, height: 19)
                .clipShape(RoundedRectangle(cornerRadius: 4.0, style: .continuous))
                .overlay(
                    Text(tapeIndex)
                        .foregroundColor(.black)
                        .modifier(CustomFontModifier(size: 12, font: .medium))
                )
        }
    }
}

