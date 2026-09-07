//
//  LaunchScreen.swift
//  SuperPreview
//
//  Created by 朱宇軒 on 2021/11/27.
//  Copyright © 2021 PeterZ. All rights reserved.
//

import SwiftUI

struct LaunchScreen: View {
    
    @State var logoAnimation = false
    @State var isFinished = false
    
    var body: some View {
       
        if !isFinished {
        ZStack{
            if #available(iOS 14.0, *) {
                Color("color-base-0")
                    .ignoresSafeArea()
            } else {
                // Fallback on earlier versions
            }
            
            ZStack {
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 160, height: 160)
                    .opacity(logoAnimation ? 1 : 0)
                    .offset(y: logoAnimation ? 0 : 30)

                VStack {
                    Spacer()

                    Text("Version 5.6.0")
                        .foregroundColor(Color("color-text-90"))
                        .modifier(CustomFontModifier(size: 12, font: .regular))
                }
            }
        }
        .onAppear{
            
            DispatchQueue.main.asyncAfter(deadline: .now()+0.3){
                withAnimation(.easeOut(duration: 0.4)){
                    logoAnimation.toggle()
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9)
                {
                    
                    withAnimation(){
                        isFinished.toggle()
                        }
                    }
                }
            }
        }
    }
}

struct LaunchScreenPreviews: PreviewProvider {
    static var previews: some View {
        LaunchScreen()
    }
}
