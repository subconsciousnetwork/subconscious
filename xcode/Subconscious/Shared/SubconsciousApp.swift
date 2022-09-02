//
//  SubconsciousApp.swift
//  Shared
//
//  Created by Gordon Brander on 9/15/21.
//

import SwiftUI
import os
import Combine
import ObservableStore

@main
struct SubconsciousApp: App {
    @StateObject private var store: AppStore = Store(
        update: AppModel.updateAndLog,
        state: AppModel(),
        environment: AppEnvironment()
    )

    var body: some Scene {
        WindowGroup {
            AppView(store: store)
        }
    }
}

//  MARK: Store typealias
typealias AppStore = Store<AppModel, AppAction, AppEnvironment>

enum AppAction {
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
    /// Get database ready for interaction
    case readyDatabase
    case migrateDatabaseSuccess(SQLite3Migrations.MigrationSuccess)
    case rebuildDatabase
    case rebuildDatabaseFailure(String)
    /// Sync database with file system
    case sync
    case syncSuccess([FileSync.Change])
    case syncFailure(String)
}

extension AppAction {
    /// Generates a short (approximately 1 line) loggable string for action.
    func toLogString() -> String {
        switch self {
        case .notebook(let action):
            return action.toLogString()
        default:
            return String(describing: self)
        }
    }
}

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
    static func tag(action: NotebookAction) -> AppAction {
        AppAction.notebook(action)
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
    static func tag(action: FeedAction) -> AppAction {
        AppAction.feed(action)
    }
}

/// Enum describing which view is currently focused.
/// Focus is mutually exclusive, and SwiftUI's FocusedState requires
/// modeling this state as an enum.
/// See https://github.com/gordonbrander/subconscious/wiki/SwiftUI-FocusState
/// 2021-12-23 Gordon Brander
enum AppFocus: Hashable, Equatable {
    case search
    case linkSearch
    case editor
    case rename
}

enum AppDatabaseState {
    case initial
    case migrating
    case broken
    case ready
}

//  MARK: Model
struct AppModel: Equatable {
    /// What is focused? (nil means nothing is focused)
    var focus: AppFocus? = nil

    /// Is database connected and migrated?
    var databaseState = AppDatabaseState.initial

    /// Feed of stories
    var feed = FeedModel()

    var notebook = NotebookModel()

    /// Determine if the interface is ready for user interaction,
    /// even if all of the data isn't refreshed yet.
    /// This is the point at which the main interface is ready to be shown.
    var isReadyForInteraction: Bool {
        self.databaseState == .ready
    }
}

//  MARK: Update
extension AppModel {
    /// Call through to main update function and log updates
    /// when `state.config.debug` is `true`.
    static func updateAndLog(
        state: AppModel,
        action: AppAction,
        environment: AppEnvironment
    ) -> Update<AppModel, AppAction> {
        Logger.action.debug("\(action.toLogString())")
        // Generate next state and effect
        let next = update(
            state: state,
            action: action,
            environment: environment
        )
        if Config.default.debug {
            Logger.state.debug("\(String(describing: next.state))")
        }
        return next
    }

    static func update(
        state: AppModel,
        action: AppAction,
        environment: AppEnvironment
    ) -> Update<AppModel, AppAction> {
        switch action {
        case .notebook(let action):
            return NotebookCursor.update(
                with: NotebookModel.update,
                state: state,
                action: action,
                environment: environment
            )
        case .feed(let action):
            return FeedCursor.update(
                with: FeedModel.update,
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
            return changeKeyboardState(state: state, keyboard: keyboard)
        case .poll:
            // Auto-save entry currently being edited, if any.
            let fx: Fx<AppAction> = Just(
                AppAction.notebook(
                    NotebookAction.autosave
                )
            )
            .eraseToAnyPublisher()
            return Update(state: state, fx: fx)
        case .readyDatabase:
            return readyDatabase(state: state, environment: environment)
        case let .migrateDatabaseSuccess(success):
            return migrateDatabaseSuccess(
                state: state,
                environment: environment,
                success: success
            )
        case .rebuildDatabase:
            return rebuildDatabase(
                state: state,
                environment: environment
            )
        case let .rebuildDatabaseFailure(error):
            environment.logger.warning(
                "Could not rebuild database: \(error)"
            )
            var model = state
            model.databaseState = .broken
            return Update(state: model)
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
        }
    }

    /// Change state of keyboard
    /// Actions come from `KeyboardService`
    static func changeKeyboardState(
        state: AppModel,
        keyboard: KeyboardState
    ) -> Update<AppModel, AppAction> {
        /// Forward keyboard change action down to Notebook component
        let fx: Fx<AppAction> = Just(
            AppAction.notebook(.changeKeyboardState(keyboard))
        )
        .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }

    /// Handle scene phase change
    static func scenePhaseChange(
        state: AppModel,
        phase: ScenePhase,
        environment: AppEnvironment
    ) -> Update<AppModel, AppAction> {
        switch phase {
        case .active:
            let fx: Fx<AppAction> = Just(
                AppAction.readyDatabase
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
    ) -> Update<AppModel, AppAction> {
        environment.logger.debug(
            "Documents: \(environment.documentURL)"
        )

        let pollFx: Fx<AppAction> = AppEnvironment.poll(
            every: Config.default.pollingInterval
        )
        .map({ date in
            AppAction.poll(date)
        })
        .eraseToAnyPublisher()

        let feedFx: Fx<AppAction> = Just(AppAction.feed(.appear))
            .eraseToAnyPublisher()

        let notebookFx: Fx<AppAction> = Just(AppAction.notebook(.appear))
            .eraseToAnyPublisher()

        // Subscribe to keyboard events
        let fx: Fx<AppAction> = environment
            .keyboard.state
            .map({ value in
                AppAction.changeKeyboardState(value)
            })
            .merge(
                with: pollFx,
                feedFx,
                notebookFx
            )
            .eraseToAnyPublisher()

        return Update(state: state, fx: fx)
    }


    /// Make database ready.
    /// This will kick off a migration IF a successful migration
    /// has not already occurred.
    static func readyDatabase(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel, AppAction> {
        switch state.databaseState {
        case .initial:
            environment.logger.log("Readying database")
            let fx: Fx<AppAction> = environment.database
                .migrate()
                .map({ success in
                    AppAction.migrateDatabaseSuccess(success)
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
            environment.logger.log("Database ready. Syncing.")
            let fx: Fx<AppAction> = Just(
                AppAction.sync
            )
            .eraseToAnyPublisher()
            return Update(state: state, fx: fx)
        }
    }

    static func migrateDatabaseSuccess(
        state: AppModel,
        environment: AppEnvironment,
        success: SQLite3Migrations.MigrationSuccess
    ) -> Update<AppModel, AppAction> {
        var model = state
        model.databaseState = .ready
        let fx: Fx<AppAction> = Just(
            AppAction.sync
        )
        .eraseToAnyPublisher()
        if success.from != success.to {
            environment.logger.log(
                "Migrated database: \(success.from)->\(success.to)"
            )
        }
        return Update(state: model, fx: fx)
    }

    static func rebuildDatabase(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel, AppAction> {
        environment.logger.warning(
            "Database is broken or has wrong schema. Attempting to rebuild."
        )
        let fx: Fx<AppAction> = environment.database
            .delete()
            .flatMap({ _ in
                environment.database.migrate()
            })
            .map({ success in
                AppAction.migrateDatabaseSuccess(success)
            })
            .catch({ error in
                Just(AppAction.rebuildDatabaseFailure(
                    error.localizedDescription)
                )
            })
            .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }

    /// Start file sync
    static func sync(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel, AppAction> {
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
        changes: [FileSync.Change]
    ) -> Update<AppModel, AppAction> {
        environment.logger.debug(
            "File sync finished: \(changes)"
        )

        // Refresh lists after completing sync.
        // This ensures that files which were deleted outside the app
        // are removed from lists once sync is complete.
        let fx: Fx<AppAction> = Just(
            AppAction.notebook(.refreshAll)
        )
        .eraseToAnyPublisher()

        return Update(state: state, fx: fx)
    }
}

//  MARK: Environment
/// A place for constants and services
struct AppEnvironment {
    var documentURL: URL
    var applicationSupportURL: URL

    var logger: Logger
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

        self.database = DatabaseService(
            documentURL: self.documentURL,
            databaseURL: self.applicationSupportURL
                .appendingPathComponent("database.sqlite"),
            migrations: Self.migrations
        )

        self.keyboard = KeyboardService()

        self.feed = FeedService()

        let zettelkastenGrammar = try! Bundle.main.read(
            resource: Config.default.traceryZettelkasten,
            withExtension: "json"
        )
        let zettelkastenGeist = try! RandomPromptGeist(
            database: database,
            data: zettelkastenGrammar
        )
        self.feed.register(name: "zettelkasten", geist: zettelkastenGeist)
    }
}

//  MARK: Migrations
extension AppEnvironment {
    static let migrations = SQLite3Migrations([
        SQLite3Migrations.Migration(
            date: "2021-11-04T12:00:00",
            sql: """
            CREATE TABLE search_history (
                id TEXT PRIMARY KEY,
                query TEXT NOT NULL,
                created TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE entry (
              slug TEXT PRIMARY KEY,
              title TEXT NOT NULL DEFAULT '',
              body TEXT NOT NULL,
              modified TEXT NOT NULL,
              size INTEGER NOT NULL
            );

            CREATE VIRTUAL TABLE entry_search USING fts5(
              slug,
              title,
              body,
              modified UNINDEXED,
              size UNINDEXED,
              content="entry",
              tokenize="porter"
            );

            /*
            Create triggers to keep fts5 virtual table in sync with content table.

            Note: SQLite documentation notes that you want to modify the fts table *before*
            the external content table, hence the BEFORE commands.

            These triggers are adapted from examples in the docs:
            https://www.sqlite.org/fts3.html#_external_content_fts4_tables_
            */
            CREATE TRIGGER entry_search_before_update BEFORE UPDATE ON entry BEGIN
              DELETE FROM entry_search WHERE rowid=old.rowid;
            END;

            CREATE TRIGGER entry_search_before_delete BEFORE DELETE ON entry BEGIN
              DELETE FROM entry_search WHERE rowid=old.rowid;
            END;

            CREATE TRIGGER entry_search_after_update AFTER UPDATE ON entry BEGIN
              INSERT INTO entry_search
                (
                  rowid,
                  slug,
                  title,
                  body,
                  modified,
                  size
                )
              VALUES
                (
                  new.rowid,
                  new.slug,
                  new.title,
                  new.body,
                  new.modified,
                  new.size
                );
            END;

            CREATE TRIGGER entry_search_after_insert AFTER INSERT ON entry BEGIN
              INSERT INTO entry_search
                (
                  rowid,
                  slug,
                  title,
                  body,
                  modified,
                  size
                )
              VALUES
                (
                  new.rowid,
                  new.slug,
                  new.title,
                  new.body,
                  new.modified,
                  new.size
                );
            END;
            """
        )!
    ])!
}
