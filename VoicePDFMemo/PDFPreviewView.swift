import SwiftUI
import PDFKit

struct PDFPreviewView: UIViewRepresentable {
    let pdfName: String

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .vertical

        if let url = Bundle.main.url(forResource: pdfName, withExtension: "pdf"),
           let document = PDFDocument(url: url) {
            pdfView.document = document
        }

        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}
}
