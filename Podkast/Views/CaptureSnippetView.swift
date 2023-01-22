//
//  RecordSnippetView.swift
//  Podkast
//
//  Created by Liam Idrovo on 1/18/23.
//

import Foundation

import UIKit

class CaptureSnippetView: UIView {
    
    private let outerCircle = UIView(frame: .zero)
    private let innerCircle = UIView(frame: .zero)
    private let label = UILabel()
    private var smallCircleWidthConstraint: NSLayoutConstraint?
    private var bigCircleWidthConstraint: NSLayoutConstraint?
    var pressDownHandler: (() -> Void)?
    var pressStopHandler: (() -> Void)?
    let INNER_WIDTH_MULTIPLER = 0.6
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        prepareSubview()
    }
    
    required init?(coder: NSCoder) {
        // We don't have to implement this init because we're not getting the view from Storyboard
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 0.5 * self.bounds.width
        
        outerCircle.layer.masksToBounds = true
        outerCircle.layer.cornerRadius = 0.5 * outerCircle.bounds.width
        innerCircle.layer.cornerRadius = 0.5 * innerCircle.bounds.width
        
    }
    
    func pressDown(handler: (() -> Void)? = nil) {
        guard var smallConstraint = smallCircleWidthConstraint,
              var bigConstraint = bigCircleWidthConstraint else {return}
        
        self.layoutIfNeeded()
        smallConstraint.isActive = false
        bigConstraint.isActive = true
        
        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
        
        // playback state retrieval will be passed in as this handler
        if handler != nil {handler!()}
        
    }
    
    func pressStop(handler: (() -> Void)?) {
        guard var smallConstraint = smallCircleWidthConstraint,
              var bigConstraint = bigCircleWidthConstraint else {return}
        
        self.layoutIfNeeded()
        smallConstraint.isActive = true
        bigConstraint.isActive = false
        
        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
        
        if handler != nil {handler!()}
    }
    
    private func prepareSubview() {
        addSubview(outerCircle)
        addSubview(label)
        outerCircle.addSubview(innerCircle)
        label.text = "Capture"
        label.font = UIFont(name: "System", size: 10)
        label.textColor = .white
        // Prevents system from automatically specifying the view's size and position. Basically, allowing constraints to work.
        outerCircle.translatesAutoresizingMaskIntoConstraints = false
        innerCircle.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        // Fixed aspect ratio
        heightAnchor.constraint(equalTo: widthAnchor, constant: 1).isActive = true
        outerCircle.heightAnchor.constraint(equalTo: outerCircle.widthAnchor, constant: 1).isActive = true
        innerCircle.heightAnchor.constraint(equalTo: innerCircle.widthAnchor, constant: 1).isActive = true
        // Centering
        outerCircle.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        outerCircle.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        innerCircle.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        innerCircle.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        label.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        // Setting size
        smallCircleWidthConstraint = outerCircle.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: INNER_WIDTH_MULTIPLER)
        bigCircleWidthConstraint = outerCircle.widthAnchor.constraint(equalTo: self.widthAnchor)
        smallCircleWidthConstraint!.isActive = true
    
        innerCircle.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: INNER_WIDTH_MULTIPLER).isActive = true

        outerCircle.backgroundColor = .systemPink
        innerCircle.backgroundColor = .red
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Docs said to call super!
        super.touchesBegan(touches, with: event)
        pressDown(handler: pressDownHandler)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        pressStop(handler: pressStopHandler)
    }
}
