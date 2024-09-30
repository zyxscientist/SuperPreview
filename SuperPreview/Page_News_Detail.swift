//
//  Page_News_Detail.swift
//  SuperPreview
//
//  Created by admin on 2021/4/29.
//  Copyright © 2021 PeterZ. All rights reserved.
//

import SwiftUI

struct Page_News_Detail: View {
    
    @State var scrollViewOffset: CGFloat = 0
    @State var startOffset: CGFloat = 0
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {

        if #available(iOS 14.0, *) {
            ScrollViewReader { proxyReader in
                ScrollView() {
                    VStack {
                        VStack(spacing: 0.0){
                            Comp_News_Title(news_title: "苹果(AAPL.US)造车或成为特斯拉(TSLA.US)重大利空，维持目标价880美元", fontsize: 24)
                                .padding(.top, 20)
                            Comp_Article_Time_Info()
                        }
                        
                        VStack(spacing: 10.0) {
                            Comp_News_Related_Stocks_Gain(name: "特斯拉(TSLA.US)")
                            Comp_News_Related_Stocks_Gain(name: "苹果(AAPL.US)")
                            Comp_News_Related_Stocks_Loss(name: "摩根史丹利(MS.US)")
                    }.padding(.vertical, 10)
                        
                        VStack(spacing: 0.0){
                            Comp_News_Writer()
                            Comp_News_Brief()
                            Comp_Heading_1(content: "特斯拉Q1财报")
                            Comp_Paragraph(content: "周一美股盘后，特斯拉发布2021年第一季度业绩及财务报告，数据显示：2021年一季度，特斯拉总营收103.89亿美元，同比增长74%；汽车业务的总营收为90.02亿美元，去年同期为51.32亿美元，同比增75%；一季度毛利润22.15亿美元，同比增长79%，GAAP毛利率为21.3%，增长70个基点。", fontsize: 18)
                            
                            Comp_Image_View(image_name: "tesla")
                            
                            Comp_Heading_2(content: "大行观点")
                            
                            
                            Comp_Paragraph(content: "摩对特斯拉目标价为880美元，该目标价中有345美元来自核心汽车业务，该行预计到2030年，特斯拉汽车销售将达540万辆；另外，基于DCF模型，该行预计到2030年，特斯拉移动服务支持业务(Tesla Mobility)的对应估值为77美元/股；此外，100美元来自第三方电池业务和电动车动力系统供应业务，75美元来自来自特斯拉能源的固定存储系统，36美元来自保险业务，246美元来自数据网络服务业务，该行预计到2030年该业务的每用户平均收入(ARPU)将达到100美元。", fontsize: 18      )
                            
                            Comp_News_Quote()
                            
                            Comp_Paragraph(content: "摩对特斯拉目标价为880美元，该目标价中有345美元来自核心汽车业务，该行预计到2030年，特斯拉汽车销售将达540万辆；另外，基于DCF模型，该行预计到2030年，特斯拉移动服务支持业务(Tesla Mobility)的对应估值为77美元/股；此外，100美元来自第三方电池业务和电动车动力系统供应业务，75美元来自来自特斯拉能源的固定存储系统，36美元来自保险业务，246美元来自数据网络服务业务，该行预计到2030年该业务的每用户平均收入(ARPU)将达到100美元。", fontsize: 18)
                            Comp_Disclaimer()
                            }.padding(.top, 20)
                    
                    }
                    .id("SCROLL_TO_TOP")
                    .overlay (
                        GeometryReader{ proxy -> Color in
                            DispatchQueue.main.async {
                                if startOffset == 0{
                                    self.startOffset = proxy.frame(in: .global).minY
                                }
                                
                                let offset = proxy.frame(in: .global).minY
                                self.scrollViewOffset = offset - startOffset
                                
                                print(self.scrollViewOffset)
                            }
                            
                           return Color.clear
                        })
                    
                    
                }
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        HStack(alignment: .top, spacing:0) {
                            Image("back-Left")
                                .onTapGesture {
                                    presentationMode.wrappedValue.dismiss()
                                }
                        }
                    }
                }
                .navigationBarBackButtonHidden(true)
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle("详情")
                .background(Color("color-base-1"))
                
                
                // 滚动至顶部按钮
                .overlay(
                    Button(action: {
                        withAnimation(.easeOut) {
                            proxyReader.scrollTo("SCROLL_TO_TOP", anchor : .top)
                        }
                    }, label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color("color-text-30"))
                            .padding(10)
                            .background(Color("color-scale-2"))
                            .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
                            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 0)
                    })
                    .padding(.trailing,15)
                    .padding(.bottom,55)
                    .opacity(-scrollViewOffset > 450 ? 1 : 0)
                    .offset(y: -scrollViewOffset > 450 ? 0 : 70)
                    .animation(.easeInOut(duration: 0.2))
                    ,alignment: .bottomTrailing
            )
            }
            
        } else {
            // Fallback on earlier versions
        }
    }
}

struct Page_News_Detail_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 14.0, *) {
            ZStack {
                Color("color-base-0")
                    .ignoresSafeArea(.container)
                Page_News_Detail()
            }
        } else {
            // Fallback on earlier versions
        }
    }
}
