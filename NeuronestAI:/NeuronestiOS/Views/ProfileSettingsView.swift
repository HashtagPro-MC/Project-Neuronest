import SwiftUI
import PhotosUI
import UIKit
import AVFoundation

struct ProfileSettingsView: View {
    @EnvironmentObject var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showLogoutConfirm = false

    // PhotosPicker
    @State private var pickedItem: PhotosPickerItem? = nil
    @State private var avatarData: Data? = nil
    @State private var showCameraDeniedAlert = false
    @State private var cameraDeniedMsg = ""
    // Camera sheet
    @State private var showCamera = false

    private let avatarKey = "profile_avatar_data"

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    avatarCard

                    sectionTitle("Danger Zone")
                    logoutCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("My Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadAvatar() }

        // ✅ iOS16/17/18 모두 안전하게
        .onChange(of: pickedItem) { newItem in
            guard let newItem else { return }
            Task { await loadPickedAvatar(newItem) }
        }

        .sheet(isPresented: $showCamera) {
            CameraPicker { image in
                saveAvatar(image: image)
                showCamera = false   // ✅ 찍고 나면 닫기
            }
            .ignoresSafeArea()
        }

        .alert("Log out?", isPresented: $showLogoutConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Log out", role: .destructive) {
                auth.logout()
                dismiss()   // ✅ 확인 누르면 바로 로그아웃 + 화면 닫힘 (슬라이드 필요 없음)
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }

    // MARK: - UI

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Profile")
                .font(.system(size: 28, weight: .heavy))
            Text("Avatar • Account")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }

    private var avatarCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                avatarView

                VStack(alignment: .leading, spacing: 6) {
                    Text(auth.userName.isEmpty ? "User" : auth.userName)
                        .font(.system(size: 18, weight: .bold))
                    Text("Change your avatar")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                Button {
                    showCamera = true
                } label: {
                    HStack {
                        Image(systemName: "camera")
                        Text("Camera")
                            .font(.system(size: 14, weight: .bold))
                        Spacer()
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.primary.opacity(0.06)))
                }
                .buttonStyle(.plain)

                PhotosPicker(selection: $pickedItem, matching: .images, photoLibrary: .shared()) {
                    HStack {
                        Image(systemName: "photo")
                        Text("Photos")
                            .font(.system(size: 14, weight: .bold))
                        Spacer()
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.primary.opacity(0.06)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(cardBG)
    }

    private var logoutCard: some View {
        Button {
            showLogoutConfirm = true
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Log out")
                    .font(.system(size: 15, weight: .bold))
                Spacer()
            }
            .foregroundStyle(.red)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.red.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.red.opacity(0.18), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var avatarView: some View {
        Group {
            if let avatarData, let ui = UIImage(data: avatarData) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Circle().fill(Color.primary.opacity(0.08))
                    Text("🧌").font(.system(size: 55))
                }
            }
        }
        .frame(width: 72, height: 72)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.primary.opacity(0.12), lineWidth: 1))
    }

    private func sectionTitle(_ t: String) -> some View {
        Text(t)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.secondary)
            .padding(.top, 4)
    }

    private var cardBG: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(Color.primary.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
    }

    // MARK: - Persistence

    private func loadAvatar() {
        avatarData = UserDefaults.standard.data(forKey: avatarKey)
    }

    @MainActor
    private func loadPickedAvatar(_ item: PhotosPickerItem) async {
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                avatarData = data
                UserDefaults.standard.set(data, forKey: avatarKey)
            }
            pickedItem = nil // ✅ 다음에 또 고르기 편하게 리셋
        } catch {
            print("Avatar load error:", error)
        }
    }

    private func saveAvatar(image: UIImage) {
        let data = image.jpegData(compressionQuality: 0.85)
        avatarData = data
        if let data { UserDefaults.standard.set(data, forKey: avatarKey) }
    }
}

