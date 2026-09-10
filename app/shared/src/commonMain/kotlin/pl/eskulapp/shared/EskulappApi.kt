package pl.eskulapp.shared

import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.engine.HttpClientEngine
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.request.get
import io.ktor.client.request.header
import io.ktor.client.statement.HttpResponse
import io.ktor.http.HttpHeaders
import io.ktor.serialization.kotlinx.json.json
import kotlinx.serialization.json.Json
import pl.eskulapp.shared.model.BundleDto

/** Wydarzenie o podanym kodzie nie istnieje (HTTP 404). */
class NotFoundException(message: String) : Exception(message)

/** Inny blad po stronie serwera. */
class ServerException(message: String) : Exception(message)

/**
 * Klient API Eskulapp, wspoldzielony Android + iOS (Ktor).
 * Odpowiednik androidowego ApiClient, ale multiplatformowy.
 */
class EskulappApi(
    private val baseUrl: String,
    private val client: HttpClient,
) {
    // Konstruktory pomocnicze , domyslne argumenty Kotlina nie sa widoczne w Swift,
    // wiec dajemy jawne warianty (EskulappApi(), EskulappApi(baseUrl:)).
    constructor() : this(DEFAULT_BASE_URL, defaultHttpClient())
    constructor(baseUrl: String) : this(baseUrl, defaultHttpClient())

    /** Pobiera komplet danych eventu po kodzie dostepu (np. "FND2027"). */
    suspend fun fetchBundle(code: String): BundleDto {
        val normalized = code.trim().uppercase()
        val resp: HttpResponse = client.get("$baseUrl/public/events/$normalized/bundle") {
            header(HttpHeaders.Accept, "application/json")
        }
        return when (resp.status.value) {
            404 -> throw NotFoundException("Nie znaleziono wydarzenia o tym kodzie.")
            in 200..299 -> resp.body()
            else -> throw ServerException("Blad serwera (${resp.status.value}).")
        }
    }

    companion object {
        const val DEFAULT_BASE_URL: String = "https://eskulapp.pl/api"
    }
}

private val eskulappJson = Json {
    ignoreUnknownKeys = true
    isLenient = true
}

/** Silnik HTTP zalezny od platformy (OkHttp na Androidzie, Darwin na iOS). */
internal expect fun platformHttpEngine(): HttpClientEngine

/** Klient Ktor z konfiguracja JSON, wspolna dla obu platform. */
fun defaultHttpClient(): HttpClient = HttpClient(platformHttpEngine()) {
    install(ContentNegotiation) {
        json(eskulappJson)
    }
}
