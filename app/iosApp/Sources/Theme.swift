import SwiftUI

// Paleta 1:1 z Androidem (ui/theme/Theme.kt).
enum C {
    static let petrol     = Color(hex: 0x0C5A63)
    static let petrolDark = Color(hex: 0x08363B)
    static let coral      = Color(hex: 0xFF6B57)
    static let coralDark  = Color(hex: 0xD9503B)
    static let ink        = Color(hex: 0x0A1B2A)
    static let muted      = Color(hex: 0x5B6B72)
    static let faint      = Color(hex: 0x9AA7AD)
    static let line       = Color(hex: 0xE1E7E9)
    static let bg         = Color(hex: 0xF6F8F9)
    static let surface    = Color(hex: 0xFFFFFF)
    static let tint       = Color(hex: 0xD7EAEC)
    static let coralTint  = Color(hex: 0xFDE6E1)
    static let coralLine  = Color(hex: 0xFFD2C9)
    static let grey       = Color(hex: 0xEDF1F2)
    static let petrolText = Color(hex: 0xBFE0E2)
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}

// Helpery formatowania 1:1 z ui/Common.kt.
func subStr(_ s: String, _ from: Int, _ to: Int) -> String {
    guard from >= 0, to <= s.count, from < to else { return "" }
    let a = s.index(s.startIndex, offsetBy: from)
    let b = s.index(s.startIndex, offsetBy: to)
    return String(s[a..<b])
}

func hhmm(_ dt: String?) -> String {
    guard let dt = dt, dt.count >= 16 else { return "" }
    return subStr(dt, 11, 16)
}

func dayShort(_ date: String?) -> String {
    guard let date = date, date.count >= 10 else { return "" }
    return subStr(date, 8, 10) + "." + subStr(date, 5, 7)
}

func initials(_ first: String, _ last: String) -> String {
    let a = first.trimmingCharacters(in: .whitespaces).first
    let b = last.trimmingCharacters(in: .whitespaces).first
    let s = [a, b].compactMap { $0 }.map { String($0).uppercased() }.joined()
    return s.isEmpty ? "?" : s
}

private let posixNowFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return f
}()

/// Czy wydarzenie jeszcze sie nie zaczelo (data startu w przyszlosci).
func isUpcoming(_ startsAt: String?) -> Bool {
    guard let s = startsAt, s.count >= 19 else { return false }
    let now = posixNowFormatter.string(from: Date())
    return s > now
}

/// Parsuje "yyyy-MM-dd HH:mm:ss" (czas lokalny) na Date.
func parseLocalDate(_ s: String?) -> Date? {
    guard let s = s, s.count >= 19 else { return nil }
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "yyyy-MM-dd HH:mm:ss"
    f.timeZone = TimeZone.current
    return f.date(from: subStr(s, 0, 19))
}

// Male komponenty wspoldzielone.

struct Seal: View {
    var size: CGFloat = 36
    var body: some View {
        ZStack {
            Circle().fill(C.petrol)
            Image(systemName: "staff.of.asclepius")
                .font(.system(size: size * 0.55, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }
}

struct Pill: View {
    let text: String
    var bg: Color
    var fg: Color
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(fg)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(bg)
            .clipShape(Capsule())
    }
}

struct Chip: View {
    let label: String
    let active: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(active ? C.surface : C.ink)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(active ? C.petrol : C.surface)
                .overlay(Capsule().stroke(C.line, lineWidth: active ? 0 : 1))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Naglowek z przyciskiem wstecz (odpowiednik BackTopBar).
struct BackHeader<Trailing: View>: View {
    let title: String
    var onBack: (() -> Void)? = nil
    @ViewBuilder var trailing: () -> Trailing
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack(spacing: 10) {
            Button {
                if let onBack = onBack { onBack() } else { dismiss() }
            } label: {
                Image(systemName: "chevron.left").font(.system(size: 20, weight: .semibold)).foregroundColor(C.ink)
            }
            .buttonStyle(.plain)
            Text(title).font(.system(size: 22, weight: .heavy)).foregroundColor(C.ink)
            Spacer()
            trailing()
        }
        .padding(.horizontal, 20).padding(.top, 14).padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(C.surface)
    }
}

extension BackHeader where Trailing == EmptyView {
    init(_ title: String, onBack: (() -> Void)? = nil) {
        self.init(title: title, onBack: onBack, trailing: { EmptyView() })
    }
}

struct EmptyHint: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(C.muted)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(32)
    }
}

func icon(_ name: String, _ color: Color, _ size: CGFloat) -> some View {
    Image(systemName: name).font(.system(size: size)).foregroundColor(color)
}
