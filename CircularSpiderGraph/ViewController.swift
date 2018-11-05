//
//  ViewController.swift
//  CircularSpiderGraph
//
//  Created by Prateek Sharma on 10/18/18.
//  Copyright © 2018 Prateek Sharma. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak private var gradView: CSGraphView! {
        didSet {
            gradView.dataSource = self
        }
    }
    
}

extension ViewController: CSGraphDataSource {
    
    func numberOfPoints(forGraph graph: CSGraphView) -> Int {
        return 5
    }
    
    func valuesForPoint(atIndex index: Int, forGraph graph: CSGraphView) -> GraphPoint {
        switch index {
        case 0: return GraphPoint(score: 75, avg: 90, isPriority: false)
        case 1: return GraphPoint(score: 69, avg: 50, isPriority: false)
        case 2: return GraphPoint(score: 100, avg: 75, isPriority: false)
        case 3: return GraphPoint(score: 51, avg: 50, isPriority: true)
        case 4: return GraphPoint(score: 56, avg: 60, isPriority: true)
        default: return GraphPoint(score: 100, avg: 100, isPriority: false)
        }
    }
    
}
