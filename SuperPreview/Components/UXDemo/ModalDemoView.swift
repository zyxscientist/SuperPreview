//
//  ModalDemoView.swift
//  SuperPreview
//
//  Figma: YFF Design System / 弹窗设计组件使用说明 / 弹窗具体说明
//

import SwiftUI

private enum ModalButtonStyle {
    case primary, secondary, destructive, disabled, text
}

private struct ModalAction: Identifiable {
    let id = UUID()
    let title: String
    let style: ModalButtonStyle
}

private enum ModalPhone: String {
    case hongKong, mainland

    var title: String {
        switch self {
        case .hongKong: return "香港: +852 2843 1422"
        case .mainland: return "大陆: 400 8439 666"
        }
    }

    var subtitle: String { "服务时间：香港交易日 9:00–18:00" }
}

private enum ModalActionRow: Identifiable {
    case buttons([ModalAction])
    case phone(ModalPhone)

    var id: String {
        switch self {
        case .buttons(let actions): return actions.map(\.id.uuidString).joined()
        case .phone(let phone): return phone.rawValue
        }
    }
}

private enum ModalExtra {
    case none, account, verification, password
}

private struct ModalExample: Identifiable {
    let id: String
    let section: String
    let name: String
    var title: String? = "标题"
    var subtitle: String? = nil
    var message: String? = ModalExample.bodyText
    var checked: Bool? = nil
    var extra: ModalExtra = .none
    var width: CGFloat = 320
    var isLimited = false
    var rows: [ModalActionRow] = [.buttons([ModalAction(title: "取消", style: .secondary)])]

    static let bodyText = "告知当前状态、信息和解决方法，文字换行情况。告知当前状态、信息和解决方法，文字换行情况。告知当前状态、信息和解决方法。"
    static let longText = "告知当前状态、信息和解决方法，文字换行情况。告知当前状态、信息和解决方法，文字换行情况。告知当前状态、信息和解决方法。告知当前状态、信息和解决方法，文字换行情况。告知当前状态、信息和解决方法，文字换行情况。告知当前状态、信息和解决方法，文字换行情况。告知当前状态、信息和解决方法。告知当前状态、信息和解决方法，文字换行情况。"

    static let examples: [ModalExample] = [
        .init(id: "limit-320", section: "弹窗类型", name: "限制高度 · 320pt", message: longText, isLimited: true, rows: [.buttons([.init(title: "取消", style: .text)])]),
        .init(id: "limit-338", section: "弹窗类型", name: "限制高度 · 338pt", message: longText, width: 338, isLimited: true, rows: [.phone(.hongKong), .phone(.mainland), .buttons([.init(title: "取消", style: .text)])]),
        .init(id: "title-none", section: "标题", name: "无标题", title: nil),
        .init(id: "title-single", section: "标题", name: "单行标题"),
        .init(id: "title-long", section: "标题", name: "长标题", title: "标题最多支持两行标题最多支持两行标题最多支持两行"),
        .init(id: "title-double", section: "标题", name: "双行标题", subtitle: "副标题"),
        .init(id: "layout-left", section: "内容布局", name: "全部居左对齐"),
        .init(id: "check-off", section: "勾选项", name: "未勾选", checked: false),
        .init(id: "check-on", section: "勾选项", name: "已勾选", checked: true),
        .init(id: "button-1", section: "按钮", name: "1×1"),
        .init(id: "button-12", section: "按钮", name: "1×2 · 默认", rows: [.buttons([.init(title: "取消", style: .secondary), .init(title: "确定", style: .primary)])]),
        .init(id: "button-12-danger", section: "按钮", name: "1×2 · 强调", rows: [.buttons([.init(title: "删除", style: .destructive), .init(title: "取消", style: .secondary)])]),
        .init(id: "button-12-disabled", section: "按钮", name: "1×2 · 不可点击", rows: [.buttons([.init(title: "取消", style: .secondary), .init(title: "确定", style: .disabled)])]),
        .init(id: "button-21", section: "按钮", name: "2×1 · 默认", rows: [.buttons([.init(title: "确定", style: .primary)]), .buttons([.init(title: "取消", style: .text)])]),
        .init(id: "button-21-danger", section: "按钮", name: "2×1 · 强调", rows: [.buttons([.init(title: "删除", style: .destructive)]), .buttons([.init(title: "取消", style: .text)])]),
        .init(id: "button-21-disabled", section: "按钮", name: "2×1 · 不可点击", rows: [.buttons([.init(title: "确定", style: .disabled)]), .buttons([.init(title: "取消", style: .text)])]),
        .init(id: "button-21-phone", section: "按钮", name: "2×1 · 电话号码", rows: [.phone(.hongKong), .buttons([.init(title: "取消", style: .text)])]),
        .init(id: "button-31", section: "按钮", name: "3×1 · 两个操作按钮", rows: [.buttons([.init(title: "确定", style: .primary)]), .buttons([.init(title: "按钮", style: .secondary)]), .buttons([.init(title: "取消", style: .text)])]),
        .init(id: "button-31-danger", section: "按钮", name: "3×1 · 默认 + 强调", rows: [.buttons([.init(title: "确定", style: .primary)]), .buttons([.init(title: "按钮", style: .destructive)]), .buttons([.init(title: "取消", style: .text)])]),
        .init(id: "button-31-disabled", section: "按钮", name: "3×1 · 默认不可点击", rows: [.buttons([.init(title: "确定", style: .disabled)]), .buttons([.init(title: "按钮", style: .secondary)]), .buttons([.init(title: "取消", style: .text)])]),
        .init(id: "button-31-phone", section: "按钮", name: "3×1 · 电话号码", rows: [.phone(.hongKong), .phone(.mainland), .buttons([.init(title: "取消", style: .text)])]),
        .init(id: "slot-account", section: "插槽内容", name: "账户信息", extra: .account),
        .init(id: "slot-verification", section: "插槽内容", name: "短信验证", title: "短信验证", message: "已向银行预留手机号发送验证码", extra: .verification),
        .init(id: "slot-password", section: "插槽内容", name: "交易密码", title: "输入交易密码以解锁交易", message: nil, extra: .password, rows: [.buttons([.init(title: "确定", style: .secondary)])])
    ]
}

struct ModalDemoView: View {
    @State private var presentedExample: ModalExample?
    private let sections = ["弹窗类型", "标题", "内容布局", "勾选项", "按钮", "插槽内容"]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 30) {
                Text("居中弹窗")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color("color-text-30"))
                Text("展示普通与限制高度的居中弹窗，以及设计稿中的标题、勾选项、按钮和内容插槽。")
                    .font(.system(size: 14))
                    .foregroundColor(Color("color-text-60"))

                ForEach(sections, id: \.self) { section in
                    VStack(alignment: .leading, spacing: 20) {
                        Text(section)
                            .font(.system(size: 19, weight: .bold))
                            .foregroundColor(Color("color-text-30"))
                        ForEach(ModalExample.examples.filter { $0.section == section }) { example in
                            exampleCard(example)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
        .background(Color("color-base-0").ignoresSafeArea())
        .navigationTitle("新弹窗组件")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $presentedExample) { example in
            ModalPresentation(example: example) { updatePresentation(nil) }
                .presentationBackground(.clear)
        }
        .transaction { transaction in
            transaction.disablesAnimations = true
        }
    }

    private func exampleCard(_ example: ModalExample) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(example.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color("color-text-30"))
            ModalCard(example: example, maximumHeight: example.isLimited ? 424 : nil, interactive: false, dismiss: {})
                .frame(maxWidth: .infinity)
            Button {
                updatePresentation(example)
            } label: {
                Text("模拟弹出")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color("color-brand-blue"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Color("color-brand-blue").opacity(0.09))
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("modal.show.\(example.id)")
        }
    }

    private func updatePresentation(_ example: ModalExample?) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            presentedExample = example
        }
    }
}

private struct ModalPresentation: View {
    let example: ModalExample
    let dismiss: () -> Void
    @State private var isVisible = false
    @State private var isDismissing = false

    private let fadeDuration: TimeInterval = 0.1

    var body: some View {
        GeometryReader { geometry in
            // GeometryReader is already inside the safe area. The remaining
            // exclusions represent the navigation bar and bottom action area.
            let availableHeight = max(200, geometry.size.height - 44 - 64)
            ZStack {
                Color("color-mask")
                    .ignoresSafeArea()
                    .onTapGesture(perform: beginDismissal)
                ModalCard(example: example, maximumHeight: availableHeight * 0.8, interactive: true, dismiss: beginDismissal)
                    .padding(.horizontal, 16)
                    .accessibilityIdentifier("modal.presented")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(isVisible ? 1 : 0)
            .animation(.linear(duration: fadeDuration), value: isVisible)
            .allowsHitTesting(isVisible && !isDismissing)
        }
        .onAppear {
            // Start after the nonanimated cover is in place, so its background
            // and the centered dialog fade together without moving.
            DispatchQueue.main.async {
                guard !isDismissing else { return }
                isVisible = true
            }
        }
        .accessibilityAddTraits(.isModal)
    }

    private func beginDismissal() {
        guard !isDismissing else { return }
        isDismissing = true
        isVisible = false
        DispatchQueue.main.asyncAfter(deadline: .now() + fadeDuration) {
            dismiss()
        }
    }
}

private struct ModalCard: View {
    let example: ModalExample
    let maximumHeight: CGFloat?
    let interactive: Bool
    let dismiss: () -> Void
    @State private var isChecked: Bool
    @State private var measuredContentHeight: CGFloat?
    @State private var measuredHeaderHeight: CGFloat = 0
    @State private var measuredActionsHeight: CGFloat = 0

    init(example: ModalExample, maximumHeight: CGFloat?, interactive: Bool, dismiss: @escaping () -> Void) {
        self.example = example
        self.maximumHeight = maximumHeight
        self.interactive = interactive
        self.dismiss = dismiss
        _isChecked = State(initialValue: example.checked ?? false)
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                titleBlock
                if example.title != nil && hasContent {
                    Color.clear.frame(height: 10)
                }
            }
            .background(ModalHeightReader { measuredHeaderHeight = $0 })

            if hasContent {
                if let maximumHeight = maximumHeight, let measuredContentHeight = measuredContentHeight {
                    ScrollView(.vertical) {
                        contentBlock
                            .fixedSize(horizontal: false, vertical: true)
                            .background(ModalHeightReader { self.measuredContentHeight = $0 })
                    }
                    .frame(height: min(measuredContentHeight, availableContentHeight(maximumHeight)))
                    .scrollDisabled(measuredContentHeight <= availableContentHeight(maximumHeight))
                } else {
                    contentBlock
                        .fixedSize(horizontal: false, vertical: true)
                        .background(ModalHeightReader { self.measuredContentHeight = $0 })
                }
            }

            if example.title != nil || hasContent {
                Color.clear.frame(height: example.isLimited ? 24 : 20)
            }

            actionRows
                .background(ModalHeightReader { measuredActionsHeight = $0 })
        }
        .padding(.top, 20)
        .frame(maxWidth: example.width)
        .background(Color("color-base-1"))
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(Color("color-separator-10"), lineWidth: 0.5)
                .allowsHitTesting(false)
        }
    }

    private var hasContent: Bool {
        example.message != nil || example.extra != .none || example.checked != nil
    }

    private func availableContentHeight(_ maximumHeight: CGFloat) -> CGFloat {
        let contentToActions: CGFloat = example.title != nil || hasContent ? (example.isLimited ? 24 : 20) : 0
        return max(0, maximumHeight - 20 - measuredHeaderHeight - contentToActions - measuredActionsHeight)
    }

    private var contentBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            messageBlock
            extraBlock
            checkBlock
        }
    }

    @ViewBuilder private var titleBlock: some View {
        if let title = example.title {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("PlusJakartaSans-Bold", size: 18, relativeTo: .headline))
                    .lineLimit(2)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
                if let subtitle = example.subtitle {
                    Text(subtitle)
                        .font(.custom("PlusJakartaSans-Regular", size: 14, relativeTo: .subheadline))
                        .foregroundColor(Color("color-text-60"))
                        .frame(minHeight: 20, alignment: .leading)
                }
            }
            .foregroundColor(Color("color-text-30"))
            .padding(.horizontal, 20)
        }
    }

    @ViewBuilder private var messageBlock: some View {
        if let message = example.message {
            Text(message)
                .font(.custom("PlusJakartaSans-Regular", size: 16, relativeTo: .body))
                .foregroundColor(Color("color-text-30"))
                .lineSpacing(4)
                .multilineTextAlignment(example.extra == .verification ? .center : .leading)
                .frame(maxWidth: .infinity, alignment: example.extra == .verification ? .center : .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 20)
        }
    }

    @ViewBuilder private var checkBlock: some View {
        if example.checked != nil {
            Button {
                if interactive { isChecked.toggle() }
            } label: {
                HStack(alignment: .top, spacing: 4) {
                    Image(isChecked ? "modal-checkbox-on" : "modal-checkbox-off")
                    Text(example.checked == true ? "不再提示此消息最多不能超过两行不再提示此消息最多不能超过两行" : "不再提示此消息")
                        .font(.custom("PlusJakartaSans-Regular", size: 12, relativeTo: .caption))
                        .foregroundColor(Color("color-text-60"))
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("不再提示此消息")
            .accessibilityValue(isChecked ? "已勾选" : "未勾选")
            .padding(.horizontal, 20)
        }
    }

    @ViewBuilder private var extraBlock: some View {
        switch example.extra {
        case .none:
            EmptyView()
        case .account:
            VStack(spacing: 8) {
                accountRow("金额", "200,000.00 HKD")
                accountRow("收款银行", "工商银行")
                accountRow("收款银行", "工商银行")
                accountRow("收款银行", "工商银行")
            }
            .font(.custom("PlusJakartaSans-Regular", size: 16, relativeTo: .body))
            .foregroundColor(Color("color-text-30"))
            .padding(10)
            .background(Color("color-scale-1"))
            .cornerRadius(10)
            .padding(.horizontal, 20)
        case .verification:
            VStack(spacing: 0) {
                Text("+86-1333456789")
                    .font(.custom("PlusJakartaSans-Bold", size: 16, relativeTo: .body))
                    .foregroundColor(Color("color-text-30"))
                    .frame(maxWidth: .infinity, minHeight: 24)

                Color.clear.frame(height: 15)
                codeFields(highlightFirst: true, square: true)
                Color.clear.frame(height: 11)

                codeFootnote("59秒后重新发送", color: Color("color-text-60"))
            }
            .padding(.horizontal, 20)
        case .password:
            VStack(spacing: 0) {
                HStack(spacing: 2) {
                    Image("modal-security")
                    Text("云锋证券全力确保您的账户安全")
                        .font(.custom("PlusJakartaSans-Regular", size: 10, relativeTo: .caption2))
                        .foregroundColor(Color("color-text-90"))
                    Spacer(minLength: 0)
                }
                .frame(minHeight: 12)

                Color.clear.frame(height: 24)
                codeFields(highlightFirst: false, square: false)
                Color.clear.frame(height: 9)

                codeFootnote("忘记密码", color: Color("color-brand-blue"))
            }
            .padding(.horizontal, 20)
        }
    }

    private func codeFields(highlightFirst: Bool, square: Bool) -> some View {
        HStack(spacing: 8.55) {
            ForEach(0..<6) { index in
                codeField(highlighted: highlightFirst && index == 0, square: square)
            }
        }
    }

    @ViewBuilder private func codeField(highlighted: Bool, square: Bool) -> some View {
        let field = RoundedRectangle(cornerRadius: 6)
            .fill(Color("color-scale-1"))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(highlighted ? Color("color-brand-blue") : .clear, lineWidth: 1)
            }
            .frame(maxWidth: .infinity)

        if square {
            field.aspectRatio(1, contentMode: .fit)
        } else {
            field.frame(height: 37)
        }
    }

    private func codeFootnote(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.custom("PlusJakartaSans-Regular", size: 12, relativeTo: .caption))
            .foregroundColor(color)
            .frame(maxWidth: .infinity, minHeight: 16, alignment: .trailing)
            .padding(.trailing, 9)
    }

    private func accountRow(_ title: String, _ value: String) -> some View {
        HStack { Text(title); Spacer(); Text(value) }
    }

    private var actionRows: some View {
        VStack(spacing: 2) {
            ForEach(example.rows) { row in
                switch row {
                case .buttons(let actions):
                    HStack(spacing: 12) {
                        ForEach(actions) { action in
                            Button {
                                if interactive { dismiss() }
                            } label: {
                                Text(action.title)
                                    .font(.custom("PlusJakartaSans-Bold", size: 16, relativeTo: .body))
                                    .foregroundColor(foreground(for: action.style))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(background(for: action.style))
                                    .clipShape(Capsule())
                            }
                            .disabled(action.style == .disabled)
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                case .phone(let phone):
                    Button {
                        if interactive { dismiss() }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(phone.title).font(.custom("PlusJakartaSans-Bold", size: 16, relativeTo: .body))
                                Text(phone.subtitle).font(.custom("PlusJakartaSans-Regular", size: 12, relativeTo: .caption)).foregroundColor(Color("color-text-60"))
                            }
                            Spacer(minLength: 0)
                            Image("modal-chevron")
                        }
                        .foregroundColor(Color("color-text-30"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .background(Color("color-scale-2"))
                        .clipShape(
                            UnevenRoundedRectangle(
                                topLeadingRadius: phone == .hongKong ? 10 : 2,
                                bottomLeadingRadius: phone == .hongKong ? 2 : 10,
                                bottomTrailingRadius: phone == .hongKong ? 2 : 10,
                                topTrailingRadius: phone == .hongKong ? 10 : 2
                            )
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                }
            }
        }
        .padding(.bottom, 8)
    }

    private func foreground(for style: ModalButtonStyle) -> Color {
        switch style {
        case .primary, .disabled: return Color("color-text-r")
        case .destructive: return Color("color-utility-red")
        case .secondary, .text: return Color("color-text-30")
        }
    }

    private func background(for style: ModalButtonStyle) -> Color {
        switch style {
        case .primary: return Color("color-base-r")
        case .secondary: return Color("color-base-r").opacity(0.08)
        case .destructive: return Color("color-utility-red").opacity(0.10)
        case .disabled: return Color("color-base-r").opacity(0.5)
        case .text: return .clear
        }
    }
}

/// Reports the view's actual height without imposing a size on it.
private struct ModalHeightReader: View {
    let onChange: (CGFloat) -> Void

    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .onAppear { onChange(geometry.size.height) }
                .onChange(of: geometry.size.height) { _, height in onChange(height) }
        }
    }
}
