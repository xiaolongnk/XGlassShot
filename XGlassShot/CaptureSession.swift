import Foundation

enum CapturePostAction: Equatable {
    case none, copyText, beautify
}

enum CaptureIntent: Equatable {
    case screenshot(CapturePostAction)
    case recording
}

struct CaptureSession {
    enum Phase: Equatable {
        case idle, selecting(CaptureIntent), processing(CaptureIntent), recording, stopping
    }

    private(set) var phase: Phase = .idle

    mutating func begin(_ intent: CaptureIntent) -> Bool {
        guard phase == .idle else { return false }
        phase = .selecting(intent)
        return true
    }

    mutating func cancelSelection() {
        guard case .selecting = phase else { return }
        phase = .idle
    }

    mutating func confirm() -> CaptureIntent? {
        guard case .selecting(let intent) = phase else { return nil }
        phase = .processing(intent)
        return intent
    }

    mutating func recordingStarted() {
        guard phase == .processing(.recording) else { return }
        phase = .recording
    }

    mutating func beginStop() -> Bool {
        guard phase == .recording else { return false }
        phase = .stopping
        return true
    }

    mutating func finish() { phase = .idle }
}

struct CapturePostActionRequest: Equatable, Identifiable {
    let id = UUID()
    let action: CapturePostAction
    let url: URL
}
