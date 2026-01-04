import SwiftUI

struct ContentView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        if auth.didFinishGetStarted {
            HomeView()
        } else {
            AuthGlassShellView()
        }
    }
}
