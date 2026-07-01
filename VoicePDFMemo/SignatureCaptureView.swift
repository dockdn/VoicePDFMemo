import SwiftUI
import UIKit

struct SignatureCaptureView: View {
    @Binding var signatureImageData: Data?

    @State private var committedStrokes: [[CGPoint]] = []
    @State private var activeStroke: [CGPoint] = []
    @State private var canvasSize: CGSize = .zero
    @State private var renderedBaseImage: UIImage?
    @State private var lastPersistedSignatureData: Data?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white

                if let renderedBaseImage {
                    Image(uiImage: renderedBaseImage)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFill()
                }

                Path { path in
                    addStrokes(committedStrokes, to: &path)
                    addStrokes([activeStroke], to: &path)
                }
                .stroke(
                    Color.black,
                    style: StrokeStyle(
                        lineWidth: 2.2,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
            }
            .contentShape(Rectangle())
            .clipped()
            .onAppear {
                updateCanvasSize(geometry.size)
                syncFromBinding()
            }
            .onChange(of: geometry.size) { newSize in
                updateCanvasSize(newSize)
            }
            .onChange(of: signatureImageData) { _ in
                syncFromBinding()
            }
            .highPriorityGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        let point = clampedPoint(value.location, in: geometry.size)

                        if activeStroke.isEmpty {
                            activeStroke = [point]
                        } else if activeStroke.last != point {
                            activeStroke.append(point)
                        }

                        persistSignature(using: geometry.size)
                    }
                    .onEnded { value in
                        let point = clampedPoint(value.location, in: geometry.size)

                        if activeStroke.isEmpty {
                            activeStroke = [point]
                        } else if activeStroke.last != point {
                            activeStroke.append(point)
                        }

                        if !activeStroke.isEmpty {
                            committedStrokes.append(activeStroke)
                            activeStroke.removeAll()
                        }

                        persistSignature(using: geometry.size)
                    }
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }

    private func addStrokes(_ strokes: [[CGPoint]], to path: inout Path) {
        for stroke in strokes where !stroke.isEmpty {
            if stroke.count == 1, let point = stroke.first {
                path.move(to: point)
                path.addLine(to: CGPoint(x: point.x + 0.1, y: point.y + 0.1))
                continue
            }

            path.move(to: stroke[0])
            for point in stroke.dropFirst() {
                path.addLine(to: point)
            }
        }
    }

    private func updateCanvasSize(_ newSize: CGSize) {
        guard newSize.width > 1, newSize.height > 1 else { return }
        canvasSize = newSize
    }

    private func syncFromBinding() {
        if signatureImageData == lastPersistedSignatureData {
            return
        }

        if let data = signatureImageData, let image = UIImage(data: data) {
            renderedBaseImage = image
        } else {
            renderedBaseImage = nil
            committedStrokes = []
            activeStroke = []
        }
    }

    private func persistSignature(using size: CGSize) {
        let targetSize = resolvedCanvasSize(from: size)
        guard targetSize.width > 1, targetSize.height > 1 else { return }

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: targetSize))

            renderedBaseImage?.draw(in: CGRect(origin: .zero, size: targetSize))

            let bezier = UIBezierPath()
            bezier.lineWidth = 2.2
            bezier.lineCapStyle = .round
            bezier.lineJoinStyle = .round

            for stroke in committedStrokes + [activeStroke] where !stroke.isEmpty {
                if stroke.count == 1, let point = stroke.first {
                    bezier.move(to: point)
                    bezier.addLine(to: CGPoint(x: point.x + 0.1, y: point.y + 0.1))
                    continue
                }

                bezier.move(to: stroke[0])
                for point in stroke.dropFirst() {
                    bezier.addLine(to: point)
                }
            }

            UIColor.black.setStroke()
            bezier.stroke()
        }

        let pngData = image.pngData()
        lastPersistedSignatureData = pngData
        signatureImageData = pngData
    }

    private func resolvedCanvasSize(from gestureSize: CGSize) -> CGSize {
        if gestureSize.width > 1, gestureSize.height > 1 {
            return gestureSize
        }

        if canvasSize.width > 1, canvasSize.height > 1 {
            return canvasSize
        }

        return CGSize(width: 300, height: 160)
    }

    private func clampedPoint(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: min(max(point.x, 0), max(size.width, 1)),
            y: min(max(point.y, 0), max(size.height, 1))
        )
    }
}
