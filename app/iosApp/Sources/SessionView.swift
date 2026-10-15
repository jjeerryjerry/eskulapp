import SwiftUI

/// Szczegoly sesji: moderatorzy, podwyklady (z wlasnymi dzwonkami), przypomnienie o sesji.
struct SessionView: View {
    let eventId: Int64
    let sessionId: Int64
    @EnvironmentObject var store: AppStore

    var body: some View {
        let bundle = store.event(eventId)?.bundle
        let session = bundle?.session(sessionId)
        let room = bundle?.room(session?.roomId)
        let moderators = bundle?.moderators(forSession: sessionId) ?? []
        let talks = bundle?.talks(forSession: sessionId) ?? []
        let on = store.sessionReminderIds.contains(sessionId)

        VStack(spacing: 0) {
            BackHeader("Sesja")
            if let x = session {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 8) {
                            let time = [hhmm(x.startsAt), hhmm(x.endsAt)].filter { !$0.isEmpty }.joined(separator: " - ")
                            if !time.isEmpty { Pill(text: time, bg: C.tint, fg: C.petrol) }
                            if let room = room { Pill(text: room, bg: C.grey, fg: C.muted) }
                        }
                        Spacer().frame(height: 16)
                        Text(x.title).font(.system(size: 22, weight: .bold)).foregroundColor(C.ink)
                        if let d = x.description, !d.isEmpty {
                            Spacer().frame(height: 12)
                            Text(d).font(.system(size: 15)).foregroundColor(C.muted).lineSpacing(5)
                        }
                        if !moderators.isEmpty {
                            Spacer().frame(height: 20)
                            Text(moderators.count == 1 ? "Moderator" : "Moderatorzy")
                                .font(.system(size: 15, weight: .semibold)).foregroundColor(C.ink)
                            Spacer().frame(height: 8)
                            ForEach(moderators) { s in
                                NavigationLink(value: Route.speaker(s.id)) {
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
                                        icon("chevron.right", C.line, 16)
                                    }
                                    .padding(.vertical, 6)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        if !talks.isEmpty {
                            Spacer().frame(height: 20)
                            Text("Wykłady w sesji").font(.system(size: 15, weight: .semibold)).foregroundColor(C.ink)
                            Spacer().frame(height: 8)
                            ForEach(talks) { t in
                                let tOn = store.reminderIds.contains(t.id)
                                let names = bundle?.speakerNames(forTalk: t.id) ?? ""
                                HStack(spacing: 8) {
                                    NavigationLink(value: Route.talk(t.id)) {
                                        HStack(spacing: 0) {
                                            Text(hhmm(t.startsAt)).font(.system(size: 13, weight: .semibold)).foregroundColor(C.petrol)
                                                .frame(width: 48, alignment: .leading)
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(t.title).font(.system(size: 14, weight: .semibold)).foregroundColor(C.ink)
                                                if !names.isEmpty { Text(names).font(.system(size: 12)).foregroundColor(C.muted) }
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    BellButton(on: tOn, size: 34) {
                                        store.toggleReminder(talkId: t.id, title: t.title, subtitle: room, startsAt: t.startsAt, on: !tOn)
                                    }
                                }
                                .padding(12)
                                .background(C.surface)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(C.line, lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.vertical, 5)
                            }
                        }
                    }
                    .padding(20).frame(maxWidth: .infinity, alignment: .leading)
                }
                Button {
                    store.toggleSessionReminder(x, room: room, on: !on)
                } label: {
                    HStack(spacing: 8) {
                        icon("bell.fill", on ? C.ink : .white, 18)
                        Text(on ? "Przypomnienie o sesji ustawione" : "Przypomnij o sesji")
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
