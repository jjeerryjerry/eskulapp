import SwiftUI

// Wejscie kodem (odpowiednik EntryScreen). firstRun = pierwszy ekran (bez wstecz),
// inaczej ekran wpychany z listy wydarzen (NavigationStack daje wstecz).
struct EntryView: View {
    var firstRun: Bool
    @EnvironmentObject var store: AppStore
    @State private var code = ""
    @State private var loading = false
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 20)
                Seal(size: 72)
                Spacer().frame(height: 22)
                Text("Dolacz do wydarzenia")
                    .font(.system(size: 24, weight: .bold)).foregroundColor(C.ink)
                Spacer().frame(height: 10)
                Text("Wpisz kod od organizatora, a pobierzemy cala agende na telefon. Dziala tez offline.")
                    .font(.system(size: 14)).foregroundColor(C.muted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
                Spacer().frame(height: 26)

                TextField("np. FND2027", text: $code)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled(true)
                    .font(.system(size: 22, weight: .bold))
                    .kerning(3)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(C.surface)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(C.line, lineWidth: 1))
                    .onChange(of: code) { newValue in
                        code = String(newValue.uppercased().filter { $0.isLetter || $0.isNumber }.prefix(32))
                    }

                if let error = error {
                    Spacer().frame(height: 12)
                    Text(error).font(.system(size: 13)).foregroundColor(C.coralDark)
                        .multilineTextAlignment(.center)
                }

                Spacer().frame(height: 18)
                Button(action: submit) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14).fill(C.petrol).frame(height: 54)
                        if loading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Pobierz wydarzenie").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                        }
                    }
                }
                .disabled(loading || code.isEmpty)
            }
            .padding(24)
            .padding(.top, 8)
        }
        .background(C.bg.ignoresSafeArea())
        .navigationTitle(firstRun ? "" : "Dodaj wydarzenie")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func submit() {
        error = nil
        loading = true
        Task {
            do {
                let id = try await store.addEvent(code)
                loading = false
                store.openEvent(id)
            } catch let e {
                loading = false
                error = (e as? APIError)?.errorDescription ?? "Cos poszlo nie tak."
            }
        }
    }
}

// Root listy wydarzen (NavigationStack dla wpychania Entry).
struct EventsRootView: View {
    var body: some View {
        NavigationStack {
            EventsView()
                .navigationBarHidden(true)
        }
    }
}

struct EventsView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Seal(size: 36)
                Text("Moje wydarzenia").font(.system(size: 22, weight: .heavy)).foregroundColor(C.ink)
                Spacer()
            }
            .padding(.horizontal, 20).padding(.top, 14)
            Spacer().frame(height: 18)

            if store.sortedEvents.isEmpty {
                VStack(spacing: 0) {
                    Spacer()
                    ZStack {
                        RoundedRectangle(cornerRadius: 60).fill(C.tint).frame(width: 120, height: 120)
                        icon("calendar", C.petrol, 56)
                    }
                    Spacer().frame(height: 20)
                    Text("Nie masz jeszcze wydarzen").font(.system(size: 20, weight: .bold)).foregroundColor(C.ink)
                    Spacer().frame(height: 8)
                    Text("Dodaj wydarzenie kodem od organizatora.")
                        .font(.system(size: 14)).foregroundColor(C.muted).multilineTextAlignment(.center)
                    Spacer()
                }
                .frame(maxWidth: .infinity).padding(24)
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(store.sortedEvents) { ev in
                            EventCard(stored: ev)
                        }
                    }
                    .padding(.horizontal, 20).padding(.vertical, 4)
                }
            }

            NavigationLink { EntryView(firstRun: false) } label: {
                HStack(spacing: 8) {
                    icon("plus", .white, 18)
                    Text("Dodaj wydarzenie kodem").font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                }
                .frame(maxWidth: .infinity).frame(height: 54)
                .background(C.petrol).clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(20)
        }
        .background(C.bg.ignoresSafeArea())
    }
}

private struct EventCard: View {
    let stored: StoredEvent
    @EnvironmentObject var store: AppStore

    var body: some View {
        let ev = stored.bundle.event
        let archived = ev.statusOrDefault == "archived"
        let notify = store.notifyIds.contains(ev.id)

        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text(ev.name).font(.system(size: 18, weight: .bold)).foregroundColor(C.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                statusBadge(ev, archived: archived)
            }
            Spacer().frame(height: 8)
            HStack(alignment: .center) {
                Text(whereText(ev)).font(.system(size: 13)).foregroundColor(C.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button {
                    store.toggleNotify(ev.id, !notify)
                } label: {
                    icon("bell.fill", notify ? C.ink : C.faint, 18)
                        .frame(width: 38, height: 38)
                        .background(notify ? C.coral : C.tint)
                        .clipShape(RoundedRectangle(cornerRadius: 11))
                }
                .buttonStyle(.plain)
            }
            Text(notify ? "Powiadomienia wlaczone" : "Powiadomienia wylaczone")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(notify ? C.coralDark : C.faint)
                .padding(.top, 6)
        }
        .padding(18)
        .background(C.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .opacity(archived ? 0.6 : 1)
        .contentShape(Rectangle())
        .onTapGesture { store.openEvent(ev.id) }
    }

    private func whereText(_ ev: EventDTO) -> String {
        var parts: [String] = []
        if let s = ev.startsAt, !s.isEmpty { parts.append(dayShort(subStr(s, 0, 10))) }
        if let city = ev.city, !city.isEmpty { parts.append(city) }
        let joined = parts.joined(separator: " \u{00B7} ")
        return joined.isEmpty ? "termin do ustalenia" : joined
    }

    @ViewBuilder
    private func statusBadge(_ ev: EventDTO, archived: Bool) -> some View {
        let (bg, fg, lbl): (Color, Color, String) = {
            if archived { return (C.grey, C.faint, "ARCHIWALNY") }
            if isUpcoming(ev.startsAt) { return (C.coralTint, C.coralDark, "NADCHODZACE") }
            return (C.tint, C.petrol, "AKTYWNY")
        }()
        Text(lbl).font(.system(size: 11, weight: .semibold)).foregroundColor(fg)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(bg).clipShape(Capsule())
    }
}
