// DebugOptions.swift
// Automatically enable helpful runtime diagnostics in DEBUG builds.

#if DEBUG
import UIKit

/// Enable verbose Auto-Layout logging so that conflicting constraints are visible in Xcode's console
/// without having to set the environment variable manually.
private let _enableUnsatisfiableConstraintLogging: Void = {
    UserDefaults.standard.set(true, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
}()
#endif 