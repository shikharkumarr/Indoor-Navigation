import SwiftUI
import CoreML
import Vision
import AVFoundation

struct CameraView2: View {
    @State private var placeName: String = "Searching..."
    let model: VNCoreMLModel
    
    var body: some View {
        ZStack {
            CameraPreview { image in
                recognizePlace(image)
            }
            VStack {
                Spacer()
                Text("Your Location : \(placeName)")
                    .font(.title2)
                    .padding()
            }
        }
    }
    
    func recognizePlace(_ image: UIImage) {
        guard let ciImage = CIImage(image: image) else {
            return
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            guard let results = request.results as? [VNClassificationObservation],
                  let topResult = results.first else {
                self.placeName = "Unable to locate"
                return
            }
            
            self.placeName = topResult.identifier
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage)
        do {
            try handler.perform([request])
        } catch {
            self.placeName = "Unable to locate"
        }
    }
}

struct CameraPreview2: UIViewRepresentable {
    typealias UIViewType = UIView
    
    var onImageCapture: (UIImage) -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let captureDevice = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: captureDevice) else {
            return view
        }
        
        captureSession.addInput(input)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(context.coordinator, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        
        captureSession.startRunning()
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        let parent: CameraPreview
        
        init(_ parent: CameraPreview) {
            self.parent = parent
        }
        
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                return
            }
            
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext(options: nil)
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
                return
            }
            
            let uiImage = UIImage(cgImage: cgImage)
            
            DispatchQueue.main.async {
                self.parent.onImageCapture(uiImage)
            }
        }
    }
}

struct ContentView2: View {
    let model: VNCoreMLModel
    
    init() {
        guard let model = try? VNCoreMLModel(for: PlaceIdentifyModel().model) else {
            fatalError("Failed to load model")
        }
        
        self.model = model
    }
    
    var body: some View {
        CameraView(model: model)
    }
}



struct ContentView2_Previews: PreviewProvider {
    static var previews: some View {
        ContentView2()
    }
}
