//
//  Untitled.swift
//  NeuralEngine
//
//  Created by Владимир on 11.01.2026.
//

import UIKit
import Vision

extension UIImage {
    func detectFaceLandmarks(completion: @escaping (VNFaceObservation?) -> Void) {
        guard let cgImage = self.cgImage else {
            completion(nil)
            return
        }

        let request = VNDetectFaceLandmarksRequest { request, error in
            if let error = error {
                print("Vision error: \(error)")
                completion(nil)
                return
            }
            let face = (request.results as? [VNFaceObservation])?.first
            completion(face)
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: CGImagePropertyOrientation.up, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
}
