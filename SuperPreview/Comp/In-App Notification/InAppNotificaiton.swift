//
//  InAppNotificaiton.swift
//  SuperPreview
//
//  Created by admin on 2025/1/7.
//  Copyright © 2025 PeterZ. All rights reserved.
//

import SwiftUI

struct InAppNotificaiton: View {
    @State private var showNotification = false
    @State private var hideNotification = false

    var body: some View {
        ZStack {
            
            Color(Color(.colorBase1)) // 使用系统颜色，或者自定义颜色
                           .edgesIgnoringSafeArea(.all) // 忽略安全区域，覆盖整个屏幕
            
            Image("fake_page_bg") // 替换为你的图片名称
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // 主界面内容
            VStack {
                Text("DEMO USAGE")
                    .foregroundColor(Color(.colorText90))
                    .font(.caption)
                    .offset(y: 200)
                    .padding()
                
                Button(action: {
                    
                    // 重置状态
                    
                    hideNotification = false
                    
                    withAnimation(.easeOut(duration: 0.9)) {
                        showNotification = true
                    }
                    
                    // 3秒后隐藏通知
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        withAnimation(.easeIn(duration: 1)) {
                            hideNotification = true
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now()+1.5) {
                            showNotification = false
                        }
                    }
                }) {
                    Text("显示通知")
                        .font(.title)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .offset(y: 200)
                
            }
            // 通知栏
            if showNotification && !hideNotification {
                NotificationView()
                    .transition(.move(edge: .top))
                    .animation(.easeIn(duration: 0.9), value: showNotification)
                    .zIndex(1) // 确保通知栏在最上层
            }
        }
        .navigationBarBackButtonHidden(true) // 隐藏返回按钮
        .navigationBarTitleDisplayMode(.inline)
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct NotificationView: View {
    var body: some View {
        VStack {
            HStack{
                HStack{
                    Text("您已成功使用港股佣金券额度88HKD。这笔佣金券可用于抵扣您在港股交易中产生的佣金费用，帮助您降低交易成本，提升投资回报。请确保在有效期内使用该额度，以免错过优惠。如果您有任何疑问或需要进一步了解佣金券的使用规则，可以随时联系您的客户经理或查看相关说明。祝您投资顺利！")
                        .lineLimit(3)
                        .modifier(CustomFontModifier(size: 16, font: .medium))
                        .foregroundColor(Color(.colorText30))
                        .padding(.leading, 15)
                        .padding(.vertical, 16)
                    Spacer()
                }
                .background(.regularMaterial)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 16.0)) // 剪个圆角
                .overlay( // 再次叠加
                            RoundedRectangle(cornerRadius: 16.0, style: .continuous)
                                .stroke(Color(.colorSeparator20), lineWidth: 0.5)
                         )
                .shadow(
                    color: Color.black.opacity(0.19), // 阴影颜色和透明度
                    radius: 11, // 阴影半径
                    x: 0, // 水平偏移
                    y: 0 // 垂直偏移
                )
            }
            .padding(.top, 50)
            .padding(.horizontal, 15)
            Spacer()
        }
    }
}

#Preview {
    InAppNotificaiton()
}
