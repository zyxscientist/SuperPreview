//
//  AssetRatioView.swift
//  SuperPreview
//
//  Created by PeterZ on 2020/8/30.
//  Copyright © 2020 PeterZ. All rights reserved.
//

import SwiftUI

struct AssetRatioView: View {
    @Environment(\.marketColorReversed) private var marketColorReversed
    var body: some View {
            VStack {
                VStack {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 5.0) {
                            HStack(spacing: 5.0) {
                                HStack(spacing: 5.0) {
                                    Image("show")
                                    Text("总资产")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(Color("color-text-60"))
                                }
                                HStack(alignment: .center, spacing: 0.0) {
                                    Text("HKD")
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(Color("color-blue1"))
                                    Image("switch_nor")
                                }
                            }
                            Text("12,300,201.12")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(Color("color-text1"))
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 5.0) {
                            HStack(spacing: 0.0){
                                Text("持仓收益")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(Color("color-text3"))
                                Image("question")
                                }
                            VStack(alignment: .trailing) {
                                Text("+123,200.11")
                                        .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(MarketColor.resolve("color-utility-red", reversed: marketColorReversed))
                                Text("+29.21%")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(MarketColor.resolve("color-utility-red", reversed: marketColorReversed))
                                }
                            }
                        
                    }
                    Spacer()
                    HStack {
                        HStack(spacing: 5.0){
                            Circle()
                                .frame(width: 7, height: 7)
                                .padding(.bottom, 18)
                                .foregroundColor(Color("color-blue1"))
                            VStack(alignment: .leading){
                                Text("股票")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(Color("color-text1"))
                                Text("54.32%")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color("color-text1"))
                            }
                        }
                        Spacer()
                        HStack(spacing: 5.0){
                            Circle()
                                .frame(width: 7, height: 7)
                                .padding(.bottom, 18)
                                .foregroundColor(Color("color-fund-orange"))
                            VStack(alignment: .leading){
                                Text("基金")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(Color("color-text1"))
                                Text("24.32%")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color("color-text1"))
                            }
                        }
                        Spacer()
                        HStack(spacing: 5.0){
                            Circle()
                                .frame(width: 7, height: 7)
                                .padding(.bottom, 18)
                                .foregroundColor(Color("color-emoney-gold"))
                            VStack(alignment: .leading){
                                Text("有鱼额")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(Color("color-text1"))
                                Text("14.32%")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color("color-text1"))
                            }
                        }
                        Spacer()
                        HStack(spacing: 5.0){
                            Circle()
                            .frame(width: 7, height: 7)
                            .padding(.bottom, 18)
                            .foregroundColor(Color("color-cash-purple"))
                            VStack(alignment: .leading){
                                Text("现金")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(Color("color-text1"))
                                Text("10.01%")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color("color-text1"))
                            }
                        }
                    }
                    
                    ZStack(alignment: .leading) {
                        Capsule().frame(width: 365, height: 6)
                            .foregroundColor(Color("color-cash-purple"))
                        Capsule().frame(width: 309, height: 6)
                        .foregroundColor(Color("color-emoney-gold"))
                        Capsule().frame(width: 264, height: 6)
                            .foregroundColor(Color("color-fund-orange"))
                        Capsule().frame(width: 173, height: 6)
                            .foregroundColor(Color("color-blue1"))
                    }.padding(.bottom,10)
                    
                    
                }
                .padding(.horizontal,10)
                .padding(.top, 10)
                .frame(height: 150)
                .background(Color("color-base1"))
                .cornerRadius(13, antialiased: true)
            }
            .padding(.horizontal, 10)
    }
}

struct AssetRatioViewPreviews: PreviewProvider {
    static var previews: some View {
        AssetRatioView().environment(\.colorScheme, .dark)
    }
}
