import Foundation
import Combine
import SwiftUI

final class ContractStore: ObservableObject {
    @Published var contracts: [SavedContract] = []
    private let fileName = "saved_contracts.json"

    init() {
        loadContracts()
    }

    @discardableResult
    func saveNewContract(
        title: String,
        fields: [String: String],
        customerSignatureImageData: Data?,
        salespersonSignatureImageData: Data?
    ) -> SavedContract {
        let contract = SavedContract(
            id: UUID(),
            title: cleanTitle(title),
            createdAt: Date(),
            fields: fields,
            customerSignatureImageData: customerSignatureImageData,
            salespersonSignatureImageData: salespersonSignatureImageData
        )

        contracts.insert(contract, at: 0)
        saveToDisk()
        return contract
    }

    func updateContract(
        id: UUID,
        title: String,
        fields: [String: String],
        customerSignatureImageData: Data?,
        salespersonSignatureImageData: Data?
    ) {
        guard let index = contracts.firstIndex(where: { $0.id == id }) else { return }

        contracts[index].title = cleanTitle(title)
        contracts[index].fields = fields
        contracts[index].customerSignatureImageData = customerSignatureImageData
        contracts[index].salespersonSignatureImageData = salespersonSignatureImageData

        saveToDisk()
    }

    func deleteContract(id: UUID) {
        contracts.removeAll { $0.id == id }
        saveToDisk()
    }

    func deleteContract(at offsets: IndexSet) {
        contracts.remove(atOffsets: offsets)
        saveToDisk()
    }

    private func cleanTitle(_ title: String) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Untitled Contract" : trimmed
    }

    // MARK: - Disk Storage
    private func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(contracts)
            try data.write(to: fileURL())
        } catch {
            print("Save error: \(error.localizedDescription)")
        }
    }

    private func loadContracts() {
        do {
            let data = try Data(contentsOf: fileURL())
            contracts = try JSONDecoder().decode([SavedContract].self, from: data)
        } catch {
            contracts = []
        }
    }

    private func fileURL() -> URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }
}
