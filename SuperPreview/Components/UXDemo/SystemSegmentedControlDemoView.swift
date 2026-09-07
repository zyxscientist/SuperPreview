//
//  SystemSegmentedControlDemoView.swift
//  SuperPreview
//
//  Created by Codex on 2026/09/07.
//

import SwiftUI

/// 展示 SwiftUI 对 iOS 原生 UISegmentedControl 的封装方式。
///
/// 这里不重绘选中态背景或动画，实际控件仅使用 Picker + SegmentedPickerStyle，
/// 方便直接观察系统组件的默认行为。
struct SystemSegmentedControlDemoView: View {
    @State private var selectedSection: SystemSegmentedControlSection = .overview
    @State private var selectedLayout: SystemSegmentedControlLayout = .list
    @State private var isSecondaryControlDisabled = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                introduction
                primaryControlCard
                secondaryControlCard
                disabledControlCard
                implementationCard
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(Color("color-base-0").ignoresSafeArea())
        .navigationTitle("iOS Segmented Control")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("compare.systemSegmentedControl.demo")
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("iOS 系统 Segmented Control")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color("color-text-30"))

            Text("SwiftUI 通过 Picker 的 SegmentedPickerStyle 直接使用系统分段控件。下面的选中态、圆角、动画和触控反馈均由系统负责。")
                .font(.system(size: 14))
                .foregroundColor(Color("color-text-60"))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var primaryControlCard: some View {
        controlCard {
            cardHeader(
                title: "基础用法",
                subtitle: "3 个选项 · 适合页面级内容切换"
            )

            Picker("内容", selection: $selectedSection) {
                ForEach(SystemSegmentedControlSection.allCases) { section in
                    Text(section.title).tag(section)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .accessibilityIdentifier("compare.systemSegmentedControl.primary")

            selectionSummary(title: "当前选中", value: selectedSection.title)
        }
    }

    private var secondaryControlCard: some View {
        controlCard {
            cardHeader(
                title: "双选项用法",
                subtitle: "2 个选项 · 适合列表 / 卡片等视图模式切换"
            )

            Picker("显示方式", selection: $selectedLayout) {
                ForEach(SystemSegmentedControlLayout.allCases) { layout in
                    Text(layout.title).tag(layout)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .accessibilityIdentifier("compare.systemSegmentedControl.secondary")

            selectionSummary(title: "当前选中", value: selectedLayout.title)
        }
    }

    private var disabledControlCard: some View {
        controlCard {
            cardHeader(
                title: "禁用状态",
                subtitle: "系统控件会自动降低对比度并阻止交互"
            )

            Picker("不可用控件", selection: $selectedLayout) {
                ForEach(SystemSegmentedControlLayout.allCases) { layout in
                    Text(layout.title).tag(layout)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .disabled(isSecondaryControlDisabled)
            .accessibilityIdentifier("compare.systemSegmentedControl.disabled")

            Toggle("模拟禁用状态", isOn: $isSecondaryControlDisabled)
                .tint(Color("color-brand-blue"))
                .accessibilityIdentifier("compare.systemSegmentedControl.disableToggle")
        }
    }

    private var implementationCard: some View {
        controlCard {
            cardHeader(
                title: "实现方式",
                subtitle: "不需要自定义 Capsule、背景或选中态动画"
            )

            Text("Picker(\"内容\", selection: $selection) {\n    Text(\"概览\").tag(Section.overview)\n    Text(\"详情\").tag(Section.details)\n}\n.pickerStyle(SegmentedPickerStyle())")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(Color("color-text-60"))
                .fixedSize(horizontal: false, vertical: true)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color("color-base-0"))
                .cornerRadius(8)
        }
    }

    private func controlCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14, content: content)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("color-base-1"))
            .cornerRadius(12)
    }

    private func cardHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color("color-text-30"))

            Text(subtitle)
                .font(.system(size: 13))
                .foregroundColor(Color("color-text-60"))
        }
    }

    private func selectionSummary(title: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .foregroundColor(Color("color-text-60"))
            Text(value)
                .foregroundColor(Color("color-brand-blue"))
        }
        .font(.system(size: 13, weight: .medium))
        .accessibilityElement(children: .combine)
    }
}

private enum SystemSegmentedControlSection: String, CaseIterable, Identifiable {
    case overview
    case details
    case settings

    var id: Self { self }

    var title: String {
        switch self {
        case .overview: return "概览"
        case .details: return "详情"
        case .settings: return "设置"
        }
    }
}

private enum SystemSegmentedControlLayout: String, CaseIterable, Identifiable {
    case list
    case cards

    var id: Self { self }

    var title: String {
        switch self {
        case .list: return "列表"
        case .cards: return "卡片"
        }
    }
}

struct SystemSegmentedControlDemoViewPreviews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SystemSegmentedControlDemoView()
        }
        .preferredColorScheme(.dark)
    }
}
