//
//  ScaleBufferTransformer.swift
//  
//
//  Created by Chernousova Maria on 29/03/2023.
//

import Accelerate

public enum ScaleBufferTransformerError: Error {
    case cannotCreateDestinationImageBuffer
}

@available(iOS 13.0.0, *)
public class ScaleBufferTransformer: BufferTransformer {
    
    public func transformBuffer(from buffer: vImage_Buffer, withFormat format: vImage_CGImageFormat) async throws -> vImage_Buffer {
        guard var destinationBuffer = try? vImage_Buffer(width: Int(buffer.width),
                                                         height: Int(buffer.height),
                                                         bitsPerPixel: format.bitsPerPixel) else {
            throw ScaleBufferTransformerError.cannotCreateDestinationImageBuffer
        }
        
        let backgroundColor: [Pixel_8] = [0, 127, 127, 127]
        let verticalScale: Float = 0.5
        let shearAngle = atan(Double(buffer.height) /
                              Double(buffer.width * 2)) *
        180 / .pi
        
        precondition(shearAngle > -90 && shearAngle < 90,
                     "Shear angle must be greater than -90º and less than 90º.")
        
        let angle = Measurement(value: shearAngle,
                                unit: UnitAngle.degrees)
        let radians = Float(angle.converted(to: .radians).value)
        let shearSlope = tan(radians)
        
        let resamplingFilter = vImageNewResamplingFilter(verticalScale,
                                                         vImage_Flags(kvImageNoFlags))
        defer {
            vImageDestroyResamplingFilter(resamplingFilter)
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            _ = withUnsafePointer(to: buffer) { sourcePointer in
                vImageVerticalShear_ARGB8888(sourcePointer,
                                             &destinationBuffer,
                                             0, 0,
                                             0,
                                             shearSlope,
                                             resamplingFilter,
                                             backgroundColor,
                                             vImage_Flags(kvImageBackgroundColorFill))
            }
            continuation.resume(returning: destinationBuffer)
        }
    }
    
}

