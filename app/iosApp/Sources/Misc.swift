import SwiftUI

struct ContactView: View {
    let eventId: Int64
    @EnvironmentObject var store: AppStore
    @Environment(\.openURL) private var openURL

    var body: some View {
        let contacts = store.event(eventId)?.bundle.sortedContacts ?? []
        VStack(spacing: 0) {
            BackHeader("Kontakt")
            if contacts.isEmpty {
                EmptyHint(text: "Dane kontaktowe pojawia sie wkrotce.")
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(contacts) { c in
                            VStack(alignment: .leading, spacing: 0) {
                                if let name = c.name, !name.isEmpty {
                                    Text(name).font(.system(size: 15, weight: .bold)).foregroundColor(C.ink)
                                        .padding(.leading, 12).padding(.top, 12)
                                }
                                if let phone = c.phone, !phone.isEmpty {
                                    contactRow("phone.fill", "Telefon", phone) {
                                        let n = phone.replacingOccurrences(of: " ", with: "")
                                        if let u = URL(string: "tel:\(n)") { openURL(u) }
                                    }
                                }
                                if let email = c.email, !email.isEmpty {
                                    contactRow("envelope.fill", "E-mail", email) {
                                        if let u = URL(string: "mailto:\(email)") { openURL(u) }
                                    }
                                }
                                if let note = c.note, !note.isEmpty {
                                    contactRow("globe", c.label ?? "Informacja", note, action: nil)
                                }
                            }
                            .padding(4)
                            .background(C.surface)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(C.line, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(20)
                }
            }
        }
        .background(C.bg.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    @ViewBuilder
    private func contactRow(_ sym: String, _ label: String, _ value: String, action: (() -> Void)?) -> some View {
        let content = HStack(spacing: 13) {
            icon(sym, C.petrol, 20)
                .frame(width: 40, height: 40).background(C.tint).clipShape(RoundedRectangle(cornerRadius: 11))
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.system(size: 12)).foregroundColor(C.faint)
                Text(value).font(.system(size: 15, weight: .semibold)).foregroundColor(C.ink)
            }
            Spacer()
            if action != nil { icon("chevron.right", C.line, 16) }
        }
        .padding(12)
        .contentShape(Rectangle())

        if let action = action {
            Button(action: action) { content }.buttonStyle(.plain)
        } else {
            content
        }
    }
}

struct NewsView: View {
    let eventId: Int64
    @EnvironmentObject var store: AppStore

    var body: some View {
        let news = store.event(eventId)?.bundle.sortedNews ?? []
        VStack(spacing: 0) {
            BackHeader("Aktualnosci")
            if news.isEmpty {
                EmptyHint(text: "Brak aktualnosci. Wrocimy tu ze zmianami i ogloszeniami.")
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(news) { n in
                            HStack(alignment: .top, spacing: 12) {
                                icon("bell.fill", n.isPinned ? C.ink : C.petrol, 20)
                                    .frame(width: 38, height: 38)
                                    .background(n.isPinned ? C.coral : C.tint)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(n.title).font(.system(size: 15, weight: .semibold)).foregroundColor(C.ink)
                                    if let b = n.body, !b.isEmpty {
                                        Text(b).font(.system(size: 13)).foregroundColor(C.muted)
                                    }
                                    Text(hhmm(n.publishedAt)).font(.system(size: 11)).foregroundColor(C.faint).padding(.top, 3)
                                }
                                Spacer()
                            }
                            .padding(14)
                            .background(C.surface)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(n.isPinned ? C.coralLine : C.line, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(20)
                }
            }
        }
        .background(C.bg.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear { store.markAllNewsRead(eventId) }
    }
}

struct MoreView: View {
    let eventId: Int64
    @EnvironmentObject var store: AppStore
    @State private var confirmDelete = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Wiecej").font(.system(size: 22, weight: .heavy)).foregroundColor(C.ink)
                Spacer()
            }
            .padding(.horizontal, 20).padding(.top, 14).padding(.bottom, 16)
            .frame(maxWidth: .infinity).background(C.surface)

            VStack(spacing: 10) {
                NavigationLink(value: Route.contact) {
                    moreRow("phone.fill", "Kontakt", danger: false, chevron: true)
                }.buttonStyle(.plain)

                Button { store.top = .events } label: {
                    moreRow("calendar", "Lista wydarzen", danger: false, chevron: true)
                }.buttonStyle(.plain)

                Spacer().frame(height: 8)

                Button { confirmDelete = true } label: {
                    moreRow("trash", "Usun to wydarzenie", danger: true, chevron: false)
                }.buttonStyle(.plain)

                Spacer()
            }
            .padding(20)
        }
        .background(C.bg.ignoresSafeArea())
        .navigationBarHidden(true)
        .alert("Usunac wydarzenie?", isPresented: $confirmDelete) {
            Button("Usun", role: .destructive) {
                store.deleteEvent(eventId)
                store.top = .events
            }
            Button("Anuluj", role: .cancel) {}
        } message: {
            Text("Wydarzenie zniknie z listy. Mozesz dodac je ponownie kodem od organizatora.")
        }
    }

    private func moreRow(_ sym: String, _ label: String, danger: Bool, chevron: Bool) -> some View {
        HStack(spacing: 13) {
            icon(sym, danger ? C.coralDark : C.petrol, 20)
            Text(label).font(.system(size: 15, weight: .semibold)).foregroundColor(danger ? C.coralDark : C.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
            if chevron { icon("chevron.right", C.line, 16) }
        }
        .padding(16)
        .background(C.surface)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(C.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
