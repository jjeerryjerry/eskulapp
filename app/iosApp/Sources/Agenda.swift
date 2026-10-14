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
                                Text((d.label ?? "Dzień") + "  " + dayShort(d.date))
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

            let shown = visibleItems(bundle, talks: talks)
            let conflictKeys = bundle.map { Conflicts.keys(store.followedSlots($0)) } ?? []

            if shown.isEmpty {
                Text(onlyFollowed ? "Nie obserwujesz jeszcze żadnej prelekcji." : "Brak prelekcji w tym widoku.")
                    .foregroundColor(C.muted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(shown) { item in
                            switch item {
                            case .single(let t):
                                let roomName = bundle?.room(t.roomId)
                                let names = bundle?.speakerNames(forTalk: t.id) ?? ""
                                let sub = [roomName, names.isEmpty ? nil : names].compactMap { $0 }.joined(separator: " \u{00B7} ")
                                TalkRow(
                                    time: hhmm(t.startsAt), title: t.title, subtitle: sub,
                                    reminder: store.reminderIds.contains(t.id),
                                    conflict: conflictKeys.contains("t\(t.id)"),
                                    onBell: { store.toggleReminder(talkId: t.id, title: t.title, subtitle: roomName, startsAt: t.startsAt, on: !store.reminderIds.contains(t.id)) },
                                    onTap: { path.append(.talk(t.id)) }
                                )
                            case .block(let x, let subTalks):
                                let roomName = bundle?.room(x.roomId)
                                let mods = bundle?.moderatorNames(forSession: x.id) ?? ""
                                let sub = [roomName, mods.isEmpty ? nil : "Moderacja: \(mods)"].compactMap { $0 }.joined(separator: " \u{00B7} ")
                                SessionCard(
                                    time: [hhmm(x.startsAt), hhmm(x.endsAt)].filter { !$0.isEmpty }.joined(separator: " - "),
                                    title: x.title, subtitle: sub,
                                    reminder: store.sessionReminderIds.contains(x.id),
                                    conflict: conflictKeys.contains("s\(x.id)"),
                                    onBell: { store.toggleSessionReminder(x, room: roomName, on: !store.sessionReminderIds.contains(x.id)) },
                                    onTap: { path.append(.session(x.id)) }
                                ) {
                                    ForEach(subTalks) { t in
                                        SubTalkRow(
                                            time: hhmm(t.startsAt), title: t.title,
                                            subtitle: bundle?.speakerNames(forTalk: t.id) ?? "",
                                            reminder: store.reminderIds.contains(t.id),
                                            conflict: conflictKeys.contains("t\(t.id)"),
                                            onBell: { store.toggleReminder(talkId: t.id, title: t.title, subtitle: bundle?.room(t.roomId), startsAt: t.startsAt, on: !store.reminderIds.contains(t.id)) },
                                            onTap: { path.append(.talk(t.id)) }
                                        )
                                    }
                                }
                            }
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

    /// Wyklady samodzielne + sesje z podwykladami, po filtrach dnia/sali/obserwowanych.
    /// Obserwowane: sesja widoczna gdy obserwujesz ja albo ktorys podwyklad; przy
    /// obserwowanej sesji widac wszystkie podwyklady, inaczej tylko obserwowane.
    private func visibleItems(_ bundle: EventBundle?, talks: [Talk]) -> [AgendaItem] {
        guard let bundle = bundle else { return [] }
        let sessionIds = Set(bundle.sessions.map { $0.id })
        func inView(_ day: Int64?, _ room: Int64?) -> Bool {
            (dayId == nil || day == dayId) && (roomId == nil || room == roomId)
        }
        let singles: [AgendaItem] = talks.filter { t in
            !(t.sessionId.map(sessionIds.contains) ?? false) && inView(t.dayId, t.roomId) &&
                (!onlyFollowed || store.reminderIds.contains(t.id))
        }.map { .single($0) }
        let blocks: [AgendaItem] = bundle.sortedSessions.compactMap { x in
            guard inView(x.dayId, x.roomId) else { return nil }
            let sub = bundle.talks(forSession: x.id)
            if !onlyFollowed || store.sessionReminderIds.contains(x.id) { return .block(x, sub) }
            let followed = sub.filter { store.reminderIds.contains($0.id) }
            return followed.isEmpty ? nil : .block(x, followed)
        }
        return (singles + blocks).sorted { ($0.startsAt ?? "", $0.sort) < ($1.startsAt ?? "", $1.sort) }
    }
}

/// Pozycja listy agendy: wyklad samodzielny albo sesja z podwykladami.
private enum AgendaItem: Identifiable {
    case single(Talk)
    case block(Session, [Talk])
    var id: String {
        switch self { case .single(let t): return "t\(t.id)"; case .block(let x, _): return "s\(x.id)" }
    }
    var startsAt: String? {
        switch self { case .single(let t): return t.startsAt; case .block(let x, _): return x.startsAt }
    }
    var sort: Int {
        switch self { case .single(let t): return t.sort ?? 0; case .block(let x, _): return x.sort ?? 0 }
    }
}

/// Osobny przycisk dzwonka: tylko toggle przypomnienia, nie otwiera szczegolow.
struct BellButton: View {
    let on: Bool
    var size: CGFloat = 40
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            icon("bell.fill", on ? C.coral : C.faint, size >= 40 ? 20 : 17)
                .frame(width: size, height: size)
                .background(on ? C.coralTint : C.grey)
                .clipShape(RoundedRectangle(cornerRadius: 11))
        }.buttonStyle(.plain)
    }
}

struct ConflictLabel: View {
    var body: some View {
        Text("Kolizja czasowa").font(.system(size: 12, weight: .semibold)).foregroundColor(C.coralDark)
    }
}

/// Karta sesji: naglowek (czas, tytul, sala, moderacja, dzwonek sesji) + podwyklady.
private struct SessionCard<Content: View>: View {
    let time: String
    let title: String
    let subtitle: String
    let reminder: Bool
    let conflict: Bool
    let onBell: () -> Void
    let onTap: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text("SESJA").font(.system(size: 11, weight: .bold)).kerning(1).foregroundColor(C.coralDark)
                        if !time.isEmpty { Text(time).font(.system(size: 13, weight: .semibold)).foregroundColor(C.petrol) }
                    }
                    Text(title).font(.system(size: 16, weight: .bold)).foregroundColor(C.ink)
                    if !subtitle.isEmpty { Text(subtitle).font(.system(size: 12)).foregroundColor(C.muted) }
                    if conflict { ConflictLabel() }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                BellButton(on: reminder, action: onBell)
            }
            .padding(14)
            .background(C.tint.opacity(0.45))
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
            VStack(spacing: 0) { content() }
                .padding(.leading, 14).padding(.trailing, 10).padding(.vertical, 6)
        }
        .background(C.surface)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(C.tint, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct SubTalkRow: View {
    let time: String
    let title: String
    let subtitle: String
    let reminder: Bool
    let conflict: Bool
    let onBell: () -> Void
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text(time).font(.system(size: 13, weight: .semibold)).foregroundColor(C.petrol).frame(width: 44, alignment: .leading)
            Rectangle().fill(C.tint).frame(width: 2, height: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(C.ink)
                if !subtitle.isEmpty { Text(subtitle).font(.system(size: 12)).foregroundColor(C.muted) }
                if conflict { ConflictLabel() }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            BellButton(on: reminder, size: 34, action: onBell)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

private struct TalkRow: View {
    let time: String
    let title: String
    let subtitle: String
    let reminder: Bool
    let conflict: Bool
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
                if conflict { ConflictLabel() }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            BellButton(on: reminder, action: onBell)
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
                        if let x = bundle?.session(t.sessionId) {
                            NavigationLink(value: Route.session(x.id)) {
                                HStack(spacing: 8) {
                                    Text("SESJA").font(.system(size: 11, weight: .bold)).kerning(1).foregroundColor(C.coralDark)
                                    Text(x.title).font(.system(size: 13, weight: .semibold)).foregroundColor(C.ink)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    icon("chevron.right", C.petrol, 14)
                                }
                                .padding(.horizontal, 12).padding(.vertical, 10)
                                .background(C.tint.opacity(0.45))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 12)
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
                        TalkRatingBlock(eventId: eventId, talk: t)
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

// MARK: oceny prelekcji (SPEC-OCENY §5)

/// Sekcja "Oceń wykład" pod opisem prelekcji. Stan okna przeliczany co 15 s.
private struct TalkRatingBlock: View {
    let eventId: Int64
    let talk: Talk
    @EnvironmentObject var store: AppStore

    var body: some View {
        TimelineView(.periodic(from: Date(), by: 15)) { ctx in
            if let panel = makePanel(now: ctx.date) {
                RatingSectionView(panel: panel, saved: store.ratings[talk.id]?.answers) { answers in
                    store.rate(eventId: eventId, talkId: talk.id, answers: answers)
                }
                .padding(.top, 24)
            }
        }
    }

    private func makePanel(now: Date) -> RatingPanel? {
        guard let ev = store.event(eventId)?.bundle.event else { return nil }
        let window = RatingTime.window(startsAt: talk.startsAt, endsAt: talk.endsAt,
                                       openAfterStartMin: ev.ratingsOpenMin,
                                       closeAfterEndMin: ev.ratingsCloseMin, now: now)
        let local = store.ratings[talk.id]
        return ratingPanel(ratingsEnabled: ev.ratingsOn, window: window, score: local?.score,
                           status: local?.status, error: local?.error, now: now)
    }
}

/// 3 pytania, kazde 10 kropli 1..10 (petrol aktywne, coral wybrane), bez srednich.
/// Glos zapisuje sie sam, gdy sa odpowiedzi na wszystkie pytania; kolejne zmiany nadpisuja.
struct RatingSectionView: View {
    let panel: RatingPanel
    let saved: [Int]?
    let onRate: ([Int]) -> Void
    @State private var draft: [Int?] = Array(repeating: nil, count: ratingQuestions.count)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Oceń wykład").font(.system(size: 15, weight: .semibold)).foregroundColor(C.ink)
            Spacer().frame(height: 4)
            Text(panel.message)
                .font(.system(size: 13))
                .foregroundColor(panel.warning ? C.coralDark : C.muted)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(Array(ratingQuestions.enumerated()), id: \.offset) { i, q in
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(i + 1). \(q.label)").font(.system(size: 14, weight: .semibold)).foregroundColor(C.ink)
                    Text(q.text).font(.system(size: 13)).foregroundColor(C.muted).fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 4) {
                        ForEach(1...10, id: \.self) { n in
                            ScoreDrop(n: n, selected: draft[i] == n, enabled: panel.enabled, label: "\(q.label): \(n)") {
                                draft[i] = n
                                let complete = draft.compactMap { $0 }
                                if complete.count == ratingQuestions.count { onRate(complete) }
                            }
                        }
                    }
                    .padding(.top, 6)
                }
                .padding(.top, 16)
            }
            if panel.enabled && draft.contains(where: { $0 == nil }) {
                Text("Ocena zapisze się po odpowiedzi na wszystkie 3 pytania.")
                    .font(.system(size: 12)).foregroundColor(C.faint).padding(.top, 12)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(C.surface)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(C.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear { if let saved, saved.count == draft.count { draft = saved.map { $0 } } }
        .onChange(of: saved) { new in if let new, new.count == draft.count { draft = new.map { $0 } } }
    }
}

private struct ScoreDrop: View {
    let n: Int
    let selected: Bool
    let enabled: Bool
    let label: String
    let action: () -> Void

    var body: some View {
        // Kontrast wg marki: na coralu tekst ink; aktywne petrol na jasnym petrolu; nieaktywne wygaszone.
        let bg: Color = selected ? (enabled ? C.coral : C.coralTint) : (enabled ? C.tint : C.grey)
        let fg: Color = selected ? C.ink : (enabled ? C.petrol : C.faint)
        Button(action: action) {
            Text("\(n)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(fg)
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .background(Circle().fill(bg))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(label)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
