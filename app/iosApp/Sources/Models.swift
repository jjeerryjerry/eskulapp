import Foundation

// Modele danych 1:1 z kontraktem API (GET /api/public/events/{code}/bundle),
// natywne Swift Codable (odpowiednik data/model/Dto.kt + encji Room).
// Pola z domyslnymi wartosciami sa opcjonalne, defaulty stosujemy w UI.

struct EventDTO: Codable {
    let id: Int64
    let slug: String
    let name: String
    let accessCode: String
    let isClosed: Bool?
    let startsAt: String?
    let endsAt: String?
    let venueName: String?
    let city: String?
    let mapImageUrl: String?
    let mapEmbed: String?
    let pushTopic: String?
    let status: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, slug, name, city
        case accessCode = "access_code"
        case isClosed = "is_closed"
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case venueName = "venue_name"
        case mapImageUrl = "map_image_url"
        case mapEmbed = "map_embed"
        case pushTopic = "push_topic"
        case status
        case updatedAt = "updated_at"
    }

    var statusOrDefault: String { status ?? "published" }
}

struct Day: Codable, Identifiable {
    let id: Int64
    let date: String?
    let label: String?
    let sort: Int?
}

struct RoomDTO: Codable, Identifiable {
    let id: Int64
    let name: String
    let sort: Int?
}

struct Talk: Codable, Identifiable {
    let id: Int64
    let dayId: Int64?
    let roomId: Int64?
    let title: String
    let abstract: String?
    let startsAt: String?
    let endsAt: String?
    let sort: Int?

    enum CodingKeys: String, CodingKey {
        case id, title, abstract, sort
        case dayId = "day_id"
        case roomId = "room_id"
        case startsAt = "starts_at"
        case endsAt = "ends_at"
    }
}

struct Speaker: Codable, Identifiable {
    let id: Int64
    let firstName: String?
    let lastName: String?
    let title: String?
    let photoUrl: String?
    let bio: String?
    let sort: Int?

    enum CodingKeys: String, CodingKey {
        case id, title, bio, sort
        case firstName = "first_name"
        case lastName = "last_name"
        case photoUrl = "photo_url"
    }

    var first: String { firstName ?? "" }
    var last: String { lastName ?? "" }
    var fullName: String { (first.trimmingCharacters(in: .whitespaces) + " " + last.trimmingCharacters(in: .whitespaces)).trimmingCharacters(in: .whitespaces) }
}

struct TalkSpeaker: Codable {
    let talkId: Int64
    let speakerId: Int64
    enum CodingKeys: String, CodingKey {
        case talkId = "talk_id"
        case speakerId = "speaker_id"
    }
}

struct Partner: Codable, Identifiable {
    let id: Int64
    let name: String
    let logoUrl: String?
    let description: String?
    let tier: String?
    let boothLocation: String?
    let website: String?
    let sort: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, description, tier, website, sort
        case logoUrl = "logo_url"
        case boothLocation = "booth_location"
    }
}

struct Contact: Codable, Identifiable {
    let id: Int64
    let label: String?
    let name: String?
    let phone: String?
    let email: String?
    let note: String?
    let sort: Int?
}

struct News: Codable, Identifiable {
    let id: Int64
    let type: String?
    let title: String
    let body: String?
    let linkType: String?
    let linkRef: String?
    let pinned: Int?
    let publishedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, type, title, body, pinned
        case linkType = "link_type"
        case linkRef = "link_ref"
        case publishedAt = "published_at"
    }
    var isPinned: Bool { (pinned ?? 0) == 1 }
}

struct EventBundle: Codable {
    let event: EventDTO
    var days: [Day]
    var rooms: [RoomDTO]
    var talks: [Talk]
    var speakers: [Speaker]
    var talkSpeakers: [TalkSpeaker]
    var partners: [Partner]
    var contacts: [Contact]
    var news: [News]

    enum CodingKeys: String, CodingKey {
        case event, days, rooms, talks, speakers, partners, contacts, news
        case talkSpeakers = "talk_speakers"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        event = try c.decode(EventDTO.self, forKey: .event)
        days = (try? c.decode([Day].self, forKey: .days)) ?? []
        rooms = (try? c.decode([RoomDTO].self, forKey: .rooms)) ?? []
        talks = (try? c.decode([Talk].self, forKey: .talks)) ?? []
        speakers = (try? c.decode([Speaker].self, forKey: .speakers)) ?? []
        talkSpeakers = (try? c.decode([TalkSpeaker].self, forKey: .talkSpeakers)) ?? []
        partners = (try? c.decode([Partner].self, forKey: .partners)) ?? []
        contacts = (try? c.decode([Contact].self, forKey: .contacts)) ?? []
        news = (try? c.decode([News].self, forKey: .news)) ?? []
    }
}

/// Event zapisany lokalnie (offline) + moment dodania (kolejnosc listy).
struct StoredEvent: Codable, Identifiable {
    var bundle: EventBundle
    var addedAt: Double
    var id: Int64 { bundle.event.id }
}
