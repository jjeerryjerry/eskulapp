package pl.eskulapp.mobile.data

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import pl.eskulapp.mobile.BuildConfig
import pl.eskulapp.mobile.data.model.BundleDto
import pl.eskulapp.mobile.data.model.ManifestDto
import java.net.HttpURLConnection
import java.net.URL

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
}
