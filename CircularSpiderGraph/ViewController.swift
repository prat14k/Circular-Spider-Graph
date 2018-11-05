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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
    }

}

extension ViewController: CSGraphDataSource {
    
    func numberOfPoints(forGraph graph: CSGraphView) -> Int {
        return 5
    }
    
    func valuesForPoint(atIndex index: Int, forGraph graph: CSGraphView) -> GraphPoint {
        return (score: 100, avg: 100)
    }
    
}
