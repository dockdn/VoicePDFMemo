import Foundation
import SwiftUI
import PDFKit
import UIKit

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

        let renderer = UIGraphicsPDFRenderer(bounds: Layout.pageRect)

        do {
            try renderer.writePDF(to: outputURL) { context in
                context.beginPage()
                drawPageOne(in: Layout.pageRect, fields: fields)

                context.beginPage()
                drawPageTwo(
                    in: Layout.pageRect,
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

    // MARK: - Page One

    private static func drawPageOne(
        in pageRect: CGRect,
        fields: [String: String]
    ) {
        preparePage(pageRect)

        var y = drawHeader(in: pageRect, compact: false)
        y += 10

        y = drawCustomerInformation(fields: fields, y: y)
        y += 10

        y = drawEntryAgreementSection(fields: fields, y: y)
        y += 10

        y = drawProjectDatesSection(fields: fields, y: y)
        y += 10

        _ = drawPaymentSummarySection(fields: fields, y: y)

        drawPageFooter(pageNumber: 1)
    }

    // MARK: - Page Two

    private static func drawPageTwo(
        in pageRect: CGRect,
        fields: [String: String],
        customerSignatureImageData: Data?,
        salespersonSignatureImageData: Data?
    ) {
        preparePage(pageRect)

        var y = drawHeader(in: pageRect, compact: true)
        y += 12

        y = drawOfficeApprovalSection(y: y)
        y += 12

        y = drawCancellationSection(y: y)
        y += 12

        y = drawSignatureSection(
            fields: fields,
            customerSignatureImageData: customerSignatureImageData,
            salespersonSignatureImageData: salespersonSignatureImageData,
            y: y
        )
        y += 12

        y = drawLegalNoticesSection(y: y)
        y += 12

        _ = drawProgressPaymentSection(fields: fields, y: y)

        drawCreditCardFeeFooter()
        drawPageFooter(pageNumber: 2)
    }

    // MARK: - Page Sections

    @discardableResult
    private static func drawHeader(in pageRect: CGRect, compact: Bool) -> CGFloat {
        let margin = Layout.margin
        let logoRect = CGRect(x: margin, y: Layout.topMargin - 2, width: compact ? 62 : 64, height: compact ? 44 : 44)
        let centerX = pageRect.midX
        let titleY = Layout.topMargin
        let textWidth = pageRect.width - (margin * 2)

        drawLogo(in: logoRect)

        drawText(
            Copy.companyName,
            in: CGRect(x: margin, y: titleY, width: textWidth, height: 28),
            style: .title
        )

        if compact {
            drawText(
                "\(Copy.address)  |  \(Copy.cityStateZip)",
                in: CGRect(x: margin, y: titleY + 27, width: textWidth, height: 16),
                style: .smallCenter
            )

            drawText(
                "\(Copy.phoneNumbers)  |  \(Copy.licenseLine)",
                in: CGRect(x: margin, y: titleY + 43, width: textWidth, height: 14),
                style: .microCenter
            )
        } else {
            drawText(
                "\(Copy.address)  |  \(Copy.cityStateZip)",
                in: CGRect(x: margin, y: titleY + 24, width: textWidth, height: 14),
                style: .smallCenter
            )

            drawText(
                "\(Copy.website)  |  \(Copy.phoneNumbers)",
                in: CGRect(x: margin, y: titleY + 39, width: textWidth, height: 14),
                style: .smallCenter
            )

            drawText(
                Copy.licenseLine,
                in: CGRect(x: margin, y: titleY + 54, width: textWidth, height: 12),
                style: .microCenter
            )
        }

        drawText(
            "CONTRACT",
            in: CGRect(x: centerX - 110, y: compact ? titleY + 60 : titleY + 70, width: 220, height: 20),
            style: compact ? .contractLabelCompact : .sectionTitleCentered
        )

        let ruleY = compact ? titleY + 84 : titleY + 94
        drawLine(from: CGPoint(x: margin, y: ruleY), to: CGPoint(x: pageRect.width - margin, y: ruleY), width: 0.9)

        return ruleY
    }

    @discardableResult
    private static func drawCustomerInformation(fields: [String: String], y: CGFloat) -> CGFloat {
        let sectionTop = drawSectionHeader("Customer Information", y: y)
        let leftX = Layout.margin
        let rightX = Layout.pageRect.midX + 12
        let columnWidth = (Layout.contentWidth - 12) / 2
        let rowGap: CGFloat = 36

        drawField(label: "Customer Name", value: fields["to"], x: leftX, y: sectionTop, width: columnWidth)
        drawField(label: "Date", value: fields["date"], x: rightX, y: sectionTop, width: columnWidth)

        drawField(label: "Property Address", value: fields["address"], x: leftX, y: sectionTop + rowGap, width: columnWidth)
        drawField(label: "Home Phone", value: fields["home"], x: rightX, y: sectionTop + rowGap, width: columnWidth)

        drawField(label: "Email", value: fields["email"], x: leftX, y: sectionTop + rowGap * 2, width: columnWidth)
        drawField(label: "Cell Phone", value: fields["cell"], x: rightX, y: sectionTop + rowGap * 2, width: columnWidth)

        return sectionTop + (rowGap * 2) + 30
    }

    @discardableResult
    private static func drawEntryAgreementSection(fields: [String: String], y: CGFloat) -> CGFloat {
        let sectionTop = drawSectionHeader("Entry Agreement", y: y)
        let noteHeight = drawText(
            Copy.entryAgreementNotice,
            in: CGRect(x: Layout.margin, y: sectionTop, width: Layout.contentWidth, height: 30),
            style: .body
        )

        let boxY = sectionTop + noteHeight + 10
        let boxHeight: CGFloat = 176
        let entryRect = CGRect(x: Layout.margin, y: boxY, width: Layout.contentWidth, height: boxHeight)

        UIColor.white.setFill()
        UIBezierPath(roundedRect: entryRect, cornerRadius: 4).fill()
        UIColor.black.setStroke()
        let outline = UIBezierPath(roundedRect: entryRect, cornerRadius: 4)
        outline.lineWidth = 0.9
        outline.stroke()

        let entryText = cleanedText(fields["entry"])
        drawText(
            entryText,
            in: entryRect.insetBy(dx: 12, dy: 12),
            style: .entryBody
        )

        return entryRect.maxY
    }

    @discardableResult
    private static func drawProjectDatesSection(fields: [String: String], y: CGFloat) -> CGFloat {
        let sectionTop = drawSectionHeader("Project Dates", y: y)
        let leftX = Layout.margin
        let rightX = Layout.pageRect.midX + 12
        let columnWidth = (Layout.contentWidth - 12) / 2

        drawField(label: "Approximate Start Date", value: fields["startDate"], x: leftX, y: sectionTop, width: columnWidth)
        drawField(label: "Approximate Completion Date", value: fields["completionDate"], x: rightX, y: sectionTop, width: columnWidth)

        return sectionTop + 30
    }

    @discardableResult
    private static func drawPaymentSummarySection(fields: [String: String], y: CGFloat) -> CGFloat {
        let sectionTop = drawSectionHeader("Payment Summary", y: y)
        let tableRect = CGRect(x: Layout.margin, y: sectionTop, width: Layout.contentWidth, height: 126)
        let rows: [(String, String)] = [
            ("Total Cost of Work", money(fields["totalCost"])),
            ("Deposit", money(fields["deposit"])),
            ("Paid on Delivery of Material", money(fields["paidDelivery"])),
            ("Amount to be Financed", money(fields["financed"])),
            ("Balance on Completion", money(fields["balance"]))
        ]

        drawTwoColumnTable(
            rows: rows,
            in: tableRect,
            labelColumnWidth: tableRect.width * 0.68,
            valueColumnTitle: "Amount"
        )

        return tableRect.maxY
    }

    @discardableResult
    private static func drawOfficeApprovalSection(y: CGFloat) -> CGFloat {
        let sectionTop = drawSectionHeader("Contract Subject to Office Approval", y: y, centered: true)
        let rect = CGRect(x: Layout.margin, y: sectionTop, width: Layout.contentWidth, height: 38)

        drawText(
            Copy.workmansCompNotice,
            in: rect,
            style: .notice
        )

        return rect.maxY
    }

    @discardableResult
    private static func drawCancellationSection(y: CGFloat) -> CGFloat {
        let sectionTop = drawSectionHeader("Cancellation", y: y)
        let height = drawText(
            Copy.cancellationNotice,
            in: CGRect(x: Layout.margin, y: sectionTop, width: Layout.contentWidth, height: 60),
            style: .notice
        )

        return sectionTop + height
    }

    @discardableResult
    private static func drawSignatureSection(
        fields: [String: String],
        customerSignatureImageData: Data?,
        salespersonSignatureImageData: Data?,
        y: CGFloat
    ) -> CGFloat {
        let sectionTop = drawSectionHeader("Signatures", y: y)
        let leftX = Layout.margin
        let rightX = Layout.pageRect.midX + 12
        let columnWidth = (Layout.contentWidth - 12) / 2

        drawField(label: "Salesperson Printed Name", value: fields["salesperson"], x: leftX, y: sectionTop, width: columnWidth)
        drawField(label: "Customer Printed Name", value: customerPrintedName(fields), x: rightX, y: sectionTop, width: columnWidth)

        let signatureY = sectionTop + 40
        let signatureHeight: CGFloat = 38
        drawSignatureLine(
            label: "Salesperson Signature",
            value: salespersonSignatureImageData,
            x: leftX,
            y: signatureY,
            width: columnWidth,
            height: signatureHeight
        )
        drawSignatureLine(
            label: "Customer Signature",
            value: customerSignatureImageData,
            x: rightX,
            y: signatureY,
            width: columnWidth,
            height: signatureHeight
        )

        let licenseY = signatureY + 58
        drawField(label: "Salesperson License Number", value: fields["license"], x: leftX, y: licenseY, width: columnWidth)

        let acknowledgementRect = CGRect(x: rightX, y: licenseY + 2, width: columnWidth, height: 28)
        drawText(
            Copy.signatureAcknowledgement,
            in: acknowledgementRect,
            style: .smallCenteredBold
        )

        return licenseY + 32
    }

    @discardableResult
    private static func drawLegalNoticesSection(y: CGFloat) -> CGFloat {
        let sectionTop = drawSectionHeader("Legal Notices", y: y)
        var cursorY = sectionTop

        cursorY += drawLabeledParagraph(title: "Notice of Lien:", body: Copy.noticeOfLien, y: cursorY)
        cursorY += 6
        cursorY += drawLabeledParagraph(title: "Deposit of Payments:", body: Copy.depositOfPayments, y: cursorY)
        cursorY += 6
        cursorY += drawLabeledParagraph(title: "Progress Payments:", body: Copy.progressPaymentsNotice, y: cursorY)

        return cursorY
    }

    @discardableResult
    private static func drawProgressPaymentSection(fields: [String: String], y: CGFloat) -> CGFloat {
        let sectionTop = drawSectionHeader("Progress Payments", y: y)
        let introHeight = drawText(
            Copy.progressPaymentScheduleIntro,
            in: CGRect(x: Layout.margin, y: sectionTop, width: Layout.contentWidth, height: 38),
            style: .smallBody
        )

        let tableY = sectionTop + introHeight + 6
        let leftWidth = Layout.contentWidth * 0.62
        let rightWidth = Layout.contentWidth - leftWidth - 12

        drawProgressTable(
            fields: fields,
            rect: CGRect(x: Layout.margin, y: tableY, width: leftWidth, height: 112)
        )

        let escrowRect = CGRect(
            x: Layout.margin + leftWidth + 12,
            y: tableY,
            width: rightWidth,
            height: 112
        )
        drawCalloutBox(title: "Escrow Notice", body: Copy.escrowNotice, rect: escrowRect)

        return max(tableY + 112, escrowRect.maxY)
    }

    // MARK: - Section Components

    @discardableResult
    private static func drawSectionHeader(_ title: String, y: CGFloat, centered: Bool = false) -> CGFloat {
        let headerRect = CGRect(x: Layout.margin, y: y, width: Layout.contentWidth, height: 18)
        UIColor(white: 0.94, alpha: 1).setFill()
        UIBezierPath(roundedRect: headerRect, cornerRadius: 3).fill()

        drawText(
            title.uppercased(),
            in: headerRect.insetBy(dx: 8, dy: 3),
            style: centered ? .sectionHeaderCentered : .sectionHeader
        )

        return headerRect.maxY + 6
    }

    private static func drawField(label: String, value: String?, x: CGFloat, y: CGFloat, width: CGFloat) {
        drawText(label, in: CGRect(x: x, y: y, width: width, height: 12), style: .fieldLabel)
        drawText(cleanedText(value), in: CGRect(x: x, y: y + 12, width: width, height: 14), style: .fieldValue)
        drawLine(from: CGPoint(x: x, y: y + 28), to: CGPoint(x: x + width, y: y + 28), width: 0.8)
    }

    private static func drawSignatureLine(
        label: String,
        value: Data?,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        height: CGFloat
    ) {
        drawText(label, in: CGRect(x: x, y: y, width: width, height: 10), style: .fieldLabel)
        drawLine(from: CGPoint(x: x, y: y + height), to: CGPoint(x: x + width, y: y + height), width: 0.8)

        guard let value, let image = UIImage(data: value) else { return }
        image.draw(in: CGRect(x: x + 6, y: y + 8, width: width - 12, height: height - 12))
    }

    private static func drawTwoColumnTable(
        rows: [(String, String)],
        in rect: CGRect,
        labelColumnWidth: CGFloat,
        valueColumnTitle: String
    ) {
        let rowHeight = rect.height / CGFloat(rows.count + 1)
        let valueColumnWidth = rect.width - labelColumnWidth

        drawTableCell(CGRect(x: rect.minX, y: rect.minY, width: labelColumnWidth, height: rowHeight), fill: UIColor(white: 0.96, alpha: 1))
        drawTableCell(CGRect(x: rect.minX + labelColumnWidth, y: rect.minY, width: valueColumnWidth, height: rowHeight), fill: UIColor(white: 0.96, alpha: 1))

        drawText("Description", in: CGRect(x: rect.minX + 8, y: rect.minY + 6, width: labelColumnWidth - 16, height: rowHeight - 10), style: .tableHeader)
        drawText(valueColumnTitle, in: CGRect(x: rect.minX + labelColumnWidth + 8, y: rect.minY + 6, width: valueColumnWidth - 16, height: rowHeight - 10), style: .tableHeader)

        for (index, row) in rows.enumerated() {
            let rowY = rect.minY + rowHeight * CGFloat(index + 1)
            drawTableCell(CGRect(x: rect.minX, y: rowY, width: labelColumnWidth, height: rowHeight))
            drawTableCell(CGRect(x: rect.minX + labelColumnWidth, y: rowY, width: valueColumnWidth, height: rowHeight))

            drawText(row.0, in: CGRect(x: rect.minX + 8, y: rowY + 6, width: labelColumnWidth - 16, height: rowHeight - 10), style: .tableBody)
            drawText(row.1, in: CGRect(x: rect.minX + labelColumnWidth + 8, y: rowY + 6, width: valueColumnWidth - 16, height: rowHeight - 10), style: .tableBody)
        }
    }

    private static func drawProgressTable(fields: [String: String], rect: CGRect) {
        let rows: [(String, String, String)] = [
            ("Down Payment", money(fields["downPayment"]), percent(fields["downPaymentPercent"])),
            ("On Ordering Materials", money(fields["materials"]), percent(fields["materialsPercent"])),
            ("On Beginning Work", money(fields["beginWork"]), percent(fields["beginWorkPercent"])),
            ("On % Completion", money(fields["completionPercent"]), percent(fields["completionPercentValue"])),
            ("To be financed upon completion", money(fields["financeCompletion"]), percent(fields["financeCompletionPercent"]))
        ]

        let rowHeight = rect.height / CGFloat(rows.count + 1)
        let stageWidth = rect.width * 0.56
        let amountWidth = rect.width * 0.24
        let percentWidth = rect.width - stageWidth - amountWidth

        let headerFill = UIColor(white: 0.96, alpha: 1)
        drawTableCell(CGRect(x: rect.minX, y: rect.minY, width: stageWidth, height: rowHeight), fill: headerFill)
        drawTableCell(CGRect(x: rect.minX + stageWidth, y: rect.minY, width: amountWidth, height: rowHeight), fill: headerFill)
        drawTableCell(CGRect(x: rect.minX + stageWidth + amountWidth, y: rect.minY, width: percentWidth, height: rowHeight), fill: headerFill)

        drawText("Stage", in: CGRect(x: rect.minX + 6, y: rect.minY + 6, width: stageWidth - 12, height: rowHeight - 10), style: .tableHeader)
        drawText("Amount", in: CGRect(x: rect.minX + stageWidth + 6, y: rect.minY + 6, width: amountWidth - 12, height: rowHeight - 10), style: .tableHeader)
        drawText("Percent", in: CGRect(x: rect.minX + stageWidth + amountWidth + 6, y: rect.minY + 6, width: percentWidth - 12, height: rowHeight - 10), style: .tableHeader)

        for (index, row) in rows.enumerated() {
            let rowY = rect.minY + rowHeight * CGFloat(index + 1)
            drawTableCell(CGRect(x: rect.minX, y: rowY, width: stageWidth, height: rowHeight))
            drawTableCell(CGRect(x: rect.minX + stageWidth, y: rowY, width: amountWidth, height: rowHeight))
            drawTableCell(CGRect(x: rect.minX + stageWidth + amountWidth, y: rowY, width: percentWidth, height: rowHeight))

            drawText(row.0, in: CGRect(x: rect.minX + 6, y: rowY + 5, width: stageWidth - 12, height: rowHeight - 10), style: .smallTableBody)
            drawText(row.1, in: CGRect(x: rect.minX + stageWidth + 6, y: rowY + 5, width: amountWidth - 12, height: rowHeight - 10), style: .smallTableBody)
            drawText(row.2, in: CGRect(x: rect.minX + stageWidth + amountWidth + 6, y: rowY + 5, width: percentWidth - 12, height: rowHeight - 10), style: .smallTableBody)
        }
    }

    private static func drawCalloutBox(title: String, body: String, rect: CGRect) {
        UIColor(white: 0.97, alpha: 1).setFill()
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 4)
        path.fill()
        UIColor.black.setStroke()
        path.lineWidth = 0.8
        path.stroke()

        drawText(title, in: CGRect(x: rect.minX + 10, y: rect.minY + 8, width: rect.width - 20, height: 14), style: .fieldLabel)
        drawText(body, in: CGRect(x: rect.minX + 10, y: rect.minY + 24, width: rect.width - 20, height: rect.height - 32), style: .smallBody)
    }

    @discardableResult
    private static func drawLabeledParagraph(title: String, body: String, y: CGFloat) -> CGFloat {
        let attributed = NSMutableAttributedString(
            string: title + " ",
            attributes: textAttributes(for: .smallBodyBold)
        )
        attributed.append(NSAttributedString(string: body, attributes: textAttributes(for: .smallBody)))

        let rect = CGRect(x: Layout.margin, y: y, width: Layout.contentWidth, height: 80)
        let height = measureHeight(for: attributed, width: rect.width)
        attributed.draw(with: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: height), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        return height
    }

    private static func drawTableCell(_ rect: CGRect, fill: UIColor = .white) {
        fill.setFill()
        UIRectFill(rect)
        UIColor.black.setStroke()
        let path = UIBezierPath(rect: rect)
        path.lineWidth = 0.8
        path.stroke()
    }

    // MARK: - Footer

    private static func drawCreditCardFeeFooter() {
        drawText(
            Copy.creditCardFeeNotice,
            in: CGRect(x: Layout.margin, y: Layout.pageRect.height - 48, width: Layout.contentWidth, height: 14),
            style: .footerNotice
        )
    }

    private static func drawPageFooter(pageNumber: Int) {
        drawText(
            "Page \(pageNumber) of 2",
            in: CGRect(x: Layout.margin, y: Layout.pageRect.height - 28, width: Layout.contentWidth, height: 12),
            style: .footer
        )
    }

    // MARK: - Formatting

    private static func money(_ raw: String?) -> String {
        let value = cleanedText(raw)
        guard !value.isEmpty else { return "" }
        return value.hasPrefix("$") ? value : "$\(value)"
    }

    private static func percent(_ raw: String?) -> String {
        let value = cleanedText(raw)
        guard !value.isEmpty else { return "" }
        return value.hasSuffix("%") ? value : "\(value)%"
    }

    private static func customerPrintedName(_ fields: [String: String]) -> String {
        let explicit = cleanedText(fields["customerPrintName"])
        return explicit.isEmpty ? cleanedText(fields["to"]) : explicit
    }

    private static func cleanedText(_ raw: String?) -> String {
        (raw ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func cleanFileName(_ title: String) -> String {
        title
            .replacingOccurrences(of: " ", with: "_")
            .components(separatedBy: CharacterSet(charactersIn: "/\\?%*|\"<>:"))
            .joined()
    }

    // MARK: - Drawing Helpers

    private static func preparePage(_ pageRect: CGRect) {
        UIColor.white.setFill()
        UIRectFill(pageRect)
    }

    private static func drawLogo(in rect: CGRect) {
        guard let image = UIImage(named: "PantherLogo") else { return }
        image.draw(in: rect)
    }

    @discardableResult
    private static func drawText(_ text: String, in rect: CGRect, style: TextStyle) -> CGFloat {
        let attributed = NSAttributedString(string: text, attributes: textAttributes(for: style))
        let height = min(measureHeight(for: attributed, width: rect.width), rect.height)
        attributed.draw(
            with: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: max(height, rect.height)),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        return height
    }

    private static func measureHeight(for attributed: NSAttributedString, width: CGFloat) -> CGFloat {
        ceil(
            attributed.boundingRect(
                with: CGSize(width: width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            ).height
        )
    }

    private static func textAttributes(for style: TextStyle) -> [NSAttributedString.Key: Any] {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = style.alignment
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.lineSpacing = style.lineSpacing

        return [
            .font: font(size: style.fontSize, bold: style.bold),
            .foregroundColor: UIColor.black,
            .paragraphStyle: paragraph
        ]
    }

    private static func font(size: CGFloat, bold: Bool = false) -> UIFont {
        if bold {
            return UIFont(name: "TimesNewRomanPS-BoldMT", size: size)
                ?? UIFont.boldSystemFont(ofSize: size)
        } else {
            return UIFont(name: "TimesNewRomanPSMT", size: size)
                ?? UIFont.systemFont(ofSize: size)
        }
    }

    private static func drawLine(from start: CGPoint, to end: CGPoint, width: CGFloat) {
        let path = UIBezierPath()
        path.move(to: start)
        path.addLine(to: end)
        UIColor.black.setStroke()
        path.lineWidth = width
        path.stroke()
    }

    // MARK: - Layout + Copy

    private enum Layout {
        static let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        static let margin: CGFloat = 42
        static let topMargin: CGFloat = 24
        static let contentWidth: CGFloat = pageRect.width - (margin * 2)
    }

    private struct TextStyle {
        let fontSize: CGFloat
        let bold: Bool
        let alignment: NSTextAlignment
        let lineSpacing: CGFloat

        static let title = TextStyle(fontSize: 22, bold: true, alignment: .center, lineSpacing: 0.8)
        static let subtitle = TextStyle(fontSize: 11.5, bold: false, alignment: .center, lineSpacing: 1.0)
        static let bodyCenter = TextStyle(fontSize: 10.2, bold: false, alignment: .center, lineSpacing: 1.0)
        static let smallCenter = TextStyle(fontSize: 8.8, bold: false, alignment: .center, lineSpacing: 1.0)
        static let microCenter = TextStyle(fontSize: 7.4, bold: false, alignment: .center, lineSpacing: 0.8)
        static let sectionTitleCentered = TextStyle(fontSize: 17, bold: true, alignment: .center, lineSpacing: 1.0)
        static let contractLabelCompact = TextStyle(fontSize: 14.5, bold: true, alignment: .center, lineSpacing: 1.0)
        static let sectionHeader = TextStyle(fontSize: 11.2, bold: true, alignment: .left, lineSpacing: 1.0)
        static let sectionHeaderCentered = TextStyle(fontSize: 11.2, bold: true, alignment: .center, lineSpacing: 1.0)
        static let fieldLabel = TextStyle(fontSize: 9.2, bold: true, alignment: .left, lineSpacing: 1.0)
        static let fieldValue = TextStyle(fontSize: 11, bold: false, alignment: .left, lineSpacing: 1.0)
        static let body = TextStyle(fontSize: 10.2, bold: false, alignment: .left, lineSpacing: 1.5)
        static let entryBody = TextStyle(fontSize: 10.6, bold: false, alignment: .left, lineSpacing: 2.4)
        static let notice = TextStyle(fontSize: 10.5, bold: true, alignment: .center, lineSpacing: 1.6)
        static let tableHeader = TextStyle(fontSize: 9.5, bold: true, alignment: .left, lineSpacing: 1.0)
        static let tableBody = TextStyle(fontSize: 9.8, bold: false, alignment: .left, lineSpacing: 1.0)
        static let smallTableBody = TextStyle(fontSize: 8.4, bold: false, alignment: .left, lineSpacing: 0.8)
        static let smallBody = TextStyle(fontSize: 8.4, bold: false, alignment: .left, lineSpacing: 1.2)
        static let smallBodyBold = TextStyle(fontSize: 8.4, bold: true, alignment: .left, lineSpacing: 1.2)
        static let smallCenteredBold = TextStyle(fontSize: 8.6, bold: true, alignment: .center, lineSpacing: 1.2)
        static let footerNotice = TextStyle(fontSize: 10.2, bold: true, alignment: .center, lineSpacing: 1.0)
        static let footer = TextStyle(fontSize: 8.2, bold: false, alignment: .center, lineSpacing: 1.0)
    }

    private enum Copy {
        static let companyName = "Panther Siding & Windows Inc."
        static let address = "1786 Newbridge Road"
        static let cityStateZip = "North Bellmore, NY 11710"
        static let website = "www.panthersidingandwindows.com"
        static let phoneNumbers = "516-479-6660   |   718-340-2325"
        static let licenseLine = "Lic. # H18E0250000 Nassau   |   Lic. # 0988279NYC   |   Lic. # 27 254-HI Suffolk"

        static let entryAgreementNotice = "The contractor shall be held responsible only for that which is expressly written on original agreement."
        static let workmansCompNotice = "CONTRACTOR WILL PROVIDE A CERTIFICATE OF WORKMANS COMPENSATION PRIOR TO STARTING WORK"
        static let cancellationNotice = "\"YOU THE BUYER, MAY CANCEL THIS TRANSACTION AT ANY TIME PRIOR TO MIDNIGHT OF THE THIRD BUSINESS DAY AFTER THE DATE OF THIS TRANSACTION. SEE ATTACHED NOTICE OF CANCELLATION FORM FOR AN EXPLANATION OF THIS RIGHT.\""
        static let signatureAcknowledgement = "I (we) have read and signed this contract and nothing other than is set forth therein has been promised"

        static let noticeOfLien = "Whether or not any mortgage may be given on the property to be improved. Seller or any subcontractor who performs work and is not paid may have a claim against you which may be enforced against the property in accordance with applicable law."
        static let depositOfPayments = "Seller is required by law to deposit all monies received from you under the Contract prior to completion of the work in an escrow account in trust for you or to post a surety bond or indemnity contract with you guaranteeing the return of proper application of such monies."
        static let progressPaymentsNotice = "If the Contract provides only for a Down Payment to be paid before commencement of any work. It will be held in an escrow account until the work is substantially complete. Upon completion of the work, the remaining balance of the sale price will be financed on an installment sale basis as set forth in the Retail Installment Obligation."
        static let progressPaymentScheduleIntro = "If the Contract provides for a Down Payment and one or more progress payments to be paid to Seller prior to substantial completion of the work, the following schedule identifies the amount of each such payment, the time when such payments are required and the percentage of the work completed before each such progress payment is due."
        static let escrowNotice = "IN ACCORDANCE WITH NEW YORK STATE LAW, ALL MONEY RECEIVED PRIOR TO COMPLETION WILL BE PLACED IN AN ESCROW ACCOUNT IN TRUST FOR THE HOMEOWNER."
        static let creditCardFeeNotice = "*** There will be a 3.5% fee on all credit card transactions ***"
    }
}
