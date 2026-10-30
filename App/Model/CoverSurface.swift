import CoreGraphics
import Foundation
import ImageIO
import IOSurface

/// [D-cover-iosurface] A cover's image: decoded at no more than the size the
/// screen needs, drawn into an IOSurface, and tagged with the image's color
/// space. Core Animation shows a surface as is, where it copies every
/// CGImage [Q-cover-image-copied]; an untagged surface is taken to be in the
/// display's color space [Q-iosurface-color-tag].
enum CoverSurface {
  /// Pass a nil `maxPixelSize` to decode at the image's own size (centered
  /// wallpaper). Never scales up.
  static func make(from url: URL, maxPixelSize: CGFloat?) -> IOSurface? {
    let noCache = [kCGImageSourceShouldCache: false] as CFDictionary
    guard let source = CGImageSourceCreateWithURL(url as CFURL, noCache) else { return nil }
    let image: CGImage?
    if let maxPixelSize {
      let options: [CFString: Any] = [
        kCGImageSourceShouldCache: false,
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
      ]
      image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    } else {
      image = CGImageSourceCreateImageAtIndex(source, 0, noCache)
    }
    // The decoded image goes out of scope here, once it's drawn.
    return image.flatMap(draw)
  }

  /// Draws `image` into a new 8-bit BGRA surface of the same size. 8 bits
  /// is enough: macOS shows the wallpaper as SDR [L-hdr-wallpaper].
  static func draw(_ image: CGImage) -> IOSurface? {
    let width = image.width
    let height = image.height
    let colorSpace = drawingSpace(for: image)
    guard width > 0, height > 0, let icc = colorSpace.copyICCData() else { return nil }

    let bytesPerElement = 4
    let properties: [IOSurfacePropertyKey: Any] = [
      .width: width,
      .height: height,
      .bytesPerElement: bytesPerElement,
      .bytesPerRow: IOSurfaceAlignProperty(kIOSurfaceBytesPerRow, width * bytesPerElement),
      .pixelFormat: pixelFormatBGRA,
    ]
    guard let surface = IOSurface(properties: properties) else { return nil }

    surface.lock(options: [], seed: nil)
    defer { surface.unlock(options: [], seed: nil) }
    let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
    guard
      let context = CGContext(
        data: surface.baseAddress, width: width, height: height, bitsPerComponent: 8,
        bytesPerRow: surface.bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo
      )
    else { return nil }
    let bounds = CGRect(x: 0, y: 0, width: width, height: height)
    context.clear(bounds)
    context.draw(image, in: bounds)

    // [Q-iosurface-color-tag] Without this, colors are off by up to 56 of
    // 255 on a display whose color space differs from the image's.
    surface.setAttachment(icc, forKey: kIOSurfaceColorSpace as String)
    return surface
  }

  /// The image's own color space when it's RGB with a profile; sRGB for
  /// anything else (grayscale, CMYK, none) `[D-cover-iosurface]`.
  static func drawingSpace(for image: CGImage) -> CGColorSpace {
    if let space = image.colorSpace, space.model == .rgb, space.copyICCData() != nil {
      return space
    }
    return CGColorSpace(name: CGColorSpace.sRGB)!
  }

  /// 'BGRA', the same value as CoreVideo's kCVPixelFormatType_32BGRA.
  static let pixelFormatBGRA: UInt32 = 0x4247_5241
}
