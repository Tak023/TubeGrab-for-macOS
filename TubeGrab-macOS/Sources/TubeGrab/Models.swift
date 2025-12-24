//
//  Models.swift
//  TubeGrab
//
//  Data models for download items and state management
//

import Foundation
import SwiftUI

// MARK: - Download Status

enum DownloadStatus: String, Equatable {
    case queued = "Queued"
    case downloading = "Downloading"
    case complete = "Complete"
    case error = "Error"

    var color: Color {
        switch self {
        case .queued: return ModernColors.textSecondary
        case .downloading: return ModernColors.accentPrimary
        case .complete: return ModernColors.success
        case .error: return ModernColors.error
        }
    }

    var icon: String {
        switch self {
        case .queued: return "clock.fill"
        case .downloading: return "arrow.down.circle.fill"
        case .complete: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Download Item

class DownloadItem: ObservableObject, Identifiable {
    let id = UUID()
    let url: String
    let quality: VideoQuality

    @Published var title: String
    @Published var progress: Double = 0
    @Published var status: DownloadStatus = .queued
    @Published var speed: String = ""
    @Published var size: String = ""
    @Published var eta: String = ""
    @Published var errorMessage: String = ""

    init(url: String, quality: VideoQuality, title: String = "Loading...") {
        self.url = url
        self.quality = quality
        self.title = title
    }

    var truncatedTitle: String {
        if title.count > DesignConstants.maxTitleLength {
            return String(title.prefix(DesignConstants.maxTitleLength - 3)) + "..."
        }
        return title
    }
}

// MARK: - Download Manager

@MainActor
class DownloadManager: ObservableObject {
    @Published var downloads: [DownloadItem] = []
    @Published var downloadPath: URL
    @Published var isProcessing = false

    private var activeDownloads = 0
    private let maxConcurrentDownloads = 5
    private var downloadTasks: [UUID: Task<Void, Never>] = [:]

    init() {
        // Default to ~/Videos/TubeGrab or ~/Downloads/TubeGrab
        let videosPath = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask).first
        let downloadsPath = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first

        let basePath = videosPath ?? downloadsPath ?? FileManager.default.homeDirectoryForCurrentUser
        self.downloadPath = basePath.appendingPathComponent("TubeGrab")

        // Create directory if needed
        try? FileManager.default.createDirectory(at: downloadPath, withIntermediateDirectories: true)
    }

    var truncatedPath: String {
        let path = downloadPath.path
        if path.count > DesignConstants.maxPathLength {
            return "..." + String(path.suffix(DesignConstants.maxPathLength - 3))
        }
        return path
    }

    var queueCount: Int {
        downloads.filter { $0.status == .queued || $0.status == .downloading }.count
    }

    var completedCount: Int {
        downloads.filter { $0.status == .complete }.count
    }

    // MARK: - URL Validation

    func isValidYouTubeURL(_ url: String) -> Bool {
        let patterns = [
            #"^(https?://)?(www\.)?(youtube\.com|youtu\.be)/.+"#,
            #"^(https?://)?(www\.)?youtube\.com/watch\?v=[\w-]+"#,
            #"^(https?://)?(www\.)?youtu\.be/[\w-]+"#,
            #"^(https?://)?(www\.)?youtube\.com/shorts/[\w-]+"#
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(url.startIndex..., in: url)
                if regex.firstMatch(in: url, options: [], range: range) != nil {
                    return true
                }
            }
        }
        return false
    }

    // MARK: - Queue Management

    func addToQueue(url: String, quality: VideoQuality) {
        guard isValidYouTubeURL(url) else { return }

        let item = DownloadItem(url: url, quality: quality)
        downloads.insert(item, at: 0)

        // Fetch video title in background
        Task {
            await fetchVideoTitle(for: item)
        }

        // Start processing queue
        processQueue()
    }

    private func fetchVideoTitle(for item: DownloadItem) async {
        guard let ytdlpPath = findYtDlp() else { return }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: ytdlpPath)
        process.arguments = ["--get-title", "--no-playlist", item.url]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let title = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !title.isEmpty {
                item.title = title
            }
        } catch {
            // Keep default "Loading..." title if fetch fails
        }
    }

    func removeItem(_ item: DownloadItem) {
        // Cancel if downloading
        if let task = downloadTasks[item.id] {
            task.cancel()
            downloadTasks.removeValue(forKey: item.id)
            activeDownloads = max(0, activeDownloads - 1)
        }

        downloads.removeAll { $0.id == item.id }
        processQueue()
    }

    func clearCompleted() {
        downloads.removeAll { $0.status == .complete || $0.status == .error }
    }

    func clearAll() {
        // Cancel all active downloads
        for (_, task) in downloadTasks {
            task.cancel()
        }
        downloadTasks.removeAll()
        activeDownloads = 0
        downloads.removeAll()
    }

    // MARK: - Download Processing

    private func processQueue() {
        guard activeDownloads < maxConcurrentDownloads else { return }

        // Find next queued item
        guard let item = downloads.first(where: { $0.status == .queued }) else { return }

        activeDownloads += 1
        item.status = .downloading

        let task = Task {
            await downloadItem(item)
        }
        downloadTasks[item.id] = task
    }

    private func downloadItem(_ item: DownloadItem) async {
        defer {
            Task { @MainActor in
                self.activeDownloads = max(0, self.activeDownloads - 1)
                self.downloadTasks.removeValue(forKey: item.id)
                self.processQueue()
            }
        }

        // Check for yt-dlp
        guard let ytdlpPath = findYtDlp() else {
            item.status = .error
            item.errorMessage = "yt-dlp not found. Install via: brew install yt-dlp"
            return
        }

        do {
            try await executeDownload(item: item, ytdlpPath: ytdlpPath)
        } catch {
            if !Task.isCancelled {
                item.status = .error
                item.errorMessage = parseError(error.localizedDescription)
            }
        }
    }

    private func findYtDlp() -> String? {
        let possiblePaths = [
            "/opt/homebrew/bin/yt-dlp",
            "/usr/local/bin/yt-dlp",
            "/usr/bin/yt-dlp"
        ]

        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }

        // Try to find via which
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["yt-dlp"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !path.isEmpty {
                return path
            }
        } catch {
            return nil
        }

        return nil
    }

    private func executeDownload(item: DownloadItem, ytdlpPath: String) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ytdlpPath)

        let outputTemplate = downloadPath.appendingPathComponent("%(title)s.%(ext)s").path

        var arguments: [String] = []

        if item.quality.isAudioOnly {
            // Audio only - extract to m4a
            arguments = [
                "-f", "bestaudio[ext=m4a]/bestaudio",
                "-x",
                "--audio-format", "m4a",
                "-o", outputTemplate,
                "--newline",
                "--progress",
                "--no-playlist",
                item.url
            ]
        } else {
            // Video - use single file format like Python version (no merging needed)
            let height = item.quality.rawValue
            let formatString: String
            if height == "best" {
                // Prefer pre-merged mp4, fallback to best available
                formatString = "best[ext=mp4]/best"
            } else {
                // Prefer pre-merged mp4 at specified height, with fallbacks
                formatString = "best[height<=\(height)][ext=mp4]/best[height<=\(height)]/best"
            }

            arguments = [
                "-f", formatString,
                "-o", outputTemplate,
                "--newline",
                "--progress",
                "--no-playlist",
                item.url
            ]
        }

        process.arguments = arguments

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        // Handle output for progress updates
        outputPipe.fileHandleForReading.readabilityHandler = { [weak item] handle in
            let data = handle.availableData
            guard !data.isEmpty, let output = String(data: data, encoding: .utf8) else { return }

            Task { @MainActor in
                self.parseProgress(output: output, item: item)
            }
        }

        try process.run()

        // Wait for completion
        await withCheckedContinuation { continuation in
            process.terminationHandler = { _ in
                continuation.resume()
            }
        }

        // Clean up handlers
        outputPipe.fileHandleForReading.readabilityHandler = nil
        errorPipe.fileHandleForReading.readabilityHandler = nil

        if process.terminationStatus == 0 {
            item.status = .complete
            item.progress = 100
            item.speed = ""
        } else {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorOutput = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "TubeGrab", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: errorOutput])
        }
    }

    private func parseProgress(output: String, item: DownloadItem?) {
        guard let item = item else { return }

        let lines = output.components(separatedBy: .newlines)

        for line in lines {
            // Parse title from destination line
            if line.contains("[download] Destination:") {
                if let title = line.components(separatedBy: "Destination:").last?.trimmingCharacters(in: .whitespaces) {
                    let fileName = URL(fileURLWithPath: title).deletingPathExtension().lastPathComponent
                    item.title = fileName
                }
            }

            // Parse progress: [download]  45.2% of 125.50MiB at 2.50MiB/s ETA 00:32
            if line.contains("[download]") && line.contains("%") {
                // Extract percentage
                if let percentMatch = line.range(of: #"(\d+\.?\d*)%"#, options: .regularExpression) {
                    let percentStr = String(line[percentMatch]).replacingOccurrences(of: "%", with: "")
                    if let percent = Double(percentStr) {
                        item.progress = percent
                    }
                }

                // Extract size
                if let sizeMatch = line.range(of: #"of\s+([\d.]+\w+)"#, options: .regularExpression) {
                    let sizeStr = String(line[sizeMatch])
                        .replacingOccurrences(of: "of ", with: "")
                        .trimmingCharacters(in: .whitespaces)
                    item.size = sizeStr
                }

                // Extract speed
                if let speedMatch = line.range(of: #"at\s+([\d.]+\w+/s)"#, options: .regularExpression) {
                    let speedStr = String(line[speedMatch])
                        .replacingOccurrences(of: "at ", with: "")
                        .trimmingCharacters(in: .whitespaces)
                    item.speed = speedStr
                }

                // Extract ETA
                if let etaMatch = line.range(of: #"ETA\s+(\d+:\d+)"#, options: .regularExpression) {
                    let etaStr = String(line[etaMatch])
                        .replacingOccurrences(of: "ETA ", with: "")
                        .trimmingCharacters(in: .whitespaces)
                    item.eta = etaStr
                }
            }

            // Already downloaded
            if line.contains("has already been downloaded") {
                item.progress = 100
                item.status = .complete
            }
        }
    }

    private func parseError(_ error: String) -> String {
        if error.contains("Private video") {
            return "This video is private"
        }
        if error.contains("Sign in") || error.contains("age") {
            return "Age-restricted or sign-in required"
        }
        if error.contains("unavailable") || error.contains("not available") {
            return "Video unavailable"
        }
        if error.contains("ffmpeg") || error.contains("FFmpeg") {
            return "ffmpeg required. Install via: brew install ffmpeg"
        }
        if error.contains("HTTP Error 429") {
            return "Rate limited. Try again later"
        }

        // Return truncated error
        let maxLength = 50
        if error.count > maxLength {
            return String(error.prefix(maxLength)) + "..."
        }
        return error
    }

    // MARK: - Folder Selection

    func selectDownloadFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.message = "Select download folder"
        panel.prompt = "Select"

        if panel.runModal() == .OK, let url = panel.url {
            downloadPath = url
        }
    }

    func openDownloadFolder() {
        NSWorkspace.shared.open(downloadPath)
    }
}
