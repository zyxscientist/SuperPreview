//
//  MarketIndustrySectorsView.swift
//  SuperPreview
//
//  组件名称：行业板块
//  简介：以每列三个行业的横向列表展示行业涨幅和领涨股票。
//  用于：新市场页的港股分类，也可独立预览。
//

import SwiftUI
import UIKit

struct MarketIndustrySector: Identifiable, Hashable {
    let id: String
    let name: String
    let percentChange: Double
    let leadingStockName: String
    let leadingStockPercentChange: Double

    var icon: MarketIndustryIcon {
        .matching(industryName: name)
    }

    static let figmaReference: [Self] = [
        Self(id: "precious-metals", name: "黄金与贵金属", percentChange: 1.82,
             leadingStockName: "紫金矿业 02899", leadingStockPercentChange: 2.46),
        Self(id: "hotels-restaurants", name: "酒店餐馆与休闲", percentChange: 0.74,
             leadingStockName: "香格里拉(亚洲) 00069", leadingStockPercentChange: 1.15),
        Self(id: "paper-forest-products", name: "纸类与林业产品", percentChange: -0.63,
             leadingStockName: "理文造纸 02314", leadingStockPercentChange: -0.88),
        Self(id: "automobiles", name: "汽车", percentChange: 2.36,
             leadingStockName: "比亚迪股份 01211", leadingStockPercentChange: 3.12),
        Self(id: "software-services", name: "软件服务", percentChange: 1.27,
             leadingStockName: "金蝶国际 00268", leadingStockPercentChange: 2.04),
        Self(id: "coal", name: "煤炭", percentChange: -0.42,
             leadingStockName: "中国神华 01088", leadingStockPercentChange: -0.31),
        Self(id: "internet-content", name: "互联网内容与信息", percentChange: 0.96,
             leadingStockName: "腾讯控股 00700", leadingStockPercentChange: 1.38),
        Self(id: "pharmaceuticals", name: "制药", percentChange: -1.14,
             leadingStockName: "石药集团 01093", leadingStockPercentChange: -1.62),
        Self(id: "insurance", name: "保险", percentChange: 0.58,
             leadingStockName: "友邦保险 01299", leadingStockPercentChange: 0.83)
    ]
}

struct MarketIndustrySectorsView: View {
    let sectors: [MarketIndustrySector]
    let onShowAll: () -> Void
    let onSelect: (MarketIndustrySector) -> Void

    private let rowsPerColumn = 3
    private let columnWidth: CGFloat = 240
    private let rowHeight: CGFloat = 94
    private let itemSpacing: CGFloat = 16
    @Environment(\.demoLanguage) private var language

    init(
        sectors: [MarketIndustrySector] = MarketIndustrySector.figmaReference,
        onShowAll: @escaping () -> Void = { /* TODO: connect the industry sectors destination. */ },
        onSelect: @escaping (MarketIndustrySector) -> Void = { _ in
            /* TODO: connect the selected industry's destination. */
        }
    ) {
        self.sectors = sectors
        self.onShowAll = onShowAll
        self.onSelect = onSelect
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            MarketIndustryCarousel(contentWidth: carouselWidth) {
                HStack(alignment: .top, spacing: itemSpacing) {
                    ForEach(columns.indices, id: \.self) { columnIndex in
                        VStack(alignment: .leading, spacing: itemSpacing) {
                            ForEach(columns[columnIndex]) { sector in
                                sectorRow(sector)
                            }
                        }
                        .frame(width: columnWidth, alignment: .leading)
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(height: columnHeight)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("market.industrySectors")
    }

    private var columns: [[MarketIndustrySector]] {
        stride(from: 0, to: sectors.count, by: rowsPerColumn).map { start in
            Array(sectors[start..<min(start + rowsPerColumn, sectors.count)])
        }
    }

    private var columnHeight: CGFloat {
        let rowCount = min(rowsPerColumn, sectors.count)
        return CGFloat(rowCount) * rowHeight + CGFloat(max(rowCount - 1, 0)) * itemSpacing
    }

    private var carouselWidth: CGFloat {
        CGFloat(columns.count) * columnWidth + CGFloat(max(columns.count - 1, 0)) * itemSpacing + 32
    }

    private var header: some View {
        Button(action: onShowAll) {
            HStack(spacing: 8) {
                Text(language.text(.marketIndustrySectors))
                    .modifier(CustomFontModifier(size: 18, font: .bold, lineHeight: 28))
                    .foregroundStyle(Color("color-text-30"))

                Spacer(minLength: 0)

                Image("chevron_right_text30_sm")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .accessibilityHidden(true)
            }
            .frame(height: 28)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .accessibilityLabel(language.actionAccessibilityLabel(name: language.text(.marketIndustrySectors), action: language.text(.viewAll)))
        .accessibilityIdentifier("market.industrySectors.showAll")
    }

    private func sectorRow(_ sector: MarketIndustrySector) -> some View {
        let sectorName = language.marketDataName("industry.\(sector.id)", fallback: sector.name)
        let leadingStockName = language.marketDataName("industry-leader.\(sector.id)", fallback: sector.leadingStockName)

        return Button {
            onSelect(sector)
        } label: {
            HStack(spacing: 12) {
                Image(sector.icon.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    .background(Color("color-base-1"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color("color-separator-10"), lineWidth: 1)
                    }
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(sectorName)
                            .foregroundStyle(Color("color-text-30"))
                            .frame(height: 20, alignment: .leading)

                        Text(formattedChange(sector.percentChange))
                            .foregroundStyle(changeColor(sector.percentChange))
                            .frame(height: 20, alignment: .leading)
                    }
                    .modifier(CustomFontModifier(size: 14, font: .medium, lineHeight: 20))

                    leadingStockTag(sector, name: leadingStockName)
                }
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.trailing, 12)
            .padding(.vertical, 12)
            .frame(width: columnWidth, height: rowHeight, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: language.text(.marketIndustryAccessibilityFormat), sectorName, formattedChange(sector.percentChange), leadingStockName, formattedChange(sector.leadingStockPercentChange)))
        .accessibilityIdentifier("market.industrySectors.sector.\(sector.id)")
    }

    private func leadingStockTag(_ sector: MarketIndustrySector, name: String) -> some View {
        HStack(spacing: 8) {
            Text(name)
                .foregroundStyle(Color("color-text-30"))
                .truncationMode(.tail)

            Text(formattedChange(sector.leadingStockPercentChange))
                .foregroundStyle(changeColor(sector.leadingStockPercentChange))
                .fixedSize(horizontal: true, vertical: false)
        }
        .modifier(CustomFontModifier(size: 11, font: .regular, lineHeight: 16))
        .frame(height: 16)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color("color-scale-1"), in: RoundedRectangle(cornerRadius: 4))
    }

    private func changeColor(_ change: Double) -> Color {
        Color(change >= 0 ? "color-utility3-red" : "color-utility3-green")
    }

    private func formattedChange(_ change: Double) -> String {
        String(format: "%+.2f%%", locale: Locale(identifier: "en_US_POSIX"), change)
    }
}

/// Own the native horizontal scroll surface so gesture priority does not
/// depend on SwiftUI's private view hierarchy or the current content offset.
private struct MarketIndustryCarousel<Content: View>: UIViewControllerRepresentable {
    let contentWidth: CGFloat
    let content: Content
    @Environment(\.colorScheme) private var colorScheme

    init(contentWidth: CGFloat, @ViewBuilder content: () -> Content) {
        self.contentWidth = contentWidth
        self.content = content()
    }

    func makeUIViewController(context: Context) -> Controller {
        Controller(
            content: AnyView(content.environment(\.colorScheme, colorScheme)),
            contentWidth: contentWidth
        )
    }

    func updateUIViewController(_ controller: Controller, context: Context) {
        controller.update(
            content: AnyView(content.environment(\.colorScheme, colorScheme)),
            contentWidth: contentWidth
        )
    }

    final class Controller: UIViewController, UIGestureRecognizerDelegate {
        private let scrollView = UIScrollView()
        private let hosting: UIHostingController<AnyView>
        private var contentWidth: CGFloat
        private var widthConstraint: NSLayoutConstraint?
        private lazy var horizontalPan: UIPanGestureRecognizer = {
            let pan = UIPanGestureRecognizer(target: self, action: #selector(keepGestureLocal(_:)))
            pan.maximumNumberOfTouches = 1
            pan.cancelsTouchesInView = false
            pan.delegate = self
            return pan
        }()

        init(content: AnyView, contentWidth: CGFloat) {
            self.hosting = UIHostingController(rootView: content)
            self.contentWidth = contentWidth
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func loadView() {
            view = scrollView
            scrollView.backgroundColor = .clear
            scrollView.contentInsetAdjustmentBehavior = .never
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.showsVerticalScrollIndicator = false
            scrollView.alwaysBounceHorizontal = true
            scrollView.alwaysBounceVertical = false
            scrollView.isDirectionalLockEnabled = true
            scrollView.accessibilityIdentifier = "market.industrySectors.carousel"
            scrollView.addGestureRecognizer(horizontalPan)

            addChild(hosting)
            hosting.safeAreaRegions = []
            hosting.view.backgroundColor = .clear
            hosting.view.translatesAutoresizingMaskIntoConstraints = false
            scrollView.addSubview(hosting.view)
            let width = hosting.view.widthAnchor.constraint(equalToConstant: contentWidth)
            widthConstraint = width
            NSLayoutConstraint.activate([
                hosting.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
                hosting.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
                hosting.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
                hosting.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
                hosting.view.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor),
                width
            ])
            hosting.didMove(toParent: self)
        }

        func update(content: AnyView, contentWidth: CGFloat) {
            hosting.rootView = content
            if self.contentWidth != contentWidth {
                self.contentWidth = contentWidth
                widthConstraint?.constant = contentWidth
            }
        }

        @objc private func keepGestureLocal(_ pan: UIPanGestureRecognizer) {
            // Scrolling remains owned by the carousel's native pan recognizer.
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
            let velocity = pan.velocity(in: pan.view)
            return abs(velocity.x) > abs(velocity.y)
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            guard let otherView = otherGestureRecognizer.view else { return false }
            return otherView === scrollView || otherView.isDescendant(of: scrollView)
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            // UIKit also asks about recognizers in cached/offscreen pages.
            // Only the carousel currently receiving the touch gets priority.
            guard gestureRecognizer.numberOfTouches > 0,
                  scrollView.bounds.contains(gestureRecognizer.location(in: scrollView)),
                  otherGestureRecognizer is UIPanGestureRecognizer,
                  let ancestor = otherGestureRecognizer.view else { return false }
            return scrollView !== ancestor && scrollView.isDescendant(of: ancestor)
        }
    }
}

struct MarketIndustrySectorsView_Previews: PreviewProvider {
    static var previews: some View {
        MarketIndustrySectorsView()
            .background(Color("color-base-1"))
            .previewLayout(.fixed(width: 402, height: 354))
            .previewDisplayName("行业板块")
    }
}
