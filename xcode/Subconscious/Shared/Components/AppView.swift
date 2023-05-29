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
            if !store.state.isAppUpgraded {
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
            if store.state.shouldPresentFirstRun {
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
                .presentationDetents([.fraction(0.999)]) // https://stackoverflow.com/a/74631815
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

typealias InviteCodeFormField = FormField<String, InviteCode>
typealias NicknameFormField = FormField<String, Petname>

// MARK: Action
enum AppAction: CustomLogStringConvertible {
    /// Sent immediately upon store creation
    case start

    case recoveryPhrase(RecoveryPhraseAction)
    case appUpgrade(AppUpgradeAction)
    case nicknameFormField(NicknameFormField.Action)
    case inviteCodeFormField(InviteCodeFormField.Action)

    /// Scene phase events
    /// See https://developer.apple.com/documentation/swiftui/scenephase
    case scenePhaseChange(ScenePhase)

    /// On view appear
    case appear

    case setAppUpgraded(_ isUpgraded: Bool)

    /// Set sphere/user nickname
    /// Sets form field, and persists if needed.
    case setNickname(_ nickname: String)
    case persistNickname(_ nickname: String)
    
    /// Write to `Slashlink.ourProfile` during onboarding
    case requestCreateInitialProfile(_ nickname: String)
    case succeedCreateInitialProfile
    case failCreateInitialProfile(_ message: String)
    
    case fetchNicknameFromProfile
    case succeedFetchNicknameFromProfile(_ nickname: Petname)
    case failFetchNicknameFromProfile(_ message: String)
    
    case setInviteCode(_ inviteCode: String)

    /// Set gateway URL
    case setGatewayURLTextField(_ gateway: String)
    case submitGatewayURL(_ gateway: String)
    case succeedResetGatewayURL(_ url: URL)

    /// Create a new sphere given an owner key name
    case createSphere
    case succeedCreateSphere(SphereReceipt)
    case failCreateSphere(_ message: String)

    /// Set identity of sphere
    case setSphereIdentity(String?)
    /// Fetch the latest sphere version, and store on model
    case refreshSphereVersion
    case succeedRefreshSphereVersion(_ version: String)
    case failRefreshSphereVersion(_ error: String)

    /// Set and persist Noosphere enabled state
    case persistNoosphereEnabled(_ isEnabled: Bool)
    /// Handle changes to AppDefaults.standard.isNoosphereEnabled, and
    /// sync the value to our store state.
    case notifyNoosphereEnabled(_ isEnabled: Bool)

    /// Set and persist first run complete state
    case persistFirstRunComplete(_ isComplete: Bool)
    /// Set first run complete value on model.
    /// This action does not persist the value. It is understood to have been
    /// persisted already.
    case notifyFirstRunComplete(_ isComplete: Bool)

    /// Reset Noosphere Service.
    /// This calls `Noosphere.reset` which resets memoized instances of
    /// `Noosphere` and `SphereFS`.
    case resetNoosphereService
    case succeedResetNoosphereService

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
    case indexOurSphere
    case succeedIndexOurSphere(version: String)
    case failIndexOurSphere(String)
    
    /// Sync database with file system.
    /// File system always wins.
    case syncLocalFilesWithDatabase
    case succeedSyncLocalFilesWithDatabase([FileFingerprintChange])
    case failSyncLocalFilesWithDatabase(String)
    
    case followDefaultGeist
    case succeedFollowDefaultGeist
    case failFollowDefaultGeist(String)
    
    case submitProvisionGatewayForm
    case requestProvisionGateway(_ inviteCode: InviteCode)
    case receiveGatewayId(_ gatewayId: String)
    case requestGatewayProvisioningStatus
    case succeedProvisionGateway(_ gatewayURL: URL)
    case failProvisionGateway(_ error: String)
    
    case setFirstRunPath([FirstRunStep])
    case pushFirstRunStep(FirstRunStep)

    /// Set settings sheet presented?
    case presentSettingsSheet(_ isPresented: Bool)
    
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

extension AppAction {
    public static func from(action: UserProfileDetailAction) -> AppAction? {
        switch action {
        case .refresh:
            return .syncAll
        case .succeedEditProfile:
            return .fetchNicknameFromProfile
        case _:
            return nil
        }
    }
}

// MARK: Cursors

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

struct NicknameFormFieldCursor: CursorProtocol {
    typealias Model = AppModel
    typealias ViewModel = NicknameFormField
    
    static func get(state: Model) -> ViewModel {
        state.nicknameFormField
    }
    
    static func set(state: Model, inner: ViewModel) -> Model {
        var model = state
        model.nicknameFormField = inner
        return model
    }
    
    static func tag(_ action: ViewModel.Action) -> Model.Action {
        switch action {
        case .setValue(let input):
            return .setNickname(input)
        default:
            return .nicknameFormField(action)
        }
    }
}

struct InviteCodeFormFieldCursor: CursorProtocol {
    typealias Model = AppModel
    typealias ViewModel = InviteCodeFormField
    
    static func get(state: Model) -> ViewModel {
        state.inviteCodeFormField
    }
    
    static func set(state: Model, inner: ViewModel) -> Model {
        var model = state
        model.inviteCodeFormField = inner
        return model
    }
    
    static func tag(_ action: ViewModel.Action) -> Model.Action {
        switch action {
        case .setValue(let input):
            return .setInviteCode(input)
        default:
            return .nicknameFormField(action)
        }
    }
}

enum AppDatabaseState {
    case initial
    case migrating
    case broken
    case ready
}

enum FirstRunStep {
    case nickname
    case sphere
    case recovery
    case connect
}

// MARK: Model
struct AppModel: ModelProtocol {
    /// Is Noosphere enabled?
    ///
    /// This property is updated at `.start` with the corresponding value
    /// stored in `AppDefaults`.
    ///
    /// This property is changed via `persistNoosphereEnabled`, which will
    /// update both the model property (triggering a view re-render)
    /// and persist the new value to UserDefaults.
    var isNoosphereEnabled = false

    /// Has first run completed?
    ///
    /// This property is updated at `.start` with the corresponding value
    /// stored in `AppDefaults`.
    ///
    /// We assign UserDefault property to model property at startup.
    /// This property is changed via `persistFirstRunComplete`, which will
    /// update both the model property (triggering a view re-render)
    /// and persist the new value to UserDefaults.
    var isFirstRunComplete = false
    var firstRunPath: [FirstRunStep] = []

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

    //  User Nickname (preferred petname)
    /// Validated nickname
    ///
    /// This property is updated at `.start` with the corresponding value
    /// stored in `AppDefaults`.
    var nickname = ""
    /// Nickname form
    ///
    /// This property is updated at `.start` with the corresponding value
    /// stored in `AppDefaults`.
    var nicknameFormField = NicknameFormField(
        value: "",
        validate: { value in Petname(value) }
    )
    /// Expose read-only value for view
    var nicknameFormFieldValue: String {
        nicknameFormField.value
    }
    /// Expose read-only valid value for view
    var isNicknameFormFieldValid: Bool {
        nicknameFormField.isValid
    }
    
    var inviteCodeFormField = InviteCodeFormField(
        value: "",
        validate: { value in InviteCode(value) }
    )
    var gatewayProvisioningStatus = ResourceStatus.initial

    /// Default sphere identity
    ///
    /// This property is updated at `.start` with the corresponding value
    /// stored in `AppDefaults`.
    var sphereIdentity: String?
    /// Default sphere version, if any.
    var sphereVersion: String?
    /// State for rendering mnemonic/recovery phrase UI.
    /// Not persisted.
    var recoveryPhrase = RecoveryPhraseModel()
    
    /// Is app in progress of upgrading?
    /// Toggled to true when database is rebuilt from scratch.
    /// Remains true until first file sync completes.
    var isAppUpgraded = true
    
    /// State for app upgrade view that takes over if we have to do any
    /// one-time long-running migration tasks at startup.
    var appUpgrade = AppUpgradeModel()

    /// Preferred Gateway URL.
    ///
    /// This property is updated at `.start` with the corresponding value
    /// stored in `AppDefaults`.
    var gatewayURL = ""
    var gatewayId: String? = nil
    var gatewayURLTextField = ""
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
    
    // MARK: Update
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
        case .appUpgrade(let action):
            return AppUpgradeCursor.update(
                state: state,
                action: action,
                environment: ()
            )
        case .nicknameFormField(let action):
            return NicknameFormFieldCursor.update(
                state: state,
                action: action,
                environment: FormFieldEnvironment()
            )
        case .inviteCodeFormField(let action):
            return InviteCodeFormFieldCursor.update(
                state: state,
                action: action,
                environment: FormFieldEnvironment()
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
        case let .setFirstRunPath(path):
            var model = state
            model.firstRunPath = path
            return Update(state: model)
        case let .pushFirstRunStep(step):
            var model = state
            model.firstRunPath.append(step)
            
            return Update(state: model)
        case let .setAppUpgraded(isUpgraded):
            return setAppUpgraded(
                state: state,
                environment: environment,
                isUpgraded: isUpgraded
            )
        case let .setInviteCode(inviteCode):
            return setInviteCode(
                state: state,
                environment: environment,
                text: inviteCode
            )
        case .createSphere:
            return createSphere(
                state: state,
                environment: environment
            )
        case let .succeedCreateSphere(receipt):
            return succeedCreateSphere(
                state: state,
                environment: environment,
                receipt: receipt
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
        case .succeedRefreshSphereVersion(let version):
            return succeedRefreshSphereVersion(
                state: state,
                environment: environment,
                version: version
            )
        case .failRefreshSphereVersion(let error):
            return failRefreshSphereVersion(
                state: state,
                environment: environment,
                error: error
            )
        case let .setNickname(nickname):
            return setNickname(
                state: state,
                environment: environment,
                text: nickname
            )
        case let .persistNickname(nickname):
            return persistNickname(
                state: state,
                environment: environment,
                text: nickname
            )
        case let .requestCreateInitialProfile(nickname):
            return requestCreateInitialProfile(
                state: state,
                environment: environment,
                nickname: nickname
            )
        case .succeedCreateInitialProfile:
            logger.log("Wrote initial profile memo")
            return Update(state: state)
        case let .failCreateInitialProfile(message):
            logger.log("Failed to write initial profile memo: \(message)")
            return Update(state: state)
        case .fetchNicknameFromProfile:
            return fetchNicknameFromProfileMemo(state: state, environment: environment)
        case let .succeedFetchNicknameFromProfile(nickname):
            return update(
                state: state,
                action: .setNickname(nickname.verbatim),
                environment: environment
            )
        case let .failFetchNicknameFromProfile(message):
            logger.log("Failed to read nickname from profile: \(message)")
            return Update(state: state)
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
        case let .succeedResetGatewayURL(url):
            return succeedResetGatewayURL(
                state: state,
                environment: environment,
                url: url
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
        case let .notifyFirstRunComplete(isComplete):
            return notifyFirstRunComplete(
                state: state,
                environment: environment,
                isComplete: isComplete
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
        case .succeedResetNoosphereService:
            return succeedResetNoosphereService(
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
        case .indexOurSphere:
            return indexOurSphere(
                state: state,
                environment: environment
            )
        case let .succeedIndexOurSphere(version):
            return succeedIndexOurSphere(
                state: state,
                environment: environment,
                version: version
            )
        case let .failIndexOurSphere(error):
            return failIndexOurSphere(
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
        case .followDefaultGeist:
            return followDefaultGeist(
                state: state,
                environment: environment
            )
        case .succeedFollowDefaultGeist:
            return Update(state: state)
        case .failFollowDefaultGeist(let error):
            logger.error("Failed to follow default geist: \(error)")
            return Update(state: state)
            
        case .submitProvisionGatewayForm:
            switch (state.inviteCodeFormField.validated, state.gatewayId) {
            case (.some(let inviteCode), .none):
                return update(
                    state: state,
                    action: .requestProvisionGateway(inviteCode),
                    environment: environment
                )
            case _:
                return update(
                    state: state,
                    action: .requestGatewayProvisioningStatus,
                    environment: environment
                )
            }
        case .requestProvisionGateway(let inviteCode):
            return requestProvisionGateway(
                state: state,
                environment: environment,
                inviteCode: inviteCode
            )
        case .receiveGatewayId(let gatewayId):
            var model = state
            model.gatewayId = gatewayId
            AppDefaults.standard.gatewayId = gatewayId
            
            return update(
                state: model,
                action: .requestGatewayProvisioningStatus,
                environment: environment
            )
        case .requestGatewayProvisioningStatus:
            return requestGatewayProvisioningStatus(
                state: state,
                environment: environment
            )
        case .succeedProvisionGateway(let url):
            return succeedProvisionGateway(
                state: state,
                environment: environment,
                url: url
            )
        case .failProvisionGateway(let error):
            return failProvisionGateway(
                state: state,
                environment: environment,
                error: error
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
        
        var model = state
        
        model.gatewayURL = AppDefaults.standard.gatewayURL
        model.gatewayURLTextField = AppDefaults.standard.gatewayURL
        model.gatewayId = AppDefaults.standard.gatewayId
        
        // Update model from app defaults
        return update(
            state: model,
            actions: [
                .notifyNoosphereEnabled(
                    AppDefaults.standard.isNoosphereEnabled
                ),
                .setSphereIdentity(
                    AppDefaults.standard.sphereIdentity
                ),
                .notifyFirstRunComplete(
                    AppDefaults.standard.firstRunComplete
                ),
                .inviteCodeFormField(
                    .setValue(input: AppDefaults.standard.inviteCode ?? "")
                )
            ],
            environment: environment
        ).mergeFx(fx)
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
            "Noosphere enabled? \(AppDefaults.standard.isNoosphereEnabled)"
        )
        return update(
            state: state,
            actions: [
                .migrateDatabase,
                .refreshSphereVersion,
                .fetchNicknameFromProfile
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
    
    static func setNickname(
        state: AppModel,
        environment: AppEnvironment,
        text: String
    ) -> Update<AppModel> {
        /// First pass down setValue to form field,
        /// then persist the nickname by reading the updated model.
        return update(
            state: state,
            actions: [
                .nicknameFormField(.setValue(input: text)),
                .persistNickname(text)
            ],
            environment: environment
        )
    }

    static func persistNickname(
        state: AppModel,
        environment: AppEnvironment,
        text: String
    ) -> Update<AppModel> {
        // Persist any valid value
        if let validated = state.nicknameFormField.validated {
            var model = state
            model.nickname = validated.description
            logger.log("Nickname saved: \(validated)")
            
            return update(
                state: model,
                action: .requestCreateInitialProfile(text),
                environment: environment
            )
        }
        
        // Otherwise, just return state
        return Update(state: state)
    }
    
    static func requestCreateInitialProfile(
        state: AppModel,
        environment: AppEnvironment,
        nickname: String
    ) -> Update<AppModel> {
        let fx: Fx<AppAction> = Future.detached {
            try await environment.userProfile.requestSetOurInitialNickname(nickname: nickname)
            return AppAction.succeedCreateInitialProfile
        }
        .recover { error in
            return AppAction.failCreateInitialProfile(error.localizedDescription)
        }
        .eraseToAnyPublisher()
        
        return Update(state: state, fx: fx)
    }
    
    static func fetchNicknameFromProfileMemo(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        let fx: Fx<AppAction> = Future.detached {
            let response = try await environment.userProfile.requestOurProfile()
            return AppAction.succeedFetchNicknameFromProfile(response.profile.nickname)
        }
        .recover { error in
            AppAction.failFetchNicknameFromProfile(error.localizedDescription)
        }
        .eraseToAnyPublisher()
        
        return Update(state: state, fx: fx)
    }
    
    static func setInviteCode(
        state: AppModel,
        environment: AppEnvironment,
        text: String
    ) -> Update<AppModel> {
        
        return update(
            state: state,
            actions: [
                .inviteCodeFormField(.setValue(input: text))
            ],
            environment: environment
        )
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
        let fx: Fx<AppAction> = Future.detached {
            await environment.noosphere.resetGateway(url: url)
            return .succeedResetGatewayURL(url)
        }
        .eraseToAnyPublisher()

        /// Only set valid nicknames
        return Update(state: model, fx: fx)
    }

    static func succeedResetGatewayURL(
        state: AppModel,
        environment: AppEnvironment,
        url: URL
    ) -> Update<AppModel> {
        logger.log("Reset gateway URL: \(url)")
        return Update(state: state)
    }

    static func createSphere(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        // We always use the default owner key name for the user's default
        // sphere.
        let ownerKeyName = Config.default.noosphere.ownerKeyName

        let fx: Fx<AppAction> = Future.detached {
            let receipt = try await environment.data.createSphere(
                ownerKeyName: ownerKeyName
            )
            return AppAction.succeedCreateSphere(receipt)
        }
        .recover({ error in
            AppAction.failCreateSphere(error.localizedDescription)
        })
        .eraseToAnyPublisher()

        return Update(state: state, fx: fx)
    }

    static func succeedCreateSphere(
        state: AppModel,
        environment: AppEnvironment,
        receipt: SphereReceipt
    ) -> Update<AppModel> {
        var actions: [AppAction] = [
            .setSphereIdentity(receipt.identity),
            .setRecoveryPhrase(receipt.mnemonic),
            .followDefaultGeist,
        ]
        
        if let inviteCode = state.inviteCodeFormField.validated {
            actions.append(.requestProvisionGateway(inviteCode))
        }
        
        return update(
            state: state,
            actions: actions,
            environment: environment
        )
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
        let fx: Fx<AppAction> = environment.noosphere.versionPublisher()
            .map({ version in
                .succeedRefreshSphereVersion(version)
            }).recover({ error in
                .failRefreshSphereVersion(error.localizedDescription)
            }).eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }

    static func succeedRefreshSphereVersion(
        state: AppModel,
        environment: AppEnvironment,
        version: String
    ) -> Update<AppModel> {
        var model = state
        model.sphereVersion = version
        logger.debug("Refreshed sphere version: \(version)")
        return Update(state: model)
    }

    static func failRefreshSphereVersion(
        state: AppModel,
        environment: AppEnvironment,
        error: String
    ) -> Update<AppModel> {
        logger.log("Failed to refresh sphere version: \(error)")
        return Update(state: state)
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
    
    /// Set first run complete state on model, but do not persist.
    /// The value is understood to have been persisted already, or is being
    /// reloaded from persisted state.
    static func notifyFirstRunComplete(
        state: AppModel,
        environment: AppEnvironment,
        isComplete: Bool
    ) -> Update<AppModel> {
        var model = state
        model.isFirstRunComplete = isComplete
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
        
        // Reset navigation
        if !isComplete {
            model.firstRunPath = []
        }
        
        return Update(state: model).animation(.default)
    }

    /// Reset NoosphereService managed instances of `Noosphere` and `Sphere`.
    static func resetNoosphereService(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        let fx: Fx<AppAction> = Future.detached {
            await environment.noosphere.reset()
            return .succeedResetNoosphereService
        }
        .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }

    static func succeedResetNoosphereService(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        logger.log("Reset noosphere service")
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
                .migratePublisher()
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

        let fx: Fx<AppAction> = environment.data.rebuildPublisher().map({
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
            let sphereIdentity = try state.sphereIdentity.unwrap()
            let did = try Did(sphereIdentity).unwrap()
            let sphereVersion = try environment.database.readSphereSyncInfo(
                sphereIdentity: did
            ).unwrap()
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
        var model = state
        model.lastGatewaySyncStatus = .pending
        logger.log("Syncing with gateway: \(model.gatewayURL)")
        let fx: Fx<AppAction> = environment.noosphere.syncPublisher()
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
            action: .indexOurSphere,
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
            action: .indexOurSphere,
            environment: environment
        )
    }
    
    static func indexOurSphere(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        let fx: Fx<AppAction> = environment.data.indexOurSpherePublisher().map({
            version in
            AppAction.succeedIndexOurSphere(version: version)
        }).catch({ error in
            Just(
                AppAction.failIndexOurSphere(error.localizedDescription)
            )
        }).eraseToAnyPublisher()
        
        var model = state
        model.sphereSyncStatus = .pending
        return Update(state: model, fx: fx)
    }
    
    static func succeedIndexOurSphere(
        state: AppModel,
        environment: AppEnvironment,
        version: String
    ) -> Update<AppModel> {
        let identity = state.sphereIdentity ?? "unknown"
        logger.log("Database indexed sphere \(identity) @ \(version)")
        
        var model = state
        model.sphereSyncStatus = .succeeded
        
        return update(
            state: model,
            action: .setAppUpgradeComplete(model.isSyncAllResolved),
            environment: environment
        )
    }
    
    static func failIndexOurSphere(
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

        let fx: Fx<AppAction> = environment.data.syncLocalWithDatabasePublisher().map({
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
    
    static func followDefaultGeist(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        let fx: Fx<AppAction> = environment.addressBook
            .followUserPublisher(
                did: Config.default.subconsciousGeistDid,
                petname: Config.default.subconsciousGeistPetname
            )
            .map {
                AppAction.succeedFollowDefaultGeist
            }
            .recover { error in
                AppAction.failFollowDefaultGeist(error.localizedDescription)
            }
            .eraseToAnyPublisher()
        
        return Update(state: state, fx: fx)
    }
    
    static func requestProvisionGateway(
        state: AppModel,
        environment: AppEnvironment,
        inviteCode: InviteCode
    ) -> Update<AppModel> {
        guard let did = state.sphereIdentity,
              let did = Did(did) else {
            return Update(state: state)
        }
        
        let fx: Fx<AppAction> =
            environment.gatewayProvisioningService
            .provisionGatewayPublisher(
                inviteCode: inviteCode,
                sphere: did
            )
            .map { res in
                .receiveGatewayId(res.gateway_id)
            }
            .recover { error in
                .failProvisionGateway(error.localizedDescription)
            }
            .eraseToAnyPublisher()
        
        var model = state
        model.gatewayProvisioningStatus = .pending
        AppDefaults.standard.inviteCode = inviteCode.description
        
        return Update(state: model, fx: fx)
    }
    
    static func requestGatewayProvisioningStatus(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        guard let gatewayId = state.gatewayId else {
            return Update(state: state)
        }
        
        var model = state
        model.gatewayProvisioningStatus = .pending
        
        let fx: Fx<AppAction> = environment.gatewayProvisioningService
            .waitForGatewayProvisioningPublisher(
                gatewayId: gatewayId
            )
            .map { url in
                guard let url = url else {
                    return AppAction.failProvisionGateway("Timed out waiting for URL")
                }
                
                return AppAction.completeProvisionGateway(url)
            }
            .recover { err in
                AppAction.failProvisionGateway(err.localizedDescription)
            }
            .eraseToAnyPublisher()
        
        return Update(state: model, fx: fx)
    }
    
    static func succeedProvisionGateway(
        state: AppModel,
        environment: AppEnvironment,
        url: URL
    ) -> Update<AppModel> {
        var model = state
        model.gatewayProvisioningStatus = .succeeded
        
        return update(
            state: model,
            actions: [
                .submitGatewayURL(url.absoluteString),
                .syncSphereWithGateway
            ],
            environment: environment
        )
    }
    
    static func failProvisionGateway(
        state: AppModel,
        environment: AppEnvironment,
        error: String
    ) -> Update<AppModel> {
        logger.error("Failed to provision gateway: \(error)")
        var model = state
        model.gatewayProvisioningStatus = .failed(error)
        
        return Update(state: model)
    }
}

// MARK: Environment
/// A place for constants and services
struct AppEnvironment {
    /// Default environment constant
    static let `default` = AppEnvironment()

    var documentURL: URL
    var applicationSupportURL: URL

    var noosphere: NoosphereService
    var database: DatabaseService
    var data: DataService
    var feed: FeedService
    
    var recoveryPhrase: RecoveryPhraseEnvironment = RecoveryPhraseEnvironment()
    
    var addressBook: AddressBookService
    var userProfile: UserProfileService
    
    var gatewayProvisioningService: GatewayProvisioningService
    
    var pasteboard = UIPasteboard.general
    
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
        self.noosphere = noosphere

        let databaseURL = self.applicationSupportURL
            .appendingPathComponent("database.sqlite")

        let database = DatabaseService(
            database: SQLite3Database(
                path: databaseURL.absoluteString,
                mode: .readwrite
            ),
            migrations: Config.migrations
        )
        self.database = database
        
        let addressBook = AddressBookService(
            noosphere: noosphere,
            database: database
        )
        self.addressBook = addressBook
        
        self.userProfile = UserProfileService(
            noosphere: noosphere,
            database: database,
            addressBook: addressBook
        )
        
        self.data = DataService(
            noosphere: noosphere,
            database: database,
            local: local,
            addressBook: addressBook
        )
        
        self.feed = FeedService()
        self.gatewayProvisioningService = GatewayProvisioningService()
    }
}

