//
//  ViewController.swift
//  Let's Play Draw
//
//  Created by hosam on 12/3/19.
//  Copyright © 2019 hosam. All rights reserved.
//

import UIKit
import Vision

class ViewController: UIViewController {
    
    let canvas = CanvasView()
    lazy var clearButton:UIButton = {
        let b = UIButton()
        b.setTitle("Clear", for: .normal)
        b.setTitleColor(.red, for: .normal)
        b.addTarget(self, action: #selector(handleClear), for: .touchUpInside)
        b.constrainHeight(constant: 60)
        b.constrainWidth(constant: 60)
        b.backgroundColor = .white
        return b
    }()
    lazy var recognizeButton:UIButton = {
        let b = UIButton()
        b.setTitle("Recognize", for: .normal)
        b.setTitleColor(.blue, for: .normal)
        b.addTarget(self, action: #selector(handleRecognize), for: .touchUpInside)
        b.constrainHeight(constant: 60)
        b.backgroundColor = .white
        return b
    }()
    let outputLabel = UILabel(text: "draw numbers.....", font: .systemFont(ofSize: 40), textColor: .black, textAlignment: .center)
    var requests = [VNRequest]() // holds Image Classification Request
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupViews()
        setupVision()
    }
    
    func setupVision() {
        // load MNIST model for the use with the Vision framework
        guard let visionModel = try? VNCoreMLModel(for: MNIST().model) else {fatalError("can not load Vision ML model")}
        
        // create a classification request and tell it to call handleClassification once its done
        let classificationRequest = VNCoreMLRequest(model: visionModel, completionHandler: self.handleClassification)
        
        self.requests = [classificationRequest] // assigns the classificationRequest to the global requests array
        
    }
    
    func handleClassification (request:VNRequest, error:Error?) {
        guard let observations = request.results else {print("no results"); return}
        
        // process the ovservations
        let classifications = observations
            .flatMap({$0 as? VNClassificationObservation}) // cast all elements to VNClassificationObservation objects
            .filter({$0.confidence > 0.8}) // only choose observations with a confidence of more than 80%
            .map({$0.identifier}) // only choose the identifier string to be placed into the classifications array
        
        DispatchQueue.main.async {
            self.outputLabel.text = classifications.first // update the UI with the classification
        }
        
    }
    
    func setupViews()  {
        view.backgroundColor = .white
        outputLabel.constrainHeight(constant: 180)
        
        let buttons =   view.hstack(clearButton,UIView(),recognizeButton).withMargins(.init(top: 16, left: 16, bottom: 16, right: 16))
        view.stack(outputLabel,buttons,canvas, spacing: 8)
    }
    
   
    
    @objc  func handleClear()  {
        canvas.clearCanvas()
        outputLabel.text = "Draw..."
    }
    
    @objc  func handleRecognize()  {
        let image = UIImage(view: canvas) // get UIImage from CanvasView
        let scaledImage = image.scaleImage(image: image, toSize: CGSize(width: 28, height: 28)) // scale the image to the required size of 28x28 for better recognition results
        
        let imageRequestHandler = VNImageRequestHandler(cgImage: scaledImage.cgImage!, options: [:]) // create a handler that should perform the vision request
        
        do {
            try imageRequestHandler.perform(self.requests)
        }catch{
            print(error)
        }
    }
}

