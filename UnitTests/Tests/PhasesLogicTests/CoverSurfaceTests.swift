import CoreGraphics
import Foundation
import ImageIO
import IOSurface
import Testing
import UniformTypeIdentifiers
@testable import PhasesLogic

/// The cover's buffer `[D-cover-iosurface]`: screen-sized at most, 8-bit
/// BGRA, tagged with the image's color space or sRGB.
struct CoverSurfaceTests {
  /// Writes a solid-color PNG in `space` and returns its URL.
  private func writePNG(width: Int, height: Int, space: CGColorSpace, components: [CGFloat]) throws -> URL {
    let isGray = space.model == .monochrome
    let context = try #require(
      CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: space,
        bitmapInfo: isGray ? CGImageAlphaInfo.none.rawValue : CGImageAlphaInfo.premultipliedLast.rawValue
      )
    )
    context.setFillColor(try #require(CGColor(colorSpace: space, components: components)))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    let image = try #require(context.makeImage())
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("cover-\(UUID().uuidString).png")
    let destination = try #require(CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil))
    CGImageDestinationAddImage(destination, image, nil)
    #expect(CGImageDestinationFinalize(destination))
    return url
  }

  private func iccData(of surface: IOSurface) -> Data? {
    surface.attachment(forKey: kIOSurfaceColorSpace as String) as? Data
  }

  private func iccData(_ name: CFString) -> Data? {
    CGColorSpace(name: name)?.copyICCData() as Data?
  }

  @Test func scalesDownToTheScreenSize() throws {
    let url = try writePNG(width: 400, height: 200, space: CGColorSpace(name: CGColorSpace.sRGB)!, components: [1, 0, 0, 1])
    defer { try? FileManager.default.removeItem(at: url) }
    let surface = try #require(CoverSurface.make(from: url, maxPixelSize: 100))
    #expect(surface.width == 100)
    #expect(surface.height == 50)
    #expect(surface.pixelFormat == CoverSurface.pixelFormatBGRA)
  }

  @Test func neverScalesUp() throws {
    let url = try writePNG(width: 40, height: 20, space: CGColorSpace(name: CGColorSpace.sRGB)!, components: [1, 0, 0, 1])
    defer { try? FileManager.default.removeItem(at: url) }
    let surface = try #require(CoverSurface.make(from: url, maxPixelSize: 1000))
    #expect(surface.width == 40)
    #expect(surface.height == 20)
  }

  @Test func centeredImageKeepsItsOwnSize() throws {
    let url = try writePNG(width: 64, height: 48, space: CGColorSpace(name: CGColorSpace.sRGB)!, components: [1, 0, 0, 1])
    defer { try? FileManager.default.removeItem(at: url) }
    let surface = try #require(CoverSurface.make(from: url, maxPixelSize: nil))
    #expect(surface.width == 64)
    #expect(surface.height == 48)
  }

  @Test func displayP3ImageIsTaggedDisplayP3() throws {
    let url = try writePNG(width: 16, height: 16, space: CGColorSpace(name: CGColorSpace.displayP3)!, components: [1, 0, 0, 1])
    defer { try? FileManager.default.removeItem(at: url) }
    let surface = try #require(CoverSurface.make(from: url, maxPixelSize: 16))
    #expect(iccData(of: surface) == iccData(CGColorSpace.displayP3))
  }

  @Test func pixelsStayInTheImagesSpace() throws {
    // P3 red drawn in P3 stays pure red: no conversion to another space.
    let url = try writePNG(width: 8, height: 8, space: CGColorSpace(name: CGColorSpace.displayP3)!, components: [1, 0, 0, 1])
    defer { try? FileManager.default.removeItem(at: url) }
    let surface = try #require(CoverSurface.make(from: url, maxPixelSize: 8))
    surface.lock(options: .readOnly, seed: nil)
    defer { surface.unlock(options: .readOnly, seed: nil) }
    let bgra = surface.baseAddress.assumingMemoryBound(to: UInt8.self)
    #expect([bgra[0], bgra[1], bgra[2], bgra[3]] == [0, 0, 255, 255])
  }

  @Test func grayscaleImageIsDrawnAndTaggedSRGB() throws {
    let url = try writePNG(width: 16, height: 16, space: CGColorSpace(name: CGColorSpace.genericGrayGamma2_2)!, components: [0.5, 1])
    defer { try? FileManager.default.removeItem(at: url) }
    let surface = try #require(CoverSurface.make(from: url, maxPixelSize: 16))
    #expect(iccData(of: surface) == iccData(CGColorSpace.sRGB))
  }

  @Test func unreadableFileMakesNoSurface() {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("missing-\(UUID().uuidString).png")
    #expect(CoverSurface.make(from: url, maxPixelSize: 100) == nil)
  }
}
