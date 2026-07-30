//
//  LiquidGlassResearchView.swift
//  SuperPreview
//
//  Created by Codex on 2026/07/23.
//

import SwiftUI

/// 用交易涨跌色观察 iOS 26 Liquid Glass 的 tint 表现。
struct LiquidGlassResearchView: View {
    var body: some View {
        VStack {
            actionButtons
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color("color-base-0").ignoresSafeArea())
        .navigationTitle("Liquid Glass 调研")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var actionButtons: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 18) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 16) {
                        tradeButton(for: .buy, shape: .roundedRectangle)
                        tradeButton(for: .sell, shape: .roundedRectangle)
                    }

                    HStack(spacing: 16) {
                        tradeButton(for: .buy, shape: .capsule)
                        tradeButton(for: .sell, shape: .capsule)
                    }

                    solidButtonPair
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    tradeButton(for: .buy, shape: .roundedRectangle)
                    tradeButton(for: .sell, shape: .roundedRectangle)
                }

                HStack(spacing: 16) {
                    tradeButton(for: .buy, shape: .capsule)
                    tradeButton(for: .sell, shape: .capsule)
                }

                solidButtonPair
            }
        }
    }

    private func tradeButton(for action: TradeAction, shape: TradeButtonShape) -> some View {
        LiquidGlassTradeButton(action: action, shape: shape, perform: {})
    }

    @ViewBuilder
    private var solidButtonPair: some View {
        if #available(iOS 26.0, *) {
            solidButtonRow
                .padding(8)
                .glassEffect(.regular, in: .rect(cornerRadius: 30))
        } else {
            solidButtonRow
                .padding(8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30))
        }
    }

    private var solidButtonRow: some View {
        HStack(spacing: 16) {
            solidTradeButton(for: .buy)
            solidTradeButton(for: .sell)
        }
    }

    private func solidTradeButton(for action: TradeAction) -> some View {
        Button(action: {}) {
            Text(action.title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(action.tint, in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(action.title)入")
        .accessibilityHint("实色按钮，外层为 Liquid Glass 背景")
    }
}

private enum TradeAction: String {
    case buy
    case sell

    var title: String {
        switch self {
        case .buy: return "买"
        case .sell: return "卖"
        }
    }

    var tint: Color {
        switch self {
        case .buy: return Color("color-utility3-red")
        case .sell: return Color("color-utility3-green")
        }
    }
}

private enum TradeButtonShape {
    case roundedRectangle

    /// 44pt 高的按钮使用 22pt 圆角，即完整胶囊形。
    case capsule

    var cornerRadius: CGFloat {
        switch self {
        case .roundedRectangle: return 8
        case .capsule: return 22
        }
    }
}

private struct LiquidGlassTradeButton: View {
    let action: TradeAction
    let shape: TradeButtonShape
    let perform: () -> Void

    var body: some View {
        if #available(iOS 26.0, *) {
            button
                .glassEffect(
                    .regular
                        .tint(action.tint)
                        .interactive(),
                    in: .rect(cornerRadius: shape.cornerRadius)
                )
        } else {
            button
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: shape.cornerRadius))
                .overlay {
                    RoundedRectangle(cornerRadius: shape.cornerRadius)
                        .stroke(action.tint.opacity(0.7), lineWidth: 1)
                }
        }
    }

    private var button: some View {
        Button(action: perform) {
            Text(action.title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(action.title)入")
        .accessibilityHint("使用\(action.title == "买" ? "涨" : "跌")色 Liquid Glass")
    }
}

#Preview {
    NavigationStack {
        LiquidGlassResearchView()
    }
}
