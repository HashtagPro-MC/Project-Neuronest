//
//  AppSecrets.swift
//  NeuronestiOS
//
//  Created by HashtagPro on 12/31/25.
//


import Foundation

enum AppSecrets {
    static var cohereApiKey: String {
        guard let v = Bundle.main.object(forInfoDictionaryKey: "COHERE_API_KEY") as? String,
              !v.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return ""
        }
        return v
    }
}
