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

    let green = UIColor(hexValue: 0x0FA45A)
    let red = UIColor(hexValue: 0xDA0032)
    let yellow = UIColor(hexValue: 0xF6AA42)
    
    @IBInspectable private var graphColor: UIColor = .white
    @IBInspectable private var pointRadius: CGFloat = 4
    @IBInspectable private var lineWidth: CGFloat = 2
    @IBInspectable private var maxRadiusScore: Double = 100
    
    private var graphPointValues = [GraphPoint]()
    
    private var isInitialSetupComplete = false
    
    weak var dataSource: CSGraphDataSource?
    
    private var dotLayers = [CAShapeLayer]()
    private var maskLayer: CAShapeLayer!
    
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        layer.contentsScale = UIScreen.main.scale
        layer.drawsAsynchronously = true
        layer.needsDisplayOnBoundsChange = true
        layer.setNeedsDisplay()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard !isInitialSetupComplete  else { return }
        initialSetup()
    }
    
    private func initialSetup() {
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
    }

    private func drawGraph() {

        let graphLinesPath = UIBezierPath()
        let graphDotsPath = UIBezierPath()
        var graphDotPaths = [Arc]()

        var startPoint: CGPoint! = nil

        var angle = -CGFloat.pi / 2
        let deltaAngle = (CGFloat.pi * 2) / CGFloat(graphPointValues.count)
        var colors = [UIColor]()
        
        for pv in graphPointValues {
            var c: UIColor
            
            c = pv.isPriority ? red : (pv.score < pv.avg ? yellow : green)
            colors.append(c)
            let scoreFactor = CGFloat(pv.score / maxRadiusScore)

            var newPoint = CGPoint.zero
            newPoint.x = bounds.midX + (bounds.midX * scoreFactor * cos(angle))
            newPoint.y = bounds.midY + (bounds.midY * scoreFactor * sin(angle))

            let arc = Arc(center: newPoint, radius: 6, lineWidth: 1.5, lineColor: .white, fillColor: c)
            graphDotPaths.append(arc)
            graphDotsPath.append(arc.bezierPath)
            
            if startPoint == nil {
                graphLinesPath.move(to: newPoint)
                startPoint = newPoint
            } else {
                graphLinesPath.addLine(to: newPoint)
            }
            angle += deltaAngle
        }
//        colors.append(colors[colors.count - 1])
//        colors.append(colors[colors.count - 1])
        colors.append(colors[0])
        let gradientLayer = ConicalGradientLay()
        gradientLayer.frame = bounds
        gradientLayer.colors = colors
        
        var locations = [1.0 / (5 * 2)]
        locations.append(locations[locations.count - 1] + (1.0 / 5))
        locations.append(locations[locations.count - 1] + (1.0 / 5))
        locations.append(locations[locations.count - 1] + (1.0 / 5))
        locations.append(locations[locations.count - 1] + (1.0 / 5))
        locations.append(locations[locations.count - 1] + (1.0 / (5 * 2)))
        gradientLayer.locations = locations
        
        layer.addSublayer(gradientLayer)
        
        graphLinesPath.addLine(to: startPoint)
        let lineLayer = CAShapeLayer()
        lineLayer.frame = bounds
        lineLayer.path = graphLinesPath.cgPath
        lineLayer.strokeColor = UIColor.black.cgColor
        lineLayer.fillColor = UIColor.clear.cgColor
        lineLayer.strokeStart = 0
        lineLayer.lineWidth = 3
        lineLayer.strokeEnd = 1
        
        
        let dotLayer = CAShapeLayer()
        dotLayer.frame = bounds
        for dotPath in graphDotPaths {
            let shapeLayer = CAShapeLayer(circle: dotPath, frame: bounds)
            layer.addSublayer(shapeLayer)
            dotLayers.append(shapeLayer)

            let maskShapeLayer = CAShapeLayer(circle: dotPath, frame: bounds)
            dotLayer.addSublayer(maskShapeLayer)
        }

        maskLayer = CAShapeLayer()
        maskLayer.frame = bounds
        maskLayer.addSublayer(lineLayer)
        maskLayer.addSublayer(dotLayer)
        layer.mask = maskLayer
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
