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

class ViewController: UIViewController {

    // MARK: - 控件
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var vaseButton: CustomButton!
    @IBOutlet weak var chairButton: CustomButton!
    @IBOutlet weak var candleButton: CustomButton!
    @IBOutlet weak var measureButton: CustomButton!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var trackingInfo: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var crosshair: UIView!
    
    // MARK: - 物体变量
    var currentMode: FunctionMode = .none
    var objects: [SCNNode] = []
    var measuringNodes: [SCNNode] = []
    
    // MARK: - 重写方法
    override func viewDidLoad() {
        super.viewDidLoad()
        
        runSession()
        trackingInfo.text = ""
        messageLabel.text = ""
        distanceLabel.isHidden = true
        selectVase()    // 默认先选择花瓶

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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
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
                #if DEBUG
                    let planeNode = createPlaneNode(center: planeAnchor.center, extent: planeAnchor.extent)
                    node.addChildNode(planeNode)
                #endif
            } else {
                
                switch self.currentMode {
                    case .none:
                        break
                    case .placeObject(let name):
                        let modelClone = SCNScene(named: name)!.rootNode.clone()
                        self.objects.append(modelClone)
                        node.addChildNode(modelClone)
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
}
