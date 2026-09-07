//
//  TodayOrdersPageView.swift
//  SuperPreview
//

import SwiftUI

/// A standalone today's-orders page launched from the trade aggregation quick menu.
///
/// The page owns the single expanded row so expanding one order collapses the
/// previous order, matching the interaction used by the order form.
struct TodayOrdersPageView: View {
    let orders: [StockOrderTodayOrderItem]
    let onOrderAction: (StockOrderTodayOrderItem, StockOrderTodayOrderAction) -> Void
    let showsNavbar: Bool
    let onBack: (() -> Void)?
    let navigationBackSwipePolicy: NavigationBackSwipePolicy?
    let bottomContentInset: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.demoLanguage) private var language
    @Environment(\.dismiss) private var dismiss
    @State private var expandedOrderID: StockOrderTodayOrderItem.ID?

    init(
        orders: [StockOrderTodayOrderItem],
        onOrderAction: @escaping (
            StockOrderTodayOrderItem,
            StockOrderTodayOrderAction
        ) -> Void = { _, _ in },
        showsNavbar: Bool = true,
        onBack: (() -> Void)? = nil,
        navigationBackSwipePolicy: NavigationBackSwipePolicy? = .system,
        bottomContentInset: CGFloat = 0
    ) {
        self.orders = orders
        self.onOrderAction = onOrderAction
        self.showsNavbar = showsNavbar
        self.onBack = onBack
        self.navigationBackSwipePolicy = navigationBackSwipePolicy
        self.bottomContentInset = bottomContentInset
    }

    var body: some View {
        VStack(spacing: 0) {
            if showsNavbar {
                StockOrderNavbar(
                    accountTitle: language.text(.todayOrders),
                    showsDebugButton: false,
                    onBack: handleBack
                )
                .accessibilityIdentifier("todayOrders.navbar")
            }

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section {
                        if orders.isEmpty {
                            emptyState
                        } else {
                            ForEach(orders) { order in
                                orderRow(order)
                            }
                        }
                    } header: {
                        TodayOrdersPageTableHeader()
                    }
                    Color.clear
                        .frame(height: bottomContentInset)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .accessibilityIdentifier("todayOrders.scroll")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color("color-base-1"))
        .toolbar(.hidden, for: .navigationBar)
        .modifier(TodayOrdersNavigationBackSwipeModifier(policy: navigationBackSwipePolicy))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("todayOrders.page")
    }

    private func handleBack() {
        if let onBack {
            onBack()
        } else {
            dismiss()
        }
    }

    private func orderRow(_ order: StockOrderTodayOrderItem) -> some View {
        StockOrderTodayOrder(
            isActionGroupExpanded: orderExpansionBinding(for: order.id),
            side: order.side,
            status: order.status,
            productName: order.productName,
            symbol: order.symbol,
            price: order.price,
            quantity: order.quantity,
            filledQuantity: order.filledQuantity,
            tag: order.tag,
            showsStatusIcon: order.showsStatusIcon,
            actions: order.actions
        ) { action in
            onOrderAction(order, action)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("todayOrders.order.\(order.id)")
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image("empty_portfolio")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 56)
                .accessibilityHidden(true)

            Text(language.text(.noTodayOrders))
                .modifier(CustomFontModifier(size: 14, font: .regular, lineHeight: 20))
                .foregroundColor(Color("color-text-60"))
        }
        .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 180)
        .accessibilityIdentifier("todayOrders.empty")
    }

    private func orderExpansionBinding(
        for id: StockOrderTodayOrderItem.ID
    ) -> Binding<Bool> {
        Binding(
            get: { expandedOrderID == id },
            set: { isExpanded in
                withAnimation(SubAssetCardMotion.expansion(reduceMotion: reduceMotion)) {
                    expandedOrderID = isExpanded ? id : nil
                }
            }
        )
    }
}

private struct TodayOrdersNavigationBackSwipeModifier: ViewModifier {
    let policy: NavigationBackSwipePolicy?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let policy {
            content.navigationBackSwipe(policy)
        } else {
            content
        }
    }
}

private struct TodayOrdersPageTableHeader: View {
    @Environment(\.demoLanguage) private var language

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Text(language.text(.orderStatusHeader))
                        .modifier(CustomFontModifier(size: 12, font: .regular, lineHeight: 16))
                        .foregroundColor(Color("color-text-60"))
                        .lineLimit(1)

                    Image("stock_order_chevron_down")
                        .scaledToFit()
                        .frame(width: 8, height: 4)
                        .accessibilityHidden(true)
                }
                .frame(width: 85, alignment: .leading)

                Text(language.text(.symbolHeader))
                    .modifier(CustomFontModifier(size: 12, font: .regular, lineHeight: 16))
                    .foregroundColor(Color("color-text-60"))
                    .lineLimit(1)
                    .frame(width: 92, alignment: .leading)
            }
            .padding(.leading, 16)
            .frame(width: 201, alignment: .leading)

            HStack(spacing: 8) {
                Text(language.text(.orderPriceHeader))
                    .modifier(CustomFontModifier(size: 12, font: .regular, lineHeight: 16))
                    .foregroundColor(Color("color-text-60"))
                    .lineLimit(1)
                    .frame(width: 90, alignment: .trailing)

                Text(language.text(.quantityFilledHeader))
                    .modifier(CustomFontModifier(size: 12, font: .regular, lineHeight: 16))
                    .foregroundColor(Color("color-text-60"))
                    .lineLimit(1)
                    .frame(width: 87, alignment: .trailing)
            }
            .padding(.trailing, 16)
            .frame(width: 201, alignment: .leading)
        }
        .frame(width: 402, height: 32, alignment: .center)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("color-base-1"))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("todayOrders.header")
    }
}

struct TodayOrdersPageView_Previews: PreviewProvider {
    static var previews: some View {
        TodayOrdersPageView(
            orders: StockOrderDemoViewModel.makeDemoTodayOrders(language: .simplifiedChinese)
        )
        .environment(\.demoLanguage, .simplifiedChinese)
        .previewLayout(.fixed(width: 402, height: 874))
    }
}
