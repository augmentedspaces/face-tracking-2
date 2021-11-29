//
//  ContentView.swift
//  face-tracking-2
//
//  Created by Sebastian Buys on 11/28/21.
//

import ARKit
import SwiftUI
import RealityKit
import Combine

// Load shader
let metalLib = MTLCreateSystemDefaultDevice()!.makeDefaultLibrary()!
let shader = CustomMaterial.SurfaceShader(named: "gradient", in: metalLib)

class ViewModel: ObservableObject {
    
}

class MyARView: ARView {
    var disposeBag: Set<AnyCancellable> = []
    var viewModel: ViewModel
    
    var originAnchor: AnchorEntity!
    var faceAnchor: ARFaceAnchor?
    var faceEntity = ModelEntity()
    
    var faceShaderMaterial = try! CustomMaterial(surfaceShader: shader, lightingModel: .lit)
    
    init(frame: CGRect, viewModel: ViewModel) {
        self.viewModel = viewModel
        super.init(frame: frame)
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(frame frameRect: CGRect) {
        fatalError("init(frame:) has not been implemented")
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        setupScene()
        setupSubscriptions()
        runSession()
    }
    
    func setupScene() {
        // Create an anchor at scene origin.
        originAnchor = AnchorEntity(world: .zero)
        self.scene.addAnchor(originAnchor)
        originAnchor.addChild(faceEntity)
    }
    
    func setupSubscriptions() {
//        scene.subscribe(to: SceneEvents.DidAddEntity.self) { [weak self] event in
//            guard let self = self else { return }
//            print("Added entity", event.entity)
//        }.store(in: &disposeBag)
    }
    
    func runSession() {
        self.renderOptions = [.disableDepthOfField,
                              .disableMotionBlur,
                              .disableAREnvironmentLighting,
                              .disableGroundingShadows,
                              // .disablePersonOcclusion,
                              .disableCameraGrain]
        
        self.automaticallyConfigureSession = false
        
        // Face tracking config
        let config = ARFaceTrackingConfiguration()
        
        // Set ARSessionDelegate.
        self.session.delegate = self
        
        // Run session
        self.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }
}

extension MyARView: ARSessionDelegate {
    /**
     ARSessionDelegate methods
     */
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
    }
    
    // Add anchors
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        print("Added anchors", anchors)
        
        // Look for face anchors
        let faceAnchors: [ARFaceAnchor] = anchors.compactMap {
            $0 as? ARFaceAnchor
        }
        
        guard let first = faceAnchors.first else {
            return
        }
        
        // Store reference to the first face detected
        self.faceAnchor = first
        
        // Update face mesh geometry attached to face anchor
        self.updateFaceEntity(faceAnchor: first)
    }
    
    func makeFaceMesh(faceAnchor: ARFaceAnchor) -> MeshResource? {
        let faceGeo: ARFaceGeometry = faceAnchor.geometry
        let indices: [UInt32] = faceGeo.triangleIndices.map({ UInt32($0)})
        
        var meshDescriptor = MeshDescriptor()
        meshDescriptor.positions = MeshBuffers.Positions(faceGeo.vertices)
        meshDescriptor.primitives = MeshDescriptor.Primitives.triangles(indices)
        meshDescriptor.textureCoordinates = MeshBuffers.TextureCoordinates(faceGeo.textureCoordinates)

        return try? MeshResource.generate(from: [meshDescriptor])
    }
    
    func updateFaceEntity(faceAnchor: ARFaceAnchor) {
        // Try creating MeshResource from ARFaceAnchor.geometry
        // And update model if successful
        if let faceMesh = makeFaceMesh(faceAnchor: faceAnchor) {
            self.faceEntity.model = ModelComponent(mesh: faceMesh, materials: [faceShaderMaterial])

        }
        
        // Update face transform
        faceEntity.transform = Transform(matrix: faceAnchor.transform)
        
        // Move forward in the z by 1cm to prevent z-fighting with actual face
        let moveTransform = Transform(scale: [1,1,1], rotation: .init(), translation: [0, 0, 0.01])
        
        faceEntity.move(to: moveTransform, relativeTo: faceEntity)
    }
    
    // Update anchors
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        
        //print(anchors.count, anchors.first.)
        
        // Get face anchors
        let faceAnchors = anchors.compactMap { $0 as? ARFaceAnchor }
        
        // Find an anchor that matches the one we detected earlier
        guard let faceAnchor = (faceAnchors.first {$0 == self.faceAnchor }) else {
            print("No match")
            return
        }
        
        self.updateFaceEntity(faceAnchor: faceAnchor)
        // Get face geometry
        //let geometry: ARFaceGeometry = faceAnchor.geometry
    }
    
    // Remove anchors
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
    }
}

struct ContentView : View {
    @ObservedObject var viewModel: ViewModel = ViewModel()
    var body: some View {
        return ARViewContainer(viewModel: viewModel).edgesIgnoringSafeArea(.all)
    }
}

struct ARViewContainer: UIViewRepresentable {
    let viewModel: ViewModel
    
    func makeUIView(context: Context) -> ARView {
        let arView = MyARView(frame: .zero, viewModel: viewModel)
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
