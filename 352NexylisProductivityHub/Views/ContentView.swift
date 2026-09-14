import SwiftUI

struct ContentView: View {
    @StateObject private var store = BoardStore()
    @Environment(\.scenePhase) private var scenePhase
    @State private var page = 0
    @State private var showSettings = false

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            CorkHeader(page: $page, onSettings: { showSettings = true })

            TabView(selection: $page) {
                PinBoardView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .tag(0)
                PulseTimerView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .tag(1)
                StreakLogView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .tag(2)
                BoardStatsView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .tag(3)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .studioBackdrop()
        .environmentObject(store)
        .sheet(isPresented: $showSettings) {
            CorkSettingsView()
                .environmentObject(store)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("dataReset"))) { _ in
            page = 0
            showSettings = false
        }
        .onReceive(NotificationCenter.default.publisher(for: BoardNote.openPulse)) { _ in
            page = 1
        }
        .onReceive(ticker) { _ in
            store.tickIfNeeded()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background || phase == .inactive {
                store.pauseTimer()
            }
        }
        .onChange(of: page) { _ in
            BoardKeyboard.dismiss()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
