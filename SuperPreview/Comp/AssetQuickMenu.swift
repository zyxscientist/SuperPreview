//
//  AssetQuickMenu.swift
//  SuperPreview
//

import SwiftUI

struct AssetQuickMenuItem: Identifiable {
    let id: String
    let title: String
    let imageName: String
    let action: () -> Void

    init(
        id: String? = nil,
        title: String,
        imageName: String,
        action: @escaping () -> Void
    ) {
        self.id = id ?? imageName
        self.title = title
        self.imageName = imageName
        self.action = action
    }
}

struct AssetQuickMenu: View {
    let items: [AssetQuickMenuItem]

    var body: some View {
        GeometryReader { proxy in
            let itemWidth = proxy.size.width / CGFloat(max(items.count, 1))

            HStack(spacing: 0) {
                ForEach(items) { item in
                    Button(action: item.action) {
                        VStack(spacing: 8) {
                            Image(item.imageName)
                                .resizable()
                                .frame(width: 30, height: 30)
                                .accessibilityHidden(true)

                            Text(item.title)
                                .font(.custom("PlusJakartaSans-Regular", size: 14, relativeTo: .subheadline))
                                .foregroundColor(Color("color-text-30"))
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, minHeight: 20, maxHeight: 20)
                        }
                        .frame(width: itemWidth, height: 74)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel(item.title)
                }
            }
            .frame(width: proxy.size.width, height: 74)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 74)
        .background(Color("color-base-1"))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("trade.quickMenu")
    }
}
