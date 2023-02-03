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
            if (
                Config.default.noosphere.enabled &&
                store.state.sphereIdentity == nil
            ) {
                FirstRunView(
                    onDone: { sphereIdentity in
                        store.send(.setSphereIdentity(sphereIdentity))
                    }
                )
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
    /// Set identity of sphere
    case setSphereIdentity(String?)

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

    /// Sync local sphere with gateway sphere
    case syncSphere
    case succeedSyncSphere(version: String)
    case failSyncSphere(String)

    /// Sync database with file system
    case sync
    case syncSuccess([FileFingerprintChange])
    case syncFailure(String)

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
        case let .setSphereIdentity(sphereIdentity):
            return setSphereIdentity(
                state: state,
                environment: environment,
                sphereIdentity: sphereIdentity
            )
        case .appear:
            return appear(state: state, environment: environment)
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
        case .syncSphere:
            return syncSphere(
                state: state,
                environment: environment
            )
        case let .succeedSyncSphere(version):
            return succeedSyncSphere(
                state: state,
                environment: environment,
                version: version
            )
        case let .failSyncSphere(error):
            return failSyncSphere(
                state: state,
                environment: environment,
                error: error
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
            logger.warning(
                "File sync failed: \(message)"
            )
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

    static func setSphereIdentity(
        state: AppModel,
        environment: AppEnvironment,
        sphereIdentity: String?
    ) -> Update<AppModel> {
        var model = state
        model.sphereIdentity = sphereIdentity
        if let sphereIdentity = sphereIdentity {
            logger.debug("Sphere identity: \(sphereIdentity)")
        }
        return Update(state: model)
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

        /// Get sphere identity, if any
        let setSphereIdentity = Just(
            AppAction.setSphereIdentity(
                environment.data.noosphere.sphereIdentity()
            )
        )

        let fx: Fx<AppAction> = setSphereIdentity.merge(with: migrate)
            .eraseToAnyPublisher()

        return Update(state: state, fx: fx)
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
            action: AppAction.sync,
            environment: environment
        )
    }

    static func syncSphere(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        guard let gatewayURL = environment.data.noosphere.gatewayURL else {
            logger.log("No gateway configured. Skipping sync.")
            return Update(state: state)
        }
        logger.log("Syncing with gateway: \(gatewayURL.absoluteString)")
        let fx: Fx<AppAction> = environment.data.syncSphere()
            .map({ version in
                AppAction.succeedSyncSphere(version: version)
            })
            .catch({ error in
                Just(AppAction.failSyncSphere(error.localizedDescription))
            })
            .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }

    static func succeedSyncSphere(
        state: AppModel,
        environment: AppEnvironment,
        version: String
    ) -> Update<AppModel> {
        logger.log("Sphere updated to version: \(version)")
        return update(
            state: state,
            action: .sync,
            environment: environment
        )
    }
    
    static func failSyncSphere(
        state: AppModel,
        environment: AppEnvironment,
        error: String
    ) -> Update<AppModel> {
        logger.log("Sphere sync failed: \(error)")
        return Update(state: state)
    }

    /// Start file sync
    static func sync(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        logger.log("File sync started")
        let fx: Fx<AppAction> = environment.data
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
                file: databaseURL,
                mode: .readwrite
            ),
            migrations: Config.migrations
        )
        
        self.data = DataService(
            documentURL: self.documentURL,
            databaseURL: databaseURL,
            noosphere: noosphere,
            database: databaseService,
            memos: memos
        )

        self.feed = FeedService()
    }
}

