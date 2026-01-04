//
//  ProfileStore.swift
//  NeuronestiOS
//
//  Created by HashtagPro on 12/31/25.
//


import SwiftUI
import PhotosUI
import Combine

@MainActor
final class ProfileStore: ObservableObject {

    // 저장 키
    private let nameKey = "profile_name"
    private let avatarKey = "profile_avatar_jpeg"

    @Published var name: String
    @Published var avatarImage: UIImage?

    init() {
        // name
        let savedName = UserDefaults.standard.string(forKey: nameKey)
        self.name = (savedName?.isEmpty == false) ? savedName! : "My Profile"

        // avatar
        if let data = UserDefaults.standard.data(forKey: avatarKey),
           let ui = UIImage(data: data) {
            self.avatarImage = ui
        } else {
            self.avatarImage = nil
        }
    }

    func saveName(_ newName: String) {
        name = newName
        UserDefaults.standard.set(newName, forKey: nameKey)
    }

    func setAvatar(_ image: UIImage?) {
        avatarImage = image
        if let image {
            // JPEG로 저장(용량 줄임)
            let data = image.jpegData(compressionQuality: 0.82)
            UserDefaults.standard.set(data, forKey: avatarKey)
        } else {
            UserDefaults.standard.removeObject(forKey: avatarKey)
        }
    }

    func resetAvatar() {
        setAvatar(nil)
    }
}
