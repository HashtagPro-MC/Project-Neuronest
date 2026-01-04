import SwiftUI

struct SurveyView: View {
    @StateObject private var vm = SurveyViewModel()

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Survey / Chat Analyzer")
                        .font(.system(size: 26, weight: .heavy))

                    Text("여기에 분석할 채팅을 붙여넣고, Cohere로 분석해.")
                        .foregroundStyle(.secondary)

                    TextEditor(text: $vm.chatText)
                        .frame(minHeight: 220)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.secondarySystemBackground))
                        )

                    Button {
                        Task { await vm.analyze() }
                    } label: {
                        HStack {
                            Spacer()
                            if vm.isLoading {
                                ProgressView().padding(.trailing, 6)
                            }
                            Text(vm.isLoading ? "Analyzing..." : "Analyze with Cohere")
                                .font(.system(size: 16, weight: .semibold))
                            Spacer()
                        }
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(vm.isLoading)

                    if let msg = vm.errorMessage {
                        Text(msg)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }

                    if !vm.resultText.isEmpty {
                        Text("Result")
                            .font(.system(size: 18, weight: .bold))
                            .padding(.top, 6)

                        Text(vm.resultText)
                            .font(.system(size: 15))
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(.secondarySystemBackground))
                            )
                    }
                }
                .padding(16)
            }
        }
    }
}
