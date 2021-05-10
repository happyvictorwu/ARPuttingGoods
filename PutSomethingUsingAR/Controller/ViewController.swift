//
//  ViewController.swift
//  PutSomethingUsingAR
//
//  Created by Victor Wu on 2019/4/9.
//  Copyright © 2019 Victor Wu. All rights reserved.
//

import ARInfoBox
import ARKit
import QuickLook
import UIKit

enum FunctionMode {
    case none
    case placeObject(String, String)
    case measure
}

class ViewController: UIViewController, UIGestureRecognizerDelegate {
    fileprivate var loadPrevious = host_cpu_load_info() // cpu需要使用

    // MARK: - 信息采集

//    let timeInterval: Int = 2  // 信息采集时间间隔
//    var cpuList: CpuInfo = CpuInfo.init()   // cpu的信息
//    var memoryList: MemoryInfo = MemoryInfo.init()  // 内存信息
    var arCollection: ARInfoController = ARInfoController(appId: "85d4a553-ee8d-4136-80ab-2469adcae44d")

    var currentFurniture: Furniture! // 当前模型信息
    var currentTime: TimeInterval = Date().timeIntervalSince1970

    // MARK: - 控件

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var vaseButton: CustomButton!
    @IBOutlet var chairButton: CustomButton!
    @IBOutlet var candleButton: CustomButton!
    @IBOutlet var measureButton: CustomButton!
    @IBOutlet var measureAddButton: UIButton!
    @IBOutlet var measureDelButton: UIButton!
    @IBOutlet var addButton: UIButton!
    @IBOutlet var confirmButton: UIButton!
    @IBOutlet var LightEstimationButton: UIButton!
    @IBOutlet var resetButton: UIButton!
    @IBOutlet var distanceLabel: UILabel!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var crosshair: UIView!

    // MARK: - 物体变量

    var currentMode: FunctionMode = .none

    var currentObject: SCNNode! // 指向当前已经放置的物体
    var currentAngleY: Float = 0.0 // 当前物体的角度偏移量

    var objects: [SCNNode] = []
    var measuringNodes: [SCNNode] = []

    // MARK: - 重写方法

    override func viewDidLoad() {
        super.viewDidLoad()

        runSession()
        messageLabel.text = ""
        distanceLabel.isHidden = true
        selectVase() // 默认先选择花瓶
        GestureRecognizerInit() // 初始化手势

        // 收集CPU，内存占用
//        baseMobileInfo()
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

    // MARK: - 手势初始化

    func GestureRecognizerInit() {
        // 手势缩放
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(didPinch(_:)))
        sceneView.addGestureRecognizer(pinchGesture)

        // 手势旋转
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
        panGesture.delegate = self
        sceneView.addGestureRecognizer(panGesture)
    }

    // 手势缩放
    @objc func didPinch(_ gesture: UIPinchGestureRecognizer) {
        guard let _ = currentObject, !confirmButton.isHidden else { return }

        var originalScale = currentObject?.scale

        switch gesture.state {
        case .began:
            gesture.scale = CGFloat((currentObject?.scale.x)!)
        case .changed:
            guard var newScale = originalScale else { return }

            if gesture.scale < 0.5 { // 0.5倍
                newScale = SCNVector3(x: 0.5, y: 0.5, z: 0.5)
            } else if gesture.scale > 2 { // 2倍
                newScale = SCNVector3(2, 2, 2)
            } else {
                newScale = SCNVector3(gesture.scale, gesture.scale, gesture.scale)
            }
            currentObject?.scale = newScale
        case .ended:
            guard var newScale = originalScale else { return }

            if gesture.scale < 0.5 {
                newScale = SCNVector3(x: 0.5, y: 0.5, z: 0.5)
            } else if gesture.scale > 2 {
                newScale = SCNVector3(2, 2, 2)
            } else {
                newScale = SCNVector3(gesture.scale, gesture.scale, gesture.scale)
            }

            currentObject?.scale = newScale
            gesture.scale = CGFloat((currentObject?.scale.x)!)

            currentFurniture.actionInteractList.append(Action.Scaling)
            print(currentFurniture.modelName + " is Action-Scaling")

        default:
            gesture.scale = 1.0
            originalScale = nil
        }
    }

    // 手势旋转
    @objc func didPan(_ gesture: UIPanGestureRecognizer) {
        guard let _ = currentObject, !confirmButton.isHidden else { return }
        let translation = gesture.translation(in: gesture.view)
        var newAngleY = (Float)(translation.x) * (Float)(Double.pi) / 180.0

        newAngleY += currentAngleY
        currentObject?.eulerAngles.y = newAngleY

        if gesture.state == .ended {
            currentAngleY = newAngleY

            currentFurniture.actionInteractList.append(Action.Rotate)
            print(currentFurniture.modelName + " is Action-Rotate")
        }
    }

    // MARK: - 点击事件

    @IBAction func didTapVase(_ sender: Any) {
        measureAddButton.isHidden = true
        addButton.isHidden = false
        selectVase()
    }

    @IBAction func didTapChair(_ sender: Any) {
        measureAddButton.isHidden = true
        addButton.isHidden = false
        currentMode = .placeObject("Furniture.scnassets/chair/chair.scn", "Chair")
        selectButton(chairButton)
    }

    @IBAction func didTapCandle(_ sender: Any) {
        measureAddButton.isHidden = true
        addButton.isHidden = false
        currentMode = .placeObject("Furniture.scnassets/candle/candle.scn", "Candle")
        selectButton(candleButton)
    }

    @IBAction func didTapReset(_ sender: Any) {
        removeAllObjects()
        distanceLabel.text = ""
    }

    @IBAction func didTapAddObject(_ sender: Any) {
        addButton.isHidden = true
        resetButton.isHidden = true
        measureButton.isHidden = true
        confirmButton.isHidden = false

        currentFurniture = Furniture()
        print("create a new furniture")
        currentFurniture.actionInteractList.append(Action.Add)
        print("a new furniture create a Action-Add")
        currentTime = Date().timeIntervalSince1970
        print("time cost calculate begin")

        if let hit = sceneView.hitTest(viewCenter, types: [.existingPlaneUsingExtent]).first {
            sceneView.session.add(anchor: ARAnchor(transform: hit.worldTransform))
            return
        } else if let hit = sceneView.hitTest(viewCenter, types: [.featurePoint]).last {
            sceneView.session.add(anchor: ARAnchor(transform: hit.worldTransform))
            return
        }
    }

    @IBAction func didTapConfirm(_ sender: Any) {
        confirmButton.isHidden = true
        resetButton.isHidden = false
        addButton.isHidden = false
        measureButton.isHidden = false

        // FIXME: upload confirmFurniture info to server
        debugPrint("upload to serve")
//
//        uploadCPU(cpu: cpuList, urlTail: "ArAnalysis/CpuInfo/receiveCpuInfo")
//        print(cpuList)
//        self.cpuList.resetAll()
//
//        uploadMemory(memory: memoryList, urlTail: "ArAnalysis/MemoryInfo/receiveMemoryInfo")
//        print(memoryList)
//        self.memoryList.resetAll()

//        uploadTriggerCount(furniture: self.currentFurniture.actionInteractList, urlTail: "ArAnalysis/InteractInfo/receiveTrigger")

//        self.currentFurniture.costTime = self.currentTime
//        uploadGazeObject(furniture: self.currentFurniture, urlTail: "ArAnalysis/InteractInfo/receiveGazeObject")
//
//        uploadInteractionLostInfo(furniture: self.currentFurniture, urlTail: "ArAnalysis/InteractInfo/receiveInteractListInfo")
        currentFurniture.costTime = Int(Double(Date().timeIntervalSince1970) - Double(currentTime))
        let f_modelName: String = currentFurniture.modelName
        let f_costTime: Int = currentFurniture.costTime
        let f_modelAction: [Action] = currentFurniture.actionInteractList
        
        debugPrint(f_costTime)
        
        arCollection.uploadTriggerCount(modelAction: f_modelAction)
        arCollection.uploadGazeObject(modelName: f_modelName, gazeTime: f_costTime)
        arCollection.uploadInteractionLostInfo(modelName: f_modelName, methodList: f_modelAction)
    }

    @IBAction func didTapSelectLight(_ sender: Any) {
        guard let configuration = sceneView.session.configuration else { return }

        if configuration.isLightEstimationEnabled == true {
            ResetSessionWithLight(chooseLight: false)
        } else {
            ResetSessionWithLight(chooseLight: true)
        }
    }

    @IBAction func didTapMeasure(_ sender: Any) {
        currentMode = .measure
        selectButton(measureButton)

        measureAddButton.isHidden = false
        addButton.isHidden = true
    }

    @IBAction func didTapMeasureAdd(_ sender: Any) {
        if let hit = sceneView.hitTest(viewCenter, types: [.existingPlaneUsingExtent]).first {
            sceneView.session.add(anchor: ARAnchor(transform: hit.worldTransform))
            return
        } else if let hit = sceneView.hitTest(viewCenter, types: [.featurePoint]).last {
            sceneView.session.add(anchor: ARAnchor(transform: hit.worldTransform))
            return
        }
    }

    @IBAction func didTapMeasureDel(_ sender: Any) {
        measureAddButton.isHidden = true
        measureDelButton.isHidden = true

        addButton.isHidden = false

        vaseButton.isHidden = false
        candleButton.isHidden = false
        chairButton.isHidden = false
        resetButton.isHidden = false

        selectVase()
    }

    // MARK: - 初始化配置

    func runSession() {
        arCollection.start()
        guard ARWorldTrackingConfiguration.isSupported else {
            messageLabel.text = "不支持 ARConfig: AR World Tracking"
            messageLabel.textColor = UIColor.red
            return
        }

        sceneView.delegate = self
        sceneView.showsStatistics = true

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.worldAlignment = .gravity
        configuration.isLightEstimationEnabled = true
        LightEstimationButton.setTitle("🌞", for: UIControl.State.normal)
        sceneView.session.run(configuration)
        #if DEBUG
//        sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
        #endif
    }

    func ResetSessionWithLight(chooseLight isLight: Bool) {
        sceneView.delegate = self
        sceneView.showsStatistics = true

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.worldAlignment = .gravity
        configuration.isLightEstimationEnabled = isLight
        if isLight {
            LightEstimationButton.setTitle("🌞", for: UIControl.State.normal)
        } else {
            LightEstimationButton.setTitle("🌛", for: UIControl.State.normal)
        }
//        sceneView.session.run(configuration)
        #if DEBUG
//        sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
        #endif
    }

    // MARK: - 选择物品

    func selectVase() {
        currentMode = .placeObject("Furniture.scnassets/vase/vase.scn", "Vase")
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

    // MARK: - 测量方法

    func measure(fromNode: SCNNode, toNode: SCNNode) {
        let measuringLineNode = createLineNode(fromNode: fromNode, toNode: toNode)
        measuringLineNode.name = "MeasuringLine"
        sceneView.scene.rootNode.addChildNode(measuringLineNode)
        objects.append(measuringLineNode)

        let dist = fromNode.position.distanceTo(toNode.position)
        let measurementValue = String(format: "%.2f", dist)
        distanceLabel.text = "Distance: \(measurementValue) m"
    }

    func updateMeasuringNodes() {
        guard measuringNodes.count > 1 else {
            return
        }
        let firstNode = measuringNodes[0]
        let secondNode = measuringNodes[1]
        let showMeasuring = measuringNodes.count == 2
        distanceLabel.isHidden = !showMeasuring

        if showMeasuring {
            measure(fromNode: firstNode, toNode: secondNode)
        } else {
            firstNode.removeFromParentNode()
            secondNode.removeFromParentNode()
            measuringNodes.removeFirst(2)

            for node in sceneView.scene.rootNode.childNodes {
                if node.name == "MeasuringLine" {
                    node.removeFromParentNode()
                }
            }
        }
    }
}

extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                self.messageLabel.text = "发现理想平面"
                self.messageLabel.textColor = UIColor.green
                #if DEBUG
//                let planeNode = createPlaneNode(center: planeAnchor.center, extent: planeAnchor.extent)
//                node.addChildNode(planeNode)
                #endif
            } else {
                switch self.currentMode {
                case .none:
                    break
                case let .placeObject(name, ObjectName):
                    self.currentObject = SCNScene(named: name)!.rootNode.clone()
                    self.objects.append(self.currentObject)
                    self.currentFurniture.modelName = ObjectName
                    print("a new furniture has Model Name call: " + self.currentFurniture.modelName)
                    node.addChildNode(self.currentObject)

                case .measure:
                    let spehereNode = createSphereNode(radius: 0.01)
                    self.objects.append(spehereNode)
                    node.addChildNode(spehereNode)
                    self.measuringNodes.append(node)

                    self.measureAddButton.isHidden = false
                    self.measureDelButton.isHidden = false

                    self.addButton.isHidden = true

                    self.vaseButton.isHidden = true
                    self.candleButton.isHidden = true
                    self.chairButton.isHidden = true
                    self.resetButton.isHidden = true
                }
            }
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                updatePlaneNode(node.childNodes[0], center: planeAnchor.center, extent: planeAnchor.extent)
            } else {
                self.updateMeasuringNodes()
            }
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else { return }
        removeChildren(inNode: node)
    }

    func sessionWasInterrupted(_ session: ARSession) {
        messageLabel.text = "检测平面: Stop"
        messageLabel.textColor = UIColor.red
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        messageLabel.text = "检测平面: Resume"
        messageLabel.textColor = UIColor.yellow
        resetTracking()
    }

    func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .normal:
            messageLabel.text = "检测到一个不算很理想平面."
            messageLabel.textColor = UIColor.yellow
            addButton.isHidden = false

        case .notAvailable:
            messageLabel.text = "检测平面不准确."
            messageLabel.textColor = UIColor.yellow
            addButton.isHidden = true

        case .limited(.excessiveMotion):
            messageLabel.text = "Tracking limited - 设备移动的太慢了."
            messageLabel.textColor = UIColor.yellow

        case .limited(.insufficientFeatures):
            messageLabel.text = "Tracking limited - 让设备处于可见状态."
            messageLabel.textColor = UIColor.yellow

        case .limited(.initializing):
            messageLabel.text = "正在初始化AR Session. 请稍等..."
            messageLabel.textColor = UIColor.red
            addButton.isHidden = true

        default:
            messageLabel.text = ""
            addButton.isHidden = true
        }
    }
}
