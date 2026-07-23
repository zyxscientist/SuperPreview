//
//  JakartaMonospacedComparisonView.swift
//  SuperPreview
//
//  Created by Codex on 2026/07/23.
//

import SwiftUI

/// 用于观察 Plus Jakarta Sans 比例数字与等宽数字在报价场景下的视觉差异。
struct JakartaMonospacedComparisonView: View {
    @State private var showsAlternateQuote = false
    @State private var isShowingDebugPanel = false
    @State private var fontWeight: JakartaFontWeight = .medium

    private var quote: JakartaQuoteSample {
        showsAlternateQuote ? .alternate : .initial
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                introduction
                horizontalComparison
                quoteSwitcher
                quoteComparison
                usageNote
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(Color("color-base-0").edgesIgnoringSafeArea(.all))
        .navigationTitle("Jakarta 等宽对比")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Debug") {
                    isShowingDebugPanel = true
                }
                .font(fontWeight.font(size: 13))
                .foregroundColor(Color("color-text-30"))
            }
        }
        .sheet(isPresented: $isShowingDebugPanel) {
            JakartaFontDebugView(selectedWeight: $fontWeight)
        }
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("数字是否等宽，直接影响报价的稳定感")
                .font(fontWeight.font(size: 20))
                .foregroundColor(Color("color-text-30"))

            Text("两侧均使用 Plus Jakarta Sans Medium；等宽样本仅额外开启 monospacedDigit()。可从字宽、连续报价与列表列对齐三个角度观察差异。")
                .font(fontWeight.font(size: 14))
                .foregroundColor(Color("color-text-60"))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// 同一串数字横向排列，便于直接观察 1、8、0 的实际占宽。
    private var horizontalComparison: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("横向字宽对比")
                    .font(fontWeight.font(size: 15))
                    .foregroundColor(Color("color-text-30"))
                Spacer()
                Text("相同字符数，不同数字字形")
                    .font(fontWeight.font(size: 11))
                    .foregroundColor(Color("color-text-60"))
            }

            JakartaHorizontalDigitRow(
                title: "默认",
                isMonospaced: false,
                fontWeight: fontWeight
            )
            JakartaHorizontalDigitRow(
                title: "等宽",
                isMonospaced: true,
                fontWeight: fontWeight
            )
        }
        .padding(14)
        .background(Color("color-base-1"))
        .cornerRadius(12)
    }

    private var quoteSwitcher: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.22)) {
                showsAlternateQuote.toggle()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 14, weight: .semibold))
                VStack(alignment: .leading, spacing: 2) {
                    Text("切换报价样本")
                        .font(fontWeight.font(size: 14))
                    Text("观察数字更新前后，读数占宽是否保持稳定")
                        .font(fontWeight.font(size: 12))
                        .foregroundColor(Color("color-text-60"))
                }
                Spacer()
                Text(showsAlternateQuote ? "样本 B" : "样本 A")
                    .font(fontWeight.font(size: 12))
                    .foregroundColor(Color("color-brand-blue"))
            }
            .foregroundColor(Color("color-text-30"))
            .padding(14)
            .background(Color("color-base-1"))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .accessibilityHint("切换一组数字宽度差异明显的报价")
    }

    /// 保留金融产品中最常见的双栏报价形式，观察实际列表里的列对齐表现。
    private var quoteComparison: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("报价列对齐")
                    .font(fontWeight.font(size: 15))
                    .foregroundColor(Color("color-text-30"))
                Spacer()
                Text("相同样本 · 并排对照")
                    .font(fontWeight.font(size: 11))
                    .foregroundColor(Color("color-text-60"))
            }

            HStack(alignment: .top, spacing: 12) {
                JakartaNumberSampleCard(
                    title: "默认",
                    subtitle: "未开启等宽",
                    isMonospaced: false,
                    quote: quote,
                    fontWeight: fontWeight
                )

                JakartaNumberSampleCard(
                    title: "等宽数字",
                    subtitle: "已开启 monospacedDigit()",
                    isMonospaced: true,
                    quote: quote,
                    fontWeight: fontWeight
                )
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Plus Jakarta Sans 默认与等宽数字报价对比")
        }
    }

    private var usageNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "eye")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color("color-brand-blue"))
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text("推荐用法")
                    .font(fontWeight.font(size: 14))
                    .foregroundColor(Color("color-text-30"))
                Text("价格、涨跌幅、时间和数量等频繁变化的读数适合开启；股票名称、代码和正文仍建议保持默认比例数字。")
                    .font(fontWeight.font(size: 13))
                    .foregroundColor(Color("color-text-60"))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(Color("color-brand-blue-20").opacity(0.48))
        .cornerRadius(10)
    }
}

private enum JakartaFontWeight: String, CaseIterable, Identifiable {
    case regular = "PlusJakartaSans-Regular"
    case medium = "PlusJakartaSans-Medium"
    case semibold = "PlusJakartaSans-SemiBold"
    case bold = "PlusJakartaSans-Bold"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .regular: return "Regular"
        case .medium: return "Medium"
        case .semibold: return "Semibold"
        case .bold: return "Bold"
        }
    }

    var description: String {
        switch self {
        case .regular: return "400 · Regular"
        case .medium: return "500 · Medium"
        case .semibold: return "600 · Semibold"
        case .bold: return "700 · Bold"
        }
    }

    func font(size: CGFloat) -> Font {
        .custom(rawValue, size: size)
    }
}

private struct JakartaFontDebugView: View {
    @Binding var selectedWeight: JakartaFontWeight
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(JakartaFontWeight.allCases) { weight in
                        Button {
                            selectedWeight = weight
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(weight.title)
                                        .font(weight.font(size: 16))
                                        .foregroundColor(Color("color-text-30"))
                                    Text(weight.description)
                                        .font(.system(size: 12))
                                        .foregroundColor(Color("color-text-60"))
                                }
                                Spacer()
                                if selectedWeight == weight {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color("color-brand-blue"))
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("选择 \(weight.title) 字重")
                    }
                } header: {
                    Text("Plus Jakarta Sans 字重")
                } footer: {
                    Text("选项来自当前已打包字体：Regular、Medium、Semibold、Bold。更改会立即应用到整个对比页。")
                }

                Section("实时预览") {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("Jakarta 111.11 / 888.88")
                            .font(selectedWeight.font(size: 20))
                        Text("Aa Bb Cc · 现价 101,010")
                            .font(selectedWeight.font(size: 15))
                            .foregroundColor(Color("color-text-60"))
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("字体 Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct JakartaHorizontalDigitRow: View {
    let title: String
    let isMonospaced: Bool
    let fontWeight: JakartaFontWeight

    // 将 "00" 放在首位，便于直接观察连续两个 0 的轮廓与间距。
    private let samples = ["00", "111.11", "888.88", "101,010"]

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 5) {
                Circle()
                    .fill(isMonospaced ? Color("color-brand-blue") : Color("color-text-60"))
                    .frame(width: 6, height: 6)
                Text(title)
                    .font(fontWeight.font(size: 12))
                    .foregroundColor(Color("color-text-30"))
            }
            .frame(width: 54, alignment: .leading)

            ForEach(samples.indices, id: \.self) { index in
                if index > 0 {
                    Rectangle()
                        .fill(Color("color-separator-20"))
                        .frame(width: 1, height: 14)
                }

                numberText(samples[index])
                    .foregroundColor(Color("color-text-30"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
        .background(isMonospaced ? Color("color-brand-blue-20").opacity(0.42) : Color("color-base-0"))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isMonospaced ? Color("color-brand-blue").opacity(0.7) : Color("color-separator-20"), lineWidth: 1)
        )
        .cornerRadius(8)
        .accessibilityLabel("\(title)：\(samples.joined(separator: "，"))")
    }

    private func numberText(_ value: String) -> Text {
        let text = Text(value).font(fontWeight.font(size: 13))
        return isMonospaced ? text.monospacedDigit() : text
    }
}

private struct JakartaQuoteSample {
    let price: String
    let change: String
    let volume: String
    let time: String

    static let initial = JakartaQuoteSample(
        price: "111.11",
        change: "+1.18%",
        volume: "101,010",
        time: "11:11:11"
    )

    static let alternate = JakartaQuoteSample(
        price: "888.88",
        change: "+8.88%",
        volume: "888,888",
        time: "18:08:18"
    )
}

private struct JakartaNumberSampleCard: View {
    let title: String
    let subtitle: String
    let isMonospaced: Bool
    let quote: JakartaQuoteSample
    let fontWeight: JakartaFontWeight

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            widthCheck
            quoteRows
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("color-base-1"))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isMonospaced ? Color("color-brand-blue").opacity(0.7) : Color("color-separator-20"), lineWidth: 1)
        )
        .cornerRadius(12)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Circle()
                    .fill(isMonospaced ? Color("color-brand-blue") : Color("color-text-60"))
                    .frame(width: 7, height: 7)
                Text(title)
                    .font(fontWeight.font(size: 15))
                    .foregroundColor(Color("color-text-30"))
            }
            Text(subtitle)
                .font(fontWeight.font(size: 11))
                .foregroundColor(Color("color-text-60"))
                .lineLimit(2)
        }
    }

    private var widthCheck: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("字宽基准")
                .font(fontWeight.font(size: 11))
                .foregroundColor(Color("color-text-60"))
            VStack(alignment: .leading, spacing: 3) {
                numberText("111.11", size: 19)
                numberText("888.88", size: 19)
            }
            .foregroundColor(Color("color-text-30"))
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(Color("color-brand-blue").opacity(0.5))
                    .frame(width: 1, height: 46)
                    .offset(x: 2)
            }
        }
    }

    private var quoteRows: some View {
        VStack(spacing: 10) {
            JakartaQuoteRow(label: "现价", value: quote.price, isMonospaced: isMonospaced, fontWeight: fontWeight)
            JakartaQuoteRow(label: "涨跌幅", value: quote.change, isMonospaced: isMonospaced, fontWeight: fontWeight, valueColor: Color("color-futu-red"))
            JakartaQuoteRow(label: "成交量", value: quote.volume, isMonospaced: isMonospaced, fontWeight: fontWeight)
            JakartaQuoteRow(label: "更新时间", value: quote.time, isMonospaced: isMonospaced, fontWeight: fontWeight)
        }
        .padding(.top, 2)
    }

    private func numberText(_ value: String, size: CGFloat) -> Text {
        let text = Text(value).font(fontWeight.font(size: size))
        return isMonospaced ? text.monospacedDigit() : text
    }
}

private struct JakartaQuoteRow: View {
    let label: String
    let value: String
    let isMonospaced: Bool
    let fontWeight: JakartaFontWeight
    var valueColor: Color = Color("color-text-30")

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(fontWeight.font(size: 11))
                .foregroundColor(Color("color-text-60"))
                .lineLimit(1)
            Spacer(minLength: 2)
            numberText
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
    }

    private var numberText: Text {
        let text = Text(value).font(fontWeight.font(size: 14))
        return isMonospaced ? text.monospacedDigit() : text
    }
}
