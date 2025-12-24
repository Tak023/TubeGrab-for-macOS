//
//  Theme.swift
//  TubeGrab
//
//  Modern dark theme colors and design constants
//

import SwiftUI

// MARK: - Modern Colors

struct ModernColors {
    // Backgrounds
    static let bgDark = Color(hex: "0D0D0D")
    static let bgSecondary = Color(hex: "1A1A1A")
    static let bgTertiary = Color(hex: "252525")
    static let bgCard = Color(hex: "1E1E1E")

    // Accents
    static let accentPrimary = Color(hex: "FF3366")
    static let accentSecondary = Color(hex: "00D4AA")

    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "A0A0A0")
    static let textMuted = Color(hex: "606060")

    // Status
    static let success = Color(hex: "00D4AA")
    static let warning = Color(hex: "FFB800")
    static let error = Color(hex: "FF4757")

    // UI Elements
    static let border = Color(hex: "2A2A2A")
    static let hover = Color(hex: "303030")

    // Gradients
    static let headerGradient = LinearGradient(
        colors: [accentPrimary.opacity(0.15), bgDark],
        startPoint: .top,
        endPoint: .bottom
    )

    static let accentGradient = LinearGradient(
        colors: [accentPrimary, accentPrimary.opacity(0.8)],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Design Constants

struct DesignConstants {
    static let cornerRadius: CGFloat = 12
    static let smallCornerRadius: CGFloat = 8
    static let spacing: CGFloat = 16
    static let smallSpacing: CGFloat = 8
    static let padding: CGFloat = 20
    static let cardPadding: CGFloat = 16

    static let iconSize: CGFloat = 20
    static let largeIconSize: CGFloat = 48

    static let progressHeight: CGFloat = 6
    static let buttonHeight: CGFloat = 44

    static let maxTitleLength = 60
    static let maxPathLength = 50
}

// MARK: - Quality Options

enum VideoQuality: String, CaseIterable, Identifiable {
    case ultra4K = "2160"
    case bestQuality = "best"
    case fullHD1080 = "1080"
    case hd720 = "720"
    case sd480 = "480"
    case low360 = "360"
    case audioOnly = "audio"

    var id: String { rawValue }

    var isAudioOnly: Bool {
        self == .audioOnly
    }

    var displayName: String {
        switch self {
        case .ultra4K: return "4K Ultra HD (2160p)"
        case .bestQuality: return "Best Quality (MP4)"
        case .fullHD1080: return "1080p Full HD"
        case .hd720: return "720p HD"
        case .sd480: return "480p SD"
        case .low360: return "360p Low"
        case .audioOnly: return "Audio Only (M4A)"
        }
    }

    var icon: String {
        switch self {
        case .ultra4K: return "4k.tv"
        case .bestQuality: return "star.fill"
        case .fullHD1080: return "play.rectangle.fill"
        case .hd720: return "play.rectangle"
        case .sd480: return "play.square"
        case .low360: return "play.square.fill"
        case .audioOnly: return "music.note"
        }
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: DesignConstants.smallCornerRadius)
                    .fill(isEnabled ? ModernColors.accentPrimary : ModernColors.textMuted)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(ModernColors.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: DesignConstants.smallCornerRadius)
                    .fill(ModernColors.bgTertiary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignConstants.smallCornerRadius)
                    .stroke(ModernColors.border, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct IconButtonStyle: ButtonStyle {
    var size: CGFloat = 36

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: DesignConstants.smallCornerRadius)
                    .fill(configuration.isPressed ? ModernColors.hover : ModernColors.bgTertiary)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
