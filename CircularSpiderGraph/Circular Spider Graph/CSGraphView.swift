//
//  CSGraphView.swift
//  CircularSpiderGraph
//
//  Created by Prateek Sharma on 10/18/18.
//  Copyright © 2018 Prateek Sharma. All rights reserved.
//

import UIKit

typealias GraphPoint = (score: Double, avg: Double)

protocol CSGraphDataSource: class {
    func numberOfPoints(forGraph graph: CSGraphView) -> Int
    func valuesForPoint(atIndex index: Int, forGraph graph: CSGraphView) -> GraphPoint
}

class CSGraphView: UIView {

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
        drawGraph()
    }

    private func drawGraph() {

        let graphLinesPath = UIBezierPath()
        let graphDotsPath = UIBezierPath()
        var graphDotPaths = [Arc]()

        var startPoint: CGPoint! = nil

        var angle = -CGFloat.pi / 2
        let deltaAngle = (CGFloat.pi * 2) / CGFloat(graphPointValues.count)
        
        for pv in graphPointValues {
            let scoreFactor = CGFloat(pv.score / maxRadiusScore)

            var newPoint = CGPoint.zero
            newPoint.x = bounds.midX + (bounds.midX * scoreFactor * cos(angle))
            newPoint.y = bounds.midY + (bounds.midY * scoreFactor * sin(angle))

            let arc = Arc(center: newPoint, radius: 10, lineWidth: 2, lineColor: .white, fillColor: .red)
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
        
        graphLinesPath.addLine(to: startPoint)
        let lineLayer = CAShapeLayer()
        lineLayer.frame = bounds
        lineLayer.path = graphLinesPath.cgPath
        lineLayer.strokeColor = UIColor.black.cgColor
        lineLayer.fillColor = UIColor.clear.cgColor
        lineLayer.strokeStart = 0
        lineLayer.lineWidth = 2
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
