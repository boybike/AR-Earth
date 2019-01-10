//
//  ViewController.swift
//  AR Earth
//
//  Created by Alex on 2017/12/27.
//  Copyright © 2017年 Alex. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
extension float4x4 {
    /**
     Treats matrix as a (right-hand column-major convention) transform matrix
     and factors out the translation component of the transform.
     */
    var translation: float3 {
        let translation = columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: VirtualObjectARView!
    @IBOutlet var image: UIImageView!
    @IBOutlet var info: UIButton!
    @IBOutlet var btnLightButton: UIButton!
    
    @IBOutlet var replace: UIButton!
    let device = AVCaptureDevice.default(for: AVMediaType.video)
    var isLightOn = true
    var didAddedMap = false
    @IBOutlet var tapToStartButton: UIButton!
    var focusSquare = FocusSquare()
    var node: SCNNode?
    
    let configuration = ARWorldTrackingConfiguration()
//    var buttonWindow: UIWindow?
    var anchorNodeList = [SCNNode]()
    var screenCenter: CGPoint {
        let bounds = sceneView.bounds
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
    let updateQueue = DispatchQueue(label: "AREarth")
    var session: ARSession {
        return sceneView.session
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Set the view's delegate
        sceneView.delegate = self
        // Show statistics such as fps and timing information
//        sceneView.showsStatistics = true
        
        // Create a new scene
//        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        let scene = SCNScene()
        // Set the scene to the view
        sceneView.scene = scene
        
        self.addButtons()
        sceneView.scene.rootNode.addChildNode(focusSquare)

        self.resetConfiguration()
        
//        info.addTarget(self, action: #selector(infoAction), for: .touchUpInside)
        replace.alpha = 0
        tapToStartButton.addTarget(self, action: #selector(tapToStartButtonAction), for: .touchUpInside)
        btnLightButton.addTarget(self, action: #selector(lightControlButtonTouched), for: .touchUpInside)
        replace.addTarget(self, action: #selector(replaceAction), for: .touchUpInside)
//        self.hideAnchorNode()
        focusSquare.hide()

    }
    
    func resetConfiguration() {
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
   
    @IBAction func replaceAction(sender: UIButton) {
        self.node?.removeFromParentNode()
        image.alpha = 1
        btnLightButton.alpha = 1
        info.alpha = 1
        replace.alpha = 0
        
        self.didAddedMap = false
        
        self.resetConfiguration()
    }
    
    
    @IBAction func lightControlButtonTouched(sender: UIButton) {
        if device==nil{
            return
        }
        do{
            //锁定设备以便进行手电筒状态修改
            try device?.lockForConfiguration()
            if isLightOn{
                //设置手电筒模式为亮灯（On）
                device?.torchMode = AVCaptureDevice.TorchMode.on
                isLightOn = false
                //改变按钮标题
//                self.btnLightButton.setTitle("Off", for: UIControlState.normal)
                self.btnLightButton.setImage(UIImage.init(named: "on.png"), for: .normal)
                
            }else{
                //设置手电筒模式为关灯（Off）
                device?.torchMode = AVCaptureDevice.TorchMode.off
                isLightOn = true
                //改变按钮标题
//                self.btnLightButton.setTitle("On", for: UIControlState.normal)
              self.btnLightButton.setImage(UIImage.init(named: "off.png"), for: .normal)
            }
            //解锁设备锁定以便其他APP做配置更新
            device?.unlockForConfiguration()
        }catch{
            return
        }
    }

    func addButtons() {
       
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.sceneView.addGestureRecognizer(tapGesture)
//        print("greet family")

        
//        let infoTap = UITapGestureRecognizer(target: self, action: #selector(handleInfoTap(_:)));
//        info.addGestureRecognizer(infoTap)
//
//        let tap = UITapGestureRecognizer(target: self, action: #selector(handleImageTap(_:)));
//        image.addGestureRecognizer(tap)
        
        let pan2Gesture = UIPanGestureRecognizer(target: self, action: #selector(handle2Pan(_:)))
        pan2Gesture.minimumNumberOfTouches = 2
        self.sceneView.addGestureRecognizer(pan2Gesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchPan(_:)))
        self.sceneView.addGestureRecognizer(pinchGesture)
//        self.buttonWindow?.rootViewController?.view.addGestureRecognizer(tapGesture)
    }
    
//    var node:SCNNode!
    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        let touch = touches.first!
//        let point = touch.location(in:self.view)
//        if image.layer.contains(point){
//            finger.alpha = 0
//            text.alpha = 0
//
//        }
//        if info.layer.contains(point){
//            print("greet you lady")
//            let alertController = UIAlertController(title: nil, message: "负责人：张睿恺/nApp开发：尹浩然/n模型处理：章斯腾/n产品设计：石心泽/n美术：夏圆媛/n指导老师：张帅、杨康",preferredStyle:.alert)
//            //显示提示框
//            self.present(alertController, animated: true, completion: nil)
//            //五秒钟后自动消失
//            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) {
//                self.presentedViewController?.dismiss(animated: false, completion: nil)
//            }
//        }
//    }
    
//    @objc func handleInfoTap(_ gestureRecognize: UITapGestureRecognizer){
//        print("greet you lady")
//        let alertController = UIAlertController(title: nil, message: "负责人：张睿恺/nApp开发：尹浩然/n模型处理：章斯腾/n产品设计：石心泽/n美术：夏圆媛/n指导老师：张帅、杨康",preferredStyle:.alert)
//        //显示提示框
//        self.present(alertController, animated: true, completion: nil)
//        //五秒钟后自动消失
//        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) {
//            self.presentedViewController?.dismiss(animated: false, completion: nil)
//        }
//    }
//   @objc func handleImageTap(_ gestureRecognize: UITapGestureRecognizer){
//    print("greet you gentleman")
//    finger.alpha = 0
//    text.alpha = 0
//
//    }
    
    @objc func infoAction() {
        print("greet you lady")
//        let alertController = UIAlertController(title: nil, message: "口袋地球是一款基于增强现实技术（Augmented Reality）的IOS手机端软件产品。用户可以通过口袋地球App查看相应地区的增强信息，从而获得更为丰富有趣的体验。",preferredStyle:.alert)
//        //显示提示框
//        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
//        alertController.addAction(cancelAction)
//        self.present(alertController, animated: true, completion: nil)
    
        //五秒钟后自动消失
//
//        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) {
//            alertController.dismiss(animated: true, completion: nil)
//        }
    }
    
    @objc func tapToStartButtonAction() {
//        finger.alpha = 0
//        text.alpha = 0
        btnLightButton.alpha = 0
        info.alpha = 0
        image.alpha = 0
//        showAnchorNode()
    }
    
    @objc func handleTap(_ gestureRecognize: UITapGestureRecognizer) {
        // retrieve the SCNView
//        print("greet too")
        if let scnView = self.view as? SCNView {
           
            // check what nodes are tapped
            let p = gestureRecognize.location(in: scnView)
            
//            let pp = image.convert(p, from: scnView)
//            if image.layer.contains(pp){
//                finger.alpha = 0
//                text.alpha = 0
//
//            }
//            let ppp = info.convert(p, from: scnView)
//            if info.layer.contains(ppp){
//                print("greet you lady")
//                let alertController = UIAlertController(title: nil, message: "负责人：张睿恺/nApp开发：尹浩然/n模型处理：章斯腾/n产品设计：石心泽/n美术：夏圆媛/n指导老师：张帅、杨康",preferredStyle:.alert)
//                //显示提示框
//                self.present(alertController, animated: true, completion: nil)
//                //五秒钟后自动消失
//                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) {
//                    self.presentedViewController?.dismiss(animated: false, completion: nil)
//                }
//            }
            
            let hitResults = scnView.hitTest(p, options: [:])
            // check that we clicked on at least one object
           
            var didshownInfoView = false
//            if self.checkIfSingleClickAt(focusSquare) {
//                return
//            }
            if !didAddedMap {
                initViewAtAnchor()
            }
            print("greet anyway")
            for result: SCNHitTestResult in hitResults {
            
                print("greet us")
                let tempNode = result.node
                print(tempNode.name ?? "greet D")

                if !didshownInfoView {
                    didshownInfoView = showInfoView(tempNode)
                }
                
              
            
            }
        }
        
    }
    
    lazy var infoView: UIView = {
        let iv = UIView(frame: CGRect(x: 10, y: 10, width: self.view.bounds.size.width-20, height: self.view.bounds.size.height-20))
        iv.alpha = 0
        
        let butt = UIButton(frame: iv.bounds)
        butt.addTarget(self, action: #selector(hideInfoView), for: .touchUpInside)
        butt.tag = 666
        iv.addSubview(butt)
        
        iv.isUserInteractionEnabled = false
        self.view.addSubview(iv)
        return iv
    }()
    
    @objc func hideInfoView() {
        infoView.isUserInteractionEnabled = false
        for sub in infoView.subviews {
            if sub.tag != 666 {
                sub.removeFromSuperview()
            }
        }
    }
    
    func showInfoView(_ node: SCNNode) -> Bool {
        
        hideInfoView()
        
        let label = UIImageView(frame: CGRect(x: 10, y: 10, width: infoView.bounds.size.width-20, height: infoView.bounds.size.height-20))
        label.contentMode = UIViewContentMode.scaleAspectFill
        label.center = view.center
//        label.numberOfLines = 0
//        label.shadowColor = UIColor.lightGray.withAlphaComponent(0.5)
//        label.textColor = UIColor.white
        infoView.addSubview(label)
        
        var didGot = false
        
        if node.name == "ming"{
            
//            label.text = "明孝陵是明代开国皇帝朱元璋的陵墓，位于中山陵以西，2003年7月，作为“中国明清皇家陵寝”的扩展项目，列入世界遗产名录，成为古都南京的第一处世界文化遗产明孝陵从1376年筹建，至1413年竣工，虽历经600多年沧桑，但主体建筑犹存，历史风貌依然。它是中国现存建筑规模最大的帝王陵墓之一。明孝陵“前朝后寝、前方后圆”的陵宫布局设计和方城明楼、宝城宝顶等建筑形式，开创了中国明清帝王陵寝建设规制的先河，北京的十三陵、河北省的清东陵、西陵、沈阳市的清福陵、昭陵，都是依照南京明孝陵的建设规制而建造的，因此被誉为中国帝陵发展史上的一座里程碑。明孝陵的神道蜿蜒曲折，整体布局呈现出了“北斗七星”的形状，这种不拘一格的神道布局，在中国帝王陵寝中具有唯一性。明孝陵尚未发掘的地下宫殿，更具有浓郁的神秘色彩。南京梅花山面积达到1533亩，植梅近4万株，品种增加到350多种，成为名副其实的天下第一梅山。"
            label.image = UIImage(named: "明孝陵.png")
            didGot = true
            
        }else if node.name == "peak"{
            
//            label.text = " 山顶公园位紫金山于头陀岭景区——钟山主峰之西，为钟山二峰，海拔425米。这里地势险要，峭石 壁立，风光绝佳，历代不少帝王将相，文人墨客来此寻幽探胜，留下许多珍贵遗迹。登高远眺，古城南京万千气象、沧桑巨变尽收眼底。景区内有闻名中外的紫金山天文台，历尽沧桑的天堡城以及刘基洞、弹琴石、黑龙潭、白云泉、江南第一弥勒佛坐像等众多胜迹。"
            label.image = UIImage(named: "山顶公园.png")
            didGot = true
            
        }else if node.name == "white horse"{
            
//            label.text = "白马公园位于钟山风景区的湖（玄武湖）山（钟山）接合部，占地500余亩，与玄武湖隔堤相望，湖水一脉相通，并与周边景观形成一条气势非凡的环湖景观带，最能体现南京山、水、城、林融汇一体的特色。白马公园充分结合区内人文景观和地势地貌，集中展示了原散落于南京四周的古代石刻文物一千多件，间植碧桃等植物万余株，草坪九千平方米，形成一座融知识、趣味、观赏、休闲为一体的市民公园，既有浓郁历史文化氛围，又有鲜明现代气息。"
            label.image = UIImage(named: "白马公园.png")

            didGot = true
            
        }else if node.name == "meiling" {
            
//            label.text = "美龄宫位于南京市区东郊四方城以东200米的小红山上。正式名称是“国民政府主席官邸”，因其位于小红山上，又称“小红山官邸”。1991年被国家建设部评为中国近代优秀建筑，2001年被国家文物局列为国家级重点文物保护单位。美龄宫始建于1931年，是一座依山而建的中西合璧式建筑。建筑外观极富中国古典韵味，内部结构、装饰具西洋风格，层次错落有致，分布有典型的西方取暖壁炉、宽大的洗浴室及现代的卫生洁具。墙面、门、窗采用现代结构形式，宽大的落地式钢门、钢窗，采光极好，室内设计现代、实用，建筑结构广泛采用了现代建筑技术——钢筋混凝土的结构技术。暗管式上、下排水。有宽大的阳台设计、现代水磨石工艺和颜色拼花瓷砖地面等。整体建筑设计别开生面，完美地将中国传统的建筑风格、建筑文化与西方现代建筑技术和手法相结合，使这幢宫殿式建筑达到了中国近代建筑史上完美的境界。当年被美国驻华大使司徒雷登赞誉为“远东第一别墅”。美龄宫主楼建筑分为：地下一层，地面二层。中层与上层之间有个半层。上层北侧有个约1米高的跃层，为蒋氏夫妇专用餐厅。下层东部分布有侍卫室、衣帽间、机要室等。中层主要作为社交活动和大型宴请场所，设有大厅、客厅、大宴会厅、卫生设施、配膳房等。上层主要为蒋氏夫妇生活、起居场所。有卧室、书房、蒋氏夫妇专用餐厅、浴室卫生间、读圣经作礼拜的凯歌堂等。现在的美龄宫内部另辟出宋美龄与美龄宫文物史料陈列馆、民国影院、咖啡吧、文史书吧等。陈列馆分宋氏传奇人生、国府主席官邸、世人评说等三个部分，通过文字、图片以及实物复制品的形式，反映宋美龄生平与美龄宫历史文化艺术特色。充满民国韵味的影院，以放映宋美龄影像资料为主，显示她的智慧才华与雍容华贵，展现她集政治家、外交家、艺术家于一身的传奇人生。"
            label.image = UIImage(named: "白马公园.png")

            didGot = true
            
        }else if node.name == "music"{
            
//            label.text = "中山陵音乐台位于南京市玄武区紫金山钟山风景名胜区中山陵广场东南。建于1932年至1933年，占地面积约为4200平方米，由关颂声、杨廷宝设计，1932年秋动工兴建，1933年8月建成。音乐台是中山陵的配套工程，主要用作纪念孙中山先生仪式时的音乐表演及集会演讲。音乐台建筑风格为中西合璧，在利用自然环境，以及平面布局和立面造型上，充分吸收古希腊建筑特点，而在照壁、乐坛等建筑物的细部处理上，则采用中国江南古典园林的表现形式。从而创造出既有开阔宏大的空间效果，又有精湛雕饰的艺术风范，达到了自然与建筑的完美和谐统一。2017年12月2日，南京中山陵音乐台入选“中国20世纪建筑遗产”"
            label.image = UIImage(named: "音乐台.png")

            didGot = true
            
        }else if node.name == "sun"{
            
//            label.text = "中山陵位于南京市玄武区紫金山南麓钟山风景区内，是中国近代伟大的民主革命先行者孙中山先生的陵寝，及其附属纪念建筑群，面积8万余平方米。中山陵自1926年春动工，至1929年夏建成，1961年成为首批全国重点文物保护单位，2006年列为首批国家重点风景名胜区和国家5A级旅游景区，2016年入选“首批中国20世纪建筑遗产”名录。中山陵前临平川，背拥青嶂，东毗灵谷寺，西邻明孝陵，整个建筑群依山势而建，由南往北沿中轴线逐渐升高，主要建筑有博爱坊、墓道、陵门、石阶、碑亭、祭堂和墓室等，排列在一条中轴线上，体现了中国传统建筑的风格，从空中往下看，像一座平卧在绿绒毯上的“自由钟”。融汇中国古代与西方建筑之精华，庄严简朴，别创新格。 中山陵各建筑在型体组合、色彩运用、材料表现和细部处理上均取得极好的效果，音乐台、光华亭、流徽榭、仰止亭、藏经楼、行健亭、永丰社、永慕庐、中山书院等建筑众星捧月般环绕在陵墓周围，构成中山陵景区的主要景观，色调和谐统一更增强了庄严的气氛，既有深刻的含意，又有宏伟的气势，且均为建筑名家之杰作，有着极高的艺术价值，被誉为“中国近代建筑史上第一陵”。"
            label.image = UIImage(named: "中山陵.png")

            didGot = true
            
        }else if node.name == "linggu"{
            
//            label.text = "位于中山陵以东约一公里处的灵谷景区，原为明朝“天下第一禅林”灵谷寺所在地，景区内汇集了六朝时期名僧宝志（即济公和尚原型）的墓塔；我国时代最早、规模最大的拱券结构建筑——明代无梁殿等众多名胜古迹。1928年，国民政府在灵谷寺旧址改建国民革命军阵亡将士公墓，留下了大仁大义牌坊、松风阁、灵谷塔等一批民国建筑精品，加之国民政府主席谭延闿墓、中国农工民主党创始人邓演达墓、国民政府主席林森的别墅——桂林石屋等，使这里成为风景区内又一处重要的民国文化展示区。灵谷景区万斛松涛、秀木佳林，是一座天然的“大氧吧”和游客休闲放松、享受生态的极佳场所。景区内近年规划建设了大型桂花专类园，面积达1700多亩，有桂花40多个品种18000余株，每至深秋，桂花飘香，景色格外迷人。"
            label.image = UIImage(named: "灵谷寺.png")

             didGot = true
            
        }
        
        infoView.alpha = 0
        UIView.animate(withDuration: 1, animations: {
            self.infoView.alpha = 1
        }) { (bo) in
            self.infoView.isUserInteractionEnabled = true
        }
        
        return didGot
        
    }
    var startRotateVector: SCNVector3!
    @objc func handle2Pan(_ gestureRecognize: UIPanGestureRecognizer) {
        if gestureRecognize.state == .began {
            startRotateVector = self.node?.eulerAngles
        } else if gestureRecognize.state == .changed {
            if startRotateVector == nil {
                startRotateVector = self.node?.eulerAngles
                return
            }
            
            let movedX = Float(gestureRecognize.translation(in: self.view).x/30)
            _ = self.node?.eulerAngles = SCNVector3Make(startRotateVector.x, startRotateVector.y+movedX, startRotateVector.z)
        } else {
            startRotateVector = nil
        }
        
    }
    
    var startScaleVector: SCNVector3!
    @objc func pinchPan(_ gestureRecognize: UIPinchGestureRecognizer) {
        if gestureRecognize.state == .began {
            startScaleVector = self.node?.scale
        } else if gestureRecognize.state == .changed {
            if startScaleVector == nil {
                startScaleVector = self.node?.scale
                return
            }
            
            let scale = Float(gestureRecognize.scale)
            _ = self.node?.scale=SCNVector3Make(startScaleVector.x*scale, startScaleVector.y*scale, startScaleVector.z*scale)
        } else {
            startScaleVector = nil
        }
        
    }
    
    func updateFocusSquare() {
       
        if didAddedMap {
            focusSquare.hide()
        } else {
            focusSquare.unhide()
        }
        
        // We should always have a valid world position unless the sceen is just being initialized.
        guard let (worldPosition, planeAnchor, _) = sceneView.worldPosition(fromScreenPosition: screenCenter, objectPosition: focusSquare.lastPosition) else {
            updateQueue.async {
                self.focusSquare.state = .initializing
                self.sceneView.pointOfView?.addChildNode(self.focusSquare)
            }
//            addObjectButton.isHidden = true
            return
        }
        
        updateQueue.async {
            self.sceneView.scene.rootNode.addChildNode(self.focusSquare)
            let camera = self.session.currentFrame?.camera
            
            if let planeAnchor = planeAnchor {
                self.focusSquare.state = .planeDetected(anchorPosition: worldPosition, planeAnchor: planeAnchor, camera: camera)
            } else {
                self.focusSquare.state = .featuresDetected(anchorPosition: worldPosition, camera: camera)
            }
        }
//        addObjectButton.isHidden = false
    }
//    func checkIfSingleClickAt(_ node: SCNNode) -> Bool{
//        if self.didAddedMap {
//            return false
//        }
//        print("greet them")
//        if let anchor = sceneView.anchor(for: node) {
//            print("greet all")
//            self.add(anchor)
//            self.didAddedMap = true
//            return true
//        }
//        return false
//    }
//    func add(_ anchor: ARAnchor!) {
//        configuration.planeDetection = .init(rawValue: 0)
//        self.hideAnchorNode()
//        print("greet me")
//        self.initViewAtAnchor(anchor)
//    }

    func initViewAtAnchor (){
       print("greet you")
//        let scnscene = SCNScene.init(named: "art.scnassets/aaaa/map.scn")
//        node = scnscene!.rootNode.childNode(withName: "main_out", recursively: true)! as? VirtualObject
//        print(VirtualObject.availableObjects.count)
//        let tempN = VirtualObject.availableObjects[1]
//        node = VirtualObject.availableObjects[1]
//        if anchor != nil {
//            node.transform = sceneView.node(for: anchor)!.convertTransform(SCNMatrix4Identity, to: sceneView.scene.rootNode)
//        }
//        node?.scale = SCNVector3Make(0.01, 0.01, 0.01)
//        sceneView.scene.rootNode.addChildNode(node)
        
        replace.alpha = 1
        
//        self.node = VirtualObject.availableObjects[2]
//
//        let cameraTransform = session.currentFrame?.camera.transform
        let focusSquarePosition = focusSquare.lastPosition
//        print(focusSquarePosition)
//        node?.setPosition(focusSquarePosition!, relativeTo: cameraTransform!, smoothMovement: false)
//
//        node?.scale = SCNVector3Make(0.01, 0.01, 0.01)
        
        updateQueue.async {
            if !self.didAddedMap {
                let scnscene = SCNScene.init(named: "art.scnassets/aaaa/map.scn")!
                self.node = scnscene.rootNode.childNode(withName: "main", recursively: true)!
                self.sceneView.scene.rootNode.addChildNode(self.node!)
                self.node?.position = SCNVector3Make(focusSquarePosition![0], focusSquarePosition![1], focusSquarePosition![2])
                self.sceneView.scene.rootNode.addChildNode(self.node!)
                self.focusSquare.hide()
                self.didAddedMap = true
            }
//            else {
//                self.node?.position = SCNVector3Make(focusSquarePosition![0], focusSquarePosition![1], focusSquarePosition![2])
//            }
        }
        replace.alpha = 1
    }
    
//    func hideAnchorNode() {
//        for node in self.anchorNodeList {
//            if let plane = node.childNode(withName: "targetPlane", recursively: true) {
//                plane.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
//            }
//        }
//    }
//    func showAnchorNode() {
//        for node in self.anchorNodeList {
//            if let plane = node.childNode(withName: "targetPlane", recursively: true) {
//                plane.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "target")
//            }
//        }
//    }
   
//    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
//        print("nodeFor")
//        let node = SCNNode()
//        let plane = SCNNode(geometry: SCNPlane(width: 0.1, height: 0.1))
//        plane.name = "targetPlane"
//
//        if didAddedMap {
//            plane.geometry?.firstMaterial?.diffuse.contents = UIColor.clear
//        } else {
//            plane.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "target")
//        }
//
//        plane.eulerAngles = SCNVector3Make(-.pi/2, 0, 0)
//        node.addChildNode(plane)
//        return node
//    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("didAdd")
        for nn in self.anchorNodeList {
            if nn === node {
                return
            }
        }
        self.anchorNodeList.append(node)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        print("didRemove")
        for nn in self.anchorNodeList.enumerated() {
            if nn.element === node {
                self.anchorNodeList.remove(at: nn.offset)
                return
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.updateFocusSquare()
        }
        
        // If light estimation is enabled, update the intensity of the model's lights and the environment map
        let baseIntensity: CGFloat = 40
        let lightingEnvironment = sceneView.scene.lightingEnvironment
        if let lightEstimate = session.currentFrame?.lightEstimate {
            lightingEnvironment.intensity = lightEstimate.ambientIntensity / baseIntensity
        } else {
            lightingEnvironment.intensity = baseIntensity
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        self.on.alpha = 0
//        self.off.alpha = 1
//        // Create a session configuration
//        let configuration = ARWorldTrackingConfiguration()
//
//        // Run the view's session
//        sceneView.session.run(configuration)
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the view's session
//        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
