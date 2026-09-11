import SwiftUI

struct PartnersView: View {
    let eventId: Int64
    @Binding var path: [Route]
    @EnvironmentObject var store: AppStore

    var body: some View {
        let partners = store.event(eventId)?.bundle.sortedPartners ?? []
        VStack(spacing: 0) {
            HStack {
                Text("Partnerzy").font(.system(size: 22, weight: .heavy)).foregroundColor(C.ink)
                Spacer()
            }
            .padding(.horizontal, 20).padding(.top, 14).padding(.bottom, 16)
            .frame(maxWidth: .infinity).background(C.surface)

            if partners.isEmpty {
                EmptyHint(text: "Partnerzy pojawia sie wkrotce.")
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(partners) { p in
                            row(p)
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
    private func row(_ p: Partner) -> some View {
        let hasBooth = !(p.boothLocation ?? "").isEmpty
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 13).fill(C.tint).frame(width: 52, height: 52)
                Text(String(p.name.prefix(2))).font(.system(size: 18, weight: .heavy)).foregroundColor(C.petrol)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(p.name).font(.system(size: 16, weight: .bold)).foregroundColor(C.ink)
                if let d = p.description, !d.isEmpty {
                    Text(d).font(.system(size: 12)).foregroundColor(C.muted)
                }
                if hasBooth {
                    HStack(spacing: 5) {
                        icon("mappin.and.ellipse", C.petrol, 12)
                        Text(p.boothLocation!).font(.system(size: 12, weight: .semibold)).foregroundColor(C.petrol)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if hasBooth {
                Button { path.append(.map(p.id)) } label: {
                    icon("mappin.and.ellipse", C.coral, 18)
                        .frame(width: 38, height: 38).background(C.coralTint).clipShape(RoundedRectangle(cornerRadius: 11))
                }.buttonStyle(.plain)
            }
            icon("chevron.right", C.line, 16)
        }
        .padding(14)
        .background(C.surface)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(C.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(Rectangle())
        .onTapGesture { path.append(.partner(p.id)) }
    }
}

struct PartnerDetailView: View {
    let eventId: Int64
    let partnerId: Int64
    @EnvironmentObject var store: AppStore
    @Environment(\.openURL) private var openURL

    var body: some View {
        let p = store.event(eventId)?.bundle.partners.first { $0.id == partnerId }
        VStack(spacing: 0) {
            BackHeader("Partner")
            if let p = p {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 18).fill(C.tint).frame(width: 72, height: 72)
                                Text(String(p.name.prefix(2))).font(.system(size: 26, weight: .heavy)).foregroundColor(C.petrol)
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                Text(p.name).font(.system(size: 20, weight: .bold)).foregroundColor(C.ink)
                                if let t = p.tier, !t.isEmpty { Pill(text: t.uppercased(), bg: C.tint, fg: C.petrol) }
                            }
                            Spacer()
                        }
                        if let d = p.description, !d.isEmpty {
                            Spacer().frame(height: 18)
                            Text(d).font(.system(size: 15)).foregroundColor(C.muted).lineSpacing(5)
                        }
                        if let booth = p.boothLocation, !booth.isEmpty {
                            Spacer().frame(height: 18)
                            HStack(spacing: 13) {
                                icon("mappin.and.ellipse", C.petrol, 20)
                                    .frame(width: 40, height: 40).background(C.tint).clipShape(RoundedRectangle(cornerRadius: 11))
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Stoisko").font(.system(size: 12)).foregroundColor(C.faint)
                                    Text(booth).font(.system(size: 15, weight: .semibold)).foregroundColor(C.ink)
                                }
                                Spacer()
                                NavigationLink(value: Route.map(partnerId)) {
                                    Text("Zobacz na mapie").font(.system(size: 13, weight: .semibold)).foregroundColor(C.petrol)
                                }
                            }
                            .padding(14)
                            .background(C.surface)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(C.line, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        if let site = p.website, !site.isEmpty {
                            Spacer().frame(height: 12)
                            Button {
                                let u = site.hasPrefix("http") ? site : "https://" + site
                                if let url = URL(string: u) { openURL(url) }
                            } label: {
                                HStack(spacing: 13) {
                                    icon("globe", C.petrol, 20)
                                        .frame(width: 40, height: 40).background(C.tint).clipShape(RoundedRectangle(cornerRadius: 11))
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text("Strona").font(.system(size: 12)).foregroundColor(C.faint)
                                        Text(site).font(.system(size: 15, weight: .semibold)).foregroundColor(C.ink)
                                    }
                                    Spacer()
                                    icon("chevron.right", C.line, 16)
                                }
                                .padding(14)
                                .background(C.surface)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(C.line, lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20).frame(maxWidth: .infinity, alignment: .leading)
                }
            } else { Spacer() }
        }
        .background(C.bg.ignoresSafeArea())
        .navigationBarHidden(true)
    }
}
