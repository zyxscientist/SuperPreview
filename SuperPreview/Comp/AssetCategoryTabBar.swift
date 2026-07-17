//
//  AssetCategoryTabBar.swift
//  SuperPreview
//

import SwiftUI

enum AssetCategory: String, CaseIterable, Identifiable {
    case stocks = "股票"
    case funds = "基金"
    case virtualAssets = "虚拟资产"

    var id: Self { self }
}

struct AssetCategoryTabBar: View {
    @Binding var selection: AssetCategory

    var body: some View {
        ZStack(alignment: .trailing) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(AssetCategory.allCases) { category in
                        categoryButton(category)
                    }
                }
                .padding(.leading, 16)
                .padding(.trailing, 56)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)

            sortMenu
        }
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .background(Color("color-base-1"))
    }

    private func categoryButton(_ category: AssetCategory) -> some View {
        let isSelected = selection == category

        return Button {
            selection = category
        } label: {
            Text(category.rawValue)
                .font(
                    .custom(
                        isSelected ? "PlusJakartaSans-Bold" : "PlusJakartaSans-Regular",
                        size: 14,
                        relativeTo: .subheadline
                    )
                )
                .foregroundColor(Color(isSelected ? "color-text-r" : "color-text-60"))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .frame(height: 20)
                .padding(.horizontal, 14)
                .padding(.vertical, 4)
                .background(Color(isSelected ? "color-base-r" : "color-base-1"))
                .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
        .frame(height: 48)
        .contentShape(Rectangle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var sortMenu: some View {
        ZStack(alignment: .trailing) {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color("color-transparent"), location: 0),
                    .init(color: Color("color-base-1"), location: 0.37413),
                    .init(color: Color("color-base-1"), location: 1)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )

            Image("headertab_sort")
                .resizable()
                .frame(width: 20, height: 20)
                .padding(.trailing, 12)
        }
        .frame(width: 56, height: 20)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct AssetCategoryTabBarPreviewContainer: View {
    @State private var selection: AssetCategory = .stocks

    var body: some View {
        VStack(spacing: 0) {
            AssetCategoryTabBar(selection: $selection)

            TabView(selection: $selection) {
                ForEach(AssetCategory.allCases) { category in
                    Text(category.rawValue)
                        .font(.custom("PlusJakartaSans-Medium", size: 16, relativeTo: .body))
                        .foregroundColor(Color("color-text-30"))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color("color-base-1"))
                        .tag(category)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .background(Color("color-base-1"))
    }
}

struct AssetCategoryTabBar_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AssetCategoryTabBarPreviewContainer()
                .previewDisplayName("Light")

            AssetCategoryTabBarPreviewContainer()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark")
        }
        .previewLayout(.fixed(width: 402, height: 180))
    }
}
