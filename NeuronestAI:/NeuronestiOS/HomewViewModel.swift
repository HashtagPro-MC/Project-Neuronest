import Foundation
import Combine

enum HomeDestination {
    case msg, search, report, calendar, diet, focus, memory
}

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var statusText: String = "Ready"
    @Published var lastOpened: HomeDestination? = nil

    func bootstrap() async {
        statusText = "Loaded"
    }

    func open(_ dest: HomeDestination) {
        lastOpened = dest
        // 나중에 여기서 네비게이션 연결하면 됨
        print("Open:", dest)
    }

    func logout() {
        print("Logout")
    }
}
