import SwiftUI

struct ContractField: Identifiable {
    let id: String
    let name: String
    let placeholder: String
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
    let fontSize: CGFloat
    let multiline: Bool

    static let fields: [ContractField] = [
        ContractField(id: "to", name: "To", placeholder: "To", x: 0.3570, y: 0.2140, width: 0.42, height: 0.02, fontSize: 10.0, multiline: false),
        ContractField(id: "date", name: "Date", placeholder: "Date", x: 0.7800, y: 0.2140, width: 0.25, height: 0.02, fontSize: 10.0, multiline: false),
        ContractField(id: "address", name: "Premises Address", placeholder: "Address", x: 0.4770, y: 0.2370, width: 0.44, height: 0.02, fontSize: 10.0, multiline: false),
        ContractField(id: "home", name: "Home #", placeholder: "Home", x: 0.7800, y: 0.2370, width: 0.25, height: 0.02, fontSize: 10.0, multiline: false),
        ContractField(id: "cell", name: "Cell #", placeholder: "Cell", x: 0.7800, y: 0.2560, width: 0.25, height: 0.02, fontSize: 10.0, multiline: false),
        ContractField(id: "email", name: "Email", placeholder: "Email", x: 0.7200, y: 0.2810, width: 0.3, height: 0.02, fontSize: 10.0, multiline: false),

        ContractField(id: "entry", name: "Entry Agreement Notes", placeholder: "Entry Agreement", x: 0.5270, y: 0.4060, width: 0.78, height: 0.205, fontSize: 8.5, multiline: true),

        ContractField(id: "startDate", name: "Approximate Start Date", placeholder: "Start", x: 0.4320, y: 0.5380, width: 0.28, height: 0.018, fontSize: 9.0, multiline: false),
        ContractField(id: "completionDate", name: "Approximate Completion Date", placeholder: "Completion", x: 0.4790, y: 0.5550, width: 0.3, height: 0.018, fontSize: 9.0, multiline: false),

        ContractField(id: "totalCost", name: "Total Cost", placeholder: "Total", x: 0.8220, y: 0.5970, width: 0.18, height: 0.018, fontSize: 8.5, multiline: false),
        ContractField(id: "deposit", name: "Deposit", placeholder: "Deposit", x: 0.8220, y: 0.6110, width: 0.18, height: 0.018, fontSize: 8.5, multiline: false),
        ContractField(id: "paidDelivery", name: "Paid on Delivery", placeholder: "Paid", x: 0.8220, y: 0.6250, width: 0.18, height: 0.018, fontSize: 8.5, multiline: false),
        ContractField(id: "financed", name: "Amount Financed", placeholder: "Financed", x: 0.8220, y: 0.6420, width: 0.18, height: 0.018, fontSize: 8.5, multiline: false),
        ContractField(id: "balance", name: "Balance on Completion", placeholder: "Balance", x: 0.8190, y: 0.6530, width: 0.18, height: 0.018, fontSize: 8.5, multiline: false),

        ContractField(id: "salesperson", name: "Salesperson Name", placeholder: "Salesperson", x: 0.4040, y: 0.7220, width: 0.28, height: 0.018, fontSize: 8.5, multiline: false),
        ContractField(id: "license", name: "Salesperson License #", placeholder: "License", x: 0.3860, y: 0.7600, width: 0.28, height: 0.018, fontSize: 8.5, multiline: false),

        ContractField(id: "downPayment", name: "Down Payment", placeholder: "$", x: 0.3940, y: 0.8590, width: 0.11, height: 0.014, fontSize: 7.5, multiline: false),
        ContractField(id: "downPaymentPercent", name: "Down Payment %", placeholder: "%", x: 0.4920, y: 0.8590, width: 0.08, height: 0.014, fontSize: 7.5, multiline: false),
        ContractField(id: "materials", name: "On Ordering Materials", placeholder: "$", x: 0.3910, y: 0.8680, width: 0.11, height: 0.014, fontSize: 7.5, multiline: false),
        ContractField(id: "materialsPercent", name: "Materials %", placeholder: "%", x: 0.4920, y: 0.8680, width: 0.08, height: 0.014, fontSize: 7.5, multiline: false),
        ContractField(id: "beginWork", name: "On Beginning Work", placeholder: "$", x: 0.3910, y: 0.8770, width: 0.11, height: 0.014, fontSize: 7.5, multiline: false),
        ContractField(id: "beginWorkPercent", name: "Beginning Work %", placeholder: "%", x: 0.4920, y: 0.8770, width: 0.08, height: 0.014, fontSize: 7.5, multiline: false),
        ContractField(id: "completionPercent", name: "On % Completion", placeholder: "$", x: 0.3910, y: 0.8860, width: 0.11, height: 0.014, fontSize: 7.5, multiline: false),
        ContractField(id: "completionPercentValue", name: "% Completion", placeholder: "%", x: 0.4920, y: 0.8860, width: 0.08, height: 0.014, fontSize: 7.5, multiline: false),
        ContractField(id: "financeCompletion", name: "To Be Financed Upon Completion", placeholder: "$", x: 0.3910, y: 0.8920, width: 0.11, height: 0.014, fontSize: 7.5, multiline: false),
        ContractField(id: "financeCompletionPercent", name: "Financed Completion %", placeholder: "%", x: 0.4920, y: 0.8920, width: 0.08, height: 0.014, fontSize: 7.5, multiline: false)
    ]

    static var defaultFields: [String: String] {
        Dictionary(uniqueKeysWithValues: fields.map { ($0.id, "") })
    }

    static func displayName(for id: String) -> String {
        fields.first(where: { $0.id == id })?.name ?? id
    }
}
