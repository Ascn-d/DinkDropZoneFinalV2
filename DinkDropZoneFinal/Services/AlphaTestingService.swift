import Foundation
import UIKit
import os.log

// MARK: - Simplified Alpha Testing Service (No Firebase Dependencies)
@MainActor
final class AlphaTestingService: ObservableObject {
    
    static let shared = AlphaTestingService()
    
    // MARK: - Published Properties
    @Published var isActive: Bool = false
    @Published var sessionMetrics: TestingMetrics = TestingMetrics()
    @Published var performanceData: [PerformanceMetric] = []
    
    private let logger = Logger(subsystem: "DinkDropZone", category: "AlphaTesting")
    private var sessionStartTime: Date?
    private var currentSession: TestSession?
    
    // MARK: - Data Models
    struct TestingMetrics: Codable {
        var sessionDuration: TimeInterval = 0
        var viewTransitions: Int = 0
        var userActions: Int = 0
        var errorCount: Int = 0
        var matchmakingAttempts: Int = 0
        var successfulMatches: Int = 0
        var averageResponseTime: TimeInterval = 0
        var crashCount: Int = 0
        var memoryUsage: Double = 0 // MB
        var batteryUsage: Double = 0 // %
    }
    
    struct PerformanceMetric: Identifiable, Codable {
        let id: UUID
        let timestamp: Date
        let type: MetricType
        let value: Double
        let context: String
        
        init(timestamp: Date, type: MetricType, value: Double, context: String) {
            self.id = UUID()
            self.timestamp = timestamp
            self.type = type
            self.value = value
            self.context = context
        }
        
        enum MetricType: String, Codable {
            case viewLoadTime = "view_load_time"
            case networkRequest = "network_request"
            case userAction = "user_action"
            case memory = "memory_usage"
            case battery = "battery_usage"
            case error = "error"
        }
    }
    
    struct TestSession: Codable {
        let id: String
        let userId: String
        let deviceInfo: DeviceInfo
        let startTime: Date
        var endTime: Date?
        var metrics: TestingMetrics
        var events: [TestEvent]
        
        struct DeviceInfo: Codable {
            let model: String
            let osVersion: String
            let appVersion: String
            let buildNumber: String
            let screenSize: String
            let memorySize: String
        }
        
        struct TestEvent: Codable {
            let timestamp: Date
            let type: String
            let action: String
            let parameters: [String: String]
            let duration: TimeInterval?
        }
    }
    
    private init() {
        logger.info("AlphaTestingService initialized (simplified version)")
    }
    
    // MARK: - Session Management
    
    /// Start alpha testing session
    func startTestingSession(user: User) {
        guard !isActive else { return }
        
        sessionStartTime = Date()
        isActive = true
        
        let deviceInfo = TestSession.DeviceInfo(
            model: UIDevice.current.model,
            osVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            buildNumber: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown",
            screenSize: "\(Int(UIScreen.main.bounds.width))x\(Int(UIScreen.main.bounds.height))",
            memorySize: formatMemorySize(ProcessInfo.processInfo.physicalMemory)
        )
        
        currentSession = TestSession(
            id: UUID().uuidString,
            userId: user.id.uuidString,
            deviceInfo: deviceInfo,
            startTime: Date(),
            metrics: TestingMetrics(),
            events: []
        )
        
        logger.info("Alpha testing session started for user: \(user.displayName)")
        
        // Start periodic metrics collection
        startMetricsCollection()
    }
    
    /// End alpha testing session
    func endTestingSession() {
        guard isActive, var session = currentSession else { return }
        
        session.endTime = Date()
        session.metrics.sessionDuration = Date().timeIntervalSince(session.startTime)
        
        // Save session data locally
        saveSessionLocally(session)
        
        isActive = false
        currentSession = nil
        sessionStartTime = nil
        
        logger.info("Alpha testing session ended. Duration: \(session.metrics.sessionDuration)s")
    }
    
    // MARK: - Event Tracking
    
    /// Record user action
    func recordUserAction(action: String, parameters: [String: String] = [:]) {
        guard isActive else { return }
        
        let event = TestSession.TestEvent(
            timestamp: Date(),
            type: "user_action",
            action: action,
            parameters: parameters,
            duration: nil
        )
        
        currentSession?.events.append(event)
        sessionMetrics.userActions += 1
        
        // Add performance metric
        let metric = PerformanceMetric(
            timestamp: Date(),
            type: .userAction,
            value: 1,
            context: action
        )
        performanceData.append(metric)
        
        logger.debug("Recorded user action: \(action)")
    }
    
    /// Record view transition
    func recordViewTransition(from: String, to: String, duration: TimeInterval) {
        guard isActive else { return }
        
        let event = TestSession.TestEvent(
            timestamp: Date(),
            type: "view_transition",
            action: "navigate",
            parameters: ["from": from, "to": to],
            duration: duration
        )
        
        currentSession?.events.append(event)
        sessionMetrics.viewTransitions += 1
        
        // Track view load time
        let metric = PerformanceMetric(
            timestamp: Date(),
            type: .viewLoadTime,
            value: duration,
            context: "\(from) -> \(to)"
        )
        performanceData.append(metric)
        
        logger.debug("Recorded view transition: \(from) -> \(to) (\(duration)s)")
    }
    
    /// Record error
    func recordError(_ error: Error, context: String) {
        guard isActive else { return }
        
        let event = TestSession.TestEvent(
            timestamp: Date(),
            type: "error",
            action: "error_occurred",
            parameters: [
                "error": error.localizedDescription,
                "context": context
            ],
            duration: nil
        )
        
        currentSession?.events.append(event)
        sessionMetrics.errorCount += 1
        
        let metric = PerformanceMetric(
            timestamp: Date(),
            type: .error,
            value: 1,
            context: "\(context): \(error.localizedDescription)"
        )
        performanceData.append(metric)
        
        logger.error("Recorded error: \(error.localizedDescription) in \(context)")
    }
    
    /// Record matchmaking attempt
    func recordMatchmakingAttempt(success: Bool, duration: TimeInterval) {
        guard isActive else { return }
        
        sessionMetrics.matchmakingAttempts += 1
        if success {
            sessionMetrics.successfulMatches += 1
        }
        
        let event = TestSession.TestEvent(
            timestamp: Date(),
            type: "matchmaking",
            action: success ? "match_found" : "match_failed",
            parameters: ["duration": String(duration)],
            duration: duration
        )
        
        currentSession?.events.append(event)
        
        logger.info("Recorded matchmaking attempt: \(success ? "success" : "failure") (\(duration)s)")
    }
    
    // MARK: - Performance Monitoring
    
    private func startMetricsCollection() {
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self = self, self.isActive else {
                    timer.invalidate()
                    return
                }
                await self.collectPerformanceMetrics()
            }
        }
    }
    
    private func collectPerformanceMetrics() async {
        // Collect memory usage
        let memoryUsage = getMemoryUsage()
        sessionMetrics.memoryUsage = memoryUsage
        
        let memoryMetric = PerformanceMetric(
            timestamp: Date(),
            type: .memory,
            value: memoryUsage,
            context: "periodic_collection"
        )
        performanceData.append(memoryMetric)
        
        // Collect battery level (simplified)
        let batteryLevel = UIDevice.current.batteryLevel
        if batteryLevel >= 0 {
            sessionMetrics.batteryUsage = Double(batteryLevel * 100)
            
            let batteryMetric = PerformanceMetric(
                timestamp: Date(),
                type: .battery,
                value: Double(batteryLevel * 100),
                context: "periodic_collection"
            )
            performanceData.append(batteryMetric)
        }
        
        // Limit performance data array size
        if performanceData.count > 1000 {
            performanceData = Array(performanceData.suffix(500))
        }
    }
    
    // MARK: - Simplified Crashlytics (No Firebase)
    
    /// Set crashlytics user ID (simplified)
    func setCrashlyticsUserId(_ userId: String, displayName: String) {
        logger.info("Would set Crashlytics user ID: \(userId) (\(displayName))")
        // In a real Firebase setup, this would set Crashlytics user info
    }
    
    /// Record crash (simplified)
    func recordCrash(_ crashInfo: String) {
        sessionMetrics.crashCount += 1
        logger.error("Crash recorded: \(crashInfo)")
        
        // Save crash info locally
        let crashData = [
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "sessionId": currentSession?.id ?? "unknown",
            "crashInfo": crashInfo
        ]
        
        UserDefaults.standard.set(crashData, forKey: "lastCrash")
    }
    
    // MARK: - Data Management
    
    private func saveSessionLocally(_ session: TestSession) {
        do {
            let data = try JSONEncoder().encode(session)
            let filename = "session_\(session.id).json"
            let url = getDocumentsDirectory().appendingPathComponent(filename)
            try data.write(to: url)
            
            logger.info("Session data saved locally: \(filename)")
        } catch {
            logger.error("Failed to save session data: \(error.localizedDescription)")
        }
    }
    
    /// Get all local session files
    func getLocalSessions() -> [TestSession] {
        let documentsDir = getDocumentsDirectory()
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: documentsDir, includingPropertiesForKeys: nil)
            let sessionFiles = files.filter { $0.lastPathComponent.hasPrefix("session_") }
            
            var sessions: [TestSession] = []
            for file in sessionFiles {
                if let data = try? Data(contentsOf: file),
                   let session = try? JSONDecoder().decode(TestSession.self, from: data) {
                    sessions.append(session)
                }
            }
            
            return sessions.sorted { $0.startTime > $1.startTime }
        } catch {
            logger.error("Failed to load local sessions: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Export session data for sharing
    func exportSessionData() -> String {
        let sessions = getLocalSessions()
        
        do {
            let data = try JSONEncoder().encode(sessions)
            return String(data: data, encoding: .utf8) ?? "Failed to encode"
        } catch {
            return "Export failed: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Utility Methods
    
    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0 // Convert to MB
        } else {
            return 0.0
        }
    }
    
    private func formatMemorySize(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / 1024.0 / 1024.0 / 1024.0
        return String(format: "%.1f GB", gb)
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}