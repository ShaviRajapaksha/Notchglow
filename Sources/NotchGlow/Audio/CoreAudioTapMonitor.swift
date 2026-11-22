import Foundation
import CoreAudio
import AudioToolbox

/// Listens to everything the Mac plays using a Core Audio process tap (macOS 14.4+).
/// macOS only asks for "System Audio Recording" (audio only). No screen recording permission is involved.
@available(macOS 14.4, *)
final class CoreAudioTapMonitor: SystemAudioSource {
    var onAudio: ((Float, [Float]) -> Void)?
    var onStatus: ((Bool, String?) -> Void)?

    private var tapID = AudioObjectID(kAudioObjectUnknown)
    private var aggregateID = AudioObjectID(kAudioObjectUnknown)
    private var procID: AudioDeviceIOProcID?
    private let queue = DispatchQueue(label: "NotchGlow.coreAudioTap", qos: .userInitiated)
    private let analyzer = AudioAnalyzer()
    private var sampleRate: Double = 48000
    private var wantsRunning = false
    private var listener: AudioObjectPropertyListenerBlock?
    private(set) var isRunning = false

    // MARK: Start / stop
    func start() {
        wantsRunning = true
        guard !isRunning else { return }
        installOutputListener()
        launch()
    }

    func stop() {
        wantsRunning = false
        removeOutputListener()
        let wasRunning = isRunning
        teardown()
        if wasRunning { onStatus?(false, nil) }
    }

    private func launch() {
        do {
            try begin()
            isRunning = true
            onStatus?(true, nil)
        } catch {
            teardown()
            isRunning = false
            onStatus?(false, "Couldn't start system audio capture: \(error.localizedDescription)")
        }
    }

    /// The default output device changed (e.g. headphones plugged in): rebuild the tap for it.
    private func restart() {
        guard wantsRunning else { return }
        teardown()
        isRunning = false
        launch()
    }

    // MARK: Setup
    private func begin() throws {
        let outputUID = try Self.defaultOutputUID()

        let desc = CATapDescription(stereoGlobalTapButExcludeProcesses: [])
        desc.uuid = UUID()
        desc.name = "NotchGlow"
        desc.muteBehavior = .unmuted          // never changes what you hear
        desc.isPrivate = true

        var tap = AudioObjectID(kAudioObjectUnknown)
        var status = AudioHardwareCreateProcessTap(desc, &tap)
        guard status == noErr else { throw Self.error("create the audio tap", status) }
        tapID = tap

        var subDevice: [String: Any] = [:]
        subDevice[kAudioSubDeviceUIDKey] = outputUID
        var subTap: [String: Any] = [:]
        subTap[kAudioSubTapUIDKey] = desc.uuid.uuidString
        subTap[kAudioSubTapDriftCompensationKey] = true

        var aggregate: [String: Any] = [:]
        aggregate[kAudioAggregateDeviceNameKey] = "NotchGlow Tap"
        aggregate[kAudioAggregateDeviceUIDKey] = UUID().uuidString
        aggregate[kAudioAggregateDeviceMainSubDeviceKey] = outputUID
        aggregate[kAudioAggregateDeviceIsPrivateKey] = true
        aggregate[kAudioAggregateDeviceIsStackedKey] = false
        aggregate[kAudioAggregateDeviceTapAutoStartKey] = true
        aggregate[kAudioAggregateDeviceSubDeviceListKey] = [subDevice]
        aggregate[kAudioAggregateDeviceTapListKey] = [subTap]

        var aggID = AudioObjectID(kAudioObjectUnknown)
        status = AudioHardwareCreateAggregateDevice(aggregate as CFDictionary, &aggID)
        guard status == noErr else { throw Self.error("create the audio device", status) }
        aggregateID = aggID

        // Sample rate of the tap.
        var format = AudioStreamBasicDescription()
        var size = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
        var address = AudioObjectPropertyAddress(mSelector: kAudioTapPropertyFormat,
                                                 mScope: kAudioObjectPropertyScopeGlobal,
                                                 mElement: kAudioObjectPropertyElementMain)
        if AudioObjectGetPropertyData(tapID, &address, 0, nil, &size, &format) == noErr, format.mSampleRate > 0 {
            sampleRate = format.mSampleRate
        }

        var proc: AudioDeviceIOProcID?
        status = AudioDeviceCreateIOProcIDWithBlock(&proc, aggregateID, queue) { [weak self] _, inInputData, _, _, _ in
            self?.handle(inInputData)
        }
        guard status == noErr, let proc else { throw Self.error("start listening", status) }
        procID = proc

        status = AudioDeviceStart(aggregateID, proc)
        guard status == noErr else { throw Self.error("start the audio device", status) }
    }

    private func teardown() {
        if let p = procID {
            AudioDeviceStop(aggregateID, p)
            AudioDeviceDestroyIOProcID(aggregateID, p)
            procID = nil
        }
        if aggregateID != AudioObjectID(kAudioObjectUnknown) {
            AudioHardwareDestroyAggregateDevice(aggregateID)
            aggregateID = AudioObjectID(kAudioObjectUnknown)
        }
        if tapID != AudioObjectID(kAudioObjectUnknown) {
            AudioHardwareDestroyProcessTap(tapID)
            tapID = AudioObjectID(kAudioObjectUnknown)
        }
        isRunning = false
    }

    // MARK: Audio
    private func handle(_ input: UnsafePointer<AudioBufferList>) {
        let buffers = UnsafeMutableAudioBufferListPointer(UnsafeMutablePointer(mutating: input))
        guard buffers.count > 0, let data = buffers[0].mData else { return }
        let channels = max(1, Int(buffers[0].mNumberChannels))
        let totalSamples = Int(buffers[0].mDataByteSize) / MemoryLayout<Float>.size
        let frames = totalSamples / channels
        guard frames > 0 else { return }

        let ptr = data.assumingMemoryBound(to: Float.self)
        var mono = [Float](repeating: 0, count: frames)
        for i in 0..<frames { mono[i] = ptr[i * channels] }

        let rate = sampleRate
        let result = mono.withUnsafeBufferPointer { analyzer.analyze($0, sampleRate: rate) }
        DispatchQueue.main.async { [weak self] in self?.onAudio?(result.level, result.bands) }
    }

    // MARK: Output device changes
    private func installOutputListener() {
        guard listener == nil else { return }
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultSystemOutputDevice,
                                                 mScope: kAudioObjectPropertyScopeGlobal,
                                                 mElement: kAudioObjectPropertyElementMain)
        let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in self?.restart() }
        listener = block
        AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &address, DispatchQueue.main, block)
    }

    private func removeOutputListener() {
        guard let block = listener else { return }
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultSystemOutputDevice,
                                                 mScope: kAudioObjectPropertyScopeGlobal,
                                                 mElement: kAudioObjectPropertyElementMain)
        AudioObjectRemovePropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &address, DispatchQueue.main, block)
        listener = nil
    }

    // MARK: Helpers
    private static func defaultOutputUID() throws -> String {
        var deviceID = AudioObjectID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultSystemOutputDevice,
                                                 mScope: kAudioObjectPropertyScopeGlobal,
                                                 mElement: kAudioObjectPropertyElementMain)
        var status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID)
        guard status == noErr, deviceID != AudioObjectID(kAudioObjectUnknown) else {
            throw error("find the output device", status)
        }

        var uidAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyDeviceUID,
                                                    mScope: kAudioObjectPropertyScopeGlobal,
                                                    mElement: kAudioObjectPropertyElementMain)
        var uid: Unmanaged<CFString>?
        var uidSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        status = withUnsafeMutablePointer(to: &uid) {
            AudioObjectGetPropertyData(deviceID, &uidAddress, 0, nil, &uidSize, $0)
        }
        guard status == noErr, let value = uid?.takeRetainedValue() else {
            throw error("read the output device", status)
        }
        return value as String
    }

    private static func error(_ what: String, _ status: OSStatus) -> NSError {
        NSError(domain: "NotchGlow", code: Int(status),
                userInfo: [NSLocalizedDescriptionKey: "Could not \(what) (error \(status))."])
    }
}
