//
//  BlockEditorViewController.swift
//  BlockEditor
//
//  Created by Gordon Brander on 7/17/23.
//

import UIKit
import Combine
import os
import ObservableStore

extension BlockEditor {
    /// Represents the sections in the collection view.
    enum Section: Int, CaseIterable {
        case blocks = 0
        case appendix = 1
    }
}

extension BlockEditor {
    /// Manages the "DOM" of the editor.
    class ViewController:
        UIViewController,
        UICollectionViewDelegateFlowLayout,
        UICollectionViewDataSource
    {
        static var logger = Logger(
            subsystem: Config.default.rdns,
            category: "BlockEditorViewController"
        )
        
        /// Gesture used to toggle into block selection mode
        private lazy var longPressGesture = UILongPressGestureRecognizer(
            target: self,
            action: #selector(onLongPress)
        )

        /// Gesture used to select blocks in selection mode
        private lazy var tapGesture = UILongPressGestureRecognizer(
            target: self,
            action: #selector(onTap)
        )

        private lazy var collectionView = createCollectionView()
        
        let store: Store<Model>

        /// Cancellable for store change publisher.
        /// Subscribed in `viewDidLoad`.
        private var cancelStoreChanges: AnyCancellable?
        
        init(store: Store<Model>) {
            Self.logger.log("init")
            self.store = store
            super.init(nibName: nil, bundle: nil)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            longPressGesture.delegate = self
            view.addGestureRecognizer(longPressGesture)

            tapGesture.delegate = self
            view.addGestureRecognizer(tapGesture)

            setupViews()
            activateConstraints()
            startUpdates()
        }
        
        /// Perform initial update and subscribe to future changes
        /// to perform updates.
        private func startUpdates() {
            // Perform initial render
            self.collectionView.reloadData()

            // Subscribe to store changes and perform them.
            self.cancelStoreChanges = store.updates
                .compactMap(\.change)
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { [weak self] change in
                    self?.update(change)
                })

            self.store.send(.ready)
        }

        /// Create a configured collection view suitable for our block editor
        private func createCollectionView() -> UICollectionView {
            var config = UICollectionLayoutListConfiguration(
                appearance: .plain
            )
            config.showsSeparators = false
            let layout = UICollectionViewCompositionalLayout.list(
                using: config
            )
            
            let collectionView = UICollectionView(
                frame: .zero,
                collectionViewLayout: layout
            )
            collectionView.contentInset = UIEdgeInsets(
                top: AppTheme.unit2,
                left: 0,
                bottom: AppTheme.unit2,
                right: 0
            )

            collectionView.register(
                ErrorCell.self,
                forCellWithReuseIdentifier: ErrorCell.identifier
            )
            collectionView.register(
                TextBlockCell.self,
                forCellWithReuseIdentifier: TextBlockCell.identifier
            )
            collectionView.register(
                HeadingBlockCell.self,
                forCellWithReuseIdentifier: HeadingBlockCell.identifier
            )
            collectionView.register(
                QuoteBlockCell.self,
                forCellWithReuseIdentifier: QuoteBlockCell.identifier
            )
            collectionView.register(
                ListBlockCell.self,
                forCellWithReuseIdentifier: ListBlockCell.identifier
            )
            collectionView.register(
                RelatedCell.self,
                forCellWithReuseIdentifier: RelatedCell.identifier
            )

            collectionView.autoresizingMask = [.flexibleHeight]
            collectionView.delegate = self
            collectionView.dataSource = self

            return collectionView
        }
        
        private func setupViews() {
            view.addSubview(collectionView)
        }

        private func activateConstraints() {
            let guide = view.safeAreaLayoutGuide
            collectionView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                collectionView.leadingAnchor.constraint(
                    equalTo: guide.leadingAnchor
                ),
                collectionView.trailingAnchor.constraint(
                    equalTo: guide.trailingAnchor
                ),
                collectionView.topAnchor.constraint(
                    equalTo: guide.topAnchor
                ),
                collectionView.bottomAnchor.constraint(
                    equalTo: guide.bottomAnchor
                ),
            ])
        }

        @objc private func onLongPress(_ gesture: UIGestureRecognizer) {
            switch gesture.state {
            case .ended:
                let point = gesture.location(in: self.collectionView)
                store.send(.longPress(point))
            default:
                break
            }
        }

        @objc private func onTap(_ gesture: UIGestureRecognizer) {
            switch gesture.state {
            case .ended:
                let point = gesture.location(in: self.collectionView)
                store.send(.tap(point))
            default:
                break
            }
        }

        private func send(_ action: TextBlockAction) {
            self.store.send(.from(action))
        }

        /// Process a change message and perform related actions on controller.
        private func update(_ change: BlockEditor.Change) {
            Self.logger.log("Change: \(String(describing: change))")
            switch change {
            case .reloadEditor:
                return reloadEditor()
            case let .reconfigureCollectionItems(indexPaths):
                return reconfigureCollectionItems(indexPaths)
            case let .moveBlock(at, to):
                return moveBlock(at: at, to: to)
            case let .splitBlock(reconfigure, insert, requestEditing):
                return splitBlock(
                    reconfigure: reconfigure,
                    insert: insert,
                    requestEditing: requestEditing
                )
            case let .mergeBlockUp(reconfigure, delete, requestEditing):
                return mergeBlockUp(
                    reconfigure: reconfigure,
                    delete: delete,
                    requestEditing: requestEditing
                )
            }
        }

        private func reloadEditor() {
            UIView.performWithoutAnimation {
                collectionView.reloadData()
            }
        }

        private func reconfigureCollectionItems(
            _ indexPaths: [IndexPath]
        ) {
            UIView.performWithoutAnimation {
                self.collectionView.reconfigureItems(at: indexPaths)
            }
        }

        private func moveBlock(
            at atIndexPath: IndexPath,
            to toIndexPath: IndexPath
        ) {
            collectionView.moveItem(
                at: atIndexPath,
                to: toIndexPath
            )
        }

        private func splitBlock(
            reconfigure: IndexPath,
            insert: IndexPath,
            requestEditing id: BlockModel.ID
        ) {
            UIView.performWithoutAnimation {
                self.collectionView.performBatchUpdates(
                    {
                        self.collectionView.reconfigureItems(
                            at: [reconfigure]
                        )
                        self.collectionView.insertItems(
                            at: [insert]
                        )
                    },
                    completion: { isComplete in
                        self.store.send(.renderEditing(id: id))
                    }
                )
            }
        }

        private func mergeBlockUp(
            reconfigure: IndexPath,
            delete: IndexPath,
            requestEditing id: BlockModel.ID
        ) {
            UIView.performWithoutAnimation {
                self.collectionView.performBatchUpdates(
                    {
                        self.collectionView.reconfigureItems(
                            at: [reconfigure]
                        )
                        self.collectionView.deleteItems(
                            at: [delete]
                        )
                    },
                    completion: { isComplete in
                        self.store.send(.renderEditing(id: id))
                    }
                )
            }
        }

        /// Return 2 sections
        /// - 1 blocks
        /// - 2 "footer" containing related notes
        func numberOfSections(in collectionView: UICollectionView) -> Int {
            Section.allCases.count
        }

        /// Provides a count for data in a particular section
        func collectionView(
            _ collectionView: UICollectionView,
            numberOfItemsInSection section: Int
        ) -> Int {
            switch Section(rawValue: section) {
            case .blocks:
                return store.state.blocks.blocks.count
            case .appendix:
                return 1
            default:
                return 0
            }
        }
        
        /// Provides a UICollectionViewCell for an index path.
        /// This method is responsible for looking up data from a data source
        /// (state in our case) using the index path.
        func collectionView(
            _ collectionView: UICollectionView,
            cellForItemAt indexPath: IndexPath
        ) -> UICollectionViewCell {
            switch Section(rawValue: indexPath.section) {
            case .blocks:
                return blockCell(collectionView, forItemAt: indexPath)
            case .appendix:
                return appendixCell(collectionView, forItemAt: indexPath)
            default:
                return errorCell(collectionView, forItemAt: indexPath)
            }
        }
        
        /// Error cells are dequeued when we don't know what else to display.
        ///
        /// Error cells should never be displayed in practice, but we must
        /// have something to dequeue since `collectionView(_:cellForItemAt:)`
        /// requires a cell to be returned for every case.
        private func errorCell(
            _ collectionView: UICollectionView,
            forItemAt indexPath: IndexPath
        ) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ErrorCell.identifier,
                for: indexPath
            ) as! ErrorCell
            return cell
        }
        
        private func blockCell(
            _ collectionView: UICollectionView,
            forItemAt indexPath: IndexPath
        ) -> UICollectionViewCell {
            let block = store.state.blocks.blocks[indexPath.row]
            switch block {
            case let .heading(state):
                return headingCell(
                    collectionView,
                    forItemAt: indexPath,
                    state: state
                )
            case let .text(state):
                return textCell(
                    collectionView,
                    forItemAt: indexPath,
                    state: state
                )
            case let .quote(state):
                return quoteCell(
                    collectionView,
                    forItemAt: indexPath,
                    state: state
                )
            case let .list(state):
                return listCell(
                    collectionView,
                    forItemAt: indexPath,
                    state: state
                )
            }
        }

        private func textCell(
            _ collectionView: UICollectionView,
            forItemAt indexPath: IndexPath,
            state: TextBlockModel
        ) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: TextBlockCell.identifier,
                for: indexPath
            ) as! TextBlockCell
            cell.send = { [weak self] action in
                self?.send(action)
            }
            cell.update(parentController: self, state: state)
            return cell
        }
        
        private func headingCell(
            _ collectionView: UICollectionView,
            forItemAt indexPath: IndexPath,
            state: TextBlockModel
        ) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: HeadingBlockCell.identifier,
                for: indexPath
            ) as! HeadingBlockCell
            cell.send = { [weak self] action in
                self?.send(action)
            }
            cell.update(state)
            return cell
        }
        
        private func quoteCell(
            _ collectionView: UICollectionView,
            forItemAt indexPath: IndexPath,
            state: TextBlockModel
        ) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: QuoteBlockCell.identifier,
                for: indexPath
            ) as! QuoteBlockCell
            cell.send = { [weak self] action in
                self?.send(action)
            }
            cell.update(parentController: self, state: state)
            return cell
        }
        
        private func listCell(
            _ collectionView: UICollectionView,
            forItemAt indexPath: IndexPath,
            state: TextBlockModel
        ) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ListBlockCell.identifier,
                for: indexPath
            ) as! ListBlockCell
            cell.send = { [weak self] action in
                self?.send(action)
            }
            cell.update(parentController: self, state: state)
            return cell
        }

        private func appendixCell(
            _ collectionView: UICollectionView,
            forItemAt indexPath: IndexPath
        ) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: RelatedCell.identifier,
                for: indexPath
            ) as! RelatedCell
            let state = store.state.appendix
            cell.update(parentController: self, state: state)
            return cell
        }
    }
}

extension BlockEditor.Action {
    static func from(_ action: BlockEditor.TextBlockAction) -> Self {
        switch action {
        case .inlineFormatting(let blockInlineFormattingAction):
            switch blockInlineFormattingAction {
            case let .boldButtonPressed(id, _, selection):
                return .insertBold(id: id, selection: selection)
            case let .italicButtonPressed(id, _, selection):
                return .insertItalic(id: id, selection: selection)
            case let .codeButtonPressed(id, _, selection):
                return .insertCode(id: id, selection: selection)
            }
        case .textEditing(let blockTextEditingAction):
            switch blockTextEditingAction {
            case let .requestMergeUp(id):
                return .mergeBlockUp(id: id)
            case let .requestSplit(id, selection, _):
                return .splitBlock(id: id, selection: selection)
            case let .didChange(id, dom, selection):
                return .textDidChange(id: id, dom: dom, selection: selection)
            case let .didChangeSelection(id, selection):
                return .didChangeSelection(id: id, selection: selection)
            case let .didBeginEditing(id):
                return .editing(id: id)
            case let .didEndEditing(id):
                return .blur(id: id)
            }
        case .controls(let blockControlsAction):
            switch blockControlsAction {
            case let .upButtonPressed(id):
                return .moveBlockUp(id: id)
            case let .downButtonPressed(id):
                return .moveBlockDown(id: id)
            case let .dismissKeyboardButtonPressed(id):
                return .renderBlur(id: id)
            }
        case .onLink(let url):
            return .activateLink(url)
        case .transcludeList(let transcludeListAction):
            switch transcludeListAction {
            case let .onLink(resolvedAddress, subSlashlinkLink):
                return .requestFindLinkDetail(resolvedAddress, subSlashlinkLink)
            case let .onView(entryStub):
                return .requestDetail(entryStub)
            }
        }
    }
}

// MARK: UIGestureRecognizerDelegate
extension BlockEditor.ViewController: UIGestureRecognizerDelegate {
    /// Recognize long-press gesture simultaneously with other gestures.
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }
}
