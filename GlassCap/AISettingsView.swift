import SwiftUI

@available(macOS 12.3, *)
struct AISettingsView: View {
    @ObservedObject private var aiManager = AIManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var testResult: String?
    @State private var isTesting = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("AI Settings")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.textPrimary(for: colorScheme))
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Theme.textSecondary(for: colorScheme).opacity(0.5))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(20)

            Divider().opacity(0.3)

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Anthropic API Key")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textSecondary(for: colorScheme))

                    SecureField("sk-ant-...", text: $aiManager.apiKey)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, design: .monospaced))
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )

                    Link("Get an API key at console.anthropic.com",
                         destination: URL(string: "https://console.anthropic.com")!)
                        .font(.system(size: 11))
                        .foregroundColor(.cyan.opacity(0.8))
                }

                if let result = testResult {
                    Text(result)
                        .font(.system(size: 12))
                        .foregroundColor(result.hasPrefix("✓") ? .green : .red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(spacing: 12) {
                    Button(action: testKey) {
                        HStack(spacing: 6) {
                            if isTesting {
                                ProgressView().controlSize(.small)
                            }
                            Text(isTesting ? "Testing…" : "Test Key")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.cyan.opacity(0.8)))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!aiManager.hasAPIKey || isTesting)

                    Button(action: { dismiss() }) {
                        Text("Done")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Theme.textPrimary(for: colorScheme))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(20)
        }
        .frame(width: 420)
        .background(Theme.cardFill(for: colorScheme))
    }

    private func testKey() {
        isTesting = true
        testResult = nil
        Task {
            do {
                var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/models")!)
                req.setValue(aiManager.apiKey.trimmingCharacters(in: .whitespaces), forHTTPHeaderField: "x-api-key")
                req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
                let (_, response) = try await URLSession.shared.data(for: req)
                let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                testResult = code == 200 ? "✓ API key is valid" : "✗ Invalid key (HTTP \(code))"
            } catch {
                testResult = "✗ \(error.localizedDescription)"
            }
            isTesting = false
        }
    }
}
