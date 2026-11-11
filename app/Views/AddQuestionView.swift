import SwiftUI
import SwiftData

/// Form for adding your own Quick Pick or Fill the Blank question.
struct AddQuestionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    enum Kind: String, CaseIterable {
        case multipleChoice = "Quick Pick"
        case fillBlank = "Fill the Blank"
    }

    @State private var kind: Kind = .multipleChoice
    @State private var subject: Subject = .python
    @State private var prompt = ""
    @State private var code = ""
    @State private var choices = ["", "", "", ""]
    @State private var correctIndex = 0
    @State private var acceptedAnswers = ""
    @State private var explanation = ""

    /// Choices that were filled in, with their original positions.
    private var filled: [(index: Int, text: String)] {
        choices.enumerated()
            .map { ($0.offset, $0.element.trimmingCharacters(in: .whitespaces)) }
            .filter { !$0.1.isEmpty }
    }

    private var answerLines: [String] {
        acceptedAnswers.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    private var canSave: Bool {
        guard !prompt.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        switch kind {
        case .multipleChoice:
            return filled.count >= 2 && filled.contains { $0.index == correctIndex }
        case .fillBlank:
            return (code.contains("___") || prompt.contains("___")) && !answerLines.isEmpty
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Type", selection: $kind) {
                    ForEach(Kind.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.segmented)

                Picker("Subject", selection: $subject) {
                    ForEach(Subject.allCases) { Label($0.displayName, systemImage: $0.icon).tag($0) }
                }

                Section("Question") {
                    TextField("e.g. What does this print?", text: $prompt, axis: .vertical)
                }

                Section {
                    TextEditor(text: $code)
                        .font(.system(.callout, design: .monospaced))
                        .frame(minHeight: 80)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text(kind == .fillBlank ? "Code: put ___ where the blank goes" : "Code (optional)")
                } footer: {
                    if kind == .fillBlank {
                        Button("Insert ___") { code += "___" }
                    }
                }

                switch kind {
                case .multipleChoice:
                    Section("Choices: tap the circle next to the right one") {
                        ForEach(choices.indices, id: \.self) { i in
                            HStack {
                                Button {
                                    correctIndex = i
                                } label: {
                                    Image(systemName: correctIndex == i ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(correctIndex == i ? .green : .secondary)
                                }
                                .buttonStyle(.plain)
                                TextField("Choice \(i + 1)", text: $choices[i])
                            }
                        }
                    }
                case .fillBlank:
                    Section {
                        TextEditor(text: $acceptedAnswers)
                            .font(.system(.callout, design: .monospaced))
                            .frame(minHeight: 60)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    } header: {
                        Text("Accepted answers: one per line")
                    } footer: {
                        Text("Spacing doesn't matter when checking. The first line is shown as the solution.")
                    }
                }

                Section("Explanation") {
                    TextField("Why is it right?", text: $explanation, axis: .vertical)
                }
            }
            .navigationTitle("New Question")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(role: .close) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save", role: .confirm, action: save).disabled(!canSave) }
            }
        }
    }

    private func save() {
        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        let why = explanation.isEmpty ? "No explanation added." : explanation
        let question: Question
        switch kind {
        case .multipleChoice:
            question = Question(subject: subject, kind: .multipleChoice,
                                prompt: prompt.trimmingCharacters(in: .whitespaces),
                                code: trimmedCode.isEmpty ? nil : trimmedCode,
                                choices: filled.map(\.text),
                                correctIndex: filled.firstIndex { $0.index == correctIndex } ?? 0,
                                explanation: why, isUserCreated: true)
        case .fillBlank:
            question = Question(subject: subject, kind: .fillBlank,
                                prompt: prompt.trimmingCharacters(in: .whitespaces),
                                code: trimmedCode.isEmpty ? nil : trimmedCode,
                                answers: answerLines,
                                explanation: why, isUserCreated: true)
        }
        context.insert(question)
        try? context.save()
        dismiss()
    }
}
