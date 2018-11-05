//
//  CSGraphView.swift
//  CircularSpiderGraph
//
//  Created by Prateek Sharma on 10/18/18.
//  Copyright © 2018 Prateek Sharma. All rights reserved.
//

import UIKit

struct GraphPoint {
    let score: Double
    let avg: Double
    let isPriority: Bool
}

protocol CSGraphDataSource: class {
    func numberOfPoints(forGraph graph: CSGraphView) -> Int
    func valuesForPoint(atIndex index: Int, forGraph graph: CSGraphView) -> GraphPoint
}

class CSGraphView: UIView {
    
    private var viewCenter: CGPoint { return CGPoint(x: bounds.width / 2, y: bounds.height / 2) }
    
    @IBInspectable private var goodResultColor: UIColor = UIColor(hexValue: 0x0FA45A)
    @IBInspectable private var okayResultColor: UIColor = UIColor(hexValue: 0xF6AA42)
    @IBInspectable private var badResultColor: UIColor = UIColor(hexValue: 0xDA0032)
    
    @IBInspectable private var graphColor: UIColor = .white
    @IBInspectable private var pointRadius: CGFloat = 4
    @IBInspectable private var lineWidth: CGFloat = 2
    @IBInspectable private var maxRadiusScore: Double = 100
    
    private var graphPointValues = [GraphPoint]()
    
    private var isInitialSetupComplete = false
    
    weak var dataSource: CSGraphDataSource?
    
    private var dotLayers = [CAShapeLayer]()
    private var maskLayer: CAShapeLayer!
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard !isInitialSetupComplete  else { return }
        initialSetup()
    }
    
    private func initialSetup() {
        isInitialSetupComplete = true
        maxRadiusScore = (maxRadiusScore > 0) ? maxRadiusScore : 100
        pointRadius = (pointRadius > 0) ? pointRadius : 4
        lineWidth = (lineWidth > 0) ? lineWidth : 2
        
        loadData()
    }
    
    func reloadData() {
        graphPointValues.removeAll()
        subviews.forEach { $0.removeFromSuperview() }
        layer.sublayers?.forEach({ $0.removeFromSuperlayer() })
        
        loadData()
    }
    
    private func loadData() {
        guard let ds = dataSource  else { return }
        let numOfPoints = max(ds.numberOfPoints(forGraph: self), 0)
        for i in 0..<numOfPoints {
            graphPointValues.append(ds.valuesForPoint(atIndex: i, forGraph: self))
        }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        drawGraph()
        addAvgAnnotations()
    }
    
    private func addAvgAnnotations() {
        var angle = -CGFloat.pi / 2
        let deltaAngle = (CGFloat.pi * 2) / CGFloat(graphPointValues.count)
        
        for pv in graphPointValues {
            let scoreFactor = CGFloat(pv.avg / maxRadiusScore)
            let radius = CGSize(width: viewCenter.x * scoreFactor, height: viewCenter.y * scoreFactor)
            let center = pointOnEclipse(atAngle: angle, center: viewCenter, radius: radius)
            
            let imageView = UIImageView(image: UIImage(named: "avgResultGraphAnnotation"))
            imageView.center = center
            addSubview(imageView)
            
            angle += deltaAngle
        }
        
    }
    
    private func drawGraph() {
        guard graphPointValues.count > 2  else { return }
        var graphDotPaths = [Arc]()
        var startPoint: CGPoint! = nil
        var lastPoint: CGPoint! = nil
        var angle = -CGFloat.pi / 2
        let deltaAngle = (CGFloat.pi * 2) / CGFloat(graphPointValues.count)
        var colors = [CGColor]()
        for pv in graphPointValues {
            let scoreFactor = CGFloat(pv.score / maxRadiusScore)
            let resultColor = pv.isPriority ? badResultColor : (pv.score < pv.avg ? okayResultColor : goodResultColor)
            
            let radius = CGSize(width: viewCenter.x * scoreFactor, height: viewCenter.y * scoreFactor)
            let newPoint = pointOnEclipse(atAngle: angle, center: viewCenter, radius: radius)
            
            let arc = Arc(center: newPoint, radius: 6, lineWidth: 1.5, lineColor: .white, fillColor: resultColor)
            graphDotPaths.append(arc)
            
            if startPoint == nil {
                startPoint = newPoint
            } else {
                lineLayer(startPoint: lastPoint, endPoint: newPoint, gradientColors: [colors[colors.count - 1], resultColor.cgColor])
            }
            colors.append(resultColor.cgColor)
            lastPoint = newPoint
            angle += deltaAngle
        }
        lineLayer(startPoint: lastPoint, endPoint: startPoint, gradientColors: [colors[colors.count - 1], colors[0]])
        
        addToLayer(graphDotPaths)
    }
    
    func lineLayer(startPoint: CGPoint, endPoint: CGPoint, gradientColors: [CGColor]) {
        let padding: CGFloat = 2
        let lineLayer = CAShapeLayer()
        let layerOrigin = CGPoint(x: min(startPoint.x, endPoint.x) - padding, y: min(startPoint.y, endPoint.y) - padding)
        let layerSize = CGSize(width: abs(startPoint.x - endPoint.x) + (padding * 2), height: abs(startPoint.y - endPoint.y) + (padding * 2))
        
        let graphLinesPath = UIBezierPath()
        graphLinesPath.move(to: CGPoint(x: startPoint.x - layerOrigin.x, y: startPoint.y - layerOrigin.y))
        graphLinesPath.addLine(to: CGPoint(x: endPoint.x - layerOrigin.x, y: endPoint.y - layerOrigin.y))
        
        lineLayer.frame = CGRect(origin: CGPoint.zero, size: layerSize)
        lineLayer.path = graphLinesPath.cgPath
        lineLayer.strokeColor = UIColor.black.cgColor
        lineLayer.fillColor = UIColor.clear.cgColor
        lineLayer.strokeStart = 0
        lineLayer.lineWidth = 3
        lineLayer.strokeEnd = 1
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = gradientColors
        gradientLayer.startPoint = CGPoint(x: startPoint.x < endPoint.x ? 0 : 1, y: startPoint.y < endPoint.y ? 0 : 1)
        gradientLayer.endPoint = CGPoint(x: startPoint.x > endPoint.x ? 0 : 1, y: startPoint.y > endPoint.y ? 0 : 1)
        gradientLayer.frame = CGRect(origin: layerOrigin, size: layerSize)
        gradientLayer.mask = lineLayer
        
        layer.addSublayer(gradientLayer)
    }
    
    func pointOnEclipse(atAngle angle: CGFloat, center: CGPoint, radius: CGSize) -> CGPoint {
        var point = CGPoint.zero
        point.x = center.x + (radius.width * cos(angle))
        point.y = center.y + (radius.height * sin(angle))
        return point
    }
    
    //    func maskLayerUsing(dotArcs: [Arc], lineLayers: [CALayer]) {
    //        let dotMaskLayer = createDotMaskLayer(from: dotArcs)
    
    //        maskLayer = CAShapeLayer()
    //        maskLayer.frame = bounds
    //        maskLayer.addSublayer(lineLayers)
    //        maskLayer.addSublayer(dotMaskLayer)
    //        layer.mask = maskLayer
    //    }
    
    func addToLayer(_ dotPaths: [Arc]) {
        for dotPath in dotPaths {
            let shapeLayer = CAShapeLayer(circle: dotPath, frame: bounds)
            layer.addSublayer(shapeLayer)
            dotLayers.append(shapeLayer)
        }
    }
    
    func createDotMaskLayer(from dotPaths: [Arc]) -> CAShapeLayer {
        let dotMaskLayer = CAShapeLayer()
        dotMaskLayer.frame = bounds
        for dotPath in dotPaths {
            let maskShapeLayer = CAShapeLayer(circle: dotPath, frame: bounds)
            dotMaskLayer.addSublayer(maskShapeLayer)
        }
        
        return dotMaskLayer
    }
    
}



struct Arc {
    
    let radius: CGFloat
    let center: CGPoint
    var startAngle: CGFloat
    var endAngle: CGFloat
    var clockWise: Bool
    var lineWidth: CGFloat
    var lineColor: UIColor
    var fillColor: UIColor
    
    
    init(center: CGPoint, radius: CGFloat, startAngle: CGFloat = 0, endAngle: CGFloat = (CGFloat.pi * 2), clockWise: Bool = true, lineWidth: CGFloat = 1, lineColor: UIColor = .black, fillColor: UIColor = .clear) {
        self.center = center
        self.radius = radius
        self.startAngle = startAngle
        self.endAngle = endAngle
        self.clockWise = clockWise
        self.lineWidth = lineWidth
        self.lineColor = lineColor
        self.fillColor = fillColor
    }
    
    var bezierPath: UIBezierPath {
        return UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: clockWise)
    }
    
}

extension CAShapeLayer {
    
    convenience init(circle: Arc, frame: CGRect) {
        self.init()
        let circlePath = circle.bezierPath
        
        self.frame = frame
        path = circlePath.cgPath
        lineWidth = circle.lineWidth
        strokeColor = circle.lineColor.cgColor
        fillColor = circle.fillColor.cgColor
        strokeStart = 0
        strokeEnd = 1
    }
    
}

extension UIColor {
    
    convenience init(hexValue: UInt32, alpha: CGFloat = 1.0) {
        let red = CGFloat((hexValue & 0xFF0000) >> 16)/255.0
        let green = CGFloat((hexValue & 0xFF00) >> 8)/255.0
        let blue = CGFloat(hexValue & 0xFF)/255.0
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    convenience init(rgb: UInt) {
        self.init(
            red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgb & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
}
