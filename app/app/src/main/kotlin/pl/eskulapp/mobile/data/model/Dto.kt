package pl.eskulapp.mobile.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class BundleDto(
    val event: EventDto,
    val days: List<DayDto> = emptyList(),
    val rooms: List<RoomDto> = emptyList(),
    val talks: List<TalkDto> = emptyList(),
    val speakers: List<SpeakerDto> = emptyList(),
    @SerialName("talk_speakers") val talkSpeakers: List<TalkSpeakerDto> = emptyList(),
    val partners: List<PartnerDto> = emptyList(),
    val contacts: List<ContactDto> = emptyList(),
    val news: List<NewsDto> = emptyList(),
)

@Serializable
data class EventDto(
    val id: Long,
    val slug: String,
    val name: String,
    @SerialName("access_code") val accessCode: String,
    @SerialName("is_closed") val isClosed: Boolean = true,
    @SerialName("starts_at") val startsAt: String? = null,
    @SerialName("ends_at") val endsAt: String? = null,
    @SerialName("venue_name") val venueName: String? = null,
    val city: String? = null,
    @SerialName("map_image_url") val mapImageUrl: String? = null,
    @SerialName("map_embed") val mapEmbed: String? = null,
    @SerialName("push_topic") val pushTopic: String? = null,
    val status: String = "published",
    @SerialName("updated_at") val updatedAt: String? = null,
)

@Serializable
data class DayDto(val id: Long, val date: String? = null, val label: String? = null, val sort: Int = 0)

@Serializable
data class RoomDto(val id: Long, val name: String, val sort: Int = 0)

@Serializable
data class TalkDto(
    val id: Long,
    @SerialName("day_id") val dayId: Long? = null,
    @SerialName("room_id") val roomId: Long? = null,
    val title: String,
    val abstract: String? = null,
    @SerialName("starts_at") val startsAt: String? = null,
    @SerialName("ends_at") val endsAt: String? = null,
    val sort: Int = 0,
)

@Serializable
data class SpeakerDto(
    val id: Long,
    @SerialName("first_name") val firstName: String = "",
    @SerialName("last_name") val lastName: String = "",
    val title: String? = null,
    @SerialName("photo_url") val photoUrl: String? = null,
    val bio: String? = null,
    val sort: Int = 0,
)

@Serializable
data class TalkSpeakerDto(
    @SerialName("talk_id") val talkId: Long,
    @SerialName("speaker_id") val speakerId: Long,
)

@Serializable
data class PartnerDto(
    val id: Long,
    val name: String,
    @SerialName("logo_url") val logoUrl: String? = null,
    val description: String? = null,
    val tier: String? = null,
    @SerialName("booth_location") val boothLocation: String? = null,
    val website: String? = null,
    val sort: Int = 0,
)

@Serializable
data class ContactDto(
    val id: Long,
    val label: String? = null,
    val name: String? = null,
    val phone: String? = null,
    val email: String? = null,
    val note: String? = null,
    val sort: Int = 0,
)

@Serializable
data class NewsDto(
    val id: Long,
    val type: String = "ogloszenie",
    val title: String,
    val body: String? = null,
    @SerialName("link_type") val linkType: String? = null,
    @SerialName("link_ref") val linkRef: String? = null,
    val pinned: Int = 0,
    @SerialName("published_at") val publishedAt: String? = null,
)
