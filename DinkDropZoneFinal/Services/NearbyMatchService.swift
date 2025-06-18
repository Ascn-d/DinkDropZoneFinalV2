import Foundation
import MultipeerConnectivity
import Observation
import SwiftUI

@MainActor
@Observable
final class NearbyMatchService: NSObject {
    // MARK: - Nested types
    struct DiscoveredPeer: Identifiable, Equatable {
        let id: MCPeerID
        let displayName: String
        var elo: Int?
        var level: Int?
    }
    
    enum Message: String {
        case profile // initial discovery payload
        case invite  // invite to match
        case accept  // accept invite
        case cancel
    }
    
    // MARK: - Properties
    private let serviceType = "dinkdrop-match"
    private let myPeerID: MCPeerID
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser!
    private var browser: MCNearbyServiceBrowser!
    
    var discoveredPeers: [DiscoveredPeer] = []
    var pendingInviteFrom: DiscoveredPeer?
    var matchedPeer: DiscoveredPeer?
    
    // MARK: - Init
    init(displayName: String? = nil) {
        let resolvedName: String
        if let provided = displayName, !provided.isEmpty {
            resolvedName = provided
        } else {
            resolvedName = UIDevice.current.name
        }
        self.myPeerID = MCPeerID(displayName: resolvedName)
        super.init()
        setupSession()
        start()
    }
    
    // MARK: - Session setup
    private func setupSession() {
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
    }
    
    private func start() {
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: profilePayload(), serviceType: serviceType)
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser.delegate = self
        browser.startBrowsingForPeers()
    }
    
    deinit {}
    
    // MARK: - Public API
    func sendInvite(to peer: DiscoveredPeer) {
        guard let target = discoveredPeers.first(where: { $0.id == peer.id }) else { return }
        do {
            let payload = try JSONEncoder().encode(["type": Message.invite.rawValue])
            try session.send(payload, toPeers: [target.id], with: .reliable)
        } catch {
            print("Failed to send invite: \(error)")
        }
    }
    
    func acceptInvite(from peer: DiscoveredPeer) {
        guard let target = discoveredPeers.first(where: { $0.id == peer.id }) else { return }
        do {
            let payload = try JSONEncoder().encode(["type": Message.accept.rawValue])
            try session.send(payload, toPeers: [target.id], with: .reliable)
            matchedPeer = target
        } catch {
            print("Failed to accept invite: \(error)")
        }
    }
    
    private func profilePayload() -> [String: String] {
        // Include minimal info for discovery info (limited to 10 non-nil string pairs)
        let elo = "1450" // TODO: inject real user elo
        let lvl = "5"
        return ["elo": elo, "lvl": lvl]
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension NearbyMatchService: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        Task { @MainActor in
            let peer = DiscoveredPeer(id: peerID,
                                      displayName: peerID.displayName,
                                      elo: Int(info?["elo"] ?? ""),
                                      level: Int(info?["lvl"] ?? ""))
            if !discoveredPeers.contains(peer) {
                discoveredPeers.append(peer)
            }
        }
    }
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task { @MainActor in
            discoveredPeers.removeAll { $0.id == peerID }
        }
    }
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("Browser failed: \(error)")
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension NearbyMatchService: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("Advertiser failed: \(error)")
    }
    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        Task { @MainActor in
            invitationHandler(true, self.session)
        }
    }
}

// MARK: - MCSessionDelegate
extension NearbyMatchService: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {}
    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let dict = try? JSONDecoder().decode([String: String].self, from: data),
              let typeRaw = dict["type"],
              let type = Message(rawValue: typeRaw) else { return }
        Task { @MainActor in
            if let sender = discoveredPeers.first(where: { $0.id == peerID }) {
                switch type {
                case .invite:
                    pendingInviteFrom = sender
                case .accept:
                    matchedPeer = sender
                default:
                    break
                }
            }
        }
    }
    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
    nonisolated func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) { certificateHandler(true) }
} 