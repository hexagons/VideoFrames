#if os(macOS)
import Cocoa
#else
import UIKit
#endif
import AVFoundation

#if os(macOS)
public typealias _Image = NSImage
#else
public typealias _Image = UIImage
#endif

public enum VideoFramesError: Error {
    case videoNotFound
    case framePixelBuffer(String)
    case videoInfo(String)
}

struct VideoInfo {
    let duration: Double
    let fps: Int
    let size: CGSize
    var frameCount: Int { Int(duration * Double(fps)) }
    init(asset: AVAsset, roundFps: Bool = false) throws {
        guard let track: AVAssetTrack = asset.tracks(withMediaType: .video).first else {
            throw VideoFramesError.videoInfo("Video asset track not found.")
        }
        duration = CMTimeGetSeconds(asset.duration)
        var rawFps: Float = track.nominalFrameRate
        if roundFps {
            rawFps = round(rawFps)
        }
        guard Float(Int(rawFps)) == rawFps else {
            throw VideoFramesError.videoInfo("Decimal FPS not supported. Use --force flag to round fps.")
        }
        fps = Int(rawFps)
        size = track.naturalSize
    }
}

extension String {
    public func zfill(_ length: Int) -> String {
        fill("0", for: length)
    }
    public func sfill(_ length: Int) -> String {
        fill(" ", for: length)
    }
    func fill(_ char: Character, for length: Int) -> String {
        let diff = (length - count)
        let prefix = (diff > 0 ? String(repeating: char, count: diff) : "")
        return (prefix + self)
    }
}

extension Double {
    var formattedSeconds: String {
        let milliseconds: Int = Int(self.truncatingRemainder(dividingBy: 1.0) * 1000)
        let formattedMilliseconds: String = "\(milliseconds)".zfill(3)
        return "\(Int(self).formattedSeconds).\(formattedMilliseconds)"
    }
}

extension Int {
    var formattedSeconds: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.second, .minute, .hour]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: TimeInterval(self))!
    }
}

public func logBar(at index: Int, count: Int, from date: Date, length: Int = 50, clear: Bool = true) {
    let fraction: Double = Double(index) / Double(count - 1)
    var bar: String = ""
    bar += "["
    for i in 0..<length {
        let f = Double(i) / Double(length)
        bar += f < fraction ? "=" : " "
    }
    bar += "]"
    let percent = "\("\(Int(round(fraction * 100)))".sfill(3))%"
    let progress: String = "\("\(index + 1)".sfill("\(count)".count))/\(count)"
    let timestamp: String = (-date.timeIntervalSinceNow).formattedSeconds
    let msg: String = "\(bar)  \(percent)  \(progress)  \(timestamp)"
    if clear {
        print(msg, "\r", terminator: "")
        fflush(stdout)
    } else {
        print(msg)
    }
}
