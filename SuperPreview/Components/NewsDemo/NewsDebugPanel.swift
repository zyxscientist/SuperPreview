//
//  NewsDebugPanel.swift
//  SuperPreview
//

import SwiftUI

struct NewsDebugPanel: View {
    @Binding var language: DemoLanguage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(language.text(.debug))
                    .modifier(CustomFontModifier(size: 20, font: .bold, lineHeight: 28))
                    .foregroundColor(Color("color-text-30"))
                    .accessibilityIdentifier("news.debug.title")

                Spacer()

                Button(language.text(.done)) {
                    dismiss()
                }
                .accessibilityIdentifier("news.debug.close")
            }

            DemoLanguagePicker(language: $language)
                .environment(\.demoLanguage, language)
                .accessibilityIdentifier("news.debug.language")

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color("color-base-1").ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("news.debug.panel")
    }
}
