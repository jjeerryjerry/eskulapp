import SwiftUI

// Stala pozycja pinu (frakcje 0..1): 2 kolumny, wiersze rowno miedzy scena a wejsciem.
private func boothPos(_ i: Int, _ n: Int) -> (CGFloat, CGFloat) {
    let cols = 2
    let rows = max(1, (n + cols - 1) / cols)
    let col = i % cols
    let row = i / cols
    let fx: CGFloat = col == 0 ? 0.30 : 0.70
    let fy: CGFloat = rows <= 1 ? 0.5 : 0.22 + CGFloat(row) * (0.56 / CGFloat(rows - 1))
    return (fx, fy)
}

struct MapView: View {
    let eventId: Int64
    var highlight: Int64?
    var pushed: Bool = false
    @EnvironmentObject var store: AppStore

    @State private var selectedId: Int64?
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    init(eventId: Int64, highlight: Int64?, pushed: Bool = false) {
        self.eventId = eventId
        self.highlight = highlight
        self.pushed = pushed
        _selectedId = State(initialValue: highlight)
    }

    var body: some View {
        let bundle = store.event(eventId)?.bundle
        let event = bundle?.event
        let booths = (bundle?.sortedPartners ?? []).filter { !($0.boothLocation ?? "").isEmpty }

        VStack(spacing: 0) {
            if pushed {
                BackHeader("Mapa")
            } else {
                HStack {
                    Text("Mapa").font(.system(size: 22, weight: .heavy)).foregroundColor(C.ink)
                    Spacer()
                }
                .padding(.horizontal, 20).padding(.top, 14).padding(.bottom, 16)
                .frame(maxWidth: .infinity).background(C.surface)
            }

            ScrollView {
                VStack(spacing: 0) {
                    // Naglowek: obiekt + miasto
                    HStack(spacing: 12) {
                        icon("mappin.and.ellipse", .white, 22)
                            .frame(width: 40, height: 40).background(C.petrol).clipShape(RoundedRectangle(cornerRadius: 11))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(event?.venueName ?? "Plan przestrzeni").font(.system(size: 15, weight: .bold)).foregroundColor(C.ink)
                            if let city = event?.city, !city.isEmpty { Text(city).font(.system(size: 12)).foregroundColor(C.muted) }
                        }
                        Spacer()
                    }
                    .padding(14).background(C.tint).clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 20).padding(.vertical, 12)

                    // Plan
                    plan(booths: booths)
                        .frame(height: 460)
                        .background(C.tint)
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(C.line, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .padding(.horizontal, 20)

                    Text("Uszczypnij zeby przyblizyc. Przeciagnij aby przesunac.")
                        .font(.system(size: 10)).foregroundColor(C.faint).lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20).padding(.vertical, 8)

                    if !booths.isEmpty {
                        HStack {
                            Text("Stoiska").font(.system(size: 17, weight: .bold)).foregroundColor(C.ink)
                            Spacer()
                        }.padding(.horizontal, 20)
                        Spacer().frame(height: 8)
                        VStack(spacing: 8) {
                            ForEach(booths) { p in
                                let on = p.id == selectedId
                                HStack(spacing: 10) {
                                    icon("mappin.and.ellipse", C.coral, 20)
                                    Text(p.name).font(.system(size: 14, weight: .semibold)).foregroundColor(C.ink)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Pill(text: p.boothLocation!, bg: on ? C.surface : C.tint, fg: on ? C.coralDark : C.petrol)
                                }
                                .padding(12)
                                .background(on ? C.coralTint : C.surface)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(on ? C.coralLine : C.line, lineWidth: on ? 2 : 1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .contentShape(Rectangle())
                                .onTapGesture { selectedId = p.id }
                            }
                        }
                        .padding(.horizontal, 20)
                        Spacer().frame(height: 16)
                    }
                }
            }
        }
        .background(C.bg.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    @ViewBuilder
    private func plan(booths: [Partner]) -> some View {
        GeometryReader { geo in
            ZStack {
                // scena + wejscie + piny (skalowane/przesuwane razem)
                ZStack {
                    Text("SCENA GLOWNA")
                        .font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                        .frame(width: geo.size.width * 0.6, height: 30)
                        .background(C.petrol).clipShape(RoundedRectangle(cornerRadius: 9))
                        .position(x: geo.size.width / 2, y: 27)

                    Text("WEJSCIE GLOWNE")
                        .font(.system(size: 10, weight: .semibold)).foregroundColor(C.muted)
                        .frame(width: geo.size.width * 0.5, height: 26)
                        .background(C.grey).clipShape(RoundedRectangle(cornerRadius: 9))
                        .position(x: geo.size.width / 2, y: geo.size.height - 25)

                    if booths.isEmpty {
                        Text("Rozmieszczenie stoisk pojawi sie wkrotce.")
                            .font(.system(size: 13)).foregroundColor(C.muted)
                            .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    } else {
                        ForEach(Array(booths.enumerated()), id: \.element.id) { idx, p in
                            let (fx, fy) = boothPos(idx, booths.count)
                            let on = p.id == selectedId
                            VStack(spacing: 2) {
                                ZStack {
                                    Circle().fill(on ? C.coralDark : C.coral)
                                        .frame(width: on ? 30 : 24, height: on ? 30 : 24)
                                        .overlay(Circle().stroke(.white, lineWidth: on ? 2 : 0))
                                    icon("mappin.and.ellipse", .white, on ? 15 : 12)
                                }
                                Text(p.name)
                                    .font(.system(size: on ? 10 : 9, weight: on ? .bold : .semibold))
                                    .foregroundColor(on ? C.ink : C.petrol)
                                    .lineLimit(1)
                                Text(p.boothLocation!.split(separator: " ").last.map(String.init) ?? "")
                                    .font(.system(size: 8, weight: .medium)).foregroundColor(C.faint).lineLimit(1)
                            }
                            .frame(width: 68)
                            .position(x: geo.size.width * fx, y: geo.size.height * fy)
                        }
                    }
                }
                .scaleEffect(scale)
                .offset(offset)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(
                MagnificationGesture()
                    .onChanged { v in scale = min(max(lastScale * v, 1), 4) }
                    .onEnded { _ in
                        lastScale = scale
                        if scale <= 1 { offset = .zero; lastOffset = .zero }
                    }
            )
            .simultaneousGesture(
                DragGesture()
                    .onChanged { g in
                        guard scale > 1 else { return }
                        offset = CGSize(width: lastOffset.width + g.translation.width,
                                        height: lastOffset.height + g.translation.height)
                    }
                    .onEnded { _ in lastOffset = offset }
            )
        }
    }
}
