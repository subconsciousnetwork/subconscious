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
        action: .start,
        environment: AppEnvironment.default
    )
    @Environment(\.scenePhase) private var scenePhase: ScenePhase

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
            if (!store.state.isAppUpgraded) {
                AppUpgradeView(
                    state: store.state.appUpgrade,
                    send: Address.forward(
                        send: store.send,
                        tag: AppUpgradeCursor.tag
                    )
                )
                .transition(
                    .asymmetric(insertion: .identity, removal: .opacity)
                )
                .zIndex(2)
            }
            if (store.state.shouldPresentFirstRun) {
                FirstRunView(app: store)
                    .animation(
                        .default,
                        value: store.state.shouldPresentFirstRun
                    )
                    .zIndex(1)
            }
        }
        .sheet(
            isPresented: Binding(
                get: { store.state.isSettingsSheetPresented },
                send: store.send,
                tag: AppAction.presentSettingsSheet
            )
        ) {
            SettingsView(app: store)
        }
        .sheet(
            isPresented: Binding(
                get: { store.state.addressBook.isPresented },
                send: store.send,
                tag: AppAction.presentAddressBook
            )
        ) {
            AddressBookView(
                state: store.state.addressBook,
                send: Address.forward(
                    send: store.send,
                    tag: AppAddressBookCursor.tag
                )
            )
        }
        .onAppear {
            store.send(.appear)
        }
        .onReceive(store.actions) { action in
            let message = String.loggable(action)
            AppModel.logger.debug("[action] \(message)")
        }
        // Track changes to scene phase so we know when app gets
        // foregrounded/backgrounded.
        // See https://developer.apple.com/documentation/swiftui/scenephase
        // 2023-02-16 Gordon Brander
        .onChange(of: self.scenePhase) { phase in
            store.send(.scenePhaseChange(phase))
        }
    }
}

//  MARK: Action
enum AppAction: CustomLogStringConvertible {
    /// Sent immediately upon store creation
    case start

    case recoveryPhrase(RecoveryPhraseAction)
    case addressBook(AddressBookAction)
    case appUpgrade(AppUpgradeAction)
    case yourProfile(UserProfileDetailAction)

    /// Scene phase events
    /// See https://developer.apple.com/documentation/swiftui/scenephase
    case scenePhaseChange(ScenePhase)

    /// On view appear
    case appear

    case setAppUpgraded(_ isUpgraded: Bool)

    /// Set sphere/user nickname
    case setNicknameTextField(_ nickname: String)

    /// Set gateway URL
    case setGatewayURLTextField(_ gateway: String)
    case submitGatewayURL(_ gateway: String)

    /// Create a new sphere given an owner key name
    case createSphere(_ ownerKeyName: String?)
    case failCreateSphere(_ message: String)

    /// Set identity of sphere
    case setSphereIdentity(String?)
    /// Fetch the latest sphere version, and store on model
    case refreshSphereVersion

    /// Set and persist Noosphere enabled state
    case persistNoosphereEnabled(_ isEnabled: Bool)
    /// Handle changes to AppDefaults.standard.isNoosphereEnabled, and
    /// sync the value to our store state.
    case notifyNoosphereEnabled(_ isEnabled: Bool)

    /// Set and persist first run complete state
    case persistFirstRunComplete(_ isComplete: Bool)

    /// Reset Noosphere Service.
    /// This calls `Noosphere.reset` which resets memoized instances of
    /// `Noosphere` and `SphereFS`.
    case resetNoosphereService

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
    /// In the case that no valid migration is found, we rebuild the database
    /// from scratch, and repopulate it from our sources of truth.
    /// This will put the app in "upgrading" state, where user will be shown
    /// an upgrade screen for the duration of the upgrade.
    case rebuildDatabase
    case succeedRebuildDatabase(Int)
    case failRebuildDatabase(String)
    /// App ready for database calls and interaction
    case ready
    
    /// Sync gateway to sphere, sphere to DB, and local file system to DB
    case syncAll

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

    /// Set settings sheet presented?
    case presentSettingsSheet(_ isPresented: Bool)
    
    static func presentAddressBook(_ isPresented: Bool) -> AppAction {
        .addressBook(.present(isPresented))
    }
    
    /// Set recovery phrase on recovery phrase component
    static func setRecoveryPhrase(_ phrase: String) -> AppAction {
        .recoveryPhrase(.setPhrase(phrase))
    }

    /// Synonym for AppUpgrade event action.
    static func setAppUpgradeProgressMessage(_ message: String) -> AppAction {
        .appUpgrade(.setProgressMessage(message))
    }

    static func setAppUpgradeComplete(_ isComplete: Bool) -> AppAction {
        .appUpgrade(.setComplete(isComplete))
    }

    var logDescription: String {
        switch self {
        case let .succeedMigrateDatabase(version):
            return "succeedMigrateDatabase(\(version))"
        case let .succeedSyncLocalFilesWithDatabase(fingerprints):
            return "succeedSyncLocalFilesWithDatabase(...) \(fingerprints.count) items"
        default:
            return String(describing: self)
        }
    }
}

//  MARK: Cursors

struct AppRecoveryPhraseCursor: CursorProtocol {
    static func get(state: AppModel) -> RecoveryPhraseModel {
        state.recoveryPhrase
    }
    
    static func set(state: AppModel, inner: RecoveryPhraseModel) -> AppModel {
        var model = state
        model.recoveryPhrase = inner
        return model
    }
    
    static func tag(_ action: RecoveryPhraseAction) -> AppAction {
        .recoveryPhrase(action)
    }
}

struct AppAddressBookCursor: CursorProtocol {
    static func get(state: AppModel) -> AddressBookModel {
        state.addressBook
    }
    
    static func set(state: AppModel, inner: AddressBookModel) -> AppModel {
        var model = state
        model.addressBook = inner
        return model
    }
    
    static func tag(_ action: AddressBookAction) -> AppAction {
        .addressBook(action)
    }
}

struct AppUpgradeCursor: CursorProtocol {
    typealias Model = AppModel
    typealias ViewModel = AppUpgradeModel
    
    static func get(state: Model) -> ViewModel {
        state.appUpgrade
    }
    
    static func set(state: AppModel, inner: AppUpgradeModel) -> AppModel {
        var model = state
        model.appUpgrade = inner
        return model
    }
    
    static func tag(_ action: AppUpgradeAction) -> AppAction {
        switch action {
        case .continue:
            return .setAppUpgraded(true)
        default:
            return .appUpgrade(action)
        }
    }
}
    
struct AppYourProfileCursor: CursorProtocol {
    static func get(state: AppModel) -> UserProfileDetailModel {
        state.yourProfile
    }
    
    static func set(state: AppModel, inner: UserProfileDetailModel) -> AppModel {
        var model = state
        model.yourProfile = inner
        return model
    }
    
    static func tag(_ action: UserProfileDetailAction) -> AppAction {
        .yourProfile(action)
    }
}

enum AppDatabaseState {
    case initial
    case migrating
    case broken
    case ready
}

enum GatewaySyncStatus: Equatable {
    case initial
    case inProgress
    case success
    case failure(String)
}

//  MARK: Model
struct AppModel: ModelProtocol {
    /// Is Noosphere enabled?
    /// We assign UserDefault property to model property at startup.
    /// This property is changed via `persistNoosphereEnabled`, which will
    /// update both the model property (triggering a view re-render)
    /// and persist the new value to UserDefaults.
    var isNoosphereEnabled = AppDefaults.standard.isNoosphereEnabled

    /// Has first run completed?
    /// We assign UserDefault property to model property at startup.
    /// This property is changed via `persistFirstRunComplete`, which will
    /// update both the model property (triggering a view re-render)
    /// and persist the new value to UserDefaults.
    var isFirstRunComplete = AppDefaults.standard.firstRunComplete

    /// Should first run show?
    var shouldPresentFirstRun: Bool {
        guard isNoosphereEnabled else {
            return false
        }
        return !isFirstRunComplete
    }

    /// Is database connected and migrated?
    var databaseMigrationStatus = ResourceStatus.initial
    var localSyncStatus = ResourceStatus.initial
    var sphereSyncStatus = ResourceStatus.initial

    var isSyncAllResolved: Bool {
        databaseMigrationStatus.isResolved &&
        localSyncStatus.isResolved &&
        sphereSyncStatus.isResolved
    }

    var nickname = AppDefaults.standard.nickname
    var nicknameTextField = AppDefaults.standard.nickname ?? ""
    var isNicknameTextFieldValid = true

    /// Default sphere identity
    var sphereIdentity = AppDefaults.standard.sphereIdentity
    /// Default sphere version, if any.
    var sphereVersion: String?
    /// State for rendering mnemonic/recovery phrase UI.
    /// Not persisted.
    var recoveryPhrase = RecoveryPhraseModel()
    
    /// Holds the state of the petname directory
    /// Will be persisted to and read from the underlying sphere
    var addressBook = AddressBookModel()
    
    /// Is app in progress of upgrading?
    /// Toggled to true when database is rebuilt from scratch.
    /// Remains true until first file sync completes.
    var isAppUpgraded = true
    
    /// State for app upgrade view that takes over if we have to do any
    /// one-time long-running migration tasks at startup.
    var appUpgrade = AppUpgradeModel()
    
    var yourProfile = UserProfileDetailModel()

    var gatewayURL = AppDefaults.standard.gatewayURL
    var gatewayURLTextField = AppDefaults.standard.gatewayURL
    var isGatewayURLTextFieldValid = true
    var lastGatewaySyncStatus = ResourceStatus.initial
    
    /// Show settings sheet?
    var isSettingsSheetPresented = false
    
    /// Determine if the interface is ready for user interaction,
    /// even if all of the data isn't refreshed yet.
    /// This is the point at which the main interface is ready to be shown.
    var isReadyForInteraction: Bool {
        self.databaseMigrationStatus == .succeeded
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
        case .start:
            return start(
                state: state,
                environment: environment
            )
        case .recoveryPhrase(let action):
            return AppRecoveryPhraseCursor.update(
                state: state,
                action: action,
                environment: environment.recoveryPhrase
            )
        case .addressBook(let action):
            return AppAddressBookCursor.update(
                state: state,
                action: action,
                environment: environment.addressBook
            )
        case .appUpgrade(let action):
            return AppUpgradeCursor.update(
                state: state,
                action: action,
                environment: ()
            )
        case .yourProfile(let action):
            return AppYourProfileCursor.update(
                state: state,
                action: action,
                environment: environment
            )
        case .scenePhaseChange(let scenePhase):
            return scenePhaseChange(
                state: state,
                environment: environment,
                scenePhase: scenePhase
            )
        case .appear:
            return appear(
                state: state,
                environment: environment
            )
        case let .setAppUpgraded(isUpgraded):
            return setAppUpgraded(
                state: state,
                environment: environment,
                isUpgraded: isUpgraded
            )
        case let .setNicknameTextField(nickname):
            return setNicknameTextField(
                state: state,
                environment: environment,
                text: nickname
            )
        case let .setGatewayURLTextField(text):
            return setGatewayURLTextField(
                state: state,
                environment: environment,
                text: text
            )
        case let .submitGatewayURL(gateway):
            return submitGatewayURL(
                state: state,
                environment: environment,
                gatewayURL: gateway
            )
        case let .createSphere(ownerKeyName):
            return createSphere(
                state: state,
                environment: environment,
                ownerKeyName: ownerKeyName
            )
        case .failCreateSphere(let message):
            logger.warning("Failed to create Sphere: \(message)")
            return Update(state: state)
        case let .setSphereIdentity(sphereIdentity):
            return setSphereIdentity(
                state: state,
                environment: environment,
                sphereIdentity: sphereIdentity
            )
        case .refreshSphereVersion:
            return refreshSphereVersion(
                state: state,
                environment: environment
            )
        case let .persistNoosphereEnabled(isEnabled):
            return persistNoosphereEnabled(
                state: state,
                environment: environment,
                isEnabled: isEnabled
            )
        case let .notifyNoosphereEnabled(isEnabled):
            return notifyNoosphereEnabled(
                state: state,
                environment: environment,
                isEnabled: isEnabled
            )
        case let .persistFirstRunComplete(isComplete):
            return persistFirstRunComplete(
                state: state,
                environment: environment,
                isComplete: isComplete
            )
        case .resetNoosphereService:
            return resetNoosphereService(
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
        case .succeedRebuildDatabase(let version):
            return succeedRebuildDatabase(
                state: state,
                environment: environment,
                version: version
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
        case .syncAll:
            return syncAll(
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
            return failSyncLocalFilesWithDatabase(
                state: state,
                environment: environment,
                message: message
            )
        case let .presentSettingsSheet(isPresented):
            return presentSettingsSheet(
                state: state,
                environment: environment,
                isPresented: isPresented
            )
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
    
    static func start(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        // Subscribe to changes in AppDefaults.isNoosphereEnabled
        let fx: Fx<AppAction> = AppDefaults.standard.$isNoosphereEnabled
            .map(AppAction.notifyNoosphereEnabled)
            .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }

    /// Handle scene phase change
    static func scenePhaseChange(
        state: AppModel,
        environment: AppEnvironment,
        scenePhase: ScenePhase
    ) -> Update<AppModel> {
        switch scenePhase {
        case .inactive:
            return update(
                state: state,
                action: .resetNoosphereService,
                environment: environment
            )
        default:
            return Update(state: state)
        }
    }

    static func appear(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        logger.debug(
            "Documents: \(environment.documentURL)"
        )
        let sphereIdentity = state.sphereIdentity ?? "Unknown"
        logger.debug(
            "Sphere ID: \(sphereIdentity)"
        )
        logger.debug(
            "Sphere ID: \(sphereIdentity)"
        )
        logger.debug(
            "Noosphere enabled? \(AppDefaults.standard.isNoosphereEnabled)"
        )
        return update(
            state: state,
            actions: [
                .migrateDatabase,
                .refreshSphereVersion
            ],
            environment: environment
        )
    }
    
    static func setAppUpgraded(
        state: AppModel,
        environment: AppEnvironment,
        isUpgraded: Bool
    ) -> Update<AppModel> {
        var model = state
        model.isAppUpgraded = isUpgraded
        return Update(state: model).animation(.default)
    }
    
    static func setNicknameTextField(
        state: AppModel,
        environment: AppEnvironment,
        text: String
    ) -> Update<AppModel> {
        guard let petname = Petname(formatting: text) else {
            var model = state
            model.nicknameTextField = text
            model.isNicknameTextFieldValid = false
            return Update(state: model)
        }
        guard petname.description == text else {
            var model = state
            model.nicknameTextField = text
            model.isNicknameTextFieldValid = false
            return Update(state: model)
        }
        logger.log("Nickname saved: \(petname.description)")
        var model = state
        model.nicknameTextField = text
        model.nickname = petname.description
        // Persist
        AppDefaults.standard.nickname = petname.description
        model.isNicknameTextFieldValid = true
        return Update(state: model)
    }
    
    static func setGatewayURLTextField(
        state: AppModel,
        environment: AppEnvironment,
        text: String
    ) -> Update<AppModel> {
        let url = URL(string: text)
        let isGatewayURLTextFieldValid = url?.isHTTP() ?? false

        var model = state
        model.gatewayURLTextField = text
        model.isGatewayURLTextFieldValid = isGatewayURLTextFieldValid
        return Update(state: model)
    }
    
    static func submitGatewayURL(
        state: AppModel,
        environment: AppEnvironment,
        gatewayURL: String
    ) -> Update<AppModel> {
        var fallback = state
        fallback.gatewayURLTextField = state.gatewayURL
        fallback.isGatewayURLTextFieldValid = true

        // If URL given is not valid, fall back to original value.
        guard let url = URL(string: gatewayURL) else {
            return Update(state: fallback)
        }

        // If URL given is not HTTP, fall back to original value.
        guard url.isHTTP() else {
            return Update(state: fallback)
        }

        var model = state
        model.gatewayURL = gatewayURL
        model.gatewayURLTextField = gatewayURL
        model.isGatewayURLTextFieldValid = true

        // Persist to UserDefaults
        AppDefaults.standard.gatewayURL = gatewayURL
        // Reset gateway on environment
        environment.data.noosphere.resetGateway(url: url)

        /// Only set valid nicknames
        return Update(state: model)
    }

    static func createSphere(
        state: AppModel,
        environment: AppEnvironment,
        ownerKeyName: String?
    ) -> Update<AppModel> {
        let ownerKeyName = ownerKeyName ?? Config.default.noosphere.ownerKeyName
        do {
            let receipt = try environment.data.createSphere(
                ownerKeyName: ownerKeyName
            )
            return update(
                state: state,
                actions: [
                    .setSphereIdentity(receipt.identity),
                    .setRecoveryPhrase(receipt.mnemonic)
                ],
                environment: environment
            )
        }  catch {
            return update(
                state: state,
                action: .failCreateSphere(error.localizedDescription),
                environment: environment
            )
        }
    }

    static func setSphereIdentity(
        state: AppModel,
        environment: AppEnvironment,
        sphereIdentity: String?
    ) -> Update<AppModel> {
        var model = state
        model.sphereIdentity = sphereIdentity
        if let sphereIdentity = sphereIdentity {
            logger.debug("Set sphere ID: \(sphereIdentity)")
        }
        return Update(state: model)
    }
    
    /// Check for latest sphere version and store on the model
    static func refreshSphereVersion(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        guard let version = try? environment.data.noosphere.version() else {
            return Update(state: state)
        }
        var model = state
        model.sphereVersion = version
        logger.debug("Refreshed sphere version: \(version)")
        return Update(state: model)
    }

    /// Persist Noosphere enabled state.
    /// Note that this updates the model state (triggering a re-render),
    /// and ALSO perists the state to UserDefaults.
    static func persistNoosphereEnabled(
        state: AppModel,
        environment: AppEnvironment,
        isEnabled: Bool
    ) -> Update<AppModel> {
        // Persist setting to UserDefaults
        AppDefaults.standard.isNoosphereEnabled = isEnabled
        var model = state
        model.isNoosphereEnabled = isEnabled
        return Update(state: model)
    }

    /// Update model to match persisted enabled state.
    /// A notification is generated for every
    /// This will take care of cases where the enabled state has been set
    /// in some other place outside of our store.
    static func notifyNoosphereEnabled(
        state: AppModel,
        environment: AppEnvironment,
        isEnabled: Bool
    ) -> Update<AppModel> {
        var model = state
        model.isNoosphereEnabled = isEnabled
        return Update(state: model)
    }

    /// Persist first run complete state
    static func persistFirstRunComplete(
        state: AppModel,
        environment: AppEnvironment,
        isComplete: Bool
    ) -> Update<AppModel> {
        // Persist value
        AppDefaults.standard.firstRunComplete = isComplete
        var model = state
        model.isFirstRunComplete = isComplete
        return Update(state: model).animation(.default)
    }

    /// Reset NoosphereService managed instances of `Noosphere` and `Sphere`.
    static func resetNoosphereService(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        environment.data.noosphere.reset()
        return Update(state: state)
    }

    /// Make database ready.
    /// This will kick off a migration IF a successful migration
    /// has not already occurred.
    static func migrateDatabase(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        switch state.databaseMigrationStatus {
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
            model.databaseMigrationStatus = .pending
            return Update(state: model, fx: fx)
        case .pending:
            logger.log(
                "Database already migrating. Doing nothing."
            )
            return Update(state: state)
        case let .failed(message):
            logger.warning(
                "Database broken (doing nothing). Message: \(message)"
            )
            return Update(state: state)
        case .succeeded:
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
        model.databaseMigrationStatus = .succeeded
        return update(state: model, action: .ready, environment: environment)
    }
    
    static func rebuildDatabase(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        logger.warning(
            "No valid migrations for database. Rebuilding."
        )
        
        var model = state
        
        // Toggle app "upgrading" state.
        // Upgrade screen will be shown to user.
        model.isAppUpgraded = false
        model.databaseMigrationStatus = .pending

        let fx: Fx<AppAction> = environment.data.rebuildAsync().map({
            receipt in
            AppAction.succeedRebuildDatabase(receipt)
        }).catch({ error in
            Just(AppAction.failRebuildDatabase(error.localizedDescription))
        }).eraseToAnyPublisher()
        
        return update(
            state: model,
            action: .setAppUpgradeProgressMessage(
                String(localized: "Upgrading database...")
            ),
            environment: environment
        ).mergeFx(fx)
    }
    
    static func succeedRebuildDatabase(
        state: AppModel,
        environment: AppEnvironment,
        version: Int
    ) -> Update<AppModel> {
        logger.log(
            "Rebuilt database"
        )
        return update(
            state: state,
            actions: [
                // This will kick off .ready and .syncAll
                .succeedMigrateDatabase(version),
                .setAppUpgradeComplete(state.isSyncAllResolved)
            ],
            environment: environment
        )
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
        model.databaseMigrationStatus = .failed(error)
        return update(
            state: model,
            action: .setAppUpgradeComplete(model.isSyncAllResolved),
            environment: environment
        )
    }
    
    static func ready(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        do {
            let sphereIdentity = try environment.data.database
                .readMetadata(key: .sphereIdentity)
            let sphereVersion = try environment.data.database
                .readMetadata(key: .sphereVersion)
            logger.log("Database last-known sphere state: \(sphereIdentity) @ \(sphereVersion)")
        } catch {
            logger.log("Database last-known sphere state: unknown")
        }
        // For now, we just sync everything on ready.
        return update(
            state: state,
            action: .syncAll,
            environment: environment
        )
    }

    static func syncAll(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        return update(
            state: state,
            actions: [
                .syncSphereWithGateway,
                .syncLocalFilesWithDatabase,
                .setAppUpgradeProgressMessage("Transferring notes to database...")
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
        
        var model = state
        model.lastGatewaySyncStatus = .pending
        
        logger.log("Syncing with gateway: \(gatewayURL.absoluteString)")
        let fx: Fx<AppAction> = environment.data.syncSphereWithGateway()
            .map({ version in
                AppAction.succeedSyncSphereWithGateway(version: version)
            })
            .catch({ error in
                Just(AppAction.failSyncSphereWithGateway(error.localizedDescription))
            })
            .eraseToAnyPublisher()
        return Update(state: model, fx: fx)
    }
    
    static func succeedSyncSphereWithGateway(
        state: AppModel,
        environment: AppEnvironment,
        version: String
    ) -> Update<AppModel> {
        logger.log("Sphere synced with gateway @ \(version)")
        
        var model = state
        model.lastGatewaySyncStatus = .succeeded
        
        return update(
            state: model,
            action: .syncSphereWithDatabase,
            environment: environment
        )
    }
    
    static func failSyncSphereWithGateway(
        state: AppModel,
        environment: AppEnvironment,
        error: String
    ) -> Update<AppModel> {
        logger.log("Sphere failed to sync with gateway: \(error)")
        
        var model = state
        model.lastGatewaySyncStatus = .failed(error)
        
        return update(
            state: model,
            action: .syncSphereWithDatabase,
            environment: environment
        )
    }
    
    static func syncSphereWithDatabase(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        let fx: Fx<AppAction> = environment.data.syncSphereWithDatabaseAsync().map({
            version in
            AppAction.succeedSyncSphereWithDatabase(version: version)
        }).catch({ error in
            Just(
                AppAction.failSyncSphereWithDatabase(error.localizedDescription)
            )
        }).eraseToAnyPublisher()
        
        var model = state
        model.sphereSyncStatus = .pending
        return Update(state: model, fx: fx)
    }
    
    static func succeedSyncSphereWithDatabase(
        state: AppModel,
        environment: AppEnvironment,
        version: String
    ) -> Update<AppModel> {
        let identity = state.sphereIdentity ?? "unknown"
        logger.log("Database synced to sphere \(identity) @ \(version)")
        
        var model = state
        model.sphereSyncStatus = .succeeded
        
        return update(
            state: model,
            action: .setAppUpgradeComplete(model.isSyncAllResolved),
            environment: environment
        )
    }
    
    static func failSyncSphereWithDatabase(
        state: AppModel,
        environment: AppEnvironment,
        error: String
    ) -> Update<AppModel> {
        logger.log("Database failed to sync with sphere: \(error)")

        var model = state
        model.sphereSyncStatus = .failed(error)
        
        return update(
            state: model,
            action: .setAppUpgradeComplete(model.isSyncAllResolved),
            environment: environment
        )
    }
    
    /// Start file sync
    static func syncLocalFilesWithDatabase(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        logger.log("File sync started")

        let fx: Fx<AppAction> = environment.data.syncLocalWithDatabaseAsync().map({
            changes in
            AppAction.succeedSyncLocalFilesWithDatabase(changes)
        }).catch({ error in
            Just(AppAction.failSyncLocalFilesWithDatabase(error.localizedDescription))
        }).eraseToAnyPublisher()
        
        var model = state
        model.localSyncStatus = .pending
        return Update(state: model, fx: fx)
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
        
        var model = state
        model.localSyncStatus = .succeeded
        
        return update(
            state: model,
            action: .setAppUpgradeComplete(model.isSyncAllResolved),
            environment: environment
        )
    }
    
    static func failSyncLocalFilesWithDatabase(
        state: AppModel,
        environment: AppEnvironment,
        message: String
    ) -> Update<AppModel> {
        logger.log("File sync failed: \(message)")
        
        var model = state
        model.localSyncStatus = .failed(message)
        
        return update(
            state: model,
            action: .setAppUpgradeComplete(model.isSyncAllResolved),
            environment: environment
        )
    }

    static func presentSettingsSheet(
        state: AppModel,
        environment: AppEnvironment,
        isPresented: Bool
    ) -> Update<AppModel> {
        var model = state
        model.isSettingsSheetPresented = isPresented
        return Update(state: model)
    }
}

//  MARK: Environment
/// A place for constants and services
struct AppEnvironment {
    /// Default environment constant
    static let `default` = AppEnvironment()

    var documentURL: URL
    var applicationSupportURL: URL

    var data: DataService
    var feed: FeedService
    
    var recoveryPhrase = RecoveryPhraseEnvironment()
    var addressBook: AddressBookEnvironment

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

        let files = FileStore(documentURL: documentURL)
        let local = HeaderSubtextMemoStore(store: files)

        let globalStorageURL = applicationSupportURL.appending(
            path: Config.default.noosphere.globalStoragePath
        )
        let sphereStorageURL = applicationSupportURL.appending(
            path: Config.default.noosphere.sphereStoragePath
        )
        let defaultGateway = URL(string: AppDefaults.standard.gatewayURL)
        let defaultSphereIdentity = AppDefaults.standard.sphereIdentity

        let noosphere = NoosphereService(
            globalStorageURL: globalStorageURL,
            sphereStorageURL: sphereStorageURL,
            gatewayURL: defaultGateway,
            sphereIdentity: defaultSphereIdentity
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
        
        let addresBook = AddressBookService(noosphere: noosphere, database: databaseService)
        
        self.data = DataService(
            noosphere: noosphere,
            database: databaseService,
            local: local,
            addressBook: addresBook
        )
        
        self.addressBook = AddressBookEnvironment(data: data)

        self.feed = FeedService()
    }
}

