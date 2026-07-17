//
//  TotalAsset.swift
//  SuperPreview
//

import SwiftUI

struct TotalAsset: View {
    let currency: String
    let totalAmount: String
    let totalProfitLoss: String

    private let numberVisibilityBinding: Binding<Bool>?
    @State private var localIsNumberHidden: Bool

    init(
        currency: String = "USD",
        totalAmount: String = "9,123,090.12",
        totalProfitLoss: String = "+9,123,090.12",
        isNumberHidden: Bool = false
    ) {
        self.currency = currency
        self.totalAmount = totalAmount
        self.totalProfitLoss = totalProfitLoss
        numberVisibilityBinding = nil
        _localIsNumberHidden = State(initialValue: isNumberHidden)
    }

    init(
        currency: String = "USD",
        totalAmount: String = "9,123,090.12",
        totalProfitLoss: String = "+9,123,090.12",
        isNumberHidden: Binding<Bool>
    ) {
        self.currency = currency
        self.totalAmount = totalAmount
        self.totalProfitLoss = totalProfitLoss
        numberVisibilityBinding = isNumberHidden
        _localIsNumberHidden = State(initialValue: isNumberHidden.wrappedValue)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                title

                Text(numberIsHidden ? "***" : totalAmount)
                    .font(.custom("PlusJakartaSans-Bold", size: 30, relativeTo: .largeTitle))
                    .foregroundColor(Color("color-text-30"))
                    .frame(maxWidth: .infinity, minHeight: 40, maxHeight: 40, alignment: .leading)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                totalProfitLossRow
            }
            .frame(width: 230, alignment: .leading)

            Spacer(minLength: 0)

            if !numberIsHidden {
                AssetChart()
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, minHeight: 100, maxHeight: 100, alignment: .topLeading)
        .background(Color("color-base-1"))
    }

    private var title: some View {
        HStack(spacing: 2) {
            Button {
                toggleNumberVisibility()
            } label: {
                Image(numberIsHidden ? "total_asset_hide_number" : "total_asset_show_number")
                    .resizable()
                    .frame(width: 16, height: 16)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel(numberIsHidden ? "显示资产数字" : "隐藏资产数字")

            Text("总资产")
            Text("·")
            Text(currency)

            Image("total_asset_currency_chevron")
                .resizable()
                .frame(width: 16, height: 16)
                .accessibilityHidden(true)
        }
        .font(.custom("PlusJakartaSans-Regular", size: 14, relativeTo: .subheadline))
        .foregroundColor(Color("color-text-60"))
        .frame(height: 20)
        .accessibilityElement(children: .contain)
    }

    private var totalProfitLossRow: some View {
        HStack(spacing: 8) {
            Text("总盈亏")
                .font(.custom("PlusJakartaSans-Medium", size: 16, relativeTo: .body))
                .foregroundColor(Color("color-text-30"))

            Text(numberIsHidden ? "***" : totalProfitLoss)
                .font(.custom("PlusJakartaSans-Medium", size: 16, relativeTo: .body))
                .foregroundColor(Color(numberIsHidden ? "color-text-30" : "color-utility-red"))
        }
        .frame(maxWidth: .infinity, minHeight: 24, maxHeight: 24, alignment: .leading)
        .lineLimit(1)
    }

    private var numberIsHidden: Bool {
        numberVisibilityBinding?.wrappedValue ?? localIsNumberHidden
    }

    private func toggleNumberVisibility() {
        if let numberVisibilityBinding {
            numberVisibilityBinding.wrappedValue.toggle()
        } else {
            localIsNumberHidden.toggle()
        }
    }
}

struct TotalAsset_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TotalAsset()
                .previewDisplayName("Light · Visible")

            TotalAsset(isNumberHidden: true)
                .previewDisplayName("Light · Hidden")

            TotalAsset()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark · Visible")

            TotalAsset(isNumberHidden: true)
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark · Hidden")
        }
        .previewLayout(.fixed(width: 402, height: 100))
    }
}
