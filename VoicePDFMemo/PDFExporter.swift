import Foundation
import SwiftUI
import PDFKit

enum PDFExporter {
    static func exportContract(
        title: String,
        fields: [String: String],
        customerSignatureImageData: Data?,
        salespersonSignatureImageData: Data?
    ) -> URL? {
        let safeFileName = cleanFileName(title.isEmpty ? "Panther_Contract" : title)
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(safeFileName).pdf")

        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        do {
            try renderer.writePDF(to: outputURL) { context in
                context.beginPage()

                drawContract(
                    in: pageRect,
                    fields: fields,
                    customerSignatureImageData: customerSignatureImageData,
                    salespersonSignatureImageData: salespersonSignatureImageData
                )
            }

            return outputURL
        } catch {
            print("PDF export error: \(error.localizedDescription)")
            return nil
        }
    }

    private static func drawContract(
        in pageRect: CGRect,
        fields: [String: String],
        customerSignatureImageData: Data?,
        salespersonSignatureImageData: Data?
    ) {
        let margin: CGFloat = 42
        var y: CGFloat = 28
        let contentWidth = pageRect.width - margin * 2

        UIColor.white.setFill()
        UIRectFill(pageRect)

        drawText("Panther Siding & Windows Inc.", x: margin, y: y, width: contentWidth, fontSize: 22, bold: true, alignment: .center)
        y += 26
        drawText("1786 Newbridge Road • North Bellmore, NY 11710", x: margin, y: y, width: contentWidth, fontSize: 12, alignment: .center)
        y += 16
        drawText("516-479-6660 • 718-340-2325", x: margin, y: y, width: contentWidth, fontSize: 12, alignment: .center)
        y += 20
        drawText("CONTRACT", x: margin, y: y, width: contentWidth, fontSize: 16, bold: true, alignment: .center)
        y += 32

        drawLineField(label: "To:", value: fields["to"], x: margin, y: y, width: 310)
        drawLineField(label: "Date:", value: fields["date"], x: 390, y: y, width: 180)
        y += 28

        drawLineField(label: "On Premises Located at:", value: fields["address"], x: margin, y: y, width: 310)
        drawLineField(label: "Home #:", value: fields["home"], x: 390, y: y, width: 180)
        y += 28

        drawLineField(label: "Cell #:", value: fields["cell"], x: 390, y: y, width: 180)
        y += 28

        drawLineField(label: "Email:", value: fields["email"], x: 390, y: y, width: 180)
        y += 36

        drawText("ENTRY AGREEMENT:", x: margin, y: y, width: contentWidth, fontSize: 17, bold: true)
        y += 24

        drawText(
            "The contractor shall be held responsible only for that which is expressly written on original agreement.",
            x: margin,
            y: y,
            width: contentWidth,
            fontSize: 9
        )
        y += 18

        let entryBox = CGRect(x: margin, y: y, width: contentWidth, height: 150)
        drawBox(entryBox)
        drawText(fields["entry"] ?? "", x: entryBox.minX + 8, y: entryBox.minY + 8, width: entryBox.width - 16, fontSize: 10)
        y += 166

        drawLineField(label: "Approximate Start Date:", value: fields["startDate"], x: margin, y: y, width: contentWidth)
        y += 24
        drawLineField(label: "Approximate Completion Date:", value: fields["completionDate"], x: margin, y: y, width: contentWidth)
        y += 34

        drawText("CONTRACT SUBJECT TO OFFICE APPROVAL", x: margin, y: y, width: contentWidth, fontSize: 13, bold: true, alignment: .center)
        y += 24

        drawText("CONTRACTOR WILL PROVIDE A CERTIFICATE OF WORKMANS\nCOMPENSATION PRIOR TO STARTING WORK", x: margin, y: y, width: 290, fontSize: 9, bold: true)

        let tableX: CGFloat = 360
        let tableY = y - 4
        let rowH: CGFloat = 18
        let labelW: CGFloat = 135
        let valueW: CGFloat = 72

        let paymentRows: [(String, String)] = [
            ("Total Cost of Work", fields["totalCost"] ?? ""),
            ("Deposit", fields["deposit"] ?? ""),
            ("Paid on Delivery of Material", fields["paidDelivery"] ?? ""),
            ("Amount to be Financed", fields["financed"] ?? ""),
            ("Balance on Completion", fields["balance"] ?? "")
        ]

        for index in 0..<paymentRows.count {
            let rowY = tableY + CGFloat(index) * rowH
            drawRect(CGRect(x: tableX, y: rowY, width: labelW, height: rowH))
            drawRect(CGRect(x: tableX + labelW, y: rowY, width: valueW, height: rowH))
            drawText(paymentRows[index].0, x: tableX + 5, y: rowY + 4, width: labelW - 8, fontSize: 8)
            drawText(paymentRows[index].1, x: tableX + labelW + 5, y: rowY + 4, width: valueW - 8, fontSize: 8)
        }

        y += 110

        drawText("CANCELLATION:", x: margin, y: y, width: contentWidth, fontSize: 11, bold: true)
        y += 22

        drawText(
            "“YOU THE BUYER, MAY CANCEL THIS TRANSACTION AT ANY TIME PRIOR TO MIDNIGHT\nOF THE THIRD BUSINESS DAY AFTER THE DATE OF THIS TRANSACTION. SEE ATTACHED\nNOTICE OF CANCELLATION FORM FOR AN EXPLANATION OF THIS RIGHT.”",
            x: margin,
            y: y,
            width: contentWidth,
            fontSize: 10,
            bold: true,
            alignment: .center
        )
        y += 56

        drawLineField(label: "Print Salesman's Name:", value: fields["salesperson"], x: margin, y: y, width: 250)
        y += 28

        drawText("Salesman Signature:", x: margin, y: y + 5, width: 120, fontSize: 9, bold: true)
        drawSignature(data: salespersonSignatureImageData, rect: CGRect(x: margin + 125, y: y - 8, width: 150, height: 32))
        drawLine(x1: margin + 125, y1: y + 24, x2: margin + 275, y2: y + 24)
        y += 32

        drawLineField(label: "Salesman Lic.#:", value: fields["license"], x: margin, y: y, width: 250)

        let customerSigY = y - 32
        drawText(
            "I (we) have read and signed this contract and nothing\nother than is set forth herein has been promised",
            x: 340,
            y: customerSigY - 16,
            width: 190,
            fontSize: 7,
            bold: true,
            alignment: .center
        )
        drawSignature(data: customerSignatureImageData, rect: CGRect(x: 340, y: customerSigY + 2, width: 190, height: 34))
        drawLine(x1: 340, y1: customerSigY + 38, x2: 530, y2: customerSigY + 38)

        y += 36

        drawText(
            "Notice of Lien: Whether or not any mortgage may be given on the property to be improved, Seller or any subcontractor who performs work and is not paid may have a claim against you which may be enforced against the property in accordance with applicable law.",
            x: margin,
            y: y,
            width: contentWidth,
            fontSize: 6.8
        )
        y += 26

        drawText(
            "Deposit of Payments: Seller is required by law to deposit all monies received from you under the Contract prior to completion of the work in an escrow account in trust for you or to post a surety bond or indemnity contract with you guaranteeing the return of proper application of such monies.",
            x: margin,
            y: y,
            width: contentWidth,
            fontSize: 6.8
        )
        y += 30

        drawText(
            "Progress Payments: If the Contract provides only for a Down Payment to be paid before commencement of any work, it will be held in an escrow account until the work is substantially complete. Upon completion of the work, the remaining balance of the sale price will be financed on an installment sale basis as set forth in the Retail Installment Obligation.",
            x: margin,
            y: y,
            width: contentWidth,
            fontSize: 6.8
        )
        y += 38

        drawText(
            "If the Contract provides for a Down Payment and one or more progress payments to be paid to Seller prior to substantial completion of the work, the following schedule identifies the amount of each such payment, the time when such payments are required and the percentage of the work completed before each such progress payment is due.",
            x: margin,
            y: y,
            width: contentWidth,
            fontSize: 6.5
        )
        y += 24

        let rows: [(String, String, String)] = [
            ("Down Payment", fields["downPayment"] ?? "", fields["downPaymentPercent"] ?? ""),
            ("On Ordering Materials", fields["materials"] ?? "", fields["materialsPercent"] ?? ""),
            ("On Beginning Work", fields["beginWork"] ?? "", fields["beginWorkPercent"] ?? ""),
            ("On % Completion", fields["completionPercent"] ?? "", fields["completionPercentValue"] ?? ""),
            ("To be financed upon completion", fields["financeCompletion"] ?? "", fields["financeCompletionPercent"] ?? "")
        ]

        let scheduleX = margin + 18
        var scheduleY = y

        for row in rows {
            drawText(row.0, x: scheduleX, y: scheduleY, width: 140, fontSize: 7)
            drawText(row.1, x: scheduleX + 145, y: scheduleY, width: 65, fontSize: 7)
            drawText(row.2, x: scheduleX + 220, y: scheduleY, width: 45, fontSize: 7)
            scheduleY += 12
        }

        drawText(
            "IN ACCORDANCE WITH NEW YORK STATE LAW, ALL\nMONEY RECEIVED PRIOR TO COMPLETION WILL BE\nPLACED IN AN ESCROW ACCOUNT IN TRUST FOR THE\nHOMEOWNER.",
            x: 360,
            y: y,
            width: 200,
            fontSize: 7,
            bold: true
        )

        drawText(
            "*** There will be a 3.5% fee on all credit card transactions ***",
            x: margin,
            y: pageRect.height - 30,
            width: contentWidth,
            fontSize: 11,
            bold: true,
            alignment: .center
        )
    }

    private static func cleanFileName(_ title: String) -> String {
        title
            .replacingOccurrences(of: " ", with: "_")
            .components(separatedBy: CharacterSet(charactersIn: "/\\?%*|\"<>:"))
            .joined()
    }

    private static func drawText(
        _ text: String,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        fontSize: CGFloat,
        bold: Bool = false,
        alignment: NSTextAlignment = .left
    ) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        paragraph.lineBreakMode = .byWordWrapping

        let attributes: [NSAttributedString.Key: Any] = [
            .font: bold ? UIFont.boldSystemFont(ofSize: fontSize) : UIFont.systemFont(ofSize: fontSize),
            .foregroundColor: UIColor.black,
            .paragraphStyle: paragraph
        ]

        text.draw(
            with: CGRect(x: x, y: y, width: width, height: 500),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )
    }

    private static func drawLineField(label: String, value: String?, x: CGFloat, y: CGFloat, width: CGFloat) {
        drawText(label, x: x, y: y, width: 140, fontSize: 9)
        let lineStart = x + 140
        drawLine(x1: lineStart, y1: y + 15, x2: x + width, y2: y + 15)
        drawText(value ?? "", x: lineStart + 4, y: y + 1, width: x + width - lineStart - 4, fontSize: 9)
    }

    private static func drawBox(_ rect: CGRect) {
        UIColor.black.setStroke()
        UIBezierPath(rect: rect).stroke()
    }

    private static func drawRect(_ rect: CGRect) {
        UIColor.black.setStroke()
        UIBezierPath(rect: rect).stroke()
    }

    private static func drawLine(x1: CGFloat, y1: CGFloat, x2: CGFloat, y2: CGFloat) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: x1, y: y1))
        path.addLine(to: CGPoint(x: x2, y: y2))
        UIColor.black.setStroke()
        path.lineWidth = 0.7
        path.stroke()
    }

    private static func drawSignature(data: Data?, rect: CGRect) {
        guard let data, let image = UIImage(data: data) else { return }
        image.draw(in: rect)
    }
}
