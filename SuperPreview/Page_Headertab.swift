//
//  Page_Headertab.swift
//  SuperPreview
//
//  Created by PeterZ on 2021/8/8.
//  Copyright © 2021 PeterZ. All rights reserved.
//

import SwiftUI

struct Page_Headertab: View {
    
    
    var body: some View {
        
        VStack {
            HeeaderTabView()
        }
        
    }
}

struct Page_Headertab_Previews: PreviewProvider {
    static var previews: some View {
        Page_Headertab()
    }
}


struct HeeaderTabView: View {
    
    @State var index = 0
    
    var body: some View {
        
        HStack(spacing: 0.0){
            VStack(alignment: .center, spacing: 5.0)  {
                Text("持仓")
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
                Text("美股")
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
                Text("港股")
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
                Text("沪深")
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
                Text("新能源")
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
        }
        .padding(.horizontal, 15)
        .background(Color("color-base-1"))
        .overlay(
            Comp_Separator_Full()
        )
        
        
        // The under view group by headertab
        
        if #available(iOS 14.0, *) {
            TabView(selection: self.$index){
                Text("持仓").tag(0)
                Text("美股").tag(1)
                Text("港股").tag(2)
                Text("沪深").tag(3)
                Text("新能源").tag(4)
            }.tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        } else {
            // Fallback on earlier versions
        }
    }
}
