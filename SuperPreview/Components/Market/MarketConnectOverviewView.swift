import SwiftUI

/// Illustrative Stock Connect turnover; values are not live market data.
enum MarketConnectDirection: CaseIterable {
    case north, south
}

struct MarketConnectOverviewView: View {
    @Binding var selected: MarketConnectDirection
    @Environment(\.demoLanguage) private var language

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                tab(.north, title: .connectAShares)
                tab(.south, title: .connectHKShares)
            }
            .frame(height: 60)

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center, spacing: 8) {
                    Text(language.text(selected == .north ? .connectNorthOverview : .connectSouthOverview))
                        .modifier(CustomFontModifier(size: 18, font: .bold, lineHeight: 28))
                        .foregroundStyle(Color("color-text-30"))
                    Spacer(minLength: 0)
                    Text(language.text(.connectUpdated))
                        .modifier(CustomFontModifier(size: 12, font: .regular, lineHeight: 16))
                        .foregroundStyle(Color("color-text-90"))
                }
                .frame(height: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(language.text(.connectPreviousTurnover))
                        .modifier(CustomFontModifier(size: 14, font: .regular, lineHeight: 20))
                        .foregroundStyle(Color("color-text-60"))
                    Text(language.text(.connectTotalValue))
                        .modifier(CustomFontModifier(size: 24, font: .bold, lineHeight: 36))
                        .foregroundStyle(Color("color-text-30"))
                }

                VStack(spacing: 12) {
                    GeometryReader { geometry in
                        HStack(spacing: 4) {
                            Capsule().frame(width: max(0, (geometry.size.width - 4) * (selected == .north ? 155.0 / 366.0 : 157.0 / 366.0)))
                            Capsule()
                        }
                        .foregroundStyle(Color("color-text-30"))
                    }
                    .frame(height: 8)

                    HStack(alignment: .top, spacing: 8) {
                        detail(selected == .north ? .connectShanghaiNorth : .connectShanghaiSouth, alignment: .leading)
                        Spacer(minLength: 0)
                        detail(selected == .north ? .connectShenzhenNorth : .connectShenzhenSouth, alignment: .trailing)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .background(alignment: .top) {
            ConnectHeaderShape(isNorth: selected == .north)
                .fill(LinearGradient(colors: [Color("color-scale-1"), Color("color-base-1")], startPoint: .top, endPoint: .bottom))
                .overlay {
                    ConnectHeaderShape(isNorth: selected == .north)
                        .stroke(LinearGradient(colors: [Color("color-separator-10").opacity(0.6), Color("color-base-1")], startPoint: .top, endPoint: .bottom), lineWidth: 1)
                }
                .frame(height: 120)
                .allowsHitTesting(false)
        }
        .accessibilityIdentifier("market.connectOverview")
    }

    private func tab(_ direction: MarketConnectDirection, title: DemoCopyKey) -> some View {
        Button {
            selected = direction
        } label: {
            HStack(spacing: 4) {
                icon(direction)
                    .opacity(selected == direction ? 1 : 0.5)
                Text(language.text(title))
                    .modifier(CustomFontModifier(size: 18, font: selected == direction ? .medium : .regular, lineHeight: 28))
                    .foregroundStyle(Color(selected == direction ? "color-text-30" : "color-text-60"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected == direction ? .isSelected : [])
        .accessibilityIdentifier(direction == .north ? "market.connectOverview.north" : "market.connectOverview.south")
    }

    private func icon(_ direction: MarketConnectDirection) -> some View {
        ZStack(alignment: .topLeading) {
            if direction == .north {
                Image("market_connect_north")
                    .renderingMode(.template)
                    .resizable().frame(width: 18.763, height: 20.999)
                    .offset(x: 2.618, y: 0.853)
                Capsule().frame(width: 1.5, height: 2.05).offset(x: 11.209, y: 20.731)
                Capsule().frame(width: 2.05, height: 1.5).offset(x: 1.546, y: 12.323)
                Capsule().frame(width: 2.05, height: 1.5).offset(x: 20.405, y: 12.323)
            } else {
                Image("market_connect_south").renderingMode(.template).resizable().frame(width: 24, height: 24)
            }
        }
        .foregroundStyle(Color(direction == .north ? "color-utility3-red" : "color-utility3-green"))
        .frame(width: 24, height: 24, alignment: .topLeading)
        .accessibilityHidden(true)
    }

    private func detail(_ title: DemoCopyKey, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            (Text(language.text(title) + " ") + Text(language.text(.connectSegmentValue)).font(.custom("PlusJakartaSans-Bold", size: 14)))
                .modifier(CustomFontModifier(size: 14, font: .regular, lineHeight: 20))
                .foregroundStyle(Color("color-text-30"))
                .lineLimit(1).minimumScaleFactor(0.7)
            (Text(language.text(.connectRemainingQuota) + " ").foregroundColor(Color("color-text-60"))
             + Text(language.text(.connectQuotaSufficient)).font(.custom("PlusJakartaSans-Bold", size: 12)).foregroundColor(Color("color-utility3-green")))
                .modifier(CustomFontModifier(size: 12, font: .regular, lineHeight: 16))
                .lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
    }
}

private struct ConnectHeaderShape: Shape {
    let isNorth: Bool

    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height, m = w / 2, r: CGFloat = 20
        var p = Path()
        p.move(to: CGPoint(x: 0, y: h))
        p.addLine(to: CGPoint(x: 0, y: r))
        p.addQuadCurve(to: CGPoint(x: r, y: 0), control: .zero)
        p.addLine(to: CGPoint(x: m - r, y: 0))
        p.addQuadCurve(to: CGPoint(x: m, y: r), control: CGPoint(x: m, y: 0))
        p.addLine(to: CGPoint(x: m, y: 36))
        p.addQuadCurve(to: CGPoint(x: m + r, y: 56), control: CGPoint(x: m, y: 56))
        p.addLine(to: CGPoint(x: w - r, y: 56))
        p.addQuadCurve(to: CGPoint(x: w, y: 76), control: CGPoint(x: w, y: 56))
        p.addLine(to: CGPoint(x: w, y: h))
        p.closeSubpath()
        return isNorth ? p : p.applying(CGAffineTransform(translationX: w, y: 0).scaledBy(x: -1, y: 1))
    }
}
