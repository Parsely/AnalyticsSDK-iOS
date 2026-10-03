import Foundation

/// What a send's result means for its batch, following the outcome table in the payload spec.
enum SendOutcome: Equatable {
    /// 2xx: the server has the events.
    case sent
    /// The events can't have arrived, or we can't tell: keep the batch and back off.
    case retry
    /// 413: keep the batch and send half as many events next time. A single event that draws one is removed.
    case split
    /// Any other response: resending would only be refused again, so remove the batch.
    case drop

    init(status: Int?) {
        guard let status else {
            // Refused, reset, offline, DNS or TLS failure, timeout, or cancelled when background time ran out.
            self = .retry
            return
        }
        switch status {
        case 200..<300: self = .sent
        case 413: self = .split
        // nginx answering for a proxy that didn't, or a gateway timeout.
        case 502, 503, 504: self = .retry
        default: self = .drop
        }
    }
}
