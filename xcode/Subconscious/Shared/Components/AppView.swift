//
//  ContentView.swift
//  Shared
//
//  Created by Gordon Brander on 9/15/21.
//

import SwiftUI
import ObservableStore
import os
import Combine

/// Top-level view for app
struct AppView: View {
    /// Store for global application state
    @StateObject private var store = Store(
        state: AppModel(),
        environment: AppEnvironment.default
    )
    @Environment(\.scenePhase) var scenePhase: ScenePhase

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if Config.default.appTabs {
                    AppTabView(store: store)
                } else {
                    NotebookView(
                        store: ViewStore(
                            store: store,
                            cursor: NotebookCursor.self
                        )
                    )
                }
            }
            .zIndex(0)
            if store.state.sphereIdentity == nil {
                FirstRunView(
                    done: {}
                )
                .zIndex(1)
            }
        }
        // Track changes to scene phase so we know when app gets
        // foregrounded/backgrounded.
        // See https://developer.apple.com/documentation/swiftui/scenephase
        // 2022-02-08 Gordon Brander
        .onChange(of: self.scenePhase) { phase in
            store.send(AppAction.scenePhaseChange(phase))
        }
        .onAppear {
            store.send(.appear)
        }
    }
}

//  MARK: Action
enum AppAction: CustomLogStringConvertible {
    /// Wrapper for notebook actions
    case notebook(NotebookAction)
    /// Wrapper for feed actions
    case feed(FeedAction)

    ///  KeyboardService state change
    case changeKeyboardState(KeyboardState)

    /// Poll service
    case poll(Date)

    //  Lifecycle events
    /// When scene phase changes.
    /// E.g. when app is foregrounded, backgrounded, etc.
    case scenePhaseChange(ScenePhase)
    case appear

    //  Database
    /// Kick off database migration.
    /// This action is idempotent. It will only kick off a migration if a
    /// migration is necessary.
    ///
    /// We send this action when app is foregrounded.
    ///
    /// Technically it's a database rebuild right now. Since the source of
    /// truth is the file system, it's easier to just rebuild.
    case migrateDatabase
    case succeedMigrateDatabase(Int)
    /// Database is ready for use
    case rebuildDatabase
    case failRebuildDatabase(String)
    /// App ready for database calls and interaction
    case ready
    /// Sync database with file system
    case sync
    case syncSuccess([FileFingerprintChange])
    case syncFailure(String)
    case refreshAll

    //  Entry deletion
    /// Delete an entry
    case deleteEntry(Slug?)
    /// Confirm entry deleted
    case succeedDeleteEntry(Slug)
    /// Notify entry deletion failed
    case failDeleteEntry(String)

    // Rename and merge
    /// Move entry succeeded. Lifecycle action from Detail.
    case succeedMoveEntry(from: EntryLink, to: EntryLink)
    /// Merge entry succeeded. Lifecycle action from Detail.
    case succeedMergeEntry(parent: EntryLink, child: EntryLink)
    /// Retitle entry succeeded. Lifecycle action from Detail.
    case succeedRetitleEntry(from: EntryLink, to: EntryLink)

    var logDescription: String {
        switch self {
        case .notebook(let notebookAction):
            return "notebook(\(String.loggable(notebookAction)))"
        case .feed(let feedAction):
            return "feed(\(String.loggable(feedAction)))"
        case .poll(_):
            return "poll"
        case let .succeedMigrateDatabase(version):
            return "succeedMigrateDatabase(\(version))"
        default:
            return String(describing: self)
        }
    }
}

//  MARK: Cursors

/// Cursor functions for mapping notebook updates to app updates
struct NotebookCursor: CursorProtocol {
    /// Get notebook model from app model
    static func get(state: AppModel) -> NotebookModel {
        state.notebook
    }

    /// Set notebook on app model
    static func set(
        state: AppModel,
        inner notebook: NotebookModel
    ) -> AppModel {
        var model = state
        model.notebook = notebook
        return model
    }

    /// Tag notebook actions
    static func tag(_ action: NotebookAction) -> AppAction {
        switch action {
        case .requestDeleteEntry(let slug):
            return .deleteEntry(slug)
        case let .succeedMoveEntry(from, to):
            return .succeedMoveEntry(from: from, to: to)
        case let .succeedMergeEntry(parent, child):
            return .succeedMergeEntry(parent: parent, child: child)
        case let .succeedRetitleEntry(from, to):
            return .succeedRetitleEntry(from: from, to: to)
        default:
            return .notebook(action)
        }
    }
}

/// Cursor functions for mapping feed updates to app updates
struct FeedCursor: CursorProtocol {
    static func get(state: AppModel) -> FeedModel {
        state.feed
    }

    static func set(state: AppModel, inner feed: FeedModel) -> AppModel {
        var model = state
        model.feed = feed
        return model
    }

    /// Tag feed action
    static func tag(_ action: FeedAction) -> AppAction {
        switch action {
        case .requestDeleteEntry(let slug):
            return .deleteEntry(slug)
        case let .succeedMoveEntry(from, to):
            return .succeedMoveEntry(from: from, to: to)
        case let .succeedMergeEntry(parent, child):
            return .succeedMergeEntry(parent: parent, child: child)
        case let .succeedRetitleEntry(from, to):
            return .succeedRetitleEntry(from: from, to: to)
        default:
            return .feed(action)
        }
    }
}

enum AppDatabaseState {
    case initial
    case migrating
    case broken
    case ready
}

//  MARK: Model
struct AppModel: ModelProtocol {
    /// Is database connected and migrated?
    var databaseState = AppDatabaseState.initial
    var sphereIdentity: String?

    /// Feed of stories
    var feed = FeedModel()
    /// Your notebook containing all your notes
    var notebook = NotebookModel()

    /// Determine if the interface is ready for user interaction,
    /// even if all of the data isn't refreshed yet.
    /// This is the point at which the main interface is ready to be shown.
    var isReadyForInteraction: Bool {
        self.databaseState == .ready
    }

    //  MARK: Update
    /// Call through to main update function and log updates
    /// when `state.config.debug` is `true`.
    static func update(
        state: AppModel,
        action: AppAction,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        let message = String.loggable(action)
        Logger.action.debug("\(message)")
        // Generate next state and effect
        let next = updateApp(
            state: state,
            action: action,
            environment: environment
        )
        if Config.default.debug {
            Logger.state.debug("\(String(describing: next.state))")
        }
        return next
    }

    /// Main update function
    static func updateApp(
        state: AppModel,
        action: AppAction,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        switch action {
        case .notebook(let action):
            return NotebookCursor.update(
                state: state,
                action: action,
                environment: environment
            )
        case .feed(let action):
            return FeedCursor.update(
                state: state,
                action: action,
                environment: environment
            )
        case let .scenePhaseChange(phase):
            return scenePhaseChange(
                state: state,
                phase: phase,
                environment: environment
            )
        case .appear:
            return appear(state: state, environment: environment)
        case let .changeKeyboardState(keyboard):
            return changeKeyboardState(
                state: state,
                environment: environment,
                keyboard: keyboard
            )
        case .poll:
            return poll(
                state: state,
                environment: environment
            )
        case .migrateDatabase:
            return migrateDatabase(state: state, environment: environment)
        case let .succeedMigrateDatabase(version):
            return succeedMigrateDatabase(
                state: state,
                environment: environment,
                version: version
            )
        case .rebuildDatabase:
            return rebuildDatabase(
                state: state,
                environment: environment
            )
        case let .failRebuildDatabase(error):
            return failRebuildDatabase(
                state: state,
                environment: environment,
                error: error
            )
        case .ready:
            return ready(
                state: state,
                environment: environment
            )
        case .sync:
            return sync(
                state: state,
                environment: environment
            )
        case let .syncSuccess(changes):
            return syncSuccess(
                state: state,
                environment: environment,
                changes: changes
            )
        case let .syncFailure(message):
            environment.logger.warning(
                "File sync failed: \(message)"
            )
            return Update(state: state)
        case .refreshAll:
            return refreshAll(
                state: state,
                environment: environment
            )
        case .deleteEntry(let slug):
            return deleteEntry(
                state: state,
                environment: environment,
                slug: slug
            )
        case .succeedDeleteEntry(let slug):
            return succeedDeleteEntry(
                state: state,
                environment: environment,
                slug: slug
            )
        case .failDeleteEntry(let message):
            return log(
                state: state,
                environment: environment,
                message: message
            )
        case let .succeedMoveEntry(from, to):
            // Dispatch move actions from anywhere down to sub-components
            return update(
                state: state,
                actions: [
                    .feed(.succeedMoveEntry(from: from, to: to)),
                    .notebook(.succeedMoveEntry(from: from, to: to))
                ],
                environment: environment
            )
        case let .succeedMergeEntry(parent, child):
            // Dispatch merge actions from anywhere down to sub-components
            return update(
                state: state,
                actions: [
                    .feed(.succeedMergeEntry(parent: parent, child: child)),
                    .notebook(.succeedMergeEntry(parent: parent, child: child))
                ],
                environment: environment
            )
        case let .succeedRetitleEntry(from, to):
            // Dispatch retitle actions from anywhere down to sub-components
            return update(
                state: state,
                actions: [
                    .feed(.succeedRetitleEntry(from: from, to: to)),
                    .notebook(.succeedRetitleEntry(from: from, to: to))
                ],
                environment: environment
            )
        }
    }

    /// Log message and no-op
    static func log(
        state: AppModel,
        environment: AppEnvironment,
        message: String
    ) -> Update<AppModel> {
        environment.logger.log("\(message)")
        return Update(state: state)
    }

    /// Change state of keyboard
    /// Actions come from `KeyboardService`
    static func changeKeyboardState(
        state: AppModel,
        environment: AppEnvironment,
        keyboard: KeyboardState
    ) -> Update<AppModel> {
        switch keyboard {
        case .willShow(let size, _):
            return update(
                state: state,
                actions: [
                    .notebook(.setKeyboardHeight(size.height)),
                    .feed(.setKeyboardHeight(size.height))
                ],
                environment: environment
            )
        case .didHide:
            return update(
                state: state,
                actions: [
                    .notebook(.setKeyboardHeight(0)),
                    .feed(.setKeyboardHeight(0))
                ],
                environment: environment
            )
        default:
            return Update(state: state)
        }
    }

    /// Handle scene phase change
    static func scenePhaseChange(
        state: AppModel,
        phase: ScenePhase,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        switch phase {
        case .active:
            let fx: Fx<AppAction> = Just(
                AppAction.migrateDatabase
            )
            .eraseToAnyPublisher()
            return Update(state: state, fx: fx)
        default:
            return Update(state: state)
        }
    }

    static func appear(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        environment.logger.debug(
            "Documents: \(environment.documentURL)"
        )

        var model = state

        /// Get and set sphere identity
        let sphereIdentity = environment.noosphere.getSphereIdentity()
        model.sphereIdentity = sphereIdentity
        if let sphereIdentity = sphereIdentity {
            environment.logger.debug("Sphere Identity: \(sphereIdentity)")
        }

        let pollFx: Fx<AppAction> = AppEnvironment.poll(
            every: Config.default.pollingInterval
        )
        .map({ date in
            AppAction.poll(date)
        })
        .eraseToAnyPublisher()

        // Subscribe to keyboard events
        let fx: Fx<AppAction> = environment
            .keyboard.state
            .map({ value in
                AppAction.changeKeyboardState(value)
            })
            .merge(with: pollFx)
            .eraseToAnyPublisher()

        return Update(state: model, fx: fx)
    }

    static func poll(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        return AppModel.update(
            state: state,
            actions: [
                .feed(.autosave),
                .notebook(.autosave)
            ],
            environment: environment
        )
    }

    /// Make database ready.
    /// This will kick off a migration IF a successful migration
    /// has not already occurred.
    static func migrateDatabase(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        switch state.databaseState {
        case .initial:
            environment.logger.log("Readying database")
            let fx: Fx<AppAction> = environment.database
                .migrateAsync()
                .map({ version in
                    AppAction.succeedMigrateDatabase(version)
                })
                .catch({ _ in
                    Just(AppAction.rebuildDatabase)
                })
                .eraseToAnyPublisher()
            var model = state
            model.databaseState = .migrating
            return Update(state: model, fx: fx)
        case .migrating:
            environment.logger.log(
                "Database already migrating. Doing nothing."
            )
            return Update(state: state)
        case .broken:
            environment.logger.warning(
                "Database broken. Doing nothing."
            )
            return Update(state: state)
        case .ready:
            environment.logger.log("Database ready.")
            let fx: Fx<AppAction> = Just(AppAction.ready)
            .eraseToAnyPublisher()
            return Update(state: state, fx: fx)
        }
    }

    static func succeedMigrateDatabase(
        state: AppModel,
        environment: AppEnvironment,
        version: Int
    ) -> Update<AppModel> {
        environment.logger.log(
            "Database version: \(version)"
        )
        var model = state
        // Mark database state ready
        model.databaseState = .ready
        return update(state: model, action: .ready, environment: environment)
    }

    static func rebuildDatabase(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        environment.logger.warning(
            "Failed to migrate database. Retrying."
        )
        let fx: Fx<AppAction> = environment.database.migrateAsync()
            .map({ info in
                AppAction.succeedMigrateDatabase(info)
            })
            .catch({ error in
                Just(
                    AppAction.failRebuildDatabase(
                        error.localizedDescription
                    )
                )
            })
            .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }

    static func failRebuildDatabase(
        state: AppModel,
        environment: AppEnvironment,
        error: String
    ) -> Update<AppModel> {
        environment.logger.warning(
            "Could not rebuild database: \(error)"
        )
        var model = state
        model.databaseState = .broken
        return Update(state: model)
    }

    static func ready(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        return update(
            state: state,
            actions: [
                AppAction.sync,
                AppAction.notebook(.ready),
                AppAction.feed(.ready)
            ],
            environment: environment
        )
    }

    /// Start file sync
    static func sync(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        environment.logger.log("File sync started")
        let fx: Fx<AppAction> = environment.database
            .syncDatabase()
            .map({ changes in
                AppAction.syncSuccess(changes)
            })
            .catch({ error in
                Just(AppAction.syncFailure(error.localizedDescription))
            })
            .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }

    /// Handle successful sync
    static func syncSuccess(
        state: AppModel,
        environment: AppEnvironment,
        changes: [FileFingerprintChange]
    ) -> Update<AppModel> {
        environment.logger.debug(
            "File sync finished: \(changes)"
        )

        // Refresh lists after completing sync.
        // This ensures that files which were deleted outside the app
        // are removed from lists once sync is complete.
        return AppModel.update(
            state: state,
            action: .refreshAll,
            environment: environment
        )
    }

    /// Refresh all lists in the app.
    /// Typically done after a save or a delete to ensure old notes
    /// aren't showing up anymore.
    static func refreshAll(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        return AppModel.update(
            state: state,
            actions: [
                .feed(.refreshAll),
                .notebook(.refreshAll)
            ],
            environment: environment
        )
    }

    /// Entry delete succeeded
    static func deleteEntry(
        state: AppModel,
        environment: AppEnvironment,
        slug: Slug?
    ) -> Update<AppModel> {
        guard let slug = slug else {
            environment.logger.log(
                "Delete requested for nil slug. Doing nothing."
            )
            return Update(state: state)
        }
        let fx: Fx<AppAction> = environment.database
            .deleteEntryAsync(slug: slug)
            .map({ _ in
                AppAction.succeedDeleteEntry(slug)
            })
            .catch({ error in
                Just(
                    AppAction.failDeleteEntry(error.localizedDescription)
                )
            })
            .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }

    /// Entry delete succeeded
    static func succeedDeleteEntry(
        state: AppModel,
        environment: AppEnvironment,
        slug: Slug
    ) -> Update<AppModel> {
        environment.logger.log("Deleted entry: \(slug)")
        return AppModel.update(
            state: state,
            actions: [
                .feed(.entryDeleted(slug)),
                .notebook(.entryDeleted(slug))
            ],
            environment: environment
        )
    }
}

//  MARK: Environment
/// A place for constants and services
struct AppEnvironment {
    /// Default environment constant
    static let `default` = AppEnvironment()

    var documentURL: URL
    var applicationSupportURL: URL

    var logger: Logger
    /// Holds reference to Noosphere instance.
    /// Noosphere is meant to be a singleton, and we typically keep
    /// this instance around for the lifetime of the app.
    var noosphere: NoosphereService
    var keyboard: KeyboardService
    var database: DatabaseService
    var feed: FeedService

    /// Create a long polling publisher that never completes
    static func poll(every interval: Double) -> AnyPublisher<Date, Never> {
        Timer.publish(
            every: interval,
            on: .main,
            in: .default
        )
        .autoconnect()
        .eraseToAnyPublisher()
    }

    init() {
        self.documentURL = FileManager.default.urls(
            for: .documentDirectory,
               in: .userDomainMask
        ).first!

        self.applicationSupportURL = try! FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        self.logger = Logger.main

        let files = FileStore(documentURL: documentURL)
        let memos = HeaderSubtextMemoStore(store: files)

        let migrations = Config.migrations

        self.database = DatabaseService(
            documentURL: self.documentURL,
            databaseURL: self.applicationSupportURL
                .appendingPathComponent("database.sqlite"),
            memos: memos,
            migrations: migrations
        )

        self.noosphere = NoosphereService(
            globalStorageURL: applicationSupportURL
                .appending(path: Config.default.noosphere.globalStoragePath),
            sphereStorageURL: applicationSupportURL
                .appending(path: Config.default.noosphere.sphereStoragePath)
        )

        self.keyboard = KeyboardService()

        self.feed = FeedService()

        // MARK: zettelkasten geist
        do {
            let grammar = try Bundle.main.read(
                resource: Config.default.traceryZettelkasten,
                withExtension: "json"
            )
            let geist = try RandomPromptGeist(
                database: database,
                data: grammar
            )
            self.feed.register(name: "zettelkasten", geist: geist)
        } catch {
            logger.debug("Failed to load zettelkasten geist: \(error)")
        }
        
        // MARK: combo geist
        do {
            let grammar = try Bundle.main.read(
                resource: Config.default.traceryCombo,
                withExtension: "json"
            )
            let geist = try ComboGeist(
                database: database,
                data: grammar
            )
            
            self.feed.register(name: "combo", geist: geist)
        } catch {
            logger.debug("Failed to load combo geist: \(error)")
        }

        // MARK: Project Geist
        do {
            let grammar = try Bundle.main.read(
                resource: Config.default.traceryProject,
                withExtension: "json"
            )
            let geist = try QueryPromptGeist(
                database: database,
                data: grammar,
                query: "project"
            )
            self.feed.register(name: "project", geist: geist)
        } catch {
            logger.debug("Failed to load project Geist: \(error)")
        }
        
        // MARK: Memento Geist
        let mementoGeist = MementoGeist(database: database)
        self.feed.register(name: "memento", geist: mementoGeist)
    }
}

