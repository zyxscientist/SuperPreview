//
//  StockOrderMotion.swift
//  SuperPreview
//

import SwiftUI

enum StockOrderMotion {
    static func expansion(reduceMotion: Bool) -> Animation? {
        reduceMotion
            ? nil
            : .spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.2)
    }
}
