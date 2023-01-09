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
            
            ZStack{
                VStack {
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 140, height: 140)
                        .opacity( logoAnimation ? 1:0 )
                        .padding(.top, logoAnimation ? 240:270)
                    
                    Spacer()
                    
                    Image("name")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 134, height: 59)
                        .padding(.bottom, 25)
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

struct LaunchScreen_Previews: PreviewProvider {
    static var previews: some View {
        LaunchScreen()
    }
}
