import SwiftUI

struct EmojiPickerView: View {
    @Binding var selectedEmoji: String
    @Environment(\.dismiss) private var dismiss
    @State private var customEmoji = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Enter any emoji")
                    .font(.headline)
                    .padding(.top)

                TextField("", text: $customEmoji)
                    .font(.system(size: 80))
                    .multilineTextAlignment(.center)
                    .frame(height: 120)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .onChange(of: customEmoji) { _, newValue in
                        // Only keep emojis
                        let emojis = newValue.filter { $0.isEmoji }
                        if let firstEmoji = emojis.first {
                            customEmoji = String(firstEmoji)
                        }
                    }

                Text("Tap the field above and use your emoji keyboard")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Pick Emoji")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if !customEmoji.isEmpty {
                            selectedEmoji = customEmoji
                        }
                        dismiss()
                    }
                    .disabled(customEmoji.isEmpty)
                }
            }
        }
    }
}

extension Character {
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmoji && (scalar.value > 0x238C || unicodeScalars.count > 1)
    }
}

#Preview {
    EmojiPickerView(selectedEmoji: .constant("📝"))
}
