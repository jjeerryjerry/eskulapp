import SwiftUI
import Shared

// Waski dzialajacy pion iOS: wejscie kodem -> pobranie bundla z API (modul :shared, Ktor)
// -> pokazanie nazwy eventu i liczby prelekcji. Odpowiednik androidowego EntryScreen.
// UI natywne SwiftUI; cala logika sieci i model z KMP.

private let petrol = Color(red: 0x0C/255, green: 0x5A/255, blue: 0x63/255)
private let coral = Color(red: 0xFF/255, green: 0x6B/255, blue: 0x57/255)

struct EntryView: View {
    @State private var code = ""
    @State private var loading = false
    @State private var message = ""
    @State private var bundle: BundleDto?

    private let api = EskulappApi()

    var body: some View {
        VStack(spacing: 20) {
            Text("Eskulapp")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(petrol)

            Text("Wpisz kod wydarzenia, np. FND2027")
                .foregroundColor(.secondary)

            TextField("Kod wydarzenia", text: $code)
                .textInputAutocapitalization(.characters)
                .disableAutocorrection(true)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

            Button(action: join) {
                Text(loading ? "Laczenie..." : "Dolacz")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(coral)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(loading || code.trimmingCharacters(in: .whitespaces).isEmpty)

            if !message.isEmpty {
                Text(message).foregroundColor(.red)
            }

            if let b = bundle {
                VStack(alignment: .leading, spacing: 6) {
                    Text(b.event.name).font(.headline)
                    if let city = b.event.city { Text(city).foregroundColor(.secondary) }
                    Text("Prelekcje: \(b.talks.count)  Prelegenci: \(b.speakers.count)")
                        .font(.subheadline).foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }

            Spacer()
        }
        .padding()
    }

    private func join() {
        message = ""
        bundle = nil
        loading = true
        Task {
            do {
                let result = try await api.fetchBundle(code: code)
                await MainActor.run {
                    bundle = result
                    loading = false
                }
            } catch {
                await MainActor.run {
                    message = "Nie znaleziono wydarzenia albo blad polaczenia."
                    loading = false
                }
            }
        }
    }
}
