import SwiftUI
import PencilKit

struct SignatureCaptureView: UIViewRepresentable {
    @Binding var signatureImageData: Data?

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .white
        canvas.tool = PKInkingTool(.pen, color: .black, width: 2)
        canvas.delegate = context.coordinator
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(signatureImageData: $signatureImageData)
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var signatureImageData: Data?

        init(signatureImageData: Binding<Data?>) {
            _signatureImageData = signatureImageData
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            let image = canvasView.drawing.image(
                from: canvasView.bounds,
                scale: UIScreen.main.scale
            )
            signatureImageData = image.pngData()
        }
    }
}
