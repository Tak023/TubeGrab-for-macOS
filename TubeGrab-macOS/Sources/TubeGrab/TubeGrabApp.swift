//
//  TubeGrabApp.swift
//  TubeGrab
//
//  A modern YouTube video downloader for macOS
//

import SwiftUI

@main
struct TubeGrabApp: App {
    @StateObject private var downloadManager = DownloadManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(downloadManager)
                .frame(minWidth: 600, minHeight: 700)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
