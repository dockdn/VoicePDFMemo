import SwiftUI

struct ContractEditorView: View {
    let contract: SavedContract?
    @ObservedObject var contractStore: ContractStore

    @StateObject private var speechManager = SpeechManager()

    @State private var contractID: UUID?
    @State private var contractTitle: String
    @State private var selectedField: String = "entry"
    @State private var fields: [String: String]
    @State private var saveMessage: String = ""
    @State private var inputMode: String = "Type"
    @State private var recordingBaseText: String = ""

    @State private var customerSignatureImageData: Data?
    @State private var salespersonSignatureImageData: Data?
    @State private var signatureType: String = "customer"

    @State private var showingSignaturePad = false
    @State private var showingShareSheet = false
    @State private var exportURL: URL?

    init(contract: SavedContract?, contractStore: ContractStore) {
        self.contract = contract
        self.contractStore = contractStore

        _contractID = State(initialValue: contract?.id)
        _contractTitle = State(initialValue: contract?.title ?? "")

        var startingFields = ContractField.defaultFields
        if let savedFields = contract?.fields {
            for (key, value) in savedFields {
                startingFields[key] = value
            }
        }

        _fields = State(initialValue: startingFields)
        _customerSignatureImageData = State(initialValue: contract?.customerSignatureImageData)
        _salespersonSignatureImageData = State(initialValue: contract?.salespersonSignatureImageData)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                headerCard
                contractInfoCard
                entryAgreementCard
                datesCard
                paymentCard
                bottomPaymentScheduleCard
                signaturesCard
                actionButtons

                if !saveMessage.isEmpty {
                    Text(saveMessage)
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
            .padding()
        }
        .navigationTitle(contractID == nil ? "New Contract" : "Edit Contract")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            speechManager.requestPermissions()
        }
        .onChange(of: speechManager.transcribedText) { newValue in
            let spokenText = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !spokenText.isEmpty else { return }

            fields[selectedField] = combinedText(
                base: recordingBaseText,
                addition: newValue
            )
        }
        .sheet(isPresented: $showingSignaturePad) {
            signatureSheet
        }
        .sheet(isPresented: $showingShareSheet) {
            if let exportURL {
                ShareSheet(activityItems: [exportURL])
            }
        }
    }

    private var headerCard: some View {
        VStack(spacing: 6) {
            Text("Panther Siding & Windows Inc.")
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)

            Text("1786 Newbridge Road\nNorth Bellmore, NY 11710")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Text("CONTRACT")
                .font(.headline)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private var contractInfoCard: some View {
        card(title: "Customer Information") {
            labeledTextField("Contract Title", text: $contractTitle)
            fieldTextField("To", id: "to")
            fieldTextField("Date", id: "date")
            fieldTextField("Premises Address", id: "address")
            fieldTextField("Home #", id: "home")
            fieldTextField("Cell #", id: "cell")
            fieldTextField("Email", id: "email")
        }
    }

    private var entryAgreementCard: some View {
        card(title: "Entry Agreement") {
            Text("The contractor shall be held responsible only for that which is expressly written on original agreement.")
                .font(.caption)
                .foregroundColor(.secondary)

            Picker("Input Mode", selection: $inputMode) {
                Text("Type").tag("Type")
                Text("Record").tag("Record")
            }
            .pickerStyle(.segmented)

            if inputMode == "Type" {
                TextEditor(text: binding(for: "entry"))
                    .frame(minHeight: 180)
                    .padding(8)
                    .background(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.25))
                    )
                    .onTapGesture {
                        selectedField = "entry"
                    }
            } else {
                VStack(spacing: 10) {
                    Text(fields["entry"] ?? "")
                        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)

                    Button {
                        selectedField = "entry"

                        if speechManager.isRecording {
                            let finalText = speechManager.transcribedText.trimmingCharacters(in: .whitespacesAndNewlines)

                            if !finalText.isEmpty {
                                fields[selectedField] = combinedText(
                                    base: recordingBaseText,
                                    addition: speechManager.transcribedText
                                )
                            }

                            speechManager.stopRecording()
                        } else {
                            recordingBaseText = fields[selectedField] ?? ""
                            speechManager.transcribedText = ""
                            speechManager.startRecording()
                        }
                    } label: {
                        Text(speechManager.isRecording ? "Stop Recording" : "Record Entry Agreement")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(speechManager.isRecording ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
            }
        }
    }

    private var datesCard: some View {
        card(title: "Project Dates") {
            dateField("Approximate Start Date", id: "startDate")
            dateField("Approximate Completion Date", id: "completionDate")
        }
    }

    private var paymentCard: some View {
        card(title: "Contract Subject to Office Approval") {
            fieldTextField("Total Cost of Work", id: "totalCost", keyboard: .decimalPad)
            fieldTextField("Deposit", id: "deposit", keyboard: .decimalPad)
            fieldTextField("Paid on Delivery of Material", id: "paidDelivery", keyboard: .decimalPad)
            fieldTextField("Amount to be Financed", id: "financed", keyboard: .decimalPad)
            fieldTextField("Balance on Completion", id: "balance", keyboard: .decimalPad)
        }
    }

    private var bottomPaymentScheduleCard: some View {
        card(title: "Progress Payments") {
            twoColumnMoneyRow("Down Payment", amountID: "downPayment", percentID: "downPaymentPercent")
            twoColumnMoneyRow("On Ordering Materials", amountID: "materials", percentID: "materialsPercent")
            twoColumnMoneyRow("On Beginning Work", amountID: "beginWork", percentID: "beginWorkPercent")
            twoColumnMoneyRow("On % Completion", amountID: "completionPercent", percentID: "completionPercentValue")
            twoColumnMoneyRow("To be financed upon completion", amountID: "financeCompletion", percentID: "financeCompletionPercent")
        }
    }

    private var signaturesCard: some View {
        card(title: "Signatures") {
            fieldTextField("Print Salesman's Name", id: "salesperson")
            fieldTextField("Salesperson License #", id: "license")

            HStack {
                Button("Salesperson Signature") {
                    signatureType = "salesperson"
                    showingSignaturePad = true
                }
                .buttonStyle(.bordered)

                Spacer()

                if salespersonSignatureImageData != nil {
                    Text("Signed")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            HStack {
                Button("Customer Agreement Signature") {
                    signatureType = "customer"
                    showingSignaturePad = true
                }
                .buttonStyle(.bordered)

                Spacer()

                if customerSignatureImageData != nil {
                    Text("Signed")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button("Save Contract") {
                saveContract()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)

            Button("Export PDF") {
                exportPDF()
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)

            Button("Fill Demo") {
                fillDemoData()
            }
            .buttonStyle(.bordered)
            .foregroundColor(.secondary)
        }
    }

    private var signatureSheet: some View {
        NavigationStack {
            VStack {
                Text(signatureType == "customer" ? "Customer Agreement Signature" : "Salesperson Signature")
                    .font(.headline)
                    .padding(.top)

                SignatureCaptureView(
                    signatureImageData: signatureType == "customer"
                        ? $customerSignatureImageData
                        : $salespersonSignatureImageData
                )
                .frame(height: 300)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.4))
                )
                .padding()

                Button("Clear Signature") {
                    if signatureType == "customer" {
                        customerSignatureImageData = nil
                    } else {
                        salespersonSignatureImageData = nil
                    }
                }
                .foregroundColor(.red)

                Spacer()
            }
            .navigationTitle("Signature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showingSignaturePad = false
                    }
                }
            }
        }
    }

    private func card<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private func labeledTextField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            TextField(label, text: text)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func fieldTextField(_ label: String, id: String, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            TextField(label, text: binding(for: id))
                .textFieldStyle(.roundedBorder)
                .keyboardType(keyboard)
                .onTapGesture {
                    selectedField = id
                }
        }
    }

    private func dateField(_ label: String, id: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            DatePicker(
                label,
                selection: dateBinding(for: id),
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .frame(maxWidth: .infinity, alignment: .leading)
            .onTapGesture {
                selectedField = id
            }
        }
    }

    private func twoColumnMoneyRow(_ label: String, amountID: String, percentID: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                TextField("$", text: binding(for: amountID))
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)

                TextField("%", text: binding(for: percentID))
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
                    .frame(width: 90)
            }
        }
    }

    private func binding(for id: String) -> Binding<String> {
        Binding(
            get: { fields[id] ?? "" },
            set: { fields[id] = $0 }
        )
    }

    private func dateBinding(for id: String) -> Binding<Date> {
        Binding(
            get: { parsedDate(from: fields[id]) ?? Date() },
            set: {
                fields[id] = Self.contractDateFormatter.string(from: $0)
                selectedField = id
            }
        )
    }

    private func parsedDate(from value: String?) -> Date? {
        let trimmed = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        for formatter in Self.contractDateParsers {
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }

        return nil
    }

    private func combinedText(base: String, addition: String) -> String {
        let cleanedBase = base.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedAddition = addition.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanedBase.isEmpty { return cleanedAddition }
        if cleanedAddition.isEmpty { return cleanedBase }

        return cleanedBase + " " + cleanedAddition
    }

    private func saveContract() {
        let fallbackTitle = fields["to"]?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? fields["to"]!
            : "Panther Contract"

        let finalTitle = contractTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? fallbackTitle
            : contractTitle

        if let contractID {
            contractStore.updateContract(
                id: contractID,
                title: finalTitle,
                fields: fields,
                customerSignatureImageData: customerSignatureImageData,
                salespersonSignatureImageData: salespersonSignatureImageData
            )
            saveMessage = "Updated!"
        } else {
            let saved = contractStore.saveNewContract(
                title: finalTitle,
                fields: fields,
                customerSignatureImageData: customerSignatureImageData,
                salespersonSignatureImageData: salespersonSignatureImageData
            )
            contractID = saved.id
            saveMessage = "Saved!"
        }
    }

    private func exportPDF() {
        saveContract()

        let finalTitle = contractTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? (fields["to"] ?? "Panther Contract")
            : contractTitle

        exportURL = PDFExporter.exportContract(
            title: finalTitle,
            fields: fields,
            customerSignatureImageData: customerSignatureImageData,
            salespersonSignatureImageData: salespersonSignatureImageData
        )

        if exportURL != nil {
            showingShareSheet = true
        }
    }

    private func fillDemoData() {
        contractTitle = "Anthony Gearity - Roofing"
        fields["to"] = "Anthony Gearity"
        fields["date"] = "6/18/26"
        fields["address"] = "123 Avenue, Wantagh, NY"
        fields["home"] = "516-555-1234"
        fields["cell"] = "516-555-9876"
        fields["email"] = "customer@email.com"
        fields["entry"] = "Remove existing roofing materials. Install new underlayment, flashing, drip edge, and architectural shingles. Clean up and remove all debris upon completion."
        fields["startDate"] = "7/1/26"
        fields["completionDate"] = "7/3/26"
        fields["totalCost"] = "$14,500"
        fields["deposit"] = "$2,500"
        fields["paidDelivery"] = "$5,000"
        fields["financed"] = "$0"
        fields["balance"] = "$7,000"
        fields["salesperson"] = "Jimmy"
        fields["license"] = "0988279NYC"
        fields["downPayment"] = "$2,500"
        fields["downPaymentPercent"] = "17%"
        fields["materials"] = "$5,000"
        fields["materialsPercent"] = "34%"
        fields["beginWork"] = "$2,000"
        fields["beginWorkPercent"] = "14%"
        fields["completionPercent"] = "$5,000"
        fields["completionPercentValue"] = "35%"
        fields["financeCompletion"] = "$0"
        fields["financeCompletionPercent"] = "0%"
    }

    private static let contractDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "M/d/yy"
        return formatter
    }()

    private static let contractDateParsers: [DateFormatter] = {
        let formats = [
            "M/d/yy",
            "M/d/yyyy",
            "MM/dd/yy",
            "MM/dd/yyyy"
        ]

        return formats.map { format in
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.dateFormat = format
            return formatter
        }
    }()
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
