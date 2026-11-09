//
//  ModalDemoView.swift
//  SuperPreview
//
//  Figma: YFF Design System / 弹窗具体说明 (2190:2963) / 居中弹窗
//

import SwiftUI

private enum ModalActionState {
    case normal, pressed, disabled

    var opacity: Double {
        switch self {
        case .normal: 1
        case .pressed: 0.8
        case .disabled: 0.5
        }
    }
}

private struct ModalActionVisuals {
    let label: Color
    var fill: Color = .clear
    var stroke: Color? = nil
    var labelOpacity: Double = 1
    var opacity: Double = 1
}

private enum ModalActionAppearance {
    case solid(fill: Color, label: Color)
    case translucent(fill: Color, pressedFill: Color, label: Color)
    case outlined(ink: Color, pressedFill: Color)
    case text

    static let solidBlue = Self.solid(fill: Color(.color01SolidBlue), label: Color(.colorNeutralContrary2))
    static let solidBlack = Self.solid(fill: Color(.color01SolidBlack), label: Color(.colorTextr))
    // The design system's neutral translucent button uses the neutral gray fills.
    static let neutralGray = Self.translucent(
        fill: Color(.color01SolidGray), pressedFill: Color(.color03PressGary), label: Color(.colorText1)
    )
    static let transparentBlue = Self.translucent(
        fill: Color(.color02TransparentBlue), pressedFill: Color(.color03PressBlue), label: Color(.color01SolidBlue)
    )
    static let transparentRed = Self.translucent(
        fill: Color(.color02TransparentRed), pressedFill: Color(.color03PressRed), label: Color(.color01SolidRed)
    )
    static let outlinedBlue = Self.outlined(ink: Color(.color01SolidBlue), pressedFill: Color(.color03PressBlueLine))

    var cornerRadius: CGFloat {
        if case .text = self { return 10 }
        return 22
    }

    func visuals(for state: ModalActionState) -> ModalActionVisuals {
        switch self {
        case let .solid(fill, label):
            ModalActionVisuals(label: label, fill: fill, opacity: state.opacity)
        case let .translucent(fill, pressedFill, label):
            ModalActionVisuals(
                label: label,
                fill: state == .pressed ? pressedFill : fill,
                labelOpacity: state == .disabled ? state.opacity : 1,
                opacity: state == .pressed ? state.opacity : 1
            )
        case let .outlined(ink, pressedFill):
            ModalActionVisuals(
                label: ink,
                fill: state == .pressed ? pressedFill : .clear,
                stroke: ink,
                opacity: state.opacity
            )
        case .text:
            ModalActionVisuals(label: Color(.color01SolidBlack), opacity: state == .disabled ? state.opacity : 1)
        }
    }
}

private struct ModalActionButtonStyle: ButtonStyle {
    let appearance: ModalActionAppearance
    let isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        let state: ModalActionState = isEnabled ? (configuration.isPressed ? .pressed : .normal) : .disabled
        let visuals = appearance.visuals(for: state)
        let shape = RoundedRectangle(cornerRadius: appearance.cornerRadius, style: .circular)

        configuration.label
            .font(.custom("PlusJakartaSans-Bold", size: 16, relativeTo: .body))
            .foregroundStyle(visuals.label)
            .opacity(visuals.labelOpacity)
            .lineLimit(1)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(visuals.fill, in: shape)
            .overlay {
                if let stroke = visuals.stroke {
                    shape.strokeBorder(stroke, lineWidth: 1)
                        .allowsHitTesting(false)
                }
            }
            .contentShape(shape)
            .compositingGroup()
            .opacity(visuals.opacity)
    }
}

private struct ModalAction: Identifiable {
    let id = UUID()
    let title: String
    let appearance: ModalActionAppearance
    var isEnabled = true
}

private enum ModalPhone: String {
    case hongKong, mainland

    var title: String {
        switch self {
        case .hongKong: return "香港: +852 2843 1422"
        case .mainland: return "大陆: 400 8439 666"
        }
    }

    var subtitle: String { "服务时间：香港交易日 9:00-18:00" }
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

    var actionCount: Int {
        switch self {
        case .buttons(let actions): actions.count
        case .phone: 1
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
    var heightLimit: CGFloat? = nil
    var rows: [ModalActionRow] = [.buttons([ModalAction(title: "取消", appearance: .neutralGray)])]

    var isLimited: Bool { heightLimit != nil }
    var actionBottomInset: CGFloat {
        !isLimited && rows.reduce(0, { $0 + $1.actionCount }) > 1 ? 8 : 6
    }

    static let bodyText = "告知当前状态、信息和解决方法，文字换行情况。告知当前状态、信息和解决方法，文字换行情况。告知当前状态、信息和解决方法。"
    static let standardLimitText = "告知当前状态、信息和解决方法，文字换行情况。告知当前状态、信息和解决方法，文字换行情况。告知当前状态、信息和解决方法。告知当前状态、信息和解决方法，文字换行情况。告知当前状态、信息和解决方法，文字换行情况。告知当前状态、信息和解决方法，文字换行情况。告知当前状态、信息和解决方法。告知当前状态、信息和解决方法，文字换行情况。告知当前状态、信息和解决方法，文字换行情况。告知当前状态、信息和解决方法，文字换行情况。告知当前状态、信息和解决方法。告知当前状态、信息和解决方法，文字换行情况。告知当前状态、信息和解决方法，文字换行情况。告知当前状态、信息和解决方法，文字换行情况。告知当前状态、信息和解决方法。告知当前状态、信息和解决方法，文字换行情况。"
    static let phoneLimitText = "告知当前状态、信息和解决方法，文字换行情况。告知当前状态、信息和解决方法，文字换行情况。告知当前状态、信息和解决方法。告知当前状态、信息和解决方法，文字换行情况。告知当前状态、信息和解决方法，文字换行情况。告知当前状态、信息和解决方法，文字换行情况。告知当前状态、信息和解决方法。告知当前状态、信息和解决方法，文字换行情况。文字换行情况。告知当前状态、信息和解决方法，文字换行情况。告知当前状态、信息和解决方法，文字换行情况。告知当前状态、信息和解决方法。告知当前状态、信息和解决方法，文字换行情况。"

    static let examples: [ModalExample] = [
        .init(id: "limit-320", section: "弹窗类型", name: "限制高度 · 320pt", message: standardLimitText, heightLimit: 424),
        .init(id: "limit-320-phone", section: "弹窗类型", name: "限制高度 · 320pt（含电话）", message: phoneLimitText, heightLimit: 536, rows: [.phone(.hongKong), .phone(.mainland), .buttons([.init(title: "取消", appearance: .text)])]),
        .init(id: "title-none", section: "标题", name: "无标题", title: nil),
        .init(id: "title-single", section: "标题", name: "单行标题"),
        .init(id: "title-long", section: "标题", name: "长标题", title: "标题最多支持两行标题最多支持两行标题最多支持两行标题最多"),
        .init(id: "title-double", section: "标题", name: "双行标题", subtitle: "副标题"),
        .init(id: "layout-left", section: "内容布局", name: "全部居左对齐"),
        .init(id: "check-off", section: "勾选项", name: "未勾选", checked: false),
        .init(id: "check-on", section: "勾选项", name: "已勾选", checked: true),
        .init(id: "button-1", section: "按钮", name: "1×1"),
        .init(id: "button-12", section: "按钮", name: "1×2 · 默认", rows: [.buttons([.init(title: "取消", appearance: .neutralGray), .init(title: "确定", appearance: .solidBlue)])]),
        .init(id: "button-12-danger", section: "按钮", name: "1×2 · 强调", rows: [.buttons([.init(title: "删除", appearance: .transparentRed), .init(title: "取消", appearance: .neutralGray)])]),
        .init(id: "button-12-disabled", section: "按钮", name: "1×2 · 不可点击", rows: [.buttons([.init(title: "取消", appearance: .neutralGray), .init(title: "确定", appearance: .solidBlue, isEnabled: false)])]),
        .init(id: "button-12-transparent-disabled", section: "按钮", name: "半透明 · 禁用", rows: [.buttons([.init(title: "删除", appearance: .transparentRed, isEnabled: false), .init(title: "取消", appearance: .neutralGray)])]),
        .init(id: "button-12-outline", section: "按钮", name: "线性 · 可用与禁用", rows: [.buttons([.init(title: "取消", appearance: .outlinedBlue), .init(title: "确定", appearance: .outlinedBlue, isEnabled: false)])]),
        .init(id: "button-21", section: "按钮", name: "2×1 · 默认", rows: [.buttons([.init(title: "确定", appearance: .solidBlue)]), .buttons([.init(title: "取消", appearance: .text)])]),
        .init(id: "button-21-danger", section: "按钮", name: "2×1 · 强调", rows: [.buttons([.init(title: "删除", appearance: .transparentBlue)]), .buttons([.init(title: "取消", appearance: .text)])]),
        .init(id: "button-21-disabled", section: "按钮", name: "2×1 · 不可点击", rows: [.buttons([.init(title: "按钮", appearance: .solidBlue, isEnabled: false)]), .buttons([.init(title: "取消", appearance: .text)])]),
        .init(id: "button-21-phone", section: "按钮", name: "2×1 · 电话号码", rows: [.phone(.hongKong), .buttons([.init(title: "取消", appearance: .text)])]),
        .init(id: "button-31", section: "按钮", name: "3×1 · 两个操作按钮", rows: [.buttons([.init(title: "确定", appearance: .solidBlue)]), .buttons([.init(title: "按钮", appearance: .neutralGray)]), .buttons([.init(title: "取消", appearance: .text)])]),
        .init(id: "button-31-danger", section: "按钮", name: "3×1 · 默认 + 强调", rows: [.buttons([.init(title: "确定", appearance: .solidBlue)]), .buttons([.init(title: "按钮", appearance: .transparentBlue)]), .buttons([.init(title: "取消", appearance: .text)])]),
        .init(id: "button-31-disabled", section: "按钮", name: "3×1 · 默认不可点击", rows: [.buttons([.init(title: "确定", appearance: .solidBlack, isEnabled: false)]), .buttons([.init(title: "按钮", appearance: .neutralGray)]), .buttons([.init(title: "取消", appearance: .text)])]),
        .init(id: "button-31-phone", section: "按钮", name: "3×1 · 电话号码", rows: [.phone(.hongKong), .phone(.mainland), .buttons([.init(title: "取消", appearance: .text)])]),
        .init(id: "slot-account", section: "插槽内容", name: "账户信息", extra: .account),
        .init(id: "slot-verification", section: "插槽内容", name: "短信验证", title: "短信验证", message: "已向银行预留手机号发送验证码", extra: .verification),
        .init(id: "slot-password", section: "插槽内容", name: "交易密码", title: "输入交易密码以解锁交易", message: nil, extra: .password)
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
                    .foregroundColor(Color("color-text1"))
                Text("展示普通与限制高度的居中弹窗，以及设计稿中的标题、勾选项、按钮和内容插槽。")
                    .font(.system(size: 14))
                    .foregroundColor(Color("color-text-60"))

                ForEach(sections, id: \.self) { section in
                    VStack(alignment: .leading, spacing: 20) {
                        Text(section)
                            .font(.system(size: 19, weight: .bold))
                            .foregroundColor(Color("color-text1"))
                        ForEach(ModalExample.examples.filter { $0.section == section }) { example in
                            exampleCard(example)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
        .accessibilityIdentifier("modal.gallery")
        .background(Color("color-base0").ignoresSafeArea())
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
                .foregroundColor(Color("color-text1"))
            ModalCard(example: example, maximumHeight: example.heightLimit, interactive: false, dismiss: {})
                .frame(maxWidth: .infinity)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            Button {
                updatePresentation(example)
            } label: {
                Text("模拟弹出")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color("color-blue1"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Color("color-blue1").opacity(0.09))
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
            let heightLimit = min(example.heightLimit ?? .infinity, availableHeight * 0.8)
            ZStack {
                Color("color-mask")
                    .ignoresSafeArea()
                    .onTapGesture(perform: beginDismissal)
                ModalCard(example: example, maximumHeight: heightLimit, interactive: true, dismiss: beginDismissal)
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("modal.presented")
                    .padding(.horizontal, 16)
                    .offset(y: (geometry.safeAreaInsets.bottom - geometry.safeAreaInsets.top) / 2)
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
    private let contentInset: CGFloat = 20
    @State private var isChecked: Bool
    @State private var measuredContentHeight: CGFloat?
    @State private var measuredHeaderHeight: CGFloat = 0
    @State private var measuredActionsHeight: CGFloat = 0
    @State private var contentScrollProgress: CGFloat = 0

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
                    scrollableContent(height: min(measuredContentHeight, availableContentHeight(maximumHeight)),
                                      contentHeight: measuredContentHeight)
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
        .frame(maxWidth: 320)
        .background(Color("color-base1"))
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(Color("color-separator1"), lineWidth: 0.5)
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

    private func scrollableContent(height: CGFloat, contentHeight: CGFloat) -> some View {
        let overflows = contentHeight > height
        let thumbHeight = min(height, 30)

        return ScrollView(.vertical) {
            contentBlock
                .fixedSize(horizontal: false, vertical: true)
                .background(ModalHeightReader { measuredContentHeight = $0 })
        }
        .frame(height: height)
        .scrollDisabled(!interactive || !overflows)
        .scrollIndicators(.hidden)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            let travel = geometry.contentSize.height - geometry.containerSize.height
            guard travel > 0 else { return 0 }
            return min(max((geometry.contentOffset.y + geometry.contentInsets.top) / travel, 0), 1)
        } action: { _, progress in
            contentScrollProgress = progress
        }
        .overlay(alignment: .topTrailing) {
            if overflows && height > 0 {
                Capsule()
                    .fill(Color(.colorGrayscale3))
                    .frame(width: 4, height: thumbHeight)
                    .offset(y: (height - thumbHeight) * contentScrollProgress)
                    .padding(.trailing, 8)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityIdentifier("modal.content.scroll")
    }

    private var contentBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            messageBlock
            extraBlock
            checkBlock
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, contentInset)
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
                        .foregroundColor(Color(.colorText2))
                        .frame(minHeight: 20, alignment: .leading)
                }
            }
            .foregroundColor(Color("color-text1"))
            .padding(.horizontal, contentInset)
        }
    }

    @ViewBuilder private var messageBlock: some View {
        if let message = example.message {
            Text(message)
                .font(.custom("PlusJakartaSans-Regular", size: 16, relativeTo: .body))
                .foregroundColor(Color("color-text1"))
                .lineSpacing(5)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 2)
        }
    }

    @ViewBuilder private var checkBlock: some View {
        if example.checked != nil {
            Button {
                if interactive { isChecked.toggle() }
            } label: {
                HStack(alignment: .top, spacing: 4) {
                    Image(isChecked ? "modal-checkbox-on" : "modal-checkbox-off")
                        .frame(width: 16, height: 16)
                        .accessibilityHidden(true)
                    Text(example.checked == true ? "不再显示此消息最多不超过2行不再显示此消息最多不超过2行" : "不再显示此消息")
                        .font(.custom("PlusJakartaSans-Regular", size: 12, relativeTo: .caption))
                        .foregroundColor(Color(.colorText2))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .frame(minHeight: example.checked == true ? 32 : 16, alignment: .topLeading)
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("不再显示此消息")
            .accessibilityValue(isChecked ? "已勾选" : "未勾选")
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
            .foregroundColor(Color("color-text1"))
            .padding(.horizontal, 8)
            .padding(.vertical, 16)
            .background(Color("color-grayscale1"))
            .cornerRadius(8)
        case .verification:
            VStack(spacing: 0) {
                Text("+86-1333456789")
                    .font(.custom("PlusJakartaSans-Bold", size: 16, relativeTo: .body))
                    .foregroundColor(Color("color-text1"))
                    .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)

                Color.clear.frame(height: 16)
                codeFields(highlightFirst: true)
                Color.clear.frame(height: 12)

                codeFootnote("59秒后重新发送", color: Color(.colorText2))
            }
        case .password:
            VStack(spacing: 0) {
                HStack(spacing: 2) {
                    Image("modal-security")
                        .frame(width: 10, height: 10)
                        .accessibilityHidden(true)
                    Text("云锋证券全力确保您的账户安全")
                        .font(.custom("PlusJakartaSans-Regular", size: 10, relativeTo: .caption2))
                        .foregroundColor(Color(.colorText2))
                    Spacer(minLength: 0)
                }
                .frame(minHeight: 12)

                Color.clear.frame(height: 24)
                codeFields(highlightFirst: false)
                Color.clear.frame(height: 6)

                codeFootnote("忘记密码", color: Color("color-blue1"))
            }
        }
    }

    private func codeFields(highlightFirst: Bool) -> some View {
        HStack(spacing: 8) {
            ForEach(0..<6) { index in
                codeField(highlighted: highlightFirst && index == 0)
            }
        }
    }

    private func codeField(highlighted: Bool) -> some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color(.colorGrayscale2))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(highlighted ? Color(.colorBlue1) : .clear, lineWidth: 1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
    }

    private func codeFootnote(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.custom("PlusJakartaSans-Regular", size: 12, relativeTo: .caption))
            .foregroundColor(color)
            .frame(maxWidth: .infinity, minHeight: 16, alignment: .trailing)
    }

    private func accountRow(_ title: String, _ value: String) -> some View {
        HStack(spacing: 12) { Text(title); Spacer(minLength: 0); Text(value) }
            .frame(minHeight: 24)
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
                            }
                            .buttonStyle(ModalActionButtonStyle(appearance: action.appearance, isEnabled: action.isEnabled))
                            .disabled(!action.isEnabled)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                case .phone(let phone):
                    Button {
                        if interactive { dismiss() }
                    } label: {
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(phone.title)
                                    .font(.custom("PlusJakartaSans-Bold", size: 16, relativeTo: .body))
                                    .frame(minHeight: 24)
                                Text(phone.subtitle)
                                    .font(.custom("PlusJakartaSans-Regular", size: 12, relativeTo: .caption))
                                    .foregroundColor(Color(.colorText2))
                                    .frame(minHeight: 16)
                            }
                            Spacer(minLength: 0)
                            Image("modal-chevron")
                                .frame(width: 16, height: 16)
                                .accessibilityHidden(true)
                        }
                        .foregroundColor(Color("color-text1"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .background(Color("color-grayscale2"))
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
        .padding(.bottom, example.actionBottomInset)
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
