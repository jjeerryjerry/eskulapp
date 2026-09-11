import SwiftUI

@main
struct EskulappApp: App {
    @StateObject private var store = AppStore()
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(store)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var store: AppStore
    var body: some View {
        switch store.top {
        case .entry:
            EntryView(firstRun: true)
        case .events:
            EventsRootView()
        case .event(let id):
            EventContainerView(eventId: id)
                .id(id) // przy zmianie eventu odtwarzamy kontener (czyste stosy zakladek)
        }
    }
}
