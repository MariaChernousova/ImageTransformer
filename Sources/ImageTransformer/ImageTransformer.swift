import UIKit
import Accelerate

protocol BufferTransformer {
    
    @available(iOS 13.0.0, *)
    func transformBuffer(from buffer: vImage_Buffer, withFormat format: vImage_CGImageFormat) async throws -> vImage_Buffer
    
}

enum ImageTransformerError: Error {
    case cannotGetCGImage
    case cannotCreateBuffer
    case cannotTransformImage
    case cannotCreateBufferFormat
    case cannotCreateImageFromBuffer
    case unknown
}

@available(iOS 13.0, *)
public class ImageTransformer {
    
    public enum Strategy {
        case reflection
        case scale
        case rotation(angleInDegrees: Double)
        
        var bufferTransformer: BufferTransformer {
            switch self {
            case .reflection:
                return ReflectionBufferTransformer()
            case .scale:
                return ScaleBufferTransformer()
            case .rotation(let angleInDegrees):
                return RotationBufferTransformer(angleInDegrees: angleInDegrees)
            }
        }
    }
    
    public func transformImage(_ image: UIImage, withStrategy strategy: Strategy) async throws -> UIImage {
        guard let sourceImage = image.cgImage else {
            throw ImageTransformerError.cannotGetCGImage
        }
        let transformedImage = try await transformImage(sourceImage, withStrategy: strategy)
        return UIImage(cgImage: transformedImage)
    }
    
    private func transformImage(_ image: CGImage, withStrategy strategy: Strategy) async throws -> CGImage {
        guard let format = vImage_CGImageFormat(cgImage: image) else {
            throw ImageTransformerError.cannotCreateBufferFormat
        }
        let sourceImageBuffer = try getImageBuffer(from: image)
        let destinationImageBuffer = try await transformBuffer(sourceImageBuffer, withStrategy: strategy, withFormat: format)
        defer {
            sourceImageBuffer.free()
            destinationImageBuffer.free()
        }
        guard let transformedImage = try? destinationImageBuffer.createCGImage(format: format) else {
            throw ImageTransformerError.cannotCreateImageFromBuffer
        }
        return transformedImage
    }
    
    private func transformBuffer(_ buffer: vImage_Buffer, withStrategy strategy: Strategy, withFormat format: vImage_CGImageFormat) async throws -> vImage_Buffer {
        guard let buffer = try? await strategy.bufferTransformer.transformBuffer(from: buffer, withFormat: format) else {
            throw ImageTransformerError.cannotTransformImage
        }
        return buffer
    }
    
    private func getImageBuffer(from image: CGImage) throws -> vImage_Buffer {
        guard let buffer = try? vImage_Buffer(cgImage: image) else {
            throw ImageTransformerError.cannotCreateBuffer
        }
        return buffer
    }
    
}

