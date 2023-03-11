//
//  NewSheetView.swift
//  SuperPreview
//
//  Created by 朱宇軒 on 2023/3/11.
//  Copyright © 2023 PeterZ. All rights reserved.
//

import SwiftUI

struct MarketSheetView: View {
    @Binding var marketOpen: Bool
    
    init(marketOpen: Binding<Bool>) {
        UITableView.appearance().separatorStyle = .none
        UITableView.appearance().backgroundColor = .clear
        UITableViewCell.appearance().backgroundColor = .clear
        self._marketOpen = marketOpen
    }
    
    var body: some View {
        BottomSheetView(isOpen: $marketOpen, maxHeight: UIScreen.main.bounds.height * 0.89) {
            ZStack{
                Color.white
                Rectangle().fill(Color.black.opacity(0.8))
                
                VStack(alignment: .leading) {
                    MarketSheetViewHeader()
                    Spacer()
                    Text("Market Page")
                }.padding()
            }
        }.edgesIgnoringSafeArea(.vertical)
    }
}

//struct NewSheetView_Previews: PreviewProvider {
//    static var previews: some View {
//        NewSheetView()
//    }
//}
