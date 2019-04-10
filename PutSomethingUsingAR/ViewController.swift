//
//  ViewController.swift
//  PutSomethingUsingAR
//
//  Created by Victor Wu on 2019/4/9.
//  Copyright © 2019 Victor Wu. All rights reserved.
//

import UIKit
import ARKit

enum FunctionMode {
    case none
    case placeObject(String)
    case measure
}

class ViewController: UIViewController, UIGestureRecognizerDelegate {

    // MARK: - 控件
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var vaseButton: CustomButton!
    @IBOutlet weak var chairButton: CustomButton!
    @IBOutlet weak var candleButton: CustomButton!
    @IBOutlet weak var measureButton: CustomButton!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var crosshair: UIView!
    
    // MARK: - 物体变量
    var currentMode: FunctionMode = .none
    
    var currentObject: SCNNode!   // 指向当前已经放置的物体
    var currentAngleY: Float = 0.0  // 当前物体的角度偏移量
    
    var objects: [SCNNode] = []
    var measuringNodes: [SCNNode] = []
    
    // MARK: - 重写方法
    override func viewDidLoad() {
        super.viewDidLoad()
        
        runSession()
        messageLabel.text = ""
        distanceLabel.isHidden = true
        selectVase()    // 默认先选择花瓶
        
        // 手势缩放
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(didPinch(_:)))
        sceneView.addGestureRecognizer(pinchGesture)
        
        // 手势旋转
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
        panGesture.delegate = self
        sceneView.addGestureRecognizer(panGesture)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: - 手势缩放
    @objc func didPinch(_ gesture: UIPinchGestureRecognizer) {
        guard let _ = currentObject else { return }
        
        var originalScale = currentObject?.scale
        
        switch gesture.state {
        case .began:
            originalScale = currentObject?.scale
            gesture.scale = CGFloat((currentObject?.scale.x)!)
        case .changed:
            guard var newScale = originalScale else { return }
            
            if gesture.scale < 0.5{
                newScale = SCNVector3(x: 0.5, y: 0.5, z: 0.5)
            }else if gesture.scale > 2{
                newScale = SCNVector3(2, 2, 2)
            }else{
                newScale = SCNVector3(gesture.scale, gesture.scale, gesture.scale)
            }
            self.currentObject?.scale = newScale
        case .ended:
            guard var newScale = originalScale else { return }
            
            if gesture.scale < 0.5 {
                newScale = SCNVector3(x: 0.5, y: 0.5, z: 0.5)
            } else if gesture.scale > 2 {
                newScale = SCNVector3(2, 2, 2)
            }else{
                newScale = SCNVector3(gesture.scale, gesture.scale, gesture.scale)
            }
            self.currentObject?.scale = newScale
            gesture.scale = CGFloat((self.currentObject?.scale.x)!)
            
        default:
            gesture.scale = 1.0
            originalScale = nil
        }
    }
    
    // MARK: - 手势旋转
    @objc func didPan(_ gesture: UIPanGestureRecognizer) {
        guard let _ = currentObject else { return }
        let translation = gesture.translation(in: gesture.view)
        var newAngleY = (Float)(translation.x) * (Float)(Double.pi) / 180.0
        
        newAngleY += currentAngleY
        currentObject?.eulerAngles.y = newAngleY
        
        if gesture.state == .ended {
            currentAngleY = newAngleY
        }
    }
    
    // MARK: - 点击事件
    @IBAction func didTapVase(_ sender: Any) {
        selectVase()
    }
    
    @IBAction func didTapChair(_ sender: Any) {
        currentMode = .placeObject("Furniture.scnassets/chair/chair.scn")
        selectButton(chairButton)
    }
    
    
    @IBAction func didTapCandle(_ sender: Any) {
        currentMode = .placeObject("Furniture.scnassets/candle/candle.scn")
        selectButton(candleButton)
    }
    
    @IBAction func didTapMeasure(_ sender: Any) {
        currentMode = .measure
        selectButton(measureButton)
    }
    
    @IBAction func didTapReset(_ sender: Any) {
        removeAllObjects()
        distanceLabel.text = ""
    }
    
    @IBAction func didTapAddObject(_ sender: Any) {
        if let hit = sceneView.hitTest(viewCenter, types: [.existingPlaneUsingExtent]).first {
            sceneView.session.add(anchor: ARAnchor(transform: hit.worldTransform))
            return
        } else if let hit = sceneView.hitTest(viewCenter, types: [.featurePoint]).last {
            sceneView.session.add(anchor: ARAnchor(transform: hit.worldTransform))
            return
        }
    }
    
    // MARK: - 初始化配置
    func runSession() {
        sceneView.delegate = self
        sceneView.showsStatistics = true
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration)
        #if DEBUG
            sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
        #endif
    }
    
    // MARK: - 选择物品
    
    func selectVase() {
        currentMode = .placeObject("Furniture.scnassets/vase/vase.scn")
        selectButton(vaseButton)
    }
    
    func selectButton(_ button: UIButton) {
        unselectAllButtons()
        
        button.isSelected = true
    }
    
    func unselectAllButtons() {
        
        [chairButton, candleButton, measureButton, vaseButton].forEach {
            $0?.isSelected = false
        }
    }
    
    func removeAllObjects() {
        
        for object in objects {
            object.removeFromParentNode()
        }
        
        objects = []
    }
}

extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        DispatchQueue.main.async {
            
            if let planeAnchor = anchor as? ARPlaneAnchor {
                self.messageLabel.text = "发现理想平面"
                #if DEBUG
                    let planeNode = createPlaneNode(center: planeAnchor.center, extent: planeAnchor.extent)
                    node.addChildNode(planeNode)
                #endif
            } else {
                
                switch self.currentMode {
                    case .none:
                        break
                    case .placeObject(let name):
                        self.currentObject = SCNScene(named: name)!.rootNode.clone()
                        self.objects.append(self.currentObject)
                        node.addChildNode(self.currentObject)
                    case .measure:
                        break
                }
                    
            }
            
        }
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                updatePlaneNode(node.childNodes[0], center: planeAnchor.center, extent: planeAnchor.extent)
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else { return }
        removeChildren(inNode: node)
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        messageLabel.text = "检测平面: Stop"
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        messageLabel.text = "检测平面: Resume"
        resetTracking()
    }
    
    func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .normal :
            messageLabel.text = "检测到一个不算很理想平面."
            
        case .notAvailable:
            messageLabel.text = "检测平面不准确."
            
        case .limited(.excessiveMotion):
            messageLabel.text = "Tracking limited - 设备移动的太慢了."
            
        case .limited(.insufficientFeatures):
            messageLabel.text = "Tracking limited - 让设备处于可见状态."
            
        case .limited(.initializing):
            messageLabel.text = "正在初始化AR Session."
            
        default:
            messageLabel.text = ""
        }
    }
}
