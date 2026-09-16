package pl.eskulapp.mobile.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Maly manifest eventu na CDN (events/KOD/manifest.json). Apka odpytuje TYLKO jego
 * (krotki cache + ETag), a caly bundel ciagnie dopiero gdy `version` sie zmienil.
 * `bundlePath` jest WZGLEDNY wobec CDN_BASE, wiec zmiana domeny CDN nie wymaga
 * ponownego pieczenia po stronie serwera.
 */
@Serializable
data class ManifestDto(
    val code: String,
    @SerialName("event_id") val eventId: Long,
    val version: String,
    @SerialName("updated_at") val updatedAt: String? = null,
    @SerialName("bundle_path") val bundlePath: String,
    @SerialName("bundle_url") val bundleUrl: String? = null,
)
