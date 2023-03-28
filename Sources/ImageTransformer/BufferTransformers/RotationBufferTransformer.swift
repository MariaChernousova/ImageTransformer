//
//  RotationBufferTransformer.swift
//  
//
//  Created by Chernousova Maria on 29/03/2023.
//

import Accelerate

enum RotationBufferTransformerError: Error {
    case cannotCreateDestinationImageBuffer
}

@available(iOS 13.0.0, *)
final class RotationBufferTransformer: BufferTransformer {
    
    private let angleInDegrees: Double
    
    init(angleInDegrees: Double) {
        self.angleInDegrees = angleInDegrees
    }
    
    func transformBuffer(from buffer: vImage_Buffer, withFormat format: vImage_CGImageFormat) async throws -> vImage_Buffer {
        guard var destinationBuffer = try? vImage_Buffer(width: Int(buffer.width),
                                                         height: Int(buffer.height),
                                                         bitsPerPixel: format.bitsPerPixel) else {
            throw RotationBufferTransformerError.cannotCreateDestinationImageBuffer
        }
        let backgroundColor: [Pixel_8] = [0, 127, 127, 127]
        let angle = Measurement(value: angleInDegrees,
                                unit: UnitAngle.degrees)
        let radians = Float(angle.converted(to: .radians).value)
        
        return try await withCheckedThrowingContinuation { continuation in
            _ = withUnsafePointer(to: buffer) { sourcePointer in
                vImageRotate_ARGB8888(sourcePointer,
                                      &destinationBuffer,
                                      nil,
                                      radians,
                                      backgroundColor,
                                      vImage_Flags(kvImageBackgroundColorFill))
            }
            continuation.resume(returning: destinationBuffer)
        }
    }
}
