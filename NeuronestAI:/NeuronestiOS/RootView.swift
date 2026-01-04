import SwiftUI

struct RootView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        NavigationStack {
            if auth.didFinishGetStarted && auth.isLoggedIn {
                HomeView()
            } else {
                AuthEntryView()   // GetStarted + Login/Signup까지 여기서 처리
            }
        }
    }
}
