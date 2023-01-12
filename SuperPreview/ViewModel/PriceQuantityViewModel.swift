//
//  PriceQuantityViewModel.swift
//  SuperPreview
//
//  Created by admin on 2023/1/12.
//  Copyright © 2023 PeterZ. All rights reserved.
//

import Foundation

class PriceQuantityViewModel: ObservableObject {
    
    @Published var price: Double = 16.43
    @Published var quantity: Int = 2000
    @Published var amount: Double = 32860.00
    
    func getAmount(){
        amount = price * Double(quantity)
        print(amount)
    }
    
    func increasePrice(){
        price += 0.1
    }
    
    func decreasePrice(){
        price -= 0.1
    }
    
    func increaseQuan(){
        quantity += 2000
    }
    
    func decreaseQuan(){
        quantity -= 2000
    }
    
}
