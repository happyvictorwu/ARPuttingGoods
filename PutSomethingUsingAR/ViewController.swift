//
//  ViewController.swift
//  PutSomethingUsingAR
//
//  Created by Victor Wu on 2019/4/9.
//  Copyright © 2019 Victor Wu. All rights reserved.
//

import UIKit
import ARKit
import Alamofire
import SwiftyJSON

enum FunctionMode {
    case none
    case placeObject(String, String)
    case measure
}

class ViewController: UIViewController, UIGestureRecognizerDelegate {
    
    fileprivate var loadPrevious = host_cpu_load_info() // cpu需要使用
    
    // 初始化不变的信息
    let appId: String = "1233211234567"
    let appVersion:String = "v1.0"
    let deviceId: String = "iOS"
    
    // MARK: - 信息采集
    var cpuList: CpuInfo = CpuInfo.init()   // cpu的信息
    var memoryList: MemoryInfo = MemoryInfo.init()  // 内存信息
    
    var currentFurniture: Furniture!    // 当前模型信息
    
    // MARK: - 控件
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var vaseButton: CustomButton!
    @IBOutlet weak var chairButton: CustomButton!
    @IBOutlet weak var candleButton: CustomButton!
    @IBOutlet weak var measureButton: CustomButton!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var LightEstimationButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
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
        GestureRecognizerInit() // 初始化手势
        
        // 收集CPU，内存占用
        baseMobileInfo()
        
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
        selectVase()
    }
    
    @IBAction func didTapChair(_ sender: Any) {
        currentMode = .placeObject("Furniture.scnassets/chair/chair.scn", "Chair")
        selectButton(chairButton)
    }
    
    
    @IBAction func didTapCandle(_ sender: Any) {
        currentMode = .placeObject("Furniture.scnassets/candle/candle.scn", "Candle")
        selectButton(candleButton)
    }
    
    @IBAction func didTapReset(_ sender: Any) {
        removeAllObjects()
        distanceLabel.text = ""
        
        //TODO: - add Remove Action to server
    }
    
    @IBAction func didTapAddObject(_ sender: Any) {
        
        addButton.isHidden = true
        resetButton.isHidden = true
        confirmButton.isHidden = false
        
        currentFurniture = Furniture()
        print("create a new furniture")
        currentFurniture.actionInteractList.append(Action.Add)
        print("a new furniture create a Action-Add")
        
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
        
        // upload confirmFurniture info to server
        print("upload to serve")
   
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
        
    }
    
    // MARK: - 初始化配置
    func runSession() {
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
            sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
        #endif
    }
    
    func ResetSessionWithLight(chooseLight isLight: Bool ) {
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
        sceneView.session.run(configuration)
        #if DEBUG
        sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
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

}

extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        DispatchQueue.main.async {
            
            if let planeAnchor = anchor as? ARPlaneAnchor {
                self.messageLabel.text = "发现理想平面"
                self.messageLabel.textColor = UIColor.green
                #if DEBUG
                    let planeNode = createPlaneNode(center: planeAnchor.center, extent: planeAnchor.extent)
                    node.addChildNode(planeNode)
                #endif
            } else {
                
                switch self.currentMode {
                    case .none:
                        break
                    case .placeObject(let name, let ObjectName):
                        self.currentObject = SCNScene(named: name)!.rootNode.clone()
                        self.objects.append(self.currentObject)
                        self.currentFurniture.modelName = ObjectName
                        print("a new furniture has Model Name call: " + self.currentFurniture.modelName)
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
        case .normal :
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


extension ViewController: UIApplicationDelegate {
    
    func applicationWillTerminate(_ application: UIApplication) {
        print("background!")
        print("background!")
        print("background!")
        print("background!")
        print("background!")
        print("background!")
        baseMobileInfo()
    }
    
    //Get CPU
    func cpuUsage() -> (system: Double, user: Double, idle : Double, nice: Double){
        let load = hostCPULoadInfo();
        
        let usrDiff: Double = Double((load?.cpu_ticks.0)! - loadPrevious.cpu_ticks.0);
        let systDiff = Double((load?.cpu_ticks.1)! - loadPrevious.cpu_ticks.1);
        let idleDiff = Double((load?.cpu_ticks.2)! - loadPrevious.cpu_ticks.2);
        let niceDiff = Double((load?.cpu_ticks.3)! - loadPrevious.cpu_ticks.3);
        
        let totalTicks = usrDiff + systDiff + idleDiff + niceDiff
        print("Total ticks is ", totalTicks);
        let sys = systDiff / totalTicks * 100.0
        let usr = usrDiff / totalTicks * 100.0
        let idle = idleDiff / totalTicks * 100.0
        let nice = niceDiff / totalTicks * 100.0
        
        loadPrevious = load!
        
        return (sys, usr, idle, nice);
    }
    
    func baseMobileInfo() {
        Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: Selector(("collectMobileInfo")), userInfo: nil, repeats: true)
        
//        let urlCPU: String = "http://222.201.145.166:8421/ArAnalysis/CpuInfo/receiveCpuInfo"
//        let parameters: Parameters = [
//            "appId": "1233211234567",
//            "appVersion": "appVersion",
//            "deviceId": "dv",
//            "collectTime": "1554341709",
//            "cpuUsage": [
//                "cpuData": [1, 2, 3],
//                "timeData": [11, 22, 33]
//            ]
//        ]
//
//        Alamofire.request(urlCPU, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
//            debugPrint(response)
//        }
    }
    
    @objc func collectMobileInfo() {
        let cpuUserRatio:Double = cpuUsage().user
        let memoryRatio: Double = report_memory().ratio
        let time = calculateUnixTimestamp()
        
        // CPU
        cpuList.cpuData.append(cpuUserRatio)
        cpuList.timeData.append(time)
        
        // Memory
        memoryList.memoryData.append(memoryRatio)
        memoryList.timeData.append(time)
        
        print(cpuList.cpuData)
        print(memoryList.memoryData)
    }
}
