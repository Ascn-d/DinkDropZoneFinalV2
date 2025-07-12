import Foundation
import MultipeerConnectivity
import CoreLocation
import Combine
import os.log

// MARK: - Local Matchmaking Service for Immediate Testing
final class LocalMatchmakingService: NSObject, ObservableObject {
    
    // MARK: - Observable Properties
    @Published var nearbyPlayers: [NearbyPlayer] = []
    @Published var currentMatch: LocalMatch?
    @Published var connectionStatus: ConnectionStatus = .disconnected
    
    // Queue state properties (synced with AppState)
    @Published var isInQueue: Bool = false
    @Published var queuePosition: Int = 0
    @Published var estimatedWaitTime: TimeInterval = 0
    
    // Reference to AppState for queue state management
    private weak var appState: AppState?
    
    // MARK: - MultipeerConnectivity Properties
    // Fix: Use a shorter, valid Bonjour service type (max 15 chars, no special chars)
    private let serviceType = "dinkdrop-game"
    private let peerID: MCPeerID
    private let session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser?
    private let browser: MCNearbyServiceBrowser
    
    private let logger = Logger(subsystem: "DinkDropZone", category: "LocalMatchmaking")
    
    // MARK: - User Info
    private var currentUser: User?
    private var matchType: MatchType = .singles
    private var isServiceActive = false
    
    enum ConnectionStatus {
        case connected
        case connecting
        case disconnected
        case error(String)
    }
    
    // MARK: - Data Models
    struct NearbyPlayer: Identifiable, Codable {
        let id: String
        let displayName: String
        let elo: Int
        let matchType: String
        let distance: Double // km
        let peerID: String
        
        var eloRange: String {
            switch elo {
            case 0..<1000: return "Beginner"
            case 1000..<1200: return "Intermediate" 
            case 1200..<1400: return "Advanced"
            default: return "Expert"
            }
        }
    }
    
    struct LocalMatch: Identifiable, Codable {
        let id: String
        let player1: NearbyPlayer
        let player2: NearbyPlayer
        let matchType: String
        let createdAt: Date
        var status: MatchStatus = .proposed
        
        enum MatchStatus: String, Codable {
            case proposed = "proposed"
            case accepted = "accepted"
            case declined = "declined"
            case active = "active"
            case completed = "completed"
        }
    }
    
    // MARK: - Initialization
    init(appState: AppState? = nil) {
        // Create unique peer ID with UUID to ensure uniqueness across app instances
        let deviceName = UIDevice.current.name
        let uniqueID = UUID().uuidString.prefix(8)
        let uniquePeerName = "\(deviceName)-\(uniqueID)"
        self.peerID = MCPeerID(displayName: uniquePeerName)
        
        // Initialize session
        self.session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
        
        // Initialize browser (advertiser will be created when needed)
        self.browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        
        self.appState = appState
        
        super.init()
        
        // Set delegates
        session.delegate = self
        browser.delegate = self
        
        logger.info("LocalMatchmakingService initialized with peer: \(self.peerID.displayName)")
        logger.info("Using service type: \(self.serviceType)")
    }
    
    deinit {
        stopService()
    }
    
    // MARK: - Private Methods
    
    private func stopService() {
        guard isServiceActive else { return }
        
        logger.info("Stopping MultipeerConnectivity services")
        
        advertiser?.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        session.disconnect()
        
        advertiser = nil
        isServiceActive = false
    }
    
    private func checkNetworkReadiness() {
        logger.info("📡 Network readiness check:")
        logger.info("  - Service type: \(self.serviceType)")
        logger.info("  - Peer ID: \(self.peerID.displayName)")
        logger.info("  - Session state: \(self.session.connectedPeers.count) connected peers")
    }
    
    // MARK: - Public Methods
    
    /// Start looking for matches locally
    @MainActor
    func startMatchmaking(user: User, matchType: MatchType) async throws {
        guard let appState = appState else {
            throw MatchmakingError.noAppState
        }
        
        // Check if this specific user is already in queue
        guard self.currentUser?.id != user.id || !appState.isInQueue else {
            logger.warning("User \(user.displayName) is already in queue")
            throw MatchmakingError.alreadyInQueue
        }
        
        self.currentUser = user
        self.matchType = matchType
        
        logger.info("Starting local matchmaking for \(user.displayName)")
        
        // Stop any existing services first
        stopService()
        
        // Check network readiness
        checkNetworkReadiness()
        
        connectionStatus = .connecting
        
        // Create discovery info with user data (keep it small to avoid issues)
        let discoveryInfo = [
            "name": user.displayName.prefix(20).description, // Limit length
            "elo": String(user.elo),
            "type": matchType.rawValue
        ]
        
        logger.info("Discovery info: \(discoveryInfo)")
        
        // Create new advertiser with user info
        self.advertiser = MCNearbyServiceAdvertiser(
            peer: self.peerID,
            discoveryInfo: discoveryInfo,
            serviceType: self.serviceType
        )
        
        guard let advertiser = self.advertiser else {
            throw MatchmakingError.serviceInitializationFailed
        }
        
        advertiser.delegate = self
        
        // Start services with error handling
        logger.info("🚀 Starting advertising...")
        advertiser.startAdvertisingPeer()
        
        logger.info("🚀 Starting browsing...")
        self.browser.startBrowsingForPeers()
        
        isServiceActive = true
        
        // Update both AppState and local properties
        appState.isInQueue = true
        self.isInQueue = true
        
        connectionStatus = .connected
        
        // Start updating queue position simulation
        startQueueSimulation()
        
        logger.info("Local matchmaking started successfully")
    }
    
    /// Stop matchmaking
    @MainActor
    func stopMatchmaking() {
        guard let appState = appState else { return }
        
        logger.info("Stopping local matchmaking")
        
        stopService()
        
        // Update both AppState and local properties
        appState.isInQueue = false
        appState.queuePosition = 0
        appState.estimatedWaitTime = 0
        
        self.isInQueue = false
        self.queuePosition = 0
        self.estimatedWaitTime = 0
        
        connectionStatus = .disconnected
        nearbyPlayers.removeAll()
        
        logger.info("Local matchmaking stopped")
    }
    
    /// Send match proposal to a nearby player
    func proposeMatch(to player: NearbyPlayer) async throws {
        guard let currentUser = currentUser else {
            throw MatchmakingError.notAuthenticated
        }
        
        logger.info("Proposing match to \(player.displayName)")
        
        let match = LocalMatch(
            id: UUID().uuidString,
            player1: NearbyPlayer(
                id: currentUser.id.uuidString,
                displayName: currentUser.displayName,
                elo: currentUser.elo,
                matchType: matchType.rawValue,
                distance: 0,
                peerID: self.peerID.displayName
            ),
            player2: player,
            matchType: matchType.rawValue,
            createdAt: Date()
        )
        
        // Send proposal via MultipeerConnectivity
        if let peerID = findPeerID(for: player.peerID) {
            let proposalData = try JSONEncoder().encode(match)
            let message = MatchMessage.proposal(proposalData)
            try sendMessage(message, to: [peerID])
            
            currentMatch = match
            logger.info("Match proposal sent successfully")
        } else {
            throw MatchmakingError.networkError(NSError(domain: "LocalMatchmaking", code: 1, userInfo: [NSLocalizedDescriptionKey: "Peer not found"]))
        }
    }
    
    /// Respond to a match proposal
    func respondToProposal(accept: Bool) async throws {
        guard let match = currentMatch else {
            throw MatchmakingError.noActiveQueue
        }
        
        logger.info("Responding to proposal: \(accept ? "accept" : "decline")")
        
        let response = LocalMatchResponse(matchId: match.id, accepted: accept)
        let responseData = try JSONEncoder().encode(response)
        let message = MatchMessage.response(responseData)
        
        // Send response to all connected peers
        try sendMessage(message, to: self.session.connectedPeers)
        
        if accept {
            await MainActor.run {
                var updatedMatch = match
                updatedMatch.status = .accepted
                currentMatch = updatedMatch
            }
            
            // Stop matchmaking since we have a match
            await stopMatchmaking()
            
            logger.info("Match proposal accepted - starting game")
        } else {
            await MainActor.run {
                currentMatch = nil
            }
            logger.info("Match proposal declined")
        }
    }
    
    /// Send score update to connected peer
    func sendScoreUpdate(matchId: String, player1Score: Int, player2Score: Int) throws {
        let scoreUpdate = ScoreUpdate(
            matchId: matchId,
            player1Score: player1Score,
            player2Score: player2Score,
            timestamp: Date()
        )
        
        let scoreData = try JSONEncoder().encode(scoreUpdate)
        let message = MatchMessage.scoreUpdate(scoreData)
        
        try sendMessage(message, to: self.session.connectedPeers)
        logger.info("Sent score update: \(player1Score)-\(player2Score)")
    }
    
    // MARK: - Private Methods
    
    private func startQueueSimulation() {
        // Simulate queue position updates
        guard let appState = appState else { return }
        
        Task { @MainActor in
            let position = Int.random(in: 1...5)
            let waitTime = TimeInterval(Int.random(in: 30...120))
            
            appState.queuePosition = position
            appState.estimatedWaitTime = waitTime
            
            self.queuePosition = position
            self.estimatedWaitTime = waitTime
        }
        
        // Update position every 10 seconds
        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] timer in
            guard let self = self, let appState = self.appState else {
                timer.invalidate()
                return
            }
            
            Task { @MainActor in
                guard appState.isInQueue else {
                    timer.invalidate()
                    return
                }
                
                let newPosition = max(1, appState.queuePosition - 1)
                let newWaitTime = max(15, appState.estimatedWaitTime - 10)
                
                appState.queuePosition = newPosition
                appState.estimatedWaitTime = newWaitTime
                
                self.queuePosition = newPosition
                self.estimatedWaitTime = newWaitTime
            }
        }
    }
    
    private func findPeerID(for displayName: String) -> MCPeerID? {
        return self.session.connectedPeers.first { $0.displayName == displayName }
    }
    
    private func sendMessage(_ message: MatchMessage, to peers: [MCPeerID]) throws {
        let data = try JSONEncoder().encode(message)
        try self.session.send(data, toPeers: peers, with: .reliable)
    }
    
    private func handleReceivedData(_ data: Data, from peerID: MCPeerID) {
        do {
            let message = try JSONDecoder().decode(MatchMessage.self, from: data)
            
            switch message {
            case .proposal(let proposalData):
                let match = try JSONDecoder().decode(LocalMatch.self, from: proposalData)
                currentMatch = match
                logger.info("Received match proposal from \(peerID.displayName)")
                
                // Notify UI about new proposal
                NotificationCenter.default.post(
                    name: .localMatchProposalReceived,
                    object: match
                )
                
            case .response(let responseData):
                let response = try JSONDecoder().decode(LocalMatchResponse.self, from: responseData)
                
                if response.accepted {
                    logger.info("Match proposal accepted by \(peerID.displayName)")
                    
                    // Update match status
                    if var match = currentMatch {
                        match.status = .accepted
                        currentMatch = match
                        
                        Task { @MainActor in
                            self.stopMatchmaking()
                        }
                        
                        NotificationCenter.default.post(
                            name: .localMatchAccepted,
                            object: match
                        )
                    }
                } else {
                    logger.info("Match proposal declined by \(peerID.displayName)")
                    currentMatch = nil
                    
                    NotificationCenter.default.post(
                        name: .localMatchDeclined,
                        object: nil
                    )
                }
                
            case .scoreUpdate(let scoreData):
                let scoreUpdate = try JSONDecoder().decode(ScoreUpdate.self, from: scoreData)
                logger.info("Received score update from \(peerID.displayName): \(scoreUpdate.player1Score)-\(scoreUpdate.player2Score)")
                
                // Post notification with score update
                NotificationCenter.default.post(
                    name: .localScoreUpdated,
                    object: scoreUpdate
                )
                
            case .gameUpdate(_):
                logger.info("Received game update from \(peerID.displayName)")
                // Handle game state updates during active match
                
            case .heartbeat:
                // Keep connection alive
                break
            }
            
        } catch {
            logger.error("Failed to decode message: \(error.localizedDescription)")
        }
    }
    
    private func updateNearbyPlayers(from peerID: MCPeerID, discoveryInfo: [String: String]?) {
        guard let info = discoveryInfo,
              let displayName = info["displayName"],
              let eloString = info["elo"],
              let elo = Int(eloString),
              let matchType = info["type"],
              let userId = info["name"] else {
            logger.warning("Invalid discovery info received from \(peerID.displayName)")
            return
        }
        
        // Don't add ourselves to the nearby players list
        guard let currentUser = self.currentUser,
              userId != currentUser.id.uuidString else {
            logger.info("Ignoring our own peer: \(displayName) (\(userId))")
            return
        }
        
        // Only show players looking for the same match type
        guard matchType == self.matchType.rawValue else {
            logger.info("Ignoring player \(displayName) with different match type: \(matchType) vs \(self.matchType.rawValue)")
            return
        }
        
        let player = NearbyPlayer(
            id: userId,
            displayName: displayName,
            elo: elo,
            matchType: matchType,
            distance: 0.1, // Assume very close for local network
            peerID: peerID.displayName
        )
        
        // Add or update player
        if let index = self.nearbyPlayers.firstIndex(where: { $0.id == player.id }) {
            logger.info("Updating existing nearby player: \(displayName)")
            self.nearbyPlayers[index] = player
        } else {
            logger.info("Adding new nearby player: \(displayName) (\(userId))")
            self.nearbyPlayers.append(player)
        }
        
        logger.info("Updated nearby players: \(self.nearbyPlayers.count) found")
    }
    
    private func removeNearbyPlayer(peerID: MCPeerID) {
        self.nearbyPlayers.removeAll { $0.peerID == peerID.displayName }
        logger.info("Removed player: \(peerID.displayName)")
    }
}

// MARK: - Message Types
private enum MatchMessage: Codable {
    case proposal(Data)
    case response(Data)
    case scoreUpdate(Data)
    case gameUpdate(Data)
    case heartbeat
}

private struct LocalMatchResponse: Codable {
    let matchId: String
    let accepted: Bool
}

struct ScoreUpdate: Codable {
    let matchId: String
    let player1Score: Int
    let player2Score: Int
    let timestamp: Date
}

// MARK: - MCSessionDelegate
extension LocalMatchmakingService: MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                self.logger.info("Connected to peer: \(peerID.displayName)")
                self.connectionStatus = .connected
                
            case .connecting:
                self.logger.info("Connecting to peer: \(peerID.displayName)")
                self.connectionStatus = .connecting
                
            case .notConnected:
                self.logger.info("Disconnected from peer: \(peerID.displayName)")
                self.removeNearbyPlayer(peerID: peerID)
                
                if self.session.connectedPeers.isEmpty {
                    self.connectionStatus = .disconnected
                }
                
            @unknown default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.handleReceivedData(data, from: peerID)
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Not used in this implementation
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Not used in this implementation
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Not used in this implementation
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension LocalMatchmakingService: MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        logger.info("✅ Received invitation from: \(peerID.displayName)")
        
        // Auto-accept invitations for matchmaking
        invitationHandler(true, self.session)
    }
    
    // Add success callbacks (these are not official delegate methods, but let's add logging to know when things start successfully)
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didStartAdvertisingPeer peerID: MCPeerID) {
        logger.info("✅ Successfully started advertising peer: \(peerID.displayName)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        let nsError = error as NSError
        logger.error("Failed to start advertising: \(error.localizedDescription) (Code: \(nsError.code))")
        
        // Handle specific network errors
        if nsError.domain == "NSNetServicesErrorDomain" && nsError.code == -72008 {
            logger.warning("Network unavailable for advertising - this is expected on simulator or without network permissions")
            // Don't set error status for this specific case as it's expected on simulator
            return
        }
        
        DispatchQueue.main.async {
            self.connectionStatus = .error(error.localizedDescription)
        }
        
        // Retry after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if let appState = self.appState, appState.isInQueue {
                self.logger.info("Retrying advertising after network error...")
                advertiser.startAdvertisingPeer()
            }
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension LocalMatchmakingService: MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        logger.info("Found peer: \(peerID.displayName)")
        
        DispatchQueue.main.async {
            self.updateNearbyPlayers(from: peerID, discoveryInfo: info)
        }
        
        // Invite the peer to connect
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        logger.info("Lost peer: \(peerID.displayName)")
        
        DispatchQueue.main.async {
            self.removeNearbyPlayer(peerID: peerID)
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        let nsError = error as NSError
        logger.error("Failed to start browsing: \(error.localizedDescription) (Code: \(nsError.code))")
        
        // Handle specific network errors
        if nsError.domain == "NSNetServicesErrorDomain" && nsError.code == -72008 {
            logger.warning("Network unavailable for browsing - this is expected on simulator or without network permissions")
            // Don't set error status for this specific case as it's expected on simulator
            return
        }
        
        DispatchQueue.main.async {
            self.connectionStatus = .error(error.localizedDescription)
        }
        
        // Retry after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if let appState = self.appState, appState.isInQueue {
                self.logger.info("Retrying browsing after network error...")
                browser.startBrowsingForPeers()
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let localMatchProposalReceived = Notification.Name("localMatchProposalReceived")
    static let localMatchAccepted = Notification.Name("localMatchAccepted")
    static let localMatchDeclined = Notification.Name("localMatchDeclined")
    static let localMatchCompleted = Notification.Name("localMatchCompleted")
    static let localScoreUpdated = Notification.Name("localScoreUpdated")
}