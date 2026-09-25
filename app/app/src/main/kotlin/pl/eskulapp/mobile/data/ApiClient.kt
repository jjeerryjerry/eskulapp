package pl.eskulapp.mobile.data

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json
import pl.eskulapp.mobile.BuildConfig
import pl.eskulapp.mobile.data.model.BundleDto
import pl.eskulapp.mobile.data.model.ManifestDto
import pl.eskulapp.mobile.data.model.MyRatingDto
import pl.eskulapp.mobile.data.model.RatingRequestDto
import pl.eskulapp.mobile.ratings.RatingResult
import pl.eskulapp.mobile.ratings.ratingResultFor
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder

class NotFoundException(msg: String) : Exception(msg)

object ApiClient {
    private val json = Json { ignoreUnknownKeys = true; isLenient = true }

    /** Pobiera tekst z URL. 404 -> NotFoundException; inne bledy -> Exception. */
    private fun httpGet(urlStr: String): String {
        val conn = (URL(urlStr).openConnection() as HttpURLConnection).apply {
            requestMethod = "GET"
            connectTimeout = 12000
            readTimeout = 12000
            setRequestProperty("Accept", "application/json")
        }
        try {
            val code = conn.responseCode
            if (code == 404) throw NotFoundException("Nie znaleziono wydarzenia o tym kodzie.")
            if (code !in 200..299) throw Exception("Błąd serwera ($code).")
            return conn.inputStream.bufferedReader().use { it.readText() }
        } finally {
            conn.disconnect()
        }
    }

    // ---- CDN (architektura B): manifest + wersjonowany bundel ----

    /** Manifest eventu z CDN: CDN_BASE/events/KOD/manifest.json */
    suspend fun fetchManifest(code: String): ManifestDto = withContext(Dispatchers.IO) {
        val c = code.trim().uppercase()
        val body = httpGet("${BuildConfig.CDN_BASE}/events/$c/manifest.json")
        json.decodeFromString(ManifestDto.serializer(), body)
    }

    /** Niezmienny bundel z CDN po sciezce wzglednej z manifestu. */
    suspend fun fetchBundleAt(bundlePath: String): BundleDto = withContext(Dispatchers.IO) {
        val body = httpGet("${BuildConfig.CDN_BASE}/${bundlePath.trimStart('/')}")
        json.decodeFromString(BundleDto.serializer(), body)
    }

    // ---- Fallback: bezposrednio z PHP API (gdy CDN niedostepny) ----

    suspend fun fetchBundle(code: String): BundleDto = withContext(Dispatchers.IO) {
        val c = code.trim().uppercase()
        val body = httpGet("${BuildConfig.API_BASE}/public/events/$c/bundle")
        json.decodeFromString(BundleDto.serializer(), body)
    }

    // ---- Oceny prelekcji (SPEC-OCENY §4): zawsze PHP API, nigdy CDN ----

    /** Wysyla glos. Nie rzuca: siec/429/5xx = Retry, odrzucenie przez serwer = Rejected. */
    suspend fun postRating(code: String, talkId: Long, installId: String, score: Int): RatingResult =
        withContext(Dispatchers.IO) {
            val c = URLEncoder.encode(code.trim().uppercase(), "UTF-8")
            val payload = json.encodeToString(RatingRequestDto.serializer(), RatingRequestDto(installId, score))
            val conn = try {
                (URL("${BuildConfig.API_BASE}/public/events/$c/talks/$talkId/rating").openConnection() as HttpURLConnection)
            } catch (e: IOException) {
                return@withContext RatingResult.Retry
            }
            try {
                conn.requestMethod = "POST"
                conn.connectTimeout = 12000
                conn.readTimeout = 12000
                conn.doOutput = true
                conn.setRequestProperty("Content-Type", "application/json; charset=utf-8")
                conn.setRequestProperty("Accept", "application/json")
                conn.outputStream.use { it.write(payload.toByteArray(Charsets.UTF_8)) }
                val http = conn.responseCode
                val stream = if (http in 200..299) conn.inputStream else conn.errorStream
                val body = stream?.bufferedReader()?.use { it.readText() }
                ratingResultFor(http, body, score)
            } catch (e: IOException) {
                RatingResult.Retry
            } finally {
                conn.disconnect()
            }
        }

    /** Oceny tego urzadzenia w evencie (odtworzenie stanu po wyczyszczeniu lokalnej bazy). */
    suspend fun fetchMyRatings(code: String, installId: String): List<MyRatingDto> = withContext(Dispatchers.IO) {
        val c = URLEncoder.encode(code.trim().uppercase(), "UTF-8")
        val id = URLEncoder.encode(installId, "UTF-8")
        val body = httpGet("${BuildConfig.API_BASE}/public/events/$c/ratings/mine?install_id=$id")
        json.decodeFromString(ListSerializer(MyRatingDto.serializer()), body)
    }
}
