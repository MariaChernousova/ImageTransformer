//
//  ReflectionBufferTransformer.swift
//  
//
//  Created by Chernousova Maria on 29/03/2023.
//

import Accelerate

public enum ReflectionBufferTransformerError: Error {
    case cannotCreateDestinationImageBuffer
}

@available(iOS 13.0.0, *)
public class ReflectionBufferTransformer: BufferTransformer {
    
    public func transformBuffer(from buffer: vImage_Buffer, withFormat format: vImage_CGImageFormat) async throws -> vImage_Buffer {
        guard var destinationBuffer = try? vImage_Buffer(width: Int(buffer.width),
                                                         height: Int(buffer.height),
                                                         bitsPerPixel: format.bitsPerPixel) else {
            throw ReflectionBufferTransformerError.cannotCreateDestinationImageBuffer
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            _ = withUnsafePointer(to: buffer) { sourcePointer in
                vImageVerticalReflect_ARGB8888(sourcePointer,
                                               &destinationBuffer,
                                               vImage_Flags(kvImageNoFlags))
            }
            continuation.resume(returning: destinationBuffer)
        }
    }
}

