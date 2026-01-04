//
//  GeminiDietService.swift
//  NeuronestiOS
//
//  Created by HashtagPro on 12/31/25.
//


import Foundation

struct CohereDietService {
    private let apiKey: String
    init(apiKey: String = AppSecrets.cohereApiKey) { self.apiKey = apiKey }

    // gemini v1beta endpoint
    private let endpoint =
    "https://api.cohere.com/v2/chat"

    enum MealType: String {
        case breakfast = "Breakfast"
        case lunch = "Lunch"
        case dinner = "Dinner"
    }

    func generateMealPlan(for meal: MealType) async throws -> String {
        guard !apiKey.isEmpty else { return "Missing Cohere Api key in Info.plist." }

        // ✅ US target, Alzheimer-friendly(=MIND/Mediterranean style), no diagnosis
        let prompt = """
        You are Neuronest AI — a nutrition assistant. You are NOT a medical professional.
        Do not diagnose, do not claim to treat or prevent Alzheimer's disease.
        Provide general, evidence-informed healthy eating guidance (MIND/Mediterranean style).

        Target user: US-based, grocery-store ingredients, simple home cooking.

        Task:
        Create ONE \(meal.rawValue) plan that is “brain-health friendly.”
        Output format EXACTLY:

        Title:
        1) Menu (1 main + 1 side if appropriate):
        2) Ingredients (with approximate US measurements):
        3) Step-by-step cooking (5–10 steps, beginner-friendly):
        4) Time & servings:
        5) Optional swaps (allergies/diet: dairy-free, gluten-free, vegetarian):
        6) Why this is a good choice (short, non-medical, 2–3 bullets):
        7) Shopping tip (1 line):
        8) Tell the user the recipe and how to do it
        """

        let body: [String: Any] = [
            "contents": [[
                "role": "user",
                "parts": [[ "text": prompt ]]
            ]],
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": 700
            ]
        ]

        var request = URLRequest(url: URL(string: "\(endpoint)?key=\(apiKey)")!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            let raw = String(data: data, encoding: .utf8) ?? ""
            return "Gemini error (\(http.statusCode)): \(raw)"
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let text =
        (((json?["candidates"] as? [[String: Any]])?.first?["content"] as? [String: Any])?["parts"] as? [[String: Any]])?
            .compactMap { $0["text"] as? String }
            .joined(separator: "\n")

        return (text?.isEmpty == false) ? text! : "AI response was empty."
    }
}
