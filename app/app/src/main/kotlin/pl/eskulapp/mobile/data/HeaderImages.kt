package pl.eskulapp.mobile.data

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest

/**
 * Grafika naglowka eventu (opcjonalna, z CMS), trzymana lokalnie: apka dziala offline,
 * wiec pobieramy plik przy odswiezeniu bundla, a ekran czyta go z dysku.
 * Plik: filesDir/headers/<eventId>_<sha256(url)>.img. Nowy URL = nowy plik, stare kasujemy.
 */
object HeaderImages {
    private const val MAX_BYTES = 5 * 1024 * 1024
    private const val MAX_WIDTH = 1440

    private fun dir(ctx: Context) = File(ctx.filesDir, "headers")

    fun file(ctx: Context, eventId: Long, url: String): File = File(dir(ctx), "${eventId}_${sha256(url)}.img")

    /** Pobiera grafike, gdy jej brak; usuwa nieaktualne pliki eventu. Bledy sieci ignorowane. */
    suspend fun ensure(ctx: Context, eventId: Long, url: String?) = withContext(Dispatchers.IO) {
        val keep = url?.let { file(ctx, eventId, it) }
        dir(ctx).listFiles { f -> f.name.startsWith("${eventId}_") && f != keep }?.forEach { it.delete() }
        if (keep == null || keep.exists() || !url.startsWith("https://")) return@withContext
        runCatching { download(url, keep) }
    }

    fun delete(ctx: Context, eventId: Long) {
        dir(ctx).listFiles { f -> f.name.startsWith("${eventId}_") }?.forEach { it.delete() }
    }

    /** Dekoduje z dysku z pomniejszeniem do ~MAX_WIDTH (oszczednosc pamieci). null = brak/blad. */
    fun load(f: File): Bitmap? {
        if (!f.exists()) return null
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(f.path, bounds)
        if (bounds.outWidth <= 0) return null
        var sample = 1
        while (bounds.outWidth / (sample * 2) >= MAX_WIDTH) sample *= 2
        return BitmapFactory.decodeFile(f.path, BitmapFactory.Options().apply { inSampleSize = sample })
    }

    private fun download(url: String, target: File) {
        val conn = (URL(url).openConnection() as HttpURLConnection).apply {
            connectTimeout = 12000
            readTimeout = 20000
        }
        try {
            if (conn.responseCode !in 200..299) return
            target.parentFile?.mkdirs()
            val tmp = File(target.parentFile, target.name + ".part")
            conn.inputStream.use { input ->
                tmp.outputStream().use { out ->
                    val buf = ByteArray(16 * 1024)
                    var total = 0
                    while (true) {
                        val n = input.read(buf)
                        if (n < 0) break
                        total += n
                        if (total > MAX_BYTES) { out.close(); tmp.delete(); return }
                        out.write(buf, 0, n)
                    }
                }
            }
            if (!tmp.renameTo(target)) tmp.delete()
        } finally {
            conn.disconnect()
        }
    }

    private fun sha256(s: String): String =
        MessageDigest.getInstance("SHA-256").digest(s.toByteArray()).joinToString("") { "%02x".format(it) }.take(16)
}
