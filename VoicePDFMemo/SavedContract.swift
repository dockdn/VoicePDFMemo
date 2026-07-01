import Foundation

struct SavedContract: Identifiable, Codable {
    let id: UUID
    var title: String
    var createdAt: Date
    var fields: [String: String]
    var customerSignatureImageData: Data?
    var salespersonSignatureImageData: Data?
}
