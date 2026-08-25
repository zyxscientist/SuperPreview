//
//  StockOrderSymbolSearchSheet.swift
//  SuperPreview
//

import SwiftUI

struct StockOrderSymbolSearchSheet: View {
    @Binding var query: String

    let recentSymbols: [StockOrderSymbol]
    let results: [StockOrderSymbol]
    let availability: StockOrderSearchAvailability
    let onSelect: (StockOrderSymbol) -> Void
    let onClearHistory: () -> Void
    let onRetry: () -> Void

    @Environment(\.demoLanguage) private var language
    @Environment(\.dismiss) private var dismiss
    @FocusState private var searchFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            StockOrderSearchSheetHandle()
            searchBox
            searchContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color("color-base-1"))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockOrder.symbolSearchSheet")
        .onAppear {
            DispatchQueue.main.async {
                searchFieldFocused = true
            }
        }
    }

    private var searchBox: some View {
        HStack(spacing: 0) {
            ZStack(alignment: .leading) {
                if query.isEmpty {
                    Text(language.text(.searchPlaceholder))
                        .modifier(CustomFontModifier(size: 18, font: .regular, lineHeight: 28))
                        .foregroundColor(Color("color-text-60"))
                        .padding(.leading, 12)
                        .allowsHitTesting(false)
                }

                TextField("", text: $query)
                    .modifier(CustomFontModifier(size: 18, font: .regular, lineHeight: 28))
                    .foregroundColor(Color("color-text-30"))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .focused($searchFieldFocused)
                    .padding(.leading, 12)
                    .frame(maxHeight: .infinity)
                    .accessibilityLabel(language.text(.searchPlaceholder))
                    .accessibilityIdentifier("stockOrder.symbolSearchSheet.query")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Spacer(minLength: 0)

            HStack(spacing: 16) {
                if !query.isEmpty {
                    Button {
                        query = ""
                        searchFieldFocused = true
                    } label: {
                        Image("stock_order_clear")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel(language.text(.clear))
                    .accessibilityIdentifier("stockOrder.symbolSearchSheet.clear")
                }

                Button {
                    dismiss()
                } label: {
                    Text(language.text(.cancel))
                        .modifier(CustomFontModifier(size: 16, font: .bold, lineHeight: 24))
                        .foregroundColor(Color("color-text-r"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color("color-base-r"))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(language.text(.cancel))
                .accessibilityIdentifier("stockOrder.symbolSearchSheet.cancel")
            }
            .frame(height: 32)
            .padding(.vertical, 6)
            .padding(.trailing, 6)
        }
        .frame(height: 44)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color("color-dialog"))
                .overlay {
                    // 内阴影
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.black.opacity(0.01), lineWidth: 5)
                        .blur(radius: 1)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color("color-separator-10"), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .accessibilityIdentifier("stockOrder.symbolSearchSheet.searchBox")
    }

    @ViewBuilder
    private var searchContent: some View {
        if availability == .networkError {
            networkErrorContent
        } else if query.stockOrderSearchNormalized.isEmpty {
            if recentSymbols.isEmpty {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                historyContent
            }
        } else if results.isEmpty {
            noResultContent
        } else {
            resultContent
        }
    }

    private var historyContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text(language.text(.recentSearches))
                        .modifier(CustomFontModifier(size: 14, font: .regular, lineHeight: 24))
                        .foregroundColor(Color("color-text-30"))

                    Spacer(minLength: 0)

                    Button {
                        onClearHistory()
                    } label: {
                        Image("stock_order_delete")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel(language.text(.clearSearchHistory))
                    .accessibilityIdentifier("stockOrder.symbolSearchSheet.clearHistory")
                }
                .padding(.horizontal, 16)
                .frame(height: 24)

                ForEach(recentSymbols) { symbol in
                    searchRow(symbol)
                }
            }
            .padding(.top, 16)
        }
        .accessibilityIdentifier("stockOrder.symbolSearchSheet.history")
    }

    private var resultContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(results) { symbol in
                    searchRow(symbol)
                }
            }
            .padding(.top, 16)
        }
        .accessibilityIdentifier("stockOrder.symbolSearchSheet.results")
    }

    private var noResultContent: some View {
        VStack(spacing: 24) {
            Image("stock_order_no_result")
                .resizable()
                .scaledToFit()
                .frame(width: 130, height: 80)

            Text(language.text(.noSearchResult))
                .modifier(CustomFontModifier(size: 14, font: .regular, lineHeight: 20))
                .foregroundColor(Color("color-text-60"))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
        .padding(.bottom, 10)
        .accessibilityIdentifier("stockOrder.symbolSearchSheet.noResult")
    }

    private var networkErrorContent: some View {
        VStack(spacing: 10) {
            Image("stock_order_network_error")
                .resizable()
                .scaledToFit()
                .frame(width: 130, height: 80)

            Text(language.text(.networkUnavailable))
                .modifier(CustomFontModifier(size: 14, font: .regular, lineHeight: 20))
                .foregroundColor(Color("color-text-60"))

            Button {
                onRetry()
            } label: {
                Text(language.text(.refreshNow))
                    .modifier(CustomFontModifier(size: 12, font: .regular, lineHeight: 16))
                    .foregroundColor(Color("color-brand-blue"))
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel(language.text(.refreshNow))
            .accessibilityIdentifier("stockOrder.symbolSearchSheet.retry")
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 10)
        .accessibilityIdentifier("stockOrder.symbolSearchSheet.networkError")
    }

    private func searchRow(_ symbol: StockOrderSymbol) -> some View {
        Button {
            onSelect(symbol)
        } label: {
            HStack(spacing: 2) {
                Text(symbol.id)
                    .modifier(CustomFontModifier(size: 18, font: .regular, lineHeight: 28))
                    .foregroundColor(Color("color-text-30"))
                    .lineLimit(1)
                    .frame(width: 96, alignment: .leading)

                Text(symbol.localizedName(for: language))
                    .modifier(CustomFontModifier(size: 18, font: .regular, lineHeight: 28))
                    .foregroundColor(Color("color-text-30"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                    .allowsTightening(true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(
            language.actionAccessibilityLabel(
                name: symbol.localizedName(for: language),
                action: symbol.id
            )
        )
        .accessibilityIdentifier("stockOrder.symbolSearchSheet.result.\(symbol.id)")
    }
}

private struct StockOrderSearchSheetHandle: View {
    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color("color-scale-3"))
                .frame(width: 40, height: 4)
                .padding(.top, 10)
        }
        .frame(height: 44, alignment: .top)
        .accessibilityHidden(true)
    }
}

private struct StockOrderSearchSheetPreview: View {
    let state: SearchSheetPreviewState

    @State private var query: String

    enum SearchSheetPreviewState {
        case history
        case noHistory
        case results
        case noResult
        case networkError
    }

    init(state: SearchSheetPreviewState) {
        self.state = state
        switch state {
        case .history, .noHistory:
            _query = State(initialValue: "")
        case .results, .noResult, .networkError:
            _query = State(initialValue: "a a p l")
        }
    }

    var body: some View {
        StockOrderSymbolSearchSheet(
            query: $query,
            recentSymbols: state == .noHistory ? [] : StockOrderSymbolPreviewData.recentSymbols,
            results: state == .results ? [StockOrderSymbolPreviewData.aapl] : [],
            availability: state == .networkError ? .networkError : .available,
            onSelect: { _ in },
            onClearHistory: {},
            onRetry: {}
        )
        .environment(\.demoLanguage, .simplifiedChinese)
    }
}

extension StockOrderSearchSheetPreview.SearchSheetPreviewState: Equatable {}

struct StockOrderSymbolSearchSheet_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockOrderSearchSheetPreview(state: .history)
                .previewDisplayName("History")

            StockOrderSearchSheetPreview(state: .noHistory)
                .previewDisplayName("No History")

            StockOrderSearchSheetPreview(state: .results)
                .previewDisplayName("Results")

            StockOrderSearchSheetPreview(state: .noResult)
                .previewDisplayName("No Result")

            StockOrderSearchSheetPreview(state: .networkError)
                .previewDisplayName("Network Error")
        }
        .previewLayout(.fixed(width: 402, height: 812))
    }
}
