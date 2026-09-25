package pl.eskulapp.mobile.ratings

import android.content.Context
import java.util.UUID

/**
 * Anonimowy identyfikator instalacji do ocen (SPEC-OCENY §1): losowy UUID v4, generowany
 * raz przy pierwszym uzyciu i trzymany tylko lokalnie (SharedPreferences, poza backupem),
 * wiec znika z odinstalowaniem. Nigdy nie laczony z danymi osobowymi; serwer zapisuje
 * wylacznie sha256(install_id + sol).
 */
object InstallId {
    private const val PREFS = "eskulapp_install"
    private const val KEY = "install_id"

    @Volatile private var cached: String? = null

    fun get(context: Context): String = cached ?: synchronized(this) {
        cached ?: run {
            val prefs = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            prefs.getString(KEY, null) ?: UUID.randomUUID().toString().also {
                prefs.edit().putString(KEY, it).commit()
            }
        }.also { cached = it }
    }
}
