import SwiftUI
import UIKit

// Cele nawigacji wpychane w stosy zakladek.
enum Route: Hashable {
    case talk(Int64)
    case speaker(Int64)
    case speakers
    case partner(Int64)
    case partners
    case map(Int64?)
    case contact
    case news
}

@ViewBuilder
func routeView(_ route: Route, eventId: Int64) -> some View {
    switch route {
    case .talk(let id):     TalkView(eventId: eventId, talkId: id)
    case .speaker(let id):  SpeakerDetailView(eventId: eventId, speakerId: id)
    case .speakers:         SpeakersView(eventId: eventId)
    case .partner(let id):  PartnerDetailView(eventId: eventId, partnerId: id)
    case .partners:         PartnersView(eventId: eventId, path: .constant([]))
    case .map(let h):       MapView(eventId: eventId, highlight: h, pushed: true)
    case .contact:          ContactView(eventId: eventId)
    case .news:             NewsView(eventId: eventId)
    }
}

// Kontener eventu = dolne zakladki (Wydarzenie/Agenda/Partnerzy/Mapa/Wiecej),
// kazda z wlasnym stosem nawigacji (drill-in). Odpowiednik BottomBar + eventTabs.
struct EventContainerView: View {
    let eventId: Int64
    @EnvironmentObject var store: AppStore
    @State private var tab = 0
    @State private var homePath: [Route] = []
    @State private var agendaPath: [Route] = []
    @State private var partnersPath: [Route] = []

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack(path: $homePath) {
                EventHomeView(eventId: eventId, tab: $tab, path: $homePath)
                    .navigationDestination(for: Route.self) { routeView($0, eventId: eventId) }
            }
            .tabItem { Label("Wydarzenie", systemImage: "house.fill") }.tag(0)

            NavigationStack(path: $agendaPath) {
                AgendaView(eventId: eventId, path: $agendaPath)
                    .navigationDestination(for: Route.self) { routeView($0, eventId: eventId) }
            }
            .tabItem { Label("Agenda", systemImage: "calendar") }.tag(1)

            NavigationStack(path: $partnersPath) {
                PartnersView(eventId: eventId, path: $partnersPath)
                    .navigationDestination(for: Route.self) { routeView($0, eventId: eventId) }
            }
            .tabItem { Label("Partnerzy", systemImage: "bag.fill") }.tag(2)

            NavigationStack {
                MapView(eventId: eventId, highlight: nil)
                    .navigationDestination(for: Route.self) { routeView($0, eventId: eventId) }
            }
            .tabItem { Label("Mapa", systemImage: "mappin.and.ellipse") }.tag(3)

            NavigationStack {
                MoreView(eventId: eventId)
                    .navigationDestination(for: Route.self) { routeView($0, eventId: eventId) }
            }
            .tabItem { Label("Wiecej", systemImage: "ellipsis") }.tag(4)
        }
        .tint(C.petrol)
    }
}

struct EventHomeView: View {
    let eventId: Int64
    @Binding var tab: Int
    @Binding var path: [Route]
    @EnvironmentObject var store: AppStore

    var body: some View {
        if let stored = store.event(eventId) {
            let ev = stored.bundle.event
            let unread = store.unreadCount(eventId)
            let archived = ev.statusOrDefault == "archived"

            VStack(spacing: 0) {
                header(ev, archived: archived)
                VStack(spacing: 0) {
                    if !stored.bundle.news.isEmpty {
                        newsBanner(stored: stored, unread: unread)
                        Spacer().frame(height: 16)
                    }
                    grid()
                }
                .padding(20)
                .frame(maxHeight: .infinity)
            }
            .background(C.bg.ignoresSafeArea())
            .navigationBarHidden(true)
        } else {
            C.bg
        }
    }

    @ViewBuilder
    private func header(_ ev: EventDTO, archived: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 8) {
                    Circle().fill(archived ? C.faint : C.coral).frame(width: 6, height: 6)
                    Text(archived ? "Zapisane" : "Wydarzenie").foregroundColor(C.petrolText).font(.system(size: 12))
                }
                Spacer()
                Button { store.top = .events } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left").font(.system(size: 12, weight: .semibold))
                        Text("Moje wydarzenia").font(.system(size: 12))
                    }.foregroundColor(C.petrolText)
                }
                .buttonStyle(.plain)
            }
            Spacer().frame(height: 8)
            Text(ev.name).foregroundColor(.white).font(.system(size: 24, weight: .heavy))
            Spacer().frame(height: 6)
            Text(metaText(ev)).foregroundColor(C.petrolText).font(.system(size: 13))
        }
        .padding(.horizontal, 22).padding(.top, 16).padding(.bottom, 22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(C.petrol)
        .clipShape(RoundedCorners(radius: 22, corners: [.bottomLeft, .bottomRight]))
    }

    private func metaText(_ ev: EventDTO) -> String {
        var parts: [String] = []
        if let s = ev.startsAt, !s.isEmpty {
            let start = dayShort(subStr(s, 0, 10))
            if let e = ev.endsAt, !e.isEmpty {
                let end = dayShort(subStr(e, 0, 10))
                parts.append(end != start ? "\(start)-\(end)" : start)
            } else { parts.append(start) }
        }
        if let city = ev.city, !city.isEmpty { parts.append(city) }
        parts.append("Kod \(ev.accessCode)")
        return parts.joined(separator: " \u{00B7} ")
    }

    @ViewBuilder
    private func newsBanner(stored: StoredEvent, unread: Int) -> some View {
        let latest = stored.bundle.sortedNews.first
        Button { path.append(.news) } label: {
            HStack(spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    icon("bell.fill", unread > 0 ? C.ink : .white, 20)
                        .frame(width: 36, height: 36)
                        .background(unread > 0 ? C.coral : C.petrol)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    if unread > 0 {
                        Text(unread > 9 ? "9+" : "\(unread)")
                            .font(.system(size: 10, weight: .bold)).foregroundColor(.white)
                            .frame(width: 18, height: 18).background(C.coralDark).clipShape(Circle())
                            .offset(x: 6, y: -6)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    if unread > 0 {
                        Text(latest?.title ?? "Aktualnosci").font(.system(size: 14, weight: .semibold)).foregroundColor(C.ink)
                            .lineLimit(1)
                        Text("Aktualnosci \u{00B7} \(unread) nieprzeczytane").font(.system(size: 12)).foregroundColor(C.coralDark)
                    } else {
                        Text("Aktualnosci").font(.system(size: 14, weight: .semibold)).foregroundColor(C.ink)
                        Text("brak powiadomien").font(.system(size: 12)).foregroundColor(C.muted)
                    }
                }
                Spacer()
                icon("chevron.right", unread > 0 ? C.coralDark : C.muted, 16)
            }
            .padding(14)
            .background(unread > 0 ? C.coralTint : C.tint)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func grid() -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                tile("calendar", "Agenda", "Program i sale") { tab = 1 }
                tile("person.2.fill", "Prelegenci", "Kto wystepuje") { path.append(.speakers) }
            }
            HStack(spacing: 12) {
                tile("bag.fill", "Partnerzy", "Stoiska") { tab = 2 }
                tile("mappin.and.ellipse", "Mapa", "Plan przestrzeni") { tab = 3 }
            }
        }
        .frame(maxHeight: .infinity)
    }

    private func tile(_ sym: String, _ title: String, _ sub: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                icon(sym, C.petrol, 24)
                    .frame(width: 44, height: 44).background(C.tint).clipShape(RoundedRectangle(cornerRadius: 12))
                Spacer().frame(height: 10)
                Text(title).font(.system(size: 16, weight: .semibold)).foregroundColor(C.ink)
                Text(sub).font(.system(size: 12)).foregroundColor(C.muted)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(16)
            .background(C.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// Zaokraglenie wybranych rogow (dolny header eventu).
struct RoundedCorners: Shape {
    var radius: CGFloat = 0
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let p = UIBezierPath(roundedRect: rect, byRoundingCorners: corners,
                             cornerRadii: CGSize(width: radius, height: radius))
        return Path(p.cgPath)
    }
}
