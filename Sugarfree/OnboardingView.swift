import SwiftUI

struct OnboardingView: View {
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 48)

            BrandMark(size: 72)

            Spacer()
                .frame(height: 20)

            Wordmark(size: 34)

            Spacer()
                .frame(height: 6)

            Text("Strips formatting sugar from your clipboard.")
                .font(.system(size: 13))
                .foregroundStyle(Surface.secondary)
                .multilineTextAlignment(.center)

            Spacer()
                .frame(height: 32)

            VStack(alignment: .leading, spacing: 18) {
                featureRow(
                    icon: "doc.on.clipboard",
                    title: "Watches your clipboard",
                    detail: "Monitors copies from any app and cleans formatting in real time."
                )

                featureRow(
                    icon: "textformat",
                    title: "RTF, HTML, and Markdown",
                    detail: "Handles formatting from rich text, web content, and markdown markers."
                )

                featureRow(
                    icon: "menubar.rectangle",
                    title: "Lives in your menu bar",
                    detail: "Look for the lollipop icon in the menu bar to control Sugarfree."
                )
            }
            .padding(.horizontal, 8)

            Spacer()
                .frame(height: 36)

            Button(action: onDismiss) {
                Text("Get Started")
            }
            .buttonStyle(CottonPrimaryButtonStyle())

            Spacer()
                .frame(height: 10)

            Text("Sugarfree is running. Control it from the menu bar.")
                .font(.system(size: 10.5))
                .foregroundStyle(Surface.tertiary)
                .multilineTextAlignment(.center)

            Spacer()
                .frame(height: 28)
        }
        .padding(.horizontal, 36)
        .frame(width: 400, height: 480)
        .background {
            ZStack {
                Rectangle().fill(.regularMaterial)
                AuroraBackground()
            }
            .ignoresSafeArea()
        }
    }

    private func featureRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Surface.secondary)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Surface.text)
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(Surface.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
