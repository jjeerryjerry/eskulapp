package pl.eskulapp.mobile.ui

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue

sealed interface Screen {
    data object Entry : Screen
    data object Events : Screen
    data class Event(val id: Long) : Screen
    data class Agenda(val id: Long) : Screen
    data class Speakers(val id: Long) : Screen
    data class Partners(val id: Long) : Screen
    data class MapS(val id: Long, val highlightPartnerId: Long? = null) : Screen
    data class Contact(val id: Long) : Screen
    data class News(val id: Long) : Screen
    data class Talk(val id: Long, val eventId: Long) : Screen
    data class More(val id: Long) : Screen
    data class PartnerDetail(val partnerId: Long, val eventId: Long) : Screen
    data class SpeakerDetail(val speakerId: Long, val eventId: Long) : Screen
}

class Navigator(start: Screen) {
    val stack = mutableStateListOf(start)
    val current: Screen get() = stack.last()

    /** Kierunek ostatniego przejscia: true = w glab (push, slide w lewo),
     *  false = wstecz (pop, slide w prawo). Uzywane przez AnimatedContent. */
    var lastForward: Boolean by mutableStateOf(true); private set

    fun push(s: Screen) { lastForward = true; stack.add(s) }
    fun replaceTop(s: Screen) { lastForward = true; stack[stack.lastIndex] = s }
    fun pop(): Boolean {
        if (stack.size > 1) { lastForward = false; stack.removeAt(stack.lastIndex); return true }
        return false
    }
    fun setStack(vararg s: Screen) { lastForward = true; stack.clear(); stack.addAll(s) }

    /** Nawigacja sekcji: back zawsze wraca do poprzedniego ekranu. */
    fun section(s: Screen) {
        if (current::class == s::class) return
        if (stack.size >= 2 && stack[stack.size - 2]::class == s::class) { pop(); return }
        push(s)
    }

    /** Przelaczanie zakladek dolnego menu: ten sam ruch po stosie co `section`,
     *  ale KIERUNEK animacji narzucony wg kolejnosci zakladek (indeks zrodlo vs cel).
     *  target po prawej = w przod (slajd w lewo), po lewej = wstecz (slajd w prawo). */
    fun sectionWithDir(s: Screen, forward: Boolean) {
        if (current::class == s::class) return
        if (stack.size >= 2 && stack[stack.size - 2]::class == s::class) {
            stack.removeAt(stack.lastIndex)
        } else {
            stack.add(s)
        }
        lastForward = forward
    }
}
