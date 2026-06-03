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

            Text("NoBold")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(Ink.text)

            Spacer()
                .frame(height: 6)

            Text("Strips bold formatting from your clipboard.")
                .font(.system(size: 13))
                .foregroundStyle(Ink.secondary)
                .multilineTextAlignment(.center)

            Spacer()
                .frame(height: 32)

            VStack(alignment: .leading, spacing: 18) {
                featureRow(
                    icon: "doc.on.clipboard",
                    title: "Watches your clipboard",
                    detail: "Monitors copies from any app and strips bold in real time."
                )

                featureRow(
                    icon: "textformat",
                    title: "RTF, HTML, and Markdown",
                    detail: "Handles bold from rich text, web content, and markdown markers."
                )

                featureRow(
                    icon: "menubar.rectangle",
                    title: "Lives in your menu bar",
                    detail: "Look for the stars icon in the menu bar to control NoBold."
                )
            }
            .padding(.horizontal, 8)

            Spacer()
                .frame(height: 36)

            Button(action: onDismiss) {
                Text("Get Started")
            }
            .buttonStyle(InkPrimaryButtonStyle())

            Spacer()
                .frame(height: 10)

            Text("NoBold is running. Control it from the menu bar.")
                .font(.system(size: 10.5))
                .foregroundStyle(Ink.tertiary)
                .multilineTextAlignment(.center)

            Spacer()
                .frame(height: 28)
        }
        .padding(.horizontal, 36)
        .frame(width: 400, height: 480)
        .background(Ink.desk)
    }

    private func featureRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Ink.secondary)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Ink.text)
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(Ink.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
