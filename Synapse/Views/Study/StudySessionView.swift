import SwiftUI
import SwiftData

struct StudySessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager: StudySessionManager
    @State private var selectedOptionID: String?
    @State private var confidence: Confidence = .medium
    @State private var hasSubmitted = false
    @State private var showFeedback = false
    @AppStorage("lockInMode") private var lockInMode = false
    @State private var dragOffset: CGFloat = 0
    @State private var slideOut = false
    @State private var isDraggingHorizontally: Bool?
    @State private var scrollID = UUID()
    @State private var isReviewingPrevious = false
    @State private var answeredOptions: [String: String] = [:]

    let deckID: String?

    init(deckID: String? = nil, modelContext: ModelContext) {
        self.deckID = deckID
        _manager = StateObject(wrappedValue: StudySessionManager(modelContext: modelContext))
    }

    var body: some View {
        NavigationStack {
            Group {
                if manager.isSessionComplete {
                    SessionCompleteView(session: manager.session) {
                        dismiss()
                    }
                } else if isReviewingPrevious, let prevScenario = manager.previousScenario {
                    reviewView(prevScenario)
                } else if let scenario = manager.currentScenario {
                    scenarioView(scenario)
                } else {
                    emptyState
                }
            }
            .navigationTitle("Study")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("End") { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    if !manager.currentScenarios.isEmpty {
                        ProgressView(value: manager.progress)
                            .frame(width: 120)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        lockInMode.toggle()
                    } label: {
                        Image(systemName: lockInMode ? "bolt.fill" : "bolt.slash")
                            .foregroundStyle(lockInMode ? .orange : .secondary)
                    }
                }
            }
        }
        .onAppear {
            manager.startSession(deckID: deckID)
        }
    }

    @ViewBuilder
    private func scenarioView(_ scenario: Scenario) -> some View {
        ZStack(alignment: .bottom) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 20) {
                        Color.clear.frame(height: 0).id("top")

                        if showFeedback {
                            FeedbackView(
                                scenario: scenario,
                                selectedOptionID: selectedOptionID,
                                isCorrect: selectedOptionID == scenario.correctOptionID
                            ) {
                                swipeAway()
                            }
                        } else {
                            ScenarioCardView(scenario: scenario)

                            if scenario.type == .diagram || scenario.type == .hybrid,
                               let diagramData = scenario.decodedDiagramData {
                                DiagramView(data: diagramData)
                                    .frame(height: 250)
                            }

                            DecisionOptionsView(
                                options: scenario.sortedOptions,
                                selectedID: $selectedOptionID
                            )
                            .onChange(of: selectedOptionID) { _, newValue in
                                if lockInMode, newValue != nil, !hasSubmitted {
                                    submitAnswer(for: scenario)
                                }
                            }

                            // Spacer so content isn't hidden behind the bottom bar
                            if selectedOptionID != nil && !hasSubmitted && !lockInMode {
                                Color.clear.frame(height: 160)
                            }
                        }
                    }
                    .padding()
                }
                .onChange(of: scrollID) { _, _ in
                    proxy.scrollTo("top", anchor: .top)
                }
            }
            .offset(x: slideOut ? -UIScreen.main.bounds.width : dragOffset)
            .opacity(slideOut ? 0 : 1.0 - Double(abs(dragOffset)) / 500.0)
            .simultaneousGesture(
                (showFeedback || manager.currentIndex > 0)
                    ? DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            if isDraggingHorizontally == nil {
                                let horizontal = abs(value.translation.width)
                                let vertical = abs(value.translation.height)
                                if horizontal > 8 || vertical > 8 {
                                    isDraggingHorizontally = horizontal > vertical
                                }
                            }
                            if isDraggingHorizontally == true {
                                // Left swipe on feedback → advance
                                if showFeedback && value.translation.width < 0 {
                                    dragOffset = value.translation.width
                                }
                                // Right swipe → review previous
                                else if manager.currentIndex > 0 && value.translation.width > 0 {
                                    dragOffset = value.translation.width
                                }
                            }
                        }
                        .onEnded { value in
                            if isDraggingHorizontally == true {
                                if showFeedback && (value.translation.width < -80 || value.predictedEndTranslation.width < -200) {
                                    swipeAway()
                                } else if manager.currentIndex > 0 && (value.translation.width > 80 || value.predictedEndTranslation.width > 200) {
                                    enterReview()
                                } else {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        dragOffset = 0
                                    }
                                }
                            }
                            isDraggingHorizontally = nil
                        }
                    : nil
            )

            // Swipe hints
            if showFeedback && !slideOut {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.caption2)
                    Text(manager.currentIndex > 0 ? "Next" : "Swipe left to continue")
                        .font(.caption)
                    if manager.currentIndex > 0 {
                        Text("·").font(.caption)
                        Text("Review")
                            .font(.caption)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                }
                .foregroundStyle(.tertiary)
                .padding(.bottom, 8)
                .offset(x: dragOffset)
            }

            // Sticky bottom submit bar
            if selectedOptionID != nil && !hasSubmitted && !showFeedback && !lockInMode {
                VStack(spacing: 12) {
                    Divider()
                    ConfidenceSelectorView(confidence: $confidence)

                    Button {
                        submitAnswer(for: scenario)
                    } label: {
                        Label("Submit Answer", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                .background(.ultraThinMaterial)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedOptionID)
            }
        }
    }

    private func swipeAway() {
        withAnimation(.easeIn(duration: 0.2)) {
            slideOut = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            nextScenario()
            dragOffset = 0
            slideOut = false
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No Scenarios Due",
            systemImage: "checkmark.circle",
            description: Text("All caught up! Check back later for due reviews.")
        )
    }

    private func submitAnswer(for scenario: Scenario) {
        if let selected = selectedOptionID {
            answeredOptions[scenario.id] = selected
        }
        let isCorrect = selectedOptionID == scenario.correctOptionID
        manager.recordAnswer(isCorrect: isCorrect, confidence: confidence)
        hasSubmitted = true
        scrollID = UUID()
        withAnimation {
            showFeedback = true
        }
    }

    private func nextScenario() {
        selectedOptionID = nil
        confidence = .medium
        hasSubmitted = false
        showFeedback = false
        isReviewingPrevious = false
        manager.advanceToNext()
        scrollID = UUID()
    }

    private func enterReview() {
        dragOffset = 0
        withAnimation(.easeInOut(duration: 0.25)) {
            isReviewingPrevious = true
        }
    }

    private func dismissReview() {
        dragOffset = 0
        withAnimation(.easeInOut(duration: 0.25)) {
            isReviewingPrevious = false
        }
    }

    @ViewBuilder
    private func reviewView(_ scenario: Scenario) -> some View {
        ZStack(alignment: .bottom) {
            ScrollViewReader { _ in
                ScrollView {
                    VStack(spacing: 20) {
                        // Review-only badge
                        Label("Review Only", systemImage: "eye.fill")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .clipShape(Capsule())

                        ScenarioCardView(scenario: scenario)

                        if scenario.type == .diagram || scenario.type == .hybrid,
                           let diagramData = scenario.decodedDiagramData {
                            DiagramView(data: diagramData)
                                .frame(height: 250)
                        }

                        DecisionOptionsView(
                            options: scenario.sortedOptions,
                            selectedID: .constant(answeredOptions[scenario.id]),
                            correctOptionID: scenario.correctOptionID,
                            isDisabled: true
                        )
                    }
                    .padding()
                }
            }
            .offset(x: dragOffset)
            .opacity(1.0 - Double(abs(dragOffset)) / 500.0)
            .simultaneousGesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        if isDraggingHorizontally == nil {
                            let h = abs(value.translation.width)
                            let v = abs(value.translation.height)
                            if h > 8 || v > 8 {
                                isDraggingHorizontally = h > v
                            }
                        }
                        // Left swipe to return to current card
                        if isDraggingHorizontally == true && value.translation.width < 0 {
                            dragOffset = value.translation.width
                        }
                    }
                    .onEnded { value in
                        if isDraggingHorizontally == true {
                            if value.translation.width < -80 || value.predictedEndTranslation.width < -200 {
                                dismissReview()
                            } else {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    dragOffset = 0
                                }
                            }
                        }
                        isDraggingHorizontally = nil
                    }
            )

            // Return hint
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.caption2)
                Text("Swipe left to return")
                    .font(.caption)
            }
            .foregroundStyle(.tertiary)
            .padding(.bottom, 8)
            .offset(x: dragOffset)
        }
    }
}
