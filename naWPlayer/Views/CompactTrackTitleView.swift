import SwiftUI

struct CompactTrackTitleView: View {
    let track: AudioTrack?
    let onTap: () -> Void
    @Environment(\.playerTheme) private var theme

    var body: some View {
        HStack {
            trackTitle
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture(perform: onTap)
        }
    }

    @ViewBuilder
    private var trackTitle: some View {
        if let track {
            MarqueeTrackTitle(track: track)
        } else {
            Text("No track loaded")
                .font(.headline)
                .foregroundStyle(theme.palette.text)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

private struct MarqueeTrackTitle: View {
    let track: AudioTrack
    @Environment(\.playerTheme) private var theme
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var isAnimating = false

    private var overflow: CGFloat {
        max(0, textWidth - containerWidth)
    }

    var body: some View {
        GeometryReader { proxy in
            trackTitle
                .fixedSize(horizontal: true, vertical: false)
                .background(
                    GeometryReader { textProxy in
                        Color.clear
                            .onAppear {
                                textWidth = textProxy.size.width
                            }
                            .onChange(of: textProxy.size.width) { newValue in
                                textWidth = newValue
                            }
                    }
                )
                .offset(x: overflow > 0 ? (isAnimating ? -overflow : 0) : max(0, (proxy.size.width - textWidth) / 2))
                .animation(overflow > 0 ? .easeInOut(duration: max(3, Double(overflow) / 18)).repeatForever(autoreverses: true) : .default, value: isAnimating)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: overflow > 0 ? .leading : .center)
                .clipped()
                .onAppear {
                    containerWidth = proxy.size.width
                    startIfNeeded()
                }
                .onChange(of: proxy.size.width) { newValue in
                    containerWidth = newValue
                    startIfNeeded()
                }
                .onChange(of: track.id) { _ in
                    isAnimating = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        startIfNeeded()
                    }
                }
        }
        .frame(height: 22)
    }

    private var trackTitle: Text {
        Text("\(track.artist) - ")
            .font(.subheadline)
            .foregroundColor(theme.palette.mutedText)
        + Text(track.title)
            .font(.subheadline.weight(.bold))
            .foregroundColor(theme.palette.text)
    }

    private func startIfNeeded() {
        guard textWidth > containerWidth else {
            isAnimating = false
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isAnimating = true
        }
    }
}
