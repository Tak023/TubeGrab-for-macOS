//
//  ContentView.swift
//  TubeGrab
//
//  Main application view with header, input, and download queue
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var downloadManager: DownloadManager
    @State private var urlInput: String = ""
    @State private var selectedQuality: VideoQuality = .bestQuality
    @State private var showInvalidURL = false

    var body: some View {
        ZStack {
            // Background
            ModernColors.bgDark
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HeaderView()

                // Main Content
                VStack(spacing: DesignConstants.spacing) {
                    // Input Section
                    InputSection(
                        urlInput: $urlInput,
                        selectedQuality: $selectedQuality,
                        showInvalidURL: $showInvalidURL,
                        onAdd: addToQueue
                    )

                    // Download Queue
                    DownloadQueueView()

                    // Footer
                    FooterView()
                }
                .padding(DesignConstants.padding)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func addToQueue() {
        let trimmedURL = urlInput.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedURL.isEmpty else { return }

        if downloadManager.isValidYouTubeURL(trimmedURL) {
            downloadManager.addToQueue(url: trimmedURL, quality: selectedQuality)
            urlInput = ""
            showInvalidURL = false
        } else {
            showInvalidURL = true
        }
    }
}

// MARK: - Header View

struct HeaderView: View {
    @EnvironmentObject var downloadManager: DownloadManager

    var body: some View {
        ZStack {
            ModernColors.headerGradient
                .frame(height: 80)

            HStack {
                // Logo and Title
                HStack(spacing: 12) {
                    // App Icon
                    ZStack {
                        Circle()
                            .fill(ModernColors.accentPrimary.opacity(0.2))
                            .frame(width: 44, height: 44)

                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(ModernColors.accentPrimary)
                    }

                    Text("TubeGrab")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(ModernColors.textPrimary)
                }

                Spacer()

                // Folder Button
                Button(action: { downloadManager.openDownloadFolder() }) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 16))
                        .foregroundColor(ModernColors.textSecondary)
                }
                .buttonStyle(IconButtonStyle())
                .help("Open download folder")
            }
            .padding(.horizontal, DesignConstants.padding)
        }
    }
}

// MARK: - Input Section

struct InputSection: View {
    @EnvironmentObject var downloadManager: DownloadManager
    @Binding var urlInput: String
    @Binding var selectedQuality: VideoQuality
    @Binding var showInvalidURL: Bool
    var onAdd: () -> Void

    var body: some View {
        VStack(spacing: DesignConstants.smallSpacing) {
            // URL Input Row
            HStack(spacing: DesignConstants.smallSpacing) {
                // URL Text Field
                HStack {
                    Image(systemName: "link")
                        .foregroundColor(ModernColors.textMuted)
                        .frame(width: 20)

                    TextField("Paste YouTube URL here...", text: $urlInput)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .foregroundColor(ModernColors.textPrimary)
                        .onSubmit { onAdd() }
                        .onChange(of: urlInput) {
                            showInvalidURL = false
                        }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: DesignConstants.smallCornerRadius)
                        .fill(ModernColors.bgSecondary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignConstants.smallCornerRadius)
                        .stroke(showInvalidURL ? ModernColors.error : ModernColors.border, lineWidth: 1)
                )

                // Paste Button
                Button(action: pasteFromClipboard) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 14))
                        .foregroundColor(ModernColors.textSecondary)
                }
                .buttonStyle(IconButtonStyle())
                .help("Paste from clipboard")
            }

            // Invalid URL Message
            if showInvalidURL {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                    Text("Please enter a valid YouTube URL")
                        .font(.system(size: 12))
                    Spacer()
                }
                .foregroundColor(ModernColors.error)
                .padding(.leading, 4)
            }

            // Quality and Add Button Row
            HStack(spacing: DesignConstants.smallSpacing) {
                // Quality Picker
                Menu {
                    ForEach(VideoQuality.allCases) { quality in
                        Button(action: { selectedQuality = quality }) {
                            HStack {
                                Image(systemName: quality.icon)
                                Text(quality.displayName)
                                if quality == selectedQuality {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: selectedQuality.icon)
                            .foregroundColor(ModernColors.accentSecondary)
                        Text(selectedQuality.displayName)
                            .font(.system(size: 13))
                            .foregroundColor(ModernColors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(ModernColors.textMuted)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: DesignConstants.smallCornerRadius)
                            .fill(ModernColors.bgSecondary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignConstants.smallCornerRadius)
                            .stroke(ModernColors.border, lineWidth: 1)
                    )
                }
                .menuStyle(.borderlessButton)
                .frame(maxWidth: .infinity)

                // Add to Queue Button
                Button(action: onAdd) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add to Queue")
                    }
                }
                .buttonStyle(PrimaryButtonStyle(isEnabled: !urlInput.isEmpty))
                .disabled(urlInput.isEmpty)
            }
        }
        .padding(DesignConstants.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: DesignConstants.cornerRadius)
                .fill(ModernColors.bgCard)
        )
    }

    private func pasteFromClipboard() {
        if let string = NSPasteboard.general.string(forType: .string) {
            urlInput = string.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}

// MARK: - Download Queue View

struct DownloadQueueView: View {
    @EnvironmentObject var downloadManager: DownloadManager

    var body: some View {
        VStack(spacing: DesignConstants.smallSpacing) {
            // Queue Header
            HStack {
                Text("Download Queue")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ModernColors.textPrimary)

                if downloadManager.queueCount > 0 {
                    Text("\(downloadManager.queueCount)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ModernColors.accentPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(ModernColors.accentPrimary.opacity(0.2))
                        )
                }

                Spacer()

                if !downloadManager.downloads.isEmpty {
                    Button(action: { downloadManager.clearCompleted() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                            Text("Clear Completed")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(ModernColors.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .opacity(downloadManager.completedCount > 0 ? 1 : 0.5)
                    .disabled(downloadManager.completedCount == 0)
                }
            }

            // Queue List
            if downloadManager.downloads.isEmpty {
                EmptyQueueView()
            } else {
                ScrollView {
                    LazyVStack(spacing: DesignConstants.smallSpacing) {
                        ForEach(downloadManager.downloads) { item in
                            DownloadItemView(item: item)
                        }
                    }
                }
            }
        }
        .padding(DesignConstants.cardPadding)
        .frame(maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: DesignConstants.cornerRadius)
                .fill(ModernColors.bgCard)
        )
    }
}

// MARK: - Empty Queue View

struct EmptyQueueView: View {
    var body: some View {
        VStack(spacing: DesignConstants.spacing) {
            Spacer()

            Image(systemName: "arrow.down.doc")
                .font(.system(size: 48))
                .foregroundColor(ModernColors.textMuted)

            VStack(spacing: 4) {
                Text("No downloads yet")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(ModernColors.textSecondary)

                Text("Paste a YouTube URL above to get started")
                    .font(.system(size: 13))
                    .foregroundColor(ModernColors.textMuted)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Download Item View

struct DownloadItemView: View {
    @EnvironmentObject var downloadManager: DownloadManager
    @ObservedObject var item: DownloadItem
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            // Status Icon
            Image(systemName: item.status.icon)
                .font(.system(size: 18))
                .foregroundColor(item.status.color)
                .frame(width: 24)
                .symbolEffect(.pulse, isActive: item.status == .downloading)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(item.truncatedTitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(ModernColors.textPrimary)
                    .lineLimit(1)

                // Status Row
                HStack(spacing: 8) {
                    Text(item.status.rawValue)
                        .font(.system(size: 11))
                        .foregroundColor(item.status.color)

                    if item.status == .downloading {
                        if !item.speed.isEmpty {
                            Text("•")
                                .foregroundColor(ModernColors.textMuted)
                            Text(item.speed)
                                .font(.system(size: 11))
                                .foregroundColor(ModernColors.textSecondary)
                        }

                        if !item.size.isEmpty {
                            Text("•")
                                .foregroundColor(ModernColors.textMuted)
                            Text(item.size)
                                .font(.system(size: 11))
                                .foregroundColor(ModernColors.textSecondary)
                        }
                    }

                    if item.status == .error && !item.errorMessage.isEmpty {
                        Text("•")
                            .foregroundColor(ModernColors.textMuted)
                        Text(item.errorMessage)
                            .font(.system(size: 11))
                            .foregroundColor(ModernColors.error)
                            .lineLimit(1)
                    }
                }

                // Progress Bar
                if item.status == .downloading || item.status == .complete {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 3)
                                .fill(ModernColors.bgTertiary)
                                .frame(height: DesignConstants.progressHeight)

                            // Progress
                            RoundedRectangle(cornerRadius: 3)
                                .fill(item.status == .complete ? ModernColors.success : ModernColors.accentPrimary)
                                .frame(width: geometry.size.width * (item.progress / 100), height: DesignConstants.progressHeight)
                                .animation(.easeInOut(duration: 0.3), value: item.progress)
                        }
                    }
                    .frame(height: DesignConstants.progressHeight)
                }
            }

            Spacer()

            // Progress Percentage
            if item.status == .downloading {
                Text("\(Int(item.progress))%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ModernColors.textSecondary)
                    .monospacedDigit()
            }

            // Remove Button
            Button(action: { downloadManager.removeItem(item) }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(ModernColors.textMuted)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(isHovering ? ModernColors.hover : Color.clear)
                    )
            }
            .buttonStyle(.plain)
            .opacity(isHovering ? 1 : 0.5)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: DesignConstants.smallCornerRadius)
                .fill(isHovering ? ModernColors.bgTertiary : ModernColors.bgSecondary)
        )
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Footer View

struct FooterView: View {
    @EnvironmentObject var downloadManager: DownloadManager

    var body: some View {
        HStack {
            // Download Path
            Button(action: { downloadManager.selectDownloadFolder() }) {
                HStack(spacing: 6) {
                    Image(systemName: "folder")
                        .font(.system(size: 12))
                        .foregroundColor(ModernColors.textMuted)

                    Text(downloadManager.truncatedPath)
                        .font(.system(size: 11))
                        .foregroundColor(ModernColors.textSecondary)
                        .lineLimit(1)
                }
            }
            .buttonStyle(.plain)
            .help("Click to change download folder")

            Spacer()

            // Version
            Text("v1.0")
                .font(.system(size: 11))
                .foregroundColor(ModernColors.textMuted)
        }
        .padding(.horizontal, 4)
    }
}
