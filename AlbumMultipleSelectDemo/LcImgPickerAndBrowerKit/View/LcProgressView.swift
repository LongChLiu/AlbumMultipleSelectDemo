//
//  LcProgressView.swift
//  AlbumMultipleSelectDemo
//
//  Created by 刘隆昌 on 2020/9/28.
//  Copyright © 2020 刘隆昌. All rights reserved.
//

import UIKit

class LcProgressView: UICollectionViewCell {
    
    
    var progress: Double = 0 {
        didSet {
            self.setNeedsDisplay()
            if progress == 1 {
                self.removeFromSuperview()
            }
        }
    }
    
    static func showLcProgressView(in parentView: UIView, frame: CGRect) -> LcProgressView {
        
        var progressView = parentView.viewWithTag(9999) as? LcProgressView
        
        guard (progressView != nil) else {
            progressView = LcProgressView(frame: frame)
            progressView!.tag = 9999
            //            progressView!.center = parentView.center
            progressView!.backgroundColor = UIColor.clear
            parentView.addSubview(progressView!)
            let radius = progressView!.frame.width/2
            let path = UIBezierPath(arcCenter: CGPoint(x: radius, y: radius), radius: CGFloat(radius), startAngle: 0, endAngle: CGFloat(Double.pi*2), clockwise: true)
            let circlePathLayer = CAShapeLayer()
            circlePathLayer.lineWidth = 2
            circlePathLayer.fillColor = UIColor.clear.cgColor
            circlePathLayer.strokeColor = UIColor.white.cgColor
            circlePathLayer.path = path.cgPath
            progressView!.layer.addSublayer(circlePathLayer)
            return progressView!
        }
        progressView!.frame = frame
        
        return progressView!
    }
    
    override func draw(_ rect: CGRect) {
        // Drawing code
        
        // 1.获取上下文
        let ctx = UIGraphicsGetCurrentContext()
        
        // 2.拼接路径
        let radius = self.frame.width/2
        let center = CGPoint(x: radius, y: radius)
        let startA = -Double.pi/2
        let endA = -Double.pi/2+progress*Double.pi*2
        let path = UIBezierPath(arcCenter: center, radius: CGFloat(radius/2), startAngle: CGFloat(startA), endAngle: CGFloat(endA), clockwise: true)
        ctx!.setLineWidth(CGFloat(radius));
        // 3.把路径添加到上下文
        UIColor.white.set()
        ctx!.addPath(path.cgPath);
        
        // 4.把上下文渲染到视图
        ctx!.strokePath();
    }
    
}
