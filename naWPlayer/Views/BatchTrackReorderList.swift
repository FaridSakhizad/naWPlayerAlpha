import SwiftUI
import UIKit

struct BatchTrackReorderList: UIViewRepresentable {
    let tracks: [AudioTrack]
    let markedTrackIDs: Set<AudioTrack.ID>
    let currentTrackID: AudioTrack.ID?
    let isPlaying: Bool
    let theme: PlayerTheme
    let onToggleMarkedTrack: (AudioTrack) -> Void
    let onMoveTracks: ([AudioTrack.ID], Int) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UICollectionView {
        var configuration = UICollectionLayoutListConfiguration(appearance: .plain)
        configuration.showsSeparators = true
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: UICollectionViewCompositionalLayout.list(using: configuration)
        )
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.dragInteractionEnabled = true
        collectionView.dataSource = context.coordinator
        collectionView.dragDelegate = context.coordinator
        collectionView.dropDelegate = context.coordinator
        collectionView.register(UICollectionViewListCell.self, forCellWithReuseIdentifier: Coordinator.cellReuseIdentifier)
        context.coordinator.collectionView = collectionView
        return collectionView
    }

    func updateUIView(_ collectionView: UICollectionView, context: Context) {
        let coordinator = context.coordinator
        let tracksChanged = coordinator.displayedTracks != tracks
        let presentationChanged = coordinator.markedTrackIDs != markedTrackIDs
            || coordinator.currentTrackID != currentTrackID
            || coordinator.isPlaying != isPlaying
            || coordinator.theme != theme

        coordinator.parent = self
        guard !coordinator.isDragging else { return }

        if tracksChanged {
            coordinator.displayedTracks = tracks
        }
        if tracksChanged || presentationChanged {
            coordinator.markedTrackIDs = markedTrackIDs
            coordinator.currentTrackID = currentTrackID
            coordinator.isPlaying = isPlaying
            coordinator.theme = theme
            collectionView.reloadData()
        }
    }

    final class Coordinator: NSObject, UICollectionViewDataSource, UICollectionViewDragDelegate, UICollectionViewDropDelegate {
        static let cellReuseIdentifier = "BatchTrackCell"

        var parent: BatchTrackReorderList
        weak var collectionView: UICollectionView?
        var isDragging = false
        var displayedTracks: [AudioTrack]
        var markedTrackIDs: Set<AudioTrack.ID>
        var currentTrackID: AudioTrack.ID?
        var isPlaying: Bool
        var theme: PlayerTheme
        private var draggedTrackIDs: [AudioTrack.ID] = []

        init(parent: BatchTrackReorderList) {
            self.parent = parent
            displayedTracks = parent.tracks
            markedTrackIDs = parent.markedTrackIDs
            currentTrackID = parent.currentTrackID
            isPlaying = parent.isPlaying
            theme = parent.theme
        }

        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            displayedTracks.count
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            guard
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: Self.cellReuseIdentifier,
                    for: indexPath
                ) as? UICollectionViewListCell,
                displayedTracks.indices.contains(indexPath.item)
            else {
                return UICollectionViewCell()
            }

            let track = displayedTracks[indexPath.item]
            let isCurrent = track.id == parent.currentTrackID
            let isMarked = parent.markedTrackIDs.contains(track.id)
            let rowBackground = isCurrent
                ? parent.theme.palette.panel
                : (isMarked ? parent.theme.palette.accent.opacity(0.16) : Color.clear)

            cell.contentConfiguration = UIHostingConfiguration {
                LibraryTrackRow(
                    track: track,
                    isCurrent: isCurrent,
                    isPlaying: parent.isPlaying,
                    isSelected: false,
                    isEditing: true,
                    isMarkedForDeletion: isMarked,
                    onDetails: {},
                    onPlay: {},
                    onDelete: {},
                    onToggleMarkedForDeletion: { [weak self] in
                        self?.parent.onToggleMarkedTrack(track)
                    }
                )
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(rowBackground)
                .environment(\.playerTheme, parent.theme)
            }
            .margins(.all, 0)

            return cell
        }

        func collectionView(
            _ collectionView: UICollectionView,
            itemsForBeginning session: UIDragSession,
            at indexPath: IndexPath
        ) -> [UIDragItem] {
            guard displayedTracks.indices.contains(indexPath.item) else { return [] }

            let touchedTrack = displayedTracks[indexPath.item]
            draggedTrackIDs = parent.markedTrackIDs.contains(touchedTrack.id)
                ? displayedTracks.filter { parent.markedTrackIDs.contains($0.id) }.map(\.id)
                : [touchedTrack.id]

            return draggedTrackIDs.map { trackID in
                let item = UIDragItem(itemProvider: NSItemProvider(object: trackID.uuidString as NSString))
                item.localObject = trackID
                return item
            }
        }

        func collectionView(
            _ collectionView: UICollectionView,
            dragSessionWillBegin session: UIDragSession
        ) {
            isDragging = true
        }

        func collectionView(
            _ collectionView: UICollectionView,
            dragSessionDidEnd session: UIDragSession
        ) {
            isDragging = false
        }

        func collectionView(
            _ collectionView: UICollectionView,
            dragSessionAllowsMoveOperation session: UIDragSession
        ) -> Bool {
            true
        }

        func collectionView(
            _ collectionView: UICollectionView,
            canHandle session: UIDropSession
        ) -> Bool {
            session.localDragSession != nil
        }

        func collectionView(
            _ collectionView: UICollectionView,
            dropSessionDidUpdate session: UIDropSession,
            withDestinationIndexPath destinationIndexPath: IndexPath?
        ) -> UICollectionViewDropProposal {
            guard session.localDragSession != nil else {
                return UICollectionViewDropProposal(operation: .forbidden)
            }
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }

        func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
            guard coordinator.session.localDragSession != nil else { return }

            // `dragSessionDidEnd` may precede this callback on some iOS versions,
            // so derive IDs from the coordinator instead of relying solely on state.
            let droppedTrackIDs = coordinator.items.compactMap { item in
                item.dragItem.localObject as? AudioTrack.ID
            }
            let trackIDs = droppedTrackIDs.isEmpty ? draggedTrackIDs : droppedTrackIDs
            guard !trackIDs.isEmpty else { return }

            let destination = coordinator.destinationIndexPath?.item ?? displayedTracks.count
            let reorderedTracks = reorderedTracks(moving: trackIDs, to: destination)
            guard reorderedTracks != displayedTracks else { return }

            isDragging = false
            let insertionIndex = insertionIndex(moving: trackIDs, to: destination)
            let sourceIndexPaths = displayedTracks.indices
                .filter { trackIDs.contains(displayedTracks[$0].id) }
                .map { IndexPath(item: $0, section: 0) }
                .sorted { $0.item > $1.item }
            let destinationIndexPaths = trackIDs.indices.map {
                IndexPath(item: insertionIndex + $0, section: 0)
            }

            // Keep UIKit's cells and data source in lockstep. Otherwise it treats
            // the drop as cancelled and restores the rows at their old positions.
            collectionView.performBatchUpdates {
                displayedTracks = reorderedTracks
                collectionView.deleteItems(at: sourceIndexPaths)
                collectionView.insertItems(at: destinationIndexPaths)

                for (item, destinationIndexPath) in zip(coordinator.items, destinationIndexPaths) {
                    coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
                }
            }

            parent.onMoveTracks(trackIDs, destination)
            draggedTrackIDs.removeAll()
        }

        private func reorderedTracks(moving trackIDs: [AudioTrack.ID], to destination: Int) -> [AudioTrack] {
            let movedIDs = Set(trackIDs)
            let movedTracks = displayedTracks.filter { movedIDs.contains($0.id) }
            let remainingTracks = displayedTracks.filter { !movedIDs.contains($0.id) }
            let index = insertionIndex(moving: trackIDs, to: destination)

            var result = remainingTracks
            result.insert(contentsOf: movedTracks, at: index)
            return result
        }

        private func insertionIndex(moving trackIDs: [AudioTrack.ID], to destination: Int) -> Int {
            let movedIDs = Set(trackIDs)
            let clampedDestination = min(max(destination, 0), displayedTracks.count)
            let movedBeforeDestination = displayedTracks
                .prefix(clampedDestination)
                .filter { movedIDs.contains($0.id) }
                .count
            let remainingCount = displayedTracks.count - movedIDs.count
            return min(max(clampedDestination - movedBeforeDestination, 0), remainingCount)
        }
    }
}
