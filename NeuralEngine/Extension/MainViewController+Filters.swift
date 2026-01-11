//
//  MainViewController+Filters.swift
//  NeuralEngine
//
//  Created by Владимир on 11.01.2026.
//

import UIKit
import CoreImage
import Vision

extension MainViewController {
    func enlargeEyes(in image: UIImage, face: VNFaceObservation) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        
        // Получаем landmarks глаз
        guard let leftEyeRegion = face.landmarks?.leftEye,
              let rightEyeRegion = face.landmarks?.rightEye else {
            return nil
        }
        
        // Берём центральную точку глаза (например, первую или усреднённую)
        // VNFaceLandmarkRegion2D соответствует Sequence of CGPoint
        let leftEyePoint = averagePoint(from: leftEyeRegion)
        let rightEyePoint = averagePoint(from: rightEyeRegion)
        
        let imageSize = image.size
        
        // Преобразуем нормализованные координаты Vision (0..1, Y сверху вниз)
        // в пиксельные координаты UIKit (Y снизу вверх → инвертируем)
        let leftPixelPoint = CGPoint(
            x: leftEyePoint.x * imageSize.width,
            y: (1 - leftEyePoint.y) * imageSize.height
        )
        let rightPixelPoint = CGPoint(
            x: rightEyePoint.x * imageSize.width,
            y: (1 - rightEyePoint.y) * imageSize.height
        )
        
        let context = CIContext()
        var currentImage: CIImage = ciImage
        
        for point in [leftPixelPoint, rightPixelPoint] {
            guard let bump = CIFilter(name: "CIBumpDistortion") else { continue }
            bump.setValue(currentImage, forKey: kCIInputImageKey)
            bump.setValue(CIVector(x: point.x, y: point.y), forKey: kCIInputCenterKey)
            bump.setValue(120, forKey: kCIInputRadiusKey)   // радиус области
            bump.setValue(1.8, forKey: kCIInputScaleKey)    // степень выпуклости
            
            if let output = bump.outputImage {
                currentImage = output
            }
        }
        
        // используем extent исходного изображения, чтобы не обрезать
        guard let cgImg = context.createCGImage(currentImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImg)
    }

    // Вспомогательная функция: вычисляет среднюю точку landmark-региона
    private func averagePoint(from region: VNFaceLandmarkRegion2D) -> CGPoint {
        var totalX: CGFloat = 0
        var totalY: CGFloat = 0
        let count = region.pointCount
        
        guard count > 0 else { return .zero }
        
        for i in 0..<count {
            let point = region.normalizedPoints[i]
            totalX += point.x
            totalY += point.y
        }
        
        return CGPoint(x: totalX / CGFloat(count), y: totalY / CGFloat(count))
    }
    
    func slimFace(in image: UIImage, face: VNFaceObservation) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        
        let faceRect = face.boundingBox
        let imageSize = image.size
        
        // Центр лица в пикселях
        let centerX = faceRect.midX * imageSize.width
        let centerY = (1 - faceRect.midY) * imageSize.height
        let width = faceRect.width * imageSize.width
        
        // Используем сжатие через CIPinchDistortion
        guard let pinch = CIFilter(name: "CIPinchDistortion") else { return nil }
        pinch.setValue(ciImage, forKey: kCIInputImageKey)
        pinch.setValue(CIVector(x: centerX, y: centerY), forKey: kCIInputCenterKey)
        pinch.setValue(width * 0.6, forKey: kCIInputRadiusKey)
        pinch.setValue(-0.3, forKey: kCIInputScaleKey) // отрицательное = сжатие
        
        guard let output = pinch.outputImage else { return nil }
        
        let context = CIContext()
        guard let cgImg = context.createCGImage(output, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImg)
    }
    
}
