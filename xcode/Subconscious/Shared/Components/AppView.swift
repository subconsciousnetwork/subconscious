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
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if Config.default.appTabs {
                    AppTabView(store: store)
                } else {
                    NotebookView(app: store)
                }
            }
            .zIndex(0)
            if (!store.state.isFirstRunComplete) {
                FirstRunView(
                    onDone: { sphereIdentity in
                        store.send(
                            .firstRunComplete(sphereIdentity: sphereIdentity)
                        )
                    }
                )
                .animation(.default, value: store.state.isFirstRunComplete)
                .zIndex(1)
            }
        }
        .onAppear {
            store.send(.appear)
        }
        .onReceive(store.actions) { action in
            let message = String.loggable(action)
            AppModel.logger.debug("[action] \(message)")
        }
    }
}

//  MARK: Action
enum AppAction: CustomLogStringConvertible {
    /// On view appear
    case appear

    /// Set identity of sphere
    case setSphereIdentity(String?)
    
    /// Set and persist first run complete state
    case persistFirstRunComplete(_ isComplete: Bool)

    /// Sent when first run is done
    case firstRunComplete(sphereIdentity: String)

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

    /// Sync local sphere with gateway sphere
    case syncSphereWithGateway
    case succeedSyncSphereWithGateway(version: String)
    case failSyncSphereWithGateway(String)

    /// Sync current sphere state with database state
    /// Sphere always wins.
    case syncSphereWithDatabase
    case succeedSyncSphereWithDatabase(version: String)
    case failSyncSphereWithDatabase(String)
    
    /// Sync database with file system.
    /// File system always wins.
    case syncLocalFilesWithDatabase
    case succeedSyncLocalFilesWithDatabase([FileFingerprintChange])
    case failSyncLocalFilesWithDatabase(String)

    var logDescription: String {
        switch self {
        case let .succeedMigrateDatabase(version):
            return "succeedMigrateDatabase(\(version))"
        default:
            return String(describing: self)
        }
    }
}

//  MARK: Cursors

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
    var isFirstRunComplete = false
    var sphereIdentity: String?

    /// Determine if the interface is ready for user interaction,
    /// even if all of the data isn't refreshed yet.
    /// This is the point at which the main interface is ready to be shown.
    var isReadyForInteraction: Bool {
        self.databaseState == .ready
    }

    // Logger for actions
    static let logger = Logger(
        subsystem: Config.default.rdns,
        category: "app"
    )

    //  MARK: Update
    /// Main update function
    static func update(
        state: AppModel,
        action: AppAction,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        switch action {
        case .appear:
            return appear(state: state, environment: environment)
        case let .setSphereIdentity(sphereIdentity):
            return setSphereIdentity(
                state: state,
                environment: environment,
                sphereIdentity: sphereIdentity
            )
        case let .persistFirstRunComplete(isComplete):
            return persistFirstRunComplete(
                state: state,
                environment: environment,
                isComplete: isComplete
            )
        case let .firstRunComplete(sphereIdentity):
            return firstRunComplete(
                state: state,
                environment: environment,
                sphereIdentity: sphereIdentity
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
        case .syncSphereWithGateway:
            return syncSphereWithGateway(
                state: state,
                environment: environment
            )
        case let .succeedSyncSphereWithGateway(version):
            return succeedSyncSphereWithGateway(
                state: state,
                environment: environment,
                version: version
            )
        case let .failSyncSphereWithGateway(error):
            return failSyncSphereWithGateway(
                state: state,
                environment: environment,
                error: error
            )
        case .syncSphereWithDatabase:
            return syncSphereWithDatabase(
                state: state,
                environment: environment
            )
        case let .succeedSyncSphereWithDatabase(version):
            return succeedSyncSphereWithDatabase(
                state: state,
                environment: environment,
                version: version
            )
        case let .failSyncSphereWithDatabase(error):
            return failSyncSphereWithDatabase(
                state: state,
                environment: environment,
                error: error
            )
        case .syncLocalFilesWithDatabase:
            return syncLocalFilesWithDatabase(
                state: state,
                environment: environment
            )
        case let .succeedSyncLocalFilesWithDatabase(changes):
            return succeedSyncLocalFilesWithDatabase(
                state: state,
                environment: environment,
                changes: changes
            )
        case let .failSyncLocalFilesWithDatabase(message):
            logger.log("File sync failed: \(message)")
            return Update(state: state)
        }
    }

    /// Log message and no-op
    static func log(
        state: AppModel,
        environment: AppEnvironment,
        message: String
    ) -> Update<AppModel> {
        logger.log("\(message)")
        return Update(state: state)
    }

    static func appear(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        logger.debug(
            "Documents: \(environment.documentURL)"
        )

        let migrate = Just(
            AppAction.migrateDatabase
        )

        let identity = try? environment.data.sphereIdentity()
        /// Get sphere identity, if any
        let setSphereIdentity = Just(
            AppAction.setSphereIdentity(identity)
        )

        let fx: Fx<AppAction> = setSphereIdentity.merge(with: migrate)
            .eraseToAnyPublisher()

        var model = state
        // Set first run complete from persisted state.
        model.isFirstRunComplete = environment.data.isFirstRunComplete()

        return Update(state: model, fx: fx)
    }

    static func setSphereIdentity(
        state: AppModel,
        environment: AppEnvironment,
        sphereIdentity: String?
    ) -> Update<AppModel> {
        var model = state
        model.sphereIdentity = sphereIdentity
        if let sphereIdentity = sphereIdentity {
            logger.debug("Sphere: \(sphereIdentity)")
        }
        return Update(state: model)
    }

    /// Persist first run complete state
    static func persistFirstRunComplete(
        state: AppModel,
        environment: AppEnvironment,
        isComplete: Bool
    ) -> Update<AppModel> {
        // Persist value
        environment.data.persistFirstRunComplete(isComplete)
        // Update state
        var model = state
        model.isFirstRunComplete = isComplete
        return Update(state: model)
    }

    /// Wrap up first run flow
    static func firstRunComplete(
        state: AppModel,
        environment: AppEnvironment,
        sphereIdentity: String
    ) -> Update<AppModel> {
        return update(
            state: state,
            actions: [
                .persistFirstRunComplete(true),
                .setSphereIdentity(sphereIdentity)
            ],
            environment: environment
        )
        .animation(.default)
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
            logger.log("Readying database")
            let fx: Fx<AppAction> = environment.data
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
            logger.log(
                "Database already migrating. Doing nothing."
            )
            return Update(state: state)
        case .broken:
            logger.warning(
                "Database broken. Doing nothing."
            )
            return Update(state: state)
        case .ready:
            logger.log("Database ready.")
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
        logger.log(
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
        logger.warning(
            "No valid migrations for database. Rebuilding."
        )
        let fx: Fx<AppAction> = environment.data.rebuildAsync()
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
        logger.warning(
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
                AppAction.syncLocalFilesWithDatabase,
                AppAction.syncSphereWithGateway
            ],
            environment: environment
        )
    }

    static func syncSphereWithGateway(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        guard let gatewayURL = environment.data.noosphere.gatewayURL else {
            logger.log("No gateway configured. Skipping sync.")
            return Update(state: state)
        }
        logger.log("Syncing with gateway: \(gatewayURL.absoluteString)")
        let fx: Fx<AppAction> = environment.data.syncSphereWithGateway()
            .map({ version in
                AppAction.succeedSyncSphereWithGateway(version: version)
            })
            .catch({ error in
                Just(AppAction.failSyncSphereWithGateway(error.localizedDescription))
            })
            .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }

    static func succeedSyncSphereWithGateway(
        state: AppModel,
        environment: AppEnvironment,
        version: String
    ) -> Update<AppModel> {
        logger.log("Sphere updated to version: \(version)")
        return update(
            state: state,
            action: .syncSphereWithDatabase,
            environment: environment
        )
    }
    
    static func failSyncSphereWithGateway(
        state: AppModel,
        environment: AppEnvironment,
        error: String
    ) -> Update<AppModel> {
        logger.log("Sphere sync failed: \(error)")
        return Update(state: state)
    }

    static func syncSphereWithDatabase(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        let fx: Fx<AppAction> = environment.data.syncSphereWithDatabaseAsync()
            .map({ version in
                AppAction.succeedSyncSphereWithDatabase(version: version)
            })
            .catch({ error in
                Just(
                    AppAction.failSyncSphereWithDatabase(error.localizedDescription)
                )
            })
            .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }

    static func succeedSyncSphereWithDatabase(
        state: AppModel,
        environment: AppEnvironment,
        version: String
    ) -> Update<AppModel> {
        let identity = state.sphereIdentity ?? "unknown"
        logger.log("Database synced to sphere \(identity) @ \(version)")
        return Update(state: state)
    }
    
    static func failSyncSphereWithDatabase(
        state: AppModel,
        environment: AppEnvironment,
        error: String
    ) -> Update<AppModel> {
        logger.log("Database failed to sync with sphere: \(error)")
        return Update(state: state)
    }

    /// Start file sync
    static func syncLocalFilesWithDatabase(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        logger.log("File sync started")
        let fx: Fx<AppAction> = environment.data
            .syncLocalFilesWithDatabase()
            .map({ changes in
                AppAction.succeedSyncLocalFilesWithDatabase(changes)
            })
            .catch({ error in
                Just(AppAction.failSyncLocalFilesWithDatabase(error.localizedDescription))
            })
            .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }

    /// Handle successful sync
    static func succeedSyncLocalFilesWithDatabase(
        state: AppModel,
        environment: AppEnvironment,
        changes: [FileFingerprintChange]
    ) -> Update<AppModel> {
        logger.debug(
            "File sync finished: \(changes)"
        )
        return Update(state: state)
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
    var data: DataService
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

        let noosphere = NoosphereService(
            globalStorageURL: applicationSupportURL
                .appending(path: Config.default.noosphere.globalStoragePath),
            sphereStorageURL: applicationSupportURL
                .appending(path: Config.default.noosphere.sphereStoragePath),
            gatewayURL: URL(string: Config.default.noosphere.defaultGatewayURL)
        )

        let databaseURL = self.applicationSupportURL
            .appendingPathComponent("database.sqlite")

        let databaseService = DatabaseService(
            database: SQLite3Database(
                path: databaseURL.absoluteString,
                mode: .readwrite
            ),
            migrations: Config.migrations
        )
        
        let defaults = AppDefaultsService()

        self.data = DataService(
            documentURL: self.documentURL,
            databaseURL: databaseURL,
            noosphere: noosphere,
            database: databaseService,
            memos: memos,
            defaults: defaults
        )

        self.feed = FeedService()
    }
}

