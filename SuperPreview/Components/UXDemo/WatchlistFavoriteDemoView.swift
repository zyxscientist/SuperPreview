import SwiftUI

struct WatchlistFavoriteDemoView: View {
    @Environment(\.demoLanguage) private var language

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                FavoriteSearchResult(
                    name: "比特币/港币",
                    symbol: "BTC/HKD",
                    marketBadge: .marketCrypto
                )
                FavoriteSearchResult(
                    name: "币经之路123期权收益策略主动型ETF",
                    symbol: "XOMO",
                    marketBadge: .marketRankingsHk
                )
            }
        }
        .background(Color(.colorBase1))
        .navigationTitle(language.text(.watchlistFavoriteAnimation))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct FavoriteSearchResult: View {
    let name: String
    let symbol: String
    let marketBadge: ImageResource

    @Environment(\.demoLanguage) private var language
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.toastPresenter) private var toastPresenter
    @State private var group: FavoriteGroup?

    private var isFavorite: Bool { group != nil }

    var body: some View {
        HStack(spacing: 4) {
            VStack(alignment: .leading, spacing: 2) {
                Text(highlightedName)
                    .font(.custom("PlusJakartaSans-Regular", size: 16))
                    .foregroundStyle(Color(.colorText1))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 24)
                    .accessibilityIdentifier("favoriteDemo.\(symbol).name")

                Text(verbatim: symbol)
                    .font(.custom("PlusJakartaSans-Regular", size: 13))
                    .foregroundStyle(Color(.colorText2))
                    .lineLimit(1)
                    .frame(height: 16)
            }
            .padding(.leading, 16)
            .overlay(alignment: .topLeading) {
                Image(marketBadge)
                    .resizable()
                    .frame(width: 12, height: 10)
                    .padding(.top, 7)
                    .accessibilityHidden(true)
            }

            favoriteActions
        }
        .padding(.trailing, 6)
        .frame(height: 60)
    }

    private var highlightedName: AttributedString {
        var result = AttributedString(name)
        for range in name.ranges(of: "币") {
            if let match = Range(range, in: result) {
                result[match].foregroundColor = Color(.colorBlue1)
            }
        }
        return result
    }

    private var favoriteActions: some View {
        HStack(spacing: 0) {
            FavoriteLabelReveal(progress: isFavorite ? 1 : 0) {
                groupMenu
                    .opacity(isFavorite ? 1 : 0)
            }
            .clipped()
            .contentShape(Rectangle())
            .allowsHitTesting(isFavorite)
            .accessibilityHidden(!isFavorite)

            Button(action: toggleFavorite) {
                ZStack {
                    Circle()
                        .fill(Color(.colorBase1))
                        .overlay {
                            Circle().strokeBorder(Color(.colorGrayscale1), lineWidth: 1)
                                .opacity(isFavorite ? 1 : 0)
                        }
                        .frame(width: 34, height: 34)

                    Image(isFavorite ? .watchlistFavoriteAdded : .watchlistFavoriteAdd)
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.impact(weight: .medium), trigger: isFavorite)
            .accessibilityLabel(language.actionAccessibilityLabel(
                name: name,
                action: language.text(isFavorite ? .deleteFromWatchlist : .addToWatchlist)
            ))
            .accessibilityAddTraits(isFavorite ? .isSelected : [])
            .accessibilityIdentifier("favoriteDemo.\(symbol).toggle")
        }
        .fixedSize()
        .background {
            // The 34 pt cap sits inside a 44 pt tap target. Its center stays put.
            Capsule()
                .fill(Color(.colorGrayscale1))
                .frame(height: 34)
                .padding(.leading, isFavorite ? 0 : 5)
                .padding(.trailing, 5)
                .opacity(isFavorite ? 1 : 0)
        }
        .padding(.leading, isFavorite ? 0 : 2)
    }

    private var groupMenu: some View {
        Menu {
            Picker(language.text(.editWatchlistGroup), selection: Binding(
                get: { group ?? .standard },
                set: { group = $0 }
            )) {
                ForEach(FavoriteGroup.allCases, id: \.self) { choice in
                    Text(language.text(choice.titleKey)).tag(choice)
                }
            }
        } label: {
            Text(language.text(.editWatchlistGroup))
                .font(.custom("PlusJakartaSans-Bold", size: 14))
                .foregroundStyle(Color(.colorText1))
                .fixedSize()
                .padding(.leading, 16)
                // The heart's tap target supplies the remaining 5 pt of the 8 pt gap.
                .padding(.trailing, 3)
                .frame(height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(group.map { language.text($0.titleKey) } ?? "")
        .accessibilityIdentifier("favoriteDemo.\(symbol).edit")
    }

    private func toggleFavorite() {
        let adding = !isFavorite
        let motion = adding ? ModalMotion.entrance(bounceMultiplier: 0.7) : ModalMotion.dismissal
        withAnimation(reduceMotion ? nil : motion) {
            group = adding ? .standard : nil
        }
        toastPresenter?.show(language.text(adding ? .toastAddedToWatchlist : .toastDeletedFromWatchlist))
    }

    private enum FavoriteGroup: CaseIterable {
        case standard, custom

        var titleKey: DemoCopyKey {
            self == .standard ? .defaultWatchlistGroup : .custom
        }
    }
}

/// Reports the visible width to the stock row while keeping the menu label at its natural width.
private struct FavoriteLabelReveal: Layout {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let label = subviews[0].sizeThatFits(.unspecified)
        return CGSize(width: label.width * max(0, progress), height: label.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews[0].place(at: CGPoint(x: bounds.minX, y: bounds.midY), anchor: .leading, proposal: .unspecified)
    }
}
