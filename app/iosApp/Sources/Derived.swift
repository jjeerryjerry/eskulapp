import Foundation

// Sortowania i powiazania 1:1 z zapytaniami Room (Daos.kt).
extension EventBundle {
    var sortedDays: [Day] {
        days.sorted { ($0.sort ?? 0, $0.date ?? "") < ($1.sort ?? 0, $1.date ?? "") }
    }
    var sortedRooms: [RoomDTO] {
        rooms.sorted { ($0.sort ?? 0, $0.name) < ($1.sort ?? 0, $1.name) }
    }
    var sortedTalks: [Talk] {
        talks.sorted { ($0.startsAt ?? "", $0.sort ?? 0) < ($1.startsAt ?? "", $1.sort ?? 0) }
    }
    var sortedSpeakers: [Speaker] {
        speakers.sorted { ($0.sort ?? 0, $0.last) < ($1.sort ?? 0, $1.last) }
    }
    var sortedPartners: [Partner] {
        partners.sorted { ($0.sort ?? 0, $0.name) < ($1.sort ?? 0, $1.name) }
    }
    var sortedContacts: [Contact] {
        contacts.sorted { ($0.sort ?? 0) < ($1.sort ?? 0) }
    }
    var sortedNews: [News] {
        news.sorted { a, b in
            if a.isPinned != b.isPinned { return a.isPinned && !b.isPinned }
            return (a.publishedAt ?? "") > (b.publishedAt ?? "")
        }
    }

    func room(_ id: Int64?) -> String? {
        guard let id = id else { return nil }
        return rooms.first { $0.id == id }?.name
    }

    func speakers(forTalk talkId: Int64) -> [Speaker] {
        let ids = talkSpeakers.filter { $0.talkId == talkId }.map { $0.speakerId }
        return sortedSpeakers.filter { ids.contains($0.id) }
    }

    /// Nazwiska prelegentow do wiersza agendy (imie + nazwisko, po przecinku).
    func speakerNames(forTalk talkId: Int64) -> String {
        speakers(forTalk: talkId)
            .map { $0.fullName }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    var sortedSessions: [Session] {
        sessions.sorted { ($0.startsAt ?? "", $0.sort ?? 0) < ($1.startsAt ?? "", $1.sort ?? 0) }
    }

    func session(_ id: Int64?) -> Session? {
        guard let id = id else { return nil }
        return sessions.first { $0.id == id }
    }

    func talks(forSession sessionId: Int64) -> [Talk] {
        sortedTalks.filter { $0.sessionId == sessionId }
    }

    func moderators(forSession sessionId: Int64) -> [Speaker] {
        sessionModerators.filter { $0.sessionId == sessionId }
            .sorted { ($0.sort ?? 0) < ($1.sort ?? 0) }
            .compactMap { m in speakers.first { $0.id == m.speakerId } }
    }

    func moderatorNames(forSession sessionId: Int64) -> String {
        moderators(forSession: sessionId).map { $0.fullName }.filter { !$0.isEmpty }.joined(separator: ", ")
    }

    func sessions(moderatedBy speakerId: Int64) -> [Session] {
        let ids = Set(sessionModerators.filter { $0.speakerId == speakerId }.map { $0.sessionId })
        return sortedSessions.filter { ids.contains($0.id) }
    }

    func talks(forSpeaker speakerId: Int64) -> [Talk] {
        let ids = talkSpeakers.filter { $0.speakerId == speakerId }.map { $0.talkId }
        return sortedTalks.filter { ids.contains($0.id) }
    }
}
