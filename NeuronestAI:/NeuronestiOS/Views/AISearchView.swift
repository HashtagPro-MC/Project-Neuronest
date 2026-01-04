//
//  AISearchView.swift
//  NeuronestiOS
//
//  Created by HashtagPro on 1/2/26.
//

import EventKit
import SwiftUI

struct AISearchView: View {
    @EnvironmentObject var analytics: AnalyticsStore
    @EnvironmentObject var calendarService: CalendarService
    // 필요하면 다른 스토어들도 추가:
    // @EnvironmentObject var dietCache: DietCacheStore
    // @EnvironmentObject var chatStore: ChatStore

    @State private var query: String = ""
    @State private var answer: String = ""
    @State private var isLoading = false
    @State private var err: String? = nil

    // 로컬 검색 결과(간단 리스트)
    @State private var localHits: [LocalHit] = []

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 12) {
                header

                searchBar

                if isLoading {
                    ProgressView("Searching with AI...")
                        .padding(.top, 10)
                }

                if let err {
                    Text(err).foregroundStyle(.red).font(.footnote)
                }

                if !localHits.isEmpty {
                    GroupBox("Local matches") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(localHits) { hit in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(hit.title).font(.headline)
                                    Text(hit.snippet).font(.subheadline).foregroundStyle(.secondary)
                                }
                                Divider().opacity(0.4)
                            }
                        }
                    }
                }

                GroupBox("AI Answer") {
                    if answer.isEmpty {
                        Text("Ask something like:\n• 최근 7일 중 내가 제일 잘한 게임은?\n• 내 반응속도(중앙값) 추세는?\n• 내일 훈련 일정 추가해줘(캘린더)\n• 내가 저장한 식단 추천 있어?")
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                    } else {
                        ScrollView {
                            Text(answer)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(minHeight: 140)
                    }
                }

                Spacer()
            }
            .padding(16)
        }
        .navigationTitle("Search w/ AI")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // 캘린더 권한/이벤트 로드가 아직이면:
            Task {
                try? await calendarService.requestAccess()
                calendarService.fetchUpcoming(days: 30)
            }
        }
    }

    // MARK: - UI

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("🔎 Search w/ AI")
                .font(.system(size: 28, weight: .heavy))
            Text("앱 데이터(훈련/리포트/일정) 기반으로 먼저 찾고, AI가 요약해서 답해줘.")
                .foregroundStyle(.secondary)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            TextField("Search… (예: 최근 최고 점수, 내일 일정, 집중 점수)", text: $query)
                .textFieldStyle(.roundedBorder)

            Button {
                Task { await runSearch() }
            } label: {
                Image(systemName: "sparkle.magnifyingglass")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Capsule().fill(Color.blue))
            }
            .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
        }
    }

    // MARK: - Local search + AI answer

    private func runSearch() async {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }

        err = nil
        answer = ""
        isLoading = true
        defer { isLoading = false }

        // 1) 로컬에서 먼저 찾기(앱 데이터)
        localHits = localSearch(query: q)

        // 2) AI에게 "로컬 결과 + 요약 통계" 넘겨서 답변 생성
        do {
            let client = try MistralClient(model: "mistral-small-latest")

            let context = buildContextText(hits: localHits)
            let prompt = """
            너는 Neuronest 앱의 인지훈련 코치야.
            아래 '앱 데이터'만 기반으로 사용자 질문에 답해줘.
            - 의료 진단/치료처럼 말하지 말고 코치 톤으로.
            - 데이터가 부족하면 "앱에 기록이 없어서 확답 어렵다"라고 말하고, 다음에 기록을 남기는 방법을 제안해.
            - 답변 끝에 "다음 액션 1개"를 꼭 포함해.

            사용자 질문:
            \(q)

            앱 데이터:
            \(context)
            """

            answer = try await client.chat(system: nil, user: prompt)
        } catch {
            err = error.localizedDescription
        }
    }

    // MARK: - Local search engine (simple)

    private func localSearch(query: String) -> [LocalHit] {
        let q = query.lowercased()

        var hits: [LocalHit] = []

        // A) Analytics sessions
        let sessions = analytics.sessions
        let sessionHits = sessions.suffix(80).compactMap { s -> LocalHit? in
            let total = max(1, s.correct + s.wrong)
            let acc = Int((Double(s.correct) / Double(total) * 100).rounded())
            let line = "\(s.game) ✅\(s.correct) ❌\(s.wrong) \(acc)% \(Int(s.durationSec.rounded()))s"
            if line.lowercased().contains(q) || s.game.lowercased().contains(q) {
                return LocalHit(title: "Session: \(s.game)", snippet: line, date: s.date)
            }
            return nil
        }
        hits.append(contentsOf: sessionHits)

        // B) Calendar events (EventKit)
        let evHits = calendarService.events.prefix(120).compactMap { ev -> LocalHit? in
            let title = ev.title ?? "(No title)"
            let notes = ev.notes ?? ""
            let line = "\(title) • \(format(ev.startDate)) ~ \(format(ev.endDate))"
            if title.lowercased().contains(q) || notes.lowercased().contains(q) {
                return LocalHit(title: "Calendar: \(title)", snippet: line, date: ev.startDate)
            }
            return nil
        }
        hits.append(contentsOf: evHits)

        // 정렬: 최신 우선, 최대 12개
        hits.sort { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
        return Array(hits.prefix(12))
    }

    private func buildContextText(hits: [LocalHit]) -> String {
        // 요약 통계도 같이 제공(최근 10회)
        let last10 = Array(analytics.sessions.suffix(10))
        let totalCorrect = last10.reduce(0) { $0 + $1.correct }
        let totalWrong = last10.reduce(0) { $0 + $1.wrong }
        let total = max(1, totalCorrect + totalWrong)
        let acc = Int((Double(totalCorrect) / Double(total) * 100).rounded())

        let rt = analytics.matchingRTStats(last: 10)
        let p50 = Int(rt.p50)

        let hitLines = hits.map { h in
            "- \(h.title): \(h.snippet)"
        }.joined(separator: "\n")

        return """
        [Summary recent10]
        correct=\(totalCorrect), wrong=\(totalWrong), acc=\(acc)%, RT_P50=\(p50)ms, sessions=\(last10.count)

        [Matches]
        \(hitLines.isEmpty ? "- (no local matches)" : hitLines)
        """
    }

    private func format(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, h:mm a"
        return f.string(from: d)
    }
}

// MARK: - LocalHit model

private struct LocalHit: Identifiable {
    let id = UUID()
    let title: String
    let snippet: String
    let date: Date?
}
