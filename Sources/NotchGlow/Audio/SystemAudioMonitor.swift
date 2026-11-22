import AppKit
@preconcurrency import ScreenCaptureKit
import CoreMedia
import AVFoundation

/// Listens to everything the laptop plays (music, videos, ...) using ScreenCaptureKit's audio capture.
/// Requires the "Screen & System Audio Recording" permission. Video frames are never used or stored.
final class SystemAudioMonitor: NSObject, SCStreamOutput, SCStreamDelegate, @unchecked Sendable {
    var onAudio: ((Float, [Float]) -> Void)?
    var onStatus: ((Bool, String?) -> Void)?

    private var stream: SCStream?
    private let queue = DispatchQueue(label: "NotchGlow.systemAudio", qos: .userInitiated)
    private let analyzer = AudioAnalyzer()
    private var starting = false
    private var wantsRunning = false
    private(set) var isRunning = false

    func start() {
        wantsRunning = true
        guard !isRunning, !starting else { return }
        starting = true
        Task { [weak self] in await self?.begin() }
    }

    func stop() {
        wantsRunning = false
        guard let s = stream else { return }
        stream = nil
        isRunning = false
        Task { try? await s.stopCapture() }
        onStatus?(false, nil)
    }

    private func begin() async {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            guard let display = content.displays.first else {
                throw NSError(domain: "NotchGlow", code: 1,
                              userInfo: [NSLocalizedDescriptionKey: "No display available for audio capture."])
            }
            let filter = SCContentFilter(display: display, excludingWindows: [])
            let config = SCStreamConfiguration()
            config.capturesAudio = true
            config.excludesCurrentProcessAudio = true
            config.sampleRate = 48000
            config.channelCount = 2
            config.width = 2                                   // we only want audio: keep video negligible
            config.height = 2
            config.minimumFrameInterval = CMTime(value: 1, timescale: 1)

            let s = SCStream(filter: filter, configuration: config, delegate: self)
            try s.addStreamOutput(self, type: .audio, sampleHandlerQueue: queue)
            try s.addStreamOutput(self, type: .screen, sampleHandlerQueue: queue)   // required, frames are ignored
            try await s.startCapture()

            DispatchQueue.main.async {
                self.starting = false
                if self.wantsRunning {
                    self.stream = s
                    self.isRunning = true
                    self.onStatus?(true, nil)
                } else {
                    Task { try? await s.stopCapture() }
                }
            }
        } catch {
            let message = "Couldn't start system audio capture: \(error.localizedDescription)"
            DispatchQueue.main.async {
                self.starting = false
                self.isRunning = false
                self.onStatus?(false, message)
            }
        }
    }

    // MARK: SCStreamOutput
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio, sampleBuffer.isValid else { return }

        var sizeNeeded = 0
        CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            sampleBuffer, bufferListSizeNeededOut: &sizeNeeded, bufferListOut: nil, bufferListSize: 0,
            blockBufferAllocator: nil, blockBufferMemoryAllocator: nil, flags: 0, blockBufferOut: nil)
        guard sizeNeeded > 0 else { return }

        let raw = UnsafeMutableRawPointer.allocate(byteCount: sizeNeeded, alignment: MemoryLayout<AudioBufferList>.alignment)
        defer { raw.deallocate() }
        let listPtr = raw.bindMemory(to: AudioBufferList.self, capacity: 1)
        var block: CMBlockBuffer?
        let status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            sampleBuffer, bufferListSizeNeededOut: nil, bufferListOut: listPtr, bufferListSize: sizeNeeded,
            blockBufferAllocator: nil, blockBufferMemoryAllocator: nil,
            flags: kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment, blockBufferOut: &block)
        guard status == noErr else { return }

        let buffers = UnsafeMutableAudioBufferListPointer(listPtr)
        guard buffers.count > 0, let data = buffers[0].mData else { return }

        var rate: Double = 48000
        if let fd = CMSampleBufferGetFormatDescription(sampleBuffer),
           let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(fd)?.pointee, asbd.mSampleRate > 0 {
            rate = asbd.mSampleRate
        }

        let channels = max(1, Int(buffers[0].mNumberChannels))
        let totalSamples = Int(buffers[0].mDataByteSize) / MemoryLayout<Float>.size
        let frames = totalSamples / channels
        guard frames > 0 else { return }
        let ptr = data.assumingMemoryBound(to: Float.self)
        var mono = [Float](repeating: 0, count: frames)
        for i in 0..<frames { mono[i] = ptr[i * channels] }

        let result = mono.withUnsafeBufferPointer { analyzer.analyze($0, sampleRate: rate) }
        DispatchQueue.main.async { [weak self] in self?.onAudio?(result.level, result.bands) }
    }

    // MARK: SCStreamDelegate
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        let message = "System audio capture stopped: \(error.localizedDescription)"
        DispatchQueue.main.async {
            self.stream = nil
            self.isRunning = false
            self.onStatus?(false, message)
        }
    }
}
