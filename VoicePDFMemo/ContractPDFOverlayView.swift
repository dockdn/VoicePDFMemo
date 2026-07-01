import SwiftUI
import PDFKit

struct ContractPDFOverlayView: View {
    @Binding var fields: [String: String]
    @Binding var selectedField: String
    var customerSignatureImageData: Data?
    var salespersonSignatureImageData: Data?

    private var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }

    var body: some View {
        GeometryReader { geometry in
            let pageWidth = geometry.size.width
            let pageHeight = pageWidth * 1.53

            ScrollView {
                ZStack(alignment: .topLeading) {
                    PDFTemplateImage()
                        .frame(width: pageWidth, height: pageHeight)
                        .clipped()
                        .allowsHitTesting(false)

                    ForEach(ContractField.fields) { field in
                        ContractFieldButton(
                            field: field,
                            value: fields[field.id] ?? "",
                            isSelected: selectedField == field.id,
                            pageWidth: pageWidth,
                            pageHeight: pageHeight
                        ) {
                            selectedField = field.id
                        }
                    }

                    if let salespersonSignatureImageData,
                       let image = UIImage(data: salespersonSignatureImageData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(
                                width: pageWidth * 0.22,
                                height: pageHeight * 0.030
                            )
                            .position(
                                x: pageWidth * 0.331,
                                y: pageHeight * 0.733
                            )
                            .allowsHitTesting(false)
                    }

                    if let customerSignatureImageData,
                       let image = UIImage(data: customerSignatureImageData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(
                                width: pageWidth * 0.24,
                                height: pageHeight * 0.032
                            )
                            .position(
                                x: pageWidth * 0.678,
                                y: pageHeight * 0.752
                            )
                            .allowsHitTesting(false)
                    }
                }
                .frame(width: pageWidth, height: pageHeight)
            }
        }
    }
}

struct PDFTemplateImage: View {
    var body: some View {
        if let image = renderPDFPage() {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .allowsHitTesting(false)
        } else {
            Text("PDF not found")
                .foregroundColor(.red)
                .font(.headline)
        }
    }

    private func renderPDFPage() -> UIImage? {
        guard let url = Bundle.main.url(
            forResource: "PantherEntryAgreement",
            withExtension: "pdf"
        ),
        let document = PDFDocument(url: url),
        let page = document.page(at: 0) else {
            return nil
        }

        let pageRect = page.bounds(for: .mediaBox)
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)

        return renderer.image { context in
            UIColor.white.set()
            context.fill(pageRect)
            context.cgContext.translateBy(x: 0, y: pageRect.height)
            context.cgContext.scaleBy(x: 1, y: -1)
            page.draw(with: .mediaBox, to: context.cgContext)
        }
    }
}

struct ContractFieldButton: View {
    let field: ContractField
    let value: String
    let isSelected: Bool
    let pageWidth: CGFloat
    let pageHeight: CGFloat
    let action: () -> Void

    private var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }

    private var tapWidth: CGFloat {
        isPhone ? max(field.width * pageWidth, 44) : max(field.width * pageWidth, 70)
    }

    private var tapHeight: CGFloat {
        isPhone ? max(field.height * pageHeight, 28) : max(field.height * pageHeight, 38)
    }

    private var yOffset: CGFloat {
        isPhone ? 0.006 : 0
    }

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: tapWidth, height: tapHeight)

                RoundedRectangle(cornerRadius: 2)
                    .fill(isSelected ? Color.blue.opacity(0.08) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(
                                isSelected ? Color.blue.opacity(0.85) : Color.clear,
                                lineWidth: isSelected ? 1.5 : 0
                            )
                    )
                    .frame(
                        width: field.width * pageWidth,
                        height: field.height * pageHeight
                    )

                Text(value)
                    .font(.system(size: field.fontSize))
                    .foregroundColor(.black)
                    .lineLimit(field.multiline ? 12 : 1)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(field.multiline ? 4 : 0)
                    .minimumScaleFactor(0.65)
                    .padding(.horizontal, 4)
                    .padding(.vertical, field.multiline ? 6 : 2)
                    .frame(
                        width: field.width * pageWidth,
                        height: field.height * pageHeight,
                        alignment: .topLeading
                    )
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .frame(width: tapWidth, height: tapHeight)
        .position(
            x: field.x * pageWidth,
            y: (field.y + yOffset) * pageHeight
        )
    }
}
