import SwiftUI

struct AgendaView: View {
    let eventId: Int64
    @Binding var path: [Route]
    @EnvironmentObject var store: AppStore

    @State private var dayId: Int64?
    @State private var roomId: Int64?
    @State private var onlyFollowed = false

    var body: some View {
        let bundle = store.event(eventId)?.bundle
        let days = bundle?.sortedDays ?? []
        let rooms = bundle?.sortedRooms ?? []
        let talks = bundle?.sortedTalks ?? []

        VStack(spacing: 0) {
            // Naglowek zakladki (bez wstecz) + filtr obserwowanych.
            HStack {
                Text("Agenda").font(.system(size: 22, weight: .heavy)).foregroundColor(C.ink)
                Spacer()
                Button { onlyFollowed.toggle() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: onlyFollowed ? "checkmark.square.fill" : "square")
                            .foregroundColor(onlyFollowed ? C.petrol : C.faint)
                        Text("Obserwowane").font(.system(size: 13, weight: .semibold))
                            .foregroundColor(onlyFollowed ? C.petrol : C.muted)
                    }
                }.buttonStyle(.plain)
            }
            .padding(.horizontal, 20).padding(.top, 14).padding(.bottom, 16)
            .frame(maxWidth: .infinity).background(C.surface)

            if !days.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 24) {
                        ForEach(days) { d in
                            let sel = d.id == dayId
                            VStack(spacing: 0) {
                                Text((d.label ?? "Dzien") + "  " + dayShort(d.date))
                                    .font(.system(size: 15, weight: sel ? .semibold : .medium))
                                    .foregroundColor(sel ? C.petrol : C.faint)
                                    .padding(.bottom, 12)
                                Rectangle().fill(C.petrol).frame(width: sel ? 70 : 0, height: 2.5)
                            }
                            .onTapGesture { dayId = d.id }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .background(C.surface)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Chip(label: "Wszystkie sale", active: roomId == nil) { roomId = nil }
                    ForEach(rooms) { r in
                        Chip(label: r.name, active: roomId == r.id) { roomId = r.id }
                    }
                }
                .padding(.horizontal, 20).padding(.vertical, 14)
            }

            let shown = talks.filter { t in
                (dayId == nil || t.dayId == dayId) &&
                (roomId == nil || t.roomId == roomId) &&
                (!onlyFollowed || store.reminderIds.contains(t.id))
            }

            if shown.isEmpty {
                Text(onlyFollowed ? "Nie obserwujesz jeszcze zadnej prelekcji." : "Brak prelekcji w tym widoku.")
                    .foregroundColor(C.muted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(shown) { t in
                            let roomName = bundle?.room(t.roomId)
                            let names = bundle?.speakerNames(forTalk: t.id) ?? ""
                            let sub = [roomName, names.isEmpty ? nil : names].compactMap { $0 }.joined(separator: " \u{00B7} ")
                            TalkRow(
                                time: hhmm(t.startsAt), title: t.title, subtitle: sub,
                                reminder: store.reminderIds.contains(t.id),
                                onBell: { store.toggleReminder(talkId: t.id, title: t.title, subtitle: roomName, startsAt: t.startsAt, on: !store.reminderIds.contains(t.id)) },
                                onTap: { path.append(.talk(t.id)) }
                            )
                        }
                    }
                    .padding(.horizontal, 20).padding(.vertical, 4)
                }
            }
        }
        .background(C.bg.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear { if dayId == nil { dayId = days.first?.id } }
    }
}

private struct TalkRow: View {
    let time: String
    let title: String
    let subtitle: String
    let reminder: Bool
    let onBell: () -> Void
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Text(time).font(.system(size: 14, weight: .semibold)).foregroundColor(C.petrol).frame(width: 52, alignment: .leading)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(C.ink)
                if !subtitle.isEmpty {
                    Text(subtitle).font(.system(size: 12)).foregroundColor(C.muted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onBell) {
                icon("bell.fill", reminder ? C.coral : C.faint, 20)
                    .frame(width: 40, height: 40)
                    .background(reminder ? C.coralTint : C.grey)
                    .clipShape(RoundedRectangle(cornerRadius: 11))
            }.buttonStyle(.plain)
        }
        .padding(14)
        .background(C.surface)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(C.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

struct TalkView: View {
    let eventId: Int64
    let talkId: Int64
    @EnvironmentObject var store: AppStore

    var body: some View {
        let bundle = store.event(eventId)?.bundle
        let talk = bundle?.talks.first { $0.id == talkId }
        let speakers = bundle?.speakers(forTalk: talkId) ?? []
        let room = bundle?.room(talk?.roomId)
        let on = store.reminderIds.contains(talkId)

        VStack(spacing: 0) {
            BackHeader("Prelekcja")
            if let t = talk {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 8) {
                            let time = [hhmm(t.startsAt), hhmm(t.endsAt)].filter { !$0.isEmpty }.joined(separator: " - ")
                            if !time.isEmpty { Pill(text: time, bg: C.tint, fg: C.petrol) }
                            if let room = room { Pill(text: room, bg: C.grey, fg: C.muted) }
                        }
                        Spacer().frame(height: 16)
                        Text(t.title).font(.system(size: 22, weight: .bold)).foregroundColor(C.ink)
                        if let ab = t.abstract, !ab.isEmpty {
                            Spacer().frame(height: 12)
                            Text(ab).font(.system(size: 15)).foregroundColor(C.muted).lineSpacing(5)
                        }
                        if !speakers.isEmpty {
                            Spacer().frame(height: 20)
                            Text("Prelegenci").font(.system(size: 15, weight: .semibold)).foregroundColor(C.ink)
                            Spacer().frame(height: 8)
                            ForEach(speakers) { s in
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle().fill(C.tint).frame(width: 40, height: 40)
                                        Text(initials(s.first, s.last)).font(.system(size: 14, weight: .bold)).foregroundColor(C.petrol)
                                    }
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(s.fullName).font(.system(size: 15, weight: .semibold)).foregroundColor(C.ink)
                                        if let tt = s.title, !tt.isEmpty { Text(tt).font(.system(size: 12)).foregroundColor(C.muted) }
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 6)
                            }
                        }
                    }
                    .padding(20).frame(maxWidth: .infinity, alignment: .leading)
                }
                Button {
                    store.toggleReminder(talkId: t.id, title: t.title, subtitle: room, startsAt: t.startsAt, on: !on)
                } label: {
                    HStack(spacing: 8) {
                        icon("bell.fill", on ? C.ink : .white, 18)
                        Text(on ? "Przypomnienie ustawione" : "Przypomnij mi")
                            .font(.system(size: 16, weight: .semibold)).foregroundColor(on ? C.ink : .white)
                    }
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(on ? C.coral : C.petrol).clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(20)
            } else {
                Spacer()
            }
        }
        .background(C.bg.ignoresSafeArea())
        .navigationBarHidden(true)
    }
}
