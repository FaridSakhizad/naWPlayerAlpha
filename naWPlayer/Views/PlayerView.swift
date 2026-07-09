import SwiftUI

struct PlayerView: View {
    @Environment(\.playerTheme) private var theme

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VolumeSliderView()
                    .playerPanel()

                PlayerNowPlayingSection()

                PlayerSeekSection()

                PlayerTransportControls()

                PlayerQueueSection()
            }
            .padding()
        }
        .navigationTitle("Player")
        .navigationBarTitleDisplayMode(.inline)
        .background(theme.palette.background.ignoresSafeArea())
    }
}
