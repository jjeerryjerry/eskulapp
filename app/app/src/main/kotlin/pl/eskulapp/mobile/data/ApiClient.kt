package pl.eskulapp.mobile.data

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import pl.eskulapp.mobile.BuildConfig
import pl.eskulapp.mobile.data.model.BundleDto
import java.net.HttpURLConnection
import java.net.URL

class NotFoundException(msg: String) : Exception(msg)

object ApiClient {
    private val json = Json { ignoreUnknownKeys = true; isLenient = true }

    suspend fun fetchBundle(code: String): BundleDto = withContext(Dispatchers.IO) {
        val url = URL("${BuildConfig.API_BASE}/public/events/${code.trim().uppercase()}/bundle")
        val conn = (url.openConnection() as HttpURLConnection).apply {
            requestMethod = "GET"
            connectTimeout = 12000
            readTimeout = 12000
            setRequestProperty("Accept", "application/json")
        }
        try {
            val ccode = conn.responseCode
            if (ccode == 404) throw NotFoundException("Nie znaleziono wydarzenia o tym kodzie.")
            if (ccode !in 200..299) throw Exception("Błąd serwera ($ccode).")
            val body = conn.inputStream.bufferedReader().use { it.readText() }
            json.decodeFromString(BundleDto.serializer(), body)
        } finally {
            conn.disconnect()
        }
    }
}
