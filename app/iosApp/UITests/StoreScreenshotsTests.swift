import XCTest

// Zrzuty do App Store z PRAWDZIWEJ apki (symulator 6,9"). Uruchamiane tylko w CI
// (workflow screenshots.yml). PNG trafiaja do SHOTS_DIR na hoscie + jako zalaczniki.
final class StoreScreenshotsTests: XCTestCase {
    let app = XCUIApplication()
    var n = 0

    override func setUp() {
        continueAfterFailure = true
        app.launchArguments += ["-AppleLanguages", "(pl)", "-AppleLocale", "pl_PL"]
    }

    func shot(_ name: String) {
        sleep(3)
        n += 1
        let file = String(format: "%02d-%@", n, name)
        let png = XCUIScreen.main.screenshot().pngRepresentation
        let att = XCTAttachment(data: png, uniformTypeIdentifier: "public.png")
        att.name = file; att.lifetime = .keepAlways; add(att)
        if let dir = ProcessInfo.processInfo.environment["SHOTS_DIR"] {
            try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
            try? png.write(to: URL(fileURLWithPath: dir).appendingPathComponent(file + ".png"))
        }
    }

    @discardableResult
    func tap(_ el: XCUIElement, _ timeout: TimeInterval = 15) -> Bool {
        guard el.waitForExistence(timeout: timeout) else { print("BRAK: \(el)"); return false }
        el.tap(); sleep(2); return true
    }

    func allowNotifications() {
        let sb = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let alert = sb.alerts.firstMatch
        if alert.waitForExistence(timeout: 6) {
            let allow = alert.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'allow' AND NOT label CONTAINS[c] 'don'")).firstMatch
            if allow.exists { allow.tap() } else { alert.buttons.element(boundBy: alert.buttons.count - 1).tap() }
            sleep(1)
        }
    }

    func addCode(_ code: String, shotEntry: Bool = false) {
        let field = app.textFields.firstMatch
        tap(field)
        field.typeText(code)
        if shotEntry {
            // klawiatura zaslania pol ekranu: schowaj przed zrzutem
            app.staticTexts["Dołącz do wydarzenia"].tap(); sleep(1)
            shot("wejscie-kodem")
        }
        tap(btn("Pobierz wydarzenie"))
        sleep(5)
    }

    func text(_ s: String) -> XCUIElement { app.staticTexts[s].firstMatch }
    // Etykieta przycisku z ikona to np. "Add, Dodaj wydarzenie kodem", wiec CONTAINS
    func btn(_ s: String) -> XCUIElement { app.buttons.matching(NSPredicate(format: "label CONTAINS %@", s)).firstMatch }

    func testStoreScreenshots() {
        app.launch()
        allowNotifications()

        addCode("TEST03")
        tap(btn("Moje wydarzenia"))
        tap(btn("Dodaj wydarzenie kodem"))
        addCode("TEST01")
        tap(btn("Moje wydarzenia"))
        tap(btn("Dodaj wydarzenie kodem"))
        addCode("TEST02", shotEntry: true)

        shot("ekran-wydarzenia")
        tap(app.tabBars.buttons["Agenda"]); shot("agenda")
        let times = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "^[0-9]{2}:[0-9]{2}$"))
        if times.element(boundBy: 1).waitForExistence(timeout: 10) { times.element(boundBy: 1).tap(); shot("prelekcja") }
        tap(app.tabBars.buttons["Partnerzy"]); shot("partnerzy")
        tap(app.tabBars.buttons["Mapa"]); shot("mapa")
        tap(app.tabBars.buttons["Wydarzenie"])
        tap(btn("Moje wydarzenia")); shot("moje-wydarzenia")
        tap(text("Kongres Diabetologii Klinicznej 2026"))
        tap(text("Prelegenci")); shot("prelegenci")
        // powrot do ekranu eventu: ponowne stukniecie zakladki zdejmuje stos
        tap(app.tabBars.buttons["Wydarzenie"]); tap(app.tabBars.buttons["Wydarzenie"])
        if tap(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Aktualności'")).firstMatch) { shot("aktualnosci") }
    }
}
