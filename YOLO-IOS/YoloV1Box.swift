import Foundation

@objc class YoloV1Box: NSObject {
    let shapeLayer: CAShapeLayer
    let textLayer: CATextLayer
    var x: Float;
    var y: Float;
    var width: Float;
    var height: Float;
    var confidence: Float;
    var classIndex: Int;
    var label: String;
    
    @objc init(x: Float, y: Float, width: Float, height: Float, confidence: Float, classIndex: Int, label: String) {
        shapeLayer = CAShapeLayer()
        
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = 4
        shapeLayer.isHidden = false
        textLayer = CATextLayer()
        textLayer.foregroundColor = UIColor.black.cgColor
        textLayer.isHidden = false
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.fontSize = 14
        textLayer.font = UIFont(name: "Avenir", size: textLayer.fontSize)
        textLayer.alignmentMode = CATextLayerAlignmentMode.center
        self.x = x;
        self.y = y;
        self.width = width;
        self.height = height;
        self.confidence = confidence;
        self.classIndex = classIndex;
        self.label = label;
    }
    func addToLayer(_ parent: CALayer) {
        parent.addSublayer(shapeLayer)
        parent.addSublayer(textLayer)
    }
    func addTextToLayer(_ parent: CALayer) {
        parent.addSublayer(textLayer)
    }
    
    func show(frame: CGRect, label: String, color: UIColor) {
        CATransaction.setDisableActions(true)
        let path = UIBezierPath(rect: frame)
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = color.cgColor
        shapeLayer.isHidden = false
        
        textLayer.string = label
        textLayer.backgroundColor = color.cgColor
        textLayer.isHidden = false
        
        let attributes = [
            NSAttributedString.Key.font: textLayer.font as Any
        ]
        
        let textRect = label.boundingRect(with: CGSize(width: 400, height: 100),
                                          options: .truncatesLastVisibleLine,
                                          attributes: attributes, context: nil)
        let textSize = CGSize(width: textRect.width + 12, height: textRect.height)
        let textOrigin = CGPoint(x: frame.origin.x - 2, y: frame.origin.y - textSize.height)
        textLayer.frame = CGRect(origin: textOrigin, size: textSize)
    }
    func hide() {
        shapeLayer.isHidden = true
        textLayer.isHidden = true
    }
}

