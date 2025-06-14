import Foundation
import OSLog

enum LogLevel: String {
    case debug = "🔍"
    case info = "ℹ️"
    case warning = "⚠️"
    case error = "❌"
    case critical = "💥"
}

class LoggingService {
    static let shared = LoggingService()
    private let logger: Logger
    
    private init() {
        logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.dinkdropzone", category: "App")
    }
    
    func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "\(level.rawValue) [\(fileName):\(line)] \(function): \(message)"
        
        switch level {
        case .debug:
            logger.debug("\(logMessage)")
        case .info:
            logger.info("\(logMessage)")
        case .warning:
            logger.warning("\(logMessage)")
        case .error:
            logger.error("\(logMessage)")
        case .critical:
            logger.critical("\(logMessage)")
        }
        
        #if DEBUG
        print(logMessage)
        #endif
    }
    
    func logError(_ error: Error, context: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let errorMessage = context.map { "\($0): \(error.localizedDescription)" } ?? error.localizedDescription
        log(errorMessage, level: .error, file: file, function: function, line: line)
    }
    
    func logDataError(_ error: Error, operation: String, file: String = #file, function: String = #function, line: Int = #line) {
        let context = "Data operation '\(operation)' failed"
        logError(error, context: context, file: file, function: function, line: line)
    }
} 