import SwiftUI

struct PinEditorSheet: View {
    @EnvironmentObject private var store: BoardStore
    @Environment(\.dismiss) private var dismiss

    var existing: WorkPin?

    @State private var title: String = ""
    @State private var dueDate: Date = Date()
    @State private var category: PinCategory = .work
    @State private var priority: PinPriority = .normal
    @State private var errorText: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    StickyNote {
                        VStack(alignment: .leading, spacing: 12) {
                            labeledField("Title") {
                                TextField("What needs focus?", text: $title)
                                    .foregroundColor(Color.white)
                                    .submitLabel(.done)
                                    .onSubmit { BoardKeyboard.dismiss() }
                            }

                            labeledField("Due") {
                                DatePicker("", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                                    .labelsHidden()
                                    .colorScheme(.dark)
                                    .font(.system(.body, design: .monospaced))
                            }

                            labeledField("Category") {
                                Picker("Category", selection: $category) {
                                    ForEach(PinCategory.allCases) { item in
                                        Text(item.rawValue).tag(item)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }

                            labeledField("Priority") {
                                Picker("Priority", selection: $priority) {
                                    ForEach(PinPriority.allCases) { item in
                                        Text(item.label).tag(item)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }

                            if !errorText.isEmpty {
                                Text(errorText)
                                    .font(.footnote.weight(.semibold))
                                    .foregroundColor(Palette.accent)
                            }
                        }
                    }
                }
                .padding(18)
            }
            .studioBackdrop()
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle(existing == nil ? "New Pin" : "Edit Pin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Palette.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Pin") { save() }
                        .fontWeight(.bold)
                        .foregroundColor(Palette.accent)
                }
            }
            .onAppear(perform: hydrate)
        }
    }

    private func labeledField<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.caption.weight(.bold))
                .foregroundColor(Palette.accent)
            content()
        }
    }

    private func hydrate() {
        guard let existing else { return }
        title = existing.title
        dueDate = existing.dueDate
        category = existing.category
        priority = existing.priority
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            errorText = "All fields are required."
            return
        }
        errorText = ""
        let pin = WorkPin(
            id: existing?.id ?? UUID(),
            title: trimmed,
            dueDate: dueDate,
            category: category,
            priority: priority,
            completedAt: existing?.completedAt
        )
        store.upsertTask(pin)
        dismiss()
    }
}
