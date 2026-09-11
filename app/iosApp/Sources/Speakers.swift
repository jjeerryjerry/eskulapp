import SwiftUI

struct SpeakersView: View {
    let eventId: Int64
    @EnvironmentObject var store: AppStore

    var body: some View {
        let speakers = store.event(eventId)?.bundle.sortedSpeakers ?? []
        VStack(spacing: 0) {
            BackHeader(title: "Prelegenci", trailing: {
                Text("\(speakers.count) osob").font(.system(size: 13)).foregroundColor(C.muted)
            })
            if speakers.isEmpty {
                EmptyHint(text: "Lista prelegentow pojawi sie wkrotce.")
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(speakers) { s in
                            NavigationLink(value: Route.speaker(s.id)) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle().fill(C.tint).frame(width: 46, height: 46)
                                        Text(initials(s.first, s.last)).font(.system(size: 16, weight: .bold)).foregroundColor(C.petrol)
                                    }
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(s.fullName).font(.system(size: 15, weight: .semibold)).foregroundColor(C.ink)
                                        if let t = s.title, !t.isEmpty { Text(t).font(.system(size: 12)).foregroundColor(C.muted) }
                                    }
                                    Spacer()
                                    icon("chevron.right", C.line, 16)
                                }
                                .padding(12)
                                .background(C.surface)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(C.line, lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .background(C.bg.ignoresSafeArea())
        .navigationBarHidden(true)
    }
}

struct SpeakerDetailView: View {
    let eventId: Int64
    let speakerId: Int64
    @EnvironmentObject var store: AppStore

    var body: some View {
        let bundle = store.event(eventId)?.bundle
        let s = bundle?.speakers.first { $0.id == speakerId }
        let talks = bundle?.talks(forSpeaker: speakerId) ?? []

        VStack(spacing: 0) {
            BackHeader("Prelegent")
            if let s = s {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle().fill(C.tint).frame(width: 72, height: 72)
                                Text(initials(s.first, s.last)).font(.system(size: 26, weight: .bold)).foregroundColor(C.petrol)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(s.fullName).font(.system(size: 20, weight: .bold)).foregroundColor(C.ink)
                                if let t = s.title, !t.isEmpty { Text(t).font(.system(size: 13)).foregroundColor(C.muted) }
                            }
                            Spacer()
                        }
                        if let bio = s.bio, !bio.isEmpty {
                            Spacer().frame(height: 18)
                            Text(bio).font(.system(size: 15)).foregroundColor(C.muted).lineSpacing(5)
                        }
                        if !talks.isEmpty {
                            Spacer().frame(height: 20)
                            Text("Wystapienia").font(.system(size: 15, weight: .semibold)).foregroundColor(C.ink)
                            Spacer().frame(height: 8)
                            ForEach(talks) { t in
                                let room = bundle?.room(t.roomId)
                                let day = dayShort(t.startsAt)
                                let time = hhmm(t.startsAt)
                                let sub = [day.isEmpty ? nil : day, time.isEmpty ? nil : time, room]
                                    .compactMap { $0 }.joined(separator: " \u{00B7} ")
                                NavigationLink(value: Route.talk(t.id)) {
                                    HStack(spacing: 8) {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(t.title).font(.system(size: 14, weight: .semibold)).foregroundColor(C.ink)
                                            if !sub.isEmpty { Text(sub).font(.system(size: 12)).foregroundColor(C.muted) }
                                        }
                                        Spacer()
                                        icon("chevron.right", C.line, 16)
                                    }
                                    .padding(12)
                                    .background(C.surface)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(C.line, lineWidth: 1))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                                .padding(.vertical, 5)
                            }
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
