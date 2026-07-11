//
//  NewsView.swift
//  SuperPreview
//
//  Created by admin on 2021/5/7.
//  Copyright © 2021 PeterZ. All rights reserved.
//

import SwiftUI

struct NewsView: View {
    var body: some View {


                ScrollView{
                    // 轮播图
                    NewsCarouselView()

                    EveningSummaryClipView()
                        .padding(.vertical, 10)

                    VStack(spacing: 0.0) {
                        Group{ //the maximum number of views in a container is exceeded. The max = 10

                        // #1
                        NavigationLink(
                                destination: NewsDetailView(),
                            label:{
                                NewsTextItemView(title:"美联储议息会议前瞻：美联储或延续鸽派基调", source: "有鱼资讯")
                            })

                        NavigationLink(destination: EmptyView()) {
                            EmptyView()
                        }

                        // #2
                        NewsTextImageItemView(title: "中国4月官方制造业PMI 51.1，高于2019年和2020年同期水平", source: "有鱼资讯", image_name: "city_view")
                        // #3
                        NewsTextItemView(title:"巴菲特股东大会本周来袭，这是投资者最关心的问题", source: "Yahoo Finance")
                        // #4
                            NewsTextImageItemView(title: "iOS 14.5 发布：AirTag能用了，苹果全新隐私保护策略上线", source: "智通财经", image_name: "airtag")
                        // #5
                        NewsTextImageItemView(title: "医美股爆发！A股医美股掀涨停潮，港股瑞丽医美飙涨25%", source: "有鱼资讯", image_name: "facial")
                        // #6
                        NewsTextImageItemView(title: "苹果(AAPL.US)Q2多项指标超预期，华尔街投行预计2022年初市值将达3万亿美元", source: "有鱼资讯", image_name: "macbook")
                        // #7
                        NewsTextImageItemView(title: "美团被市场监管总局立案调查！医药平台经济全线合规提速！", source: "燃次元", image_name: "meituan")
                        // #8
                        NewsTextImageItemView(title: "中国4月官方制造业PMI 51.1，高于2019年和2020年同期水平", source: "有鱼资讯", image_name: "tesla")
                        // #9
                        NewsTextImageItemView(title: "中国4月官方制造业PMI 51.1，高于2019年和2020年同期水平", source: "有鱼资讯", image_name: "tesla")
                        // #10
//                            NewsTextItemView(title:"巴菲特股东大会本周来袭，这是投资者最关心的问题", source: "Yahoo Finance")

                        }
                    }


                }
                .navigationViewStyle(StackNavigationViewStyle())
                .background(Color("color-base-1"))
        }
    }



struct NewsViewPreviews: PreviewProvider {
    static var previews: some View {
        Group {
            NewsView()
                .preferredColorScheme(.dark)
        }
    }
}
