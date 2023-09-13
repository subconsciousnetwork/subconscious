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
                if AppDefaults.standard.appTabs {
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
                get: { store.state.shouldPresentRecovery },
                set: { v in store.send(.presentRecovery(v))}
            )
        ) {
            RecoveryView(app: store)
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
typealias NicknameFormField = FormField<String, Petname.Name>
typealias GatewayUrlFormField = FormField<String, URL>
typealias RecoveryPhraseFormField = FormField<String, RecoveryPhrase>
typealias RecoveryDidFormField = FormField<String, Did>

// MARK: Action
enum AppAction: CustomLogStringConvertible {
    /// Sent immediately upon store creation
    case start

    case recoveryPhrase(RecoveryPhraseAction)
    case appUpgrade(AppUpgradeAction)
    case nicknameFormField(NicknameFormField.Action)
    case inviteCodeFormField(InviteCodeFormField.Action)
    case gatewayURLField(GatewayUrlFormField.Action)
    case recoveryPhraseField(RecoveryPhraseFormField.Action)
    case recoveryDidField(RecoveryDidFormField.Action)

    /// Scene phase events
    /// See https://developer.apple.com/documentation/swiftui/scenephase
    case scenePhaseChange(ScenePhase)

    /// On view appear
    case appear

    case setAppUpgraded(_ isUpgraded: Bool)

    /// Set sphere/user nickname
    /// Sets form field, and persists if needed.
    case setNickname(_ nickname: String)
    case submitNickname(_ nickname: Petname.Name)
    
    /// Write to `Slashlink.ourProfile` during onboarding
    case updateOurProfileWithNickname(_ nickname: Petname.Name)
    case succeedCreateUpdateNickname
    case failUpdateNickname(_ message: String)
    
    case fetchNicknameFromProfile
    case succeedFetchNicknameFromProfile(_ nickname: Petname.Name)
    case failFetchNicknameFromProfile(_ message: String)
    
    /// Set gateway URL
    case submitGatewayURL(_ url: URL)
    case submitGatewayURLForm
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

    /// Index current sphere state to database. Sphere always wins.
    /// This indexes everything from the sphere update, including memo
    /// and petname changes.
    case indexOurSphere
    case succeedIndexOurSphere(OurSphereRecord)
    case failIndexOurSphere(String)
    
    /// Sync database with file system.
    /// File system always wins.
    case syncLocalFilesWithDatabase
    case succeedSyncLocalFilesWithDatabase([FileFingerprintChange])
    case failSyncLocalFilesWithDatabase(String)
    
    /// Begin indexing peer content one-by-one.
    /// Should be called _after_ indexing our own sphere (which updates the
    /// peers information in our address book).
    case collectPeersToIndex
    case succeedCollectPeersToIndex([PeerRecord])
    case failCollectPeersToIndex(_ error: String)

    /// Index the contents of a sphere in the database
    case indexPeer(_ petname: Petname)
    case succeedIndexPeer(_ peer: PeerRecord)
    case failIndexPeer(petname: Petname, error: Error)

    /// Purge the contents of a sphere from the database
    case purgePeer(_ did: Did)
    case succeedPurgePeer(_ did: Did)
    case failPurgePeer(_ error: String)

    case followDefaultGeist
    case succeedFollowDefaultGeist
    case failFollowDefaultGeist(String)
    
    /// Invite code
    case submitInviteCodeForm
    case requestRedeemInviteCode(_ inviteCode: InviteCode)
    case succeedRedeemInviteCode(_ gatewayId: String)
    case failRedeemInviteCode(_ error: String)
    
    /// Check gateway
    case requestGatewayProvisioningStatus
    case succeedProvisionGateway(_ gatewayURL: URL)
    case failProvisionGateway(_ error: String)
    
    case setFirstRunPath([FirstRunStep])
    case pushFirstRunStep(FirstRunStep)
    
    case submitFirstRunWelcomeStep
    case submitFirstRunProfileStep
    case submitFirstRunSphereStep
    case submitFirstRunRecoveryStep
    case submitFirstRunDoneStep
    
    case requestOfflineMode

    /// Set settings sheet presented?
    case presentSettingsSheet(_ isPresented: Bool)
    
    case checkRecoveryStatus
    case presentRecovery(_ isPresented: Bool)
    
    /// Notification that a follow happened, and the sphere was resolved
    case notifySucceedResolveFollowedUser(petname: Petname, cid: Cid?)
    /// Notification that an unfollow happened somewhere else
    case notifySucceedUnfollow(identity: Did, petname: Petname)
    
    case authorization(_ action: AuthorizationSettingsAction)
    
    //  Note management actions.
    //  These actions manage note actions which have an effect on the global
    //  list of notes (deletion, creation, etc).
    //
    //  Other components may subscribe to the app store actions publisher to
    //  be notified when these global things change.
    //
    //  The general pattern is to send a "request" action in the component's
    //  own store, and then replay these as equivalent actions on the app
    //  store. The component subscribes to the app store's actions publisher
    //  and responds to "succeed" actions.
    /// Attempt to delete a memo
    case deleteMemo(Slashlink?)
    /// Deletion attempt failed
    case failDeleteMemo(String)
    /// Deletion attempt succeeded
    case succeedDeleteMemo(Slashlink)
    
    case setSelectedAppTab(AppTab)
    case requestNotebookRoot
    case requestFeedRoot
    
    case setAppTabsEnabled(Bool)

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
        case let .succeedCreateSphere(receipt):
            // !!!: Do not log mnemonic
            // The user's sphere mnemonic is carried with this sphere receipt.
            // It is a secret and should never be logged.
            return "succeedCreateSphere(\(receipt.identity))"
        default:
            return String(describing: self)
        }
    }
}

extension AppAction {
    public static func from(action: UserProfileDetailAction) -> AppAction? {
        switch action {
        case .refresh(let forceSync) where forceSync:
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

struct GatewayUrlFormFieldCursor: CursorProtocol {
    typealias Model = AppModel
    typealias ViewModel = GatewayUrlFormField
    
    static func get(state: Model) -> ViewModel {
        state.gatewayURLField
    }
    
    static func set(state: Model, inner: ViewModel) -> Model {
        var model = state
        model.gatewayURLField = inner
        return model
    }
    
    static func tag(_ action: ViewModel.Action) -> Model.Action {
        switch action {
        default:
            return .gatewayURLField(action)
        }
    }
}

struct RecoveryPhraseFormFieldCursor: CursorProtocol {
    typealias Model = AppModel
    typealias ViewModel = RecoveryPhraseFormField
    
    static func get(state: Model) -> ViewModel {
        state.recoveryPhraseField
    }
    
    static func set(state: Model, inner: ViewModel) -> Model {
        var model = state
        model.recoveryPhraseField = inner
        return model
    }
    
    static func tag(_ action: ViewModel.Action) -> Model.Action {
        switch action {
        default:
            return .recoveryPhraseField(action)
        }
    }
}

struct RecoveryDidFormFieldCursor: CursorProtocol {
    typealias Model = AppModel
    typealias ViewModel = RecoveryDidFormField
    
    static func get(state: Model) -> ViewModel {
        state.recoveryDidField
    }
    
    static func set(state: Model, inner: ViewModel) -> Model {
        var model = state
        model.recoveryDidField = inner
        return model
    }
    
    static func tag(_ action: ViewModel.Action) -> Model.Action {
        switch action {
        default:
            return .recoveryDidField(action)
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
        default:
            return .inviteCodeFormField(action)
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
    case profile
    case sphere
    case recovery
    case done
}

// MARK: Model
struct AppModel: ModelProtocol {
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
        !isFirstRunComplete
    }
    
    var shouldPresentRecovery: Bool = false
    
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
    /// stored in the user's `_profile_` memo.
    var nickname = ""
    /// Nickname form
    ///
    /// This property is updated at `.start` with the corresponding value
    /// stored in the user's `_profile_` memo.
    var nicknameFormField = NicknameFormField(
        value: "",
        validate: { value in Petname.Name(value) }
    )
    
    var inviteCode: InviteCode?
    var inviteCodeFormField = InviteCodeFormField(
        value: "",
        validate: { value in InviteCode(value) }
    )
    var inviteCodeRedemptionStatus = ResourceStatus.initial
    var gatewayProvisioningStatus = ResourceStatus.initial
    var appTabsEnabled = false
    
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
    
    var authorization = AuthorizationSettingsModel()
    
    /// Preferred Gateway URL.
    ///
    /// This property is updated at `.start` with the corresponding value
    /// stored in `AppDefaults`.
    var gatewayURL = ""
    var gatewayId: String? = nil
    var gatewayURLField = GatewayUrlFormField(
        value: "",
        validate: { value in
            guard let url = URL(string: value),
                  url.isHTTP() else {
                return nil
            }
            
            return url
        }
    )
    var lastGatewaySyncStatus = ResourceStatus.initial
    
    var recoveryPhraseField = RecoveryPhraseFormField(
        value: "",
        validate: { value in RecoveryPhrase(value) }
    )
    
    var recoveryDidField = RecoveryDidFormField(
        value: "",
        validate: { value in Did(value) }
    )
    
    var gatewayOperationInProgress: Bool {
        lastGatewaySyncStatus == .pending ||
        inviteCodeRedemptionStatus == .pending ||
        gatewayProvisioningStatus == .pending
    }
    
    /// Show settings sheet?
    var isSettingsSheetPresented = false
    
    /// Determine if the interface is ready for user interaction,
    /// even if all of the data isn't refreshed yet.
    /// This is the point at which the main interface is ready to be shown.
    var isReadyForInteraction: Bool {
        self.databaseMigrationStatus == .succeeded
    }
    
    var selectedAppTab: AppTab = .feed
    
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
        case .gatewayURLField(let action):
            return GatewayUrlFormFieldCursor.update(
                state: state,
                action: action,
                environment: FormFieldEnvironment()
            )
        case .recoveryPhraseField(let action):
            return RecoveryPhraseFormFieldCursor.update(
                state: state,
                action: action,
                environment: FormFieldEnvironment()
            )
        case .recoveryDidField(let action):
            return RecoveryDidFormFieldCursor.update(
                state: state,
                action: action,
                environment: FormFieldEnvironment()
            )
        case .authorization(let action):
            return AuthorizationSettingsCursor.update(
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
        case let .setFirstRunPath(path):
            var model = state
            model.firstRunPath = path
            return Update(state: model)
        case let .pushFirstRunStep(step):
            var model = state
            model.firstRunPath.append(step)
            
            return Update(state: model)
        case .submitFirstRunWelcomeStep:
            return submitFirstRunWelcomeStep(
                state: state,
                environment: environment
            )
        case .submitFirstRunProfileStep:
            return submitFirstRunProfileStep(
                state: state,
                environment: environment
            )
        case .submitFirstRunSphereStep:
            return submitFirstRunSphereStep(
                state: state,
                environment: environment
            )
        case .submitFirstRunRecoveryStep:
            return submitFirstRunRecoveryStep(
                state: state,
                environment: environment
            )
        case .submitFirstRunDoneStep:
            return submitFirstRunDoneStep(
                state: state,
                environment: environment
            )
        case .requestOfflineMode:
            return requestOfflineMode(
                state: state,
                environment: environment
            )
        case let .setAppUpgraded(isUpgraded):
            return setAppUpgraded(
                state: state,
                environment: environment,
                isUpgraded: isUpgraded
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
        case .submitNickname(let nickname):
            return submitNickname(
                state: state,
                environment: environment,
                nickname: nickname
            )
        case let .updateOurProfileWithNickname(nickname):
            return updateOurProfileWithNickname(
                state: state,
                environment: environment,
                nickname: nickname
            )
        case .succeedCreateUpdateNickname:
            logger.log("Wrote initial profile memo")
            return Update(state: state)
        case let .failUpdateNickname(message):
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
        case .submitGatewayURL(let url):
            return submitGatewayURL(
                state: state,
                environment: environment,
                url: url
            )
        case .submitGatewayURLForm:
            return submitGatewayURLForm(
                state: state,
                environment: environment
            )
        case let .succeedResetGatewayURL(url):
            return succeedResetGatewayURL(
                state: state,
                environment: environment,
                url: url
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
        case let .succeedIndexOurSphere(receipt):
            return succeedIndexOurSphere(
                state: state,
                environment: environment,
                receipt: receipt
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
        case .collectPeersToIndex:
            return collectPeersToIndex(
                state: state,
                environment: environment
            )
        case .succeedCollectPeersToIndex(let peers):
            return succeedCollectPeersToIndex(
                state: state,
                environment: environment,
                peers: peers
            )
        case .failCollectPeersToIndex(let error):
            return failCollectPeersToIndex(
                state: state,
                environment: environment,
                error: error
            )
        case .indexPeer(let petname):
            return indexPeer(
                state: state,
                environment: environment,
                petname: petname
            )
        case .succeedIndexPeer(let peer):
            return succeedIndexPeer(
                state: state,
                environment: environment,
                peer: peer
            )
        case let .failIndexPeer(petname, error):
            return failIndexPeer(
                state: state,
                environment: environment,
                petname: petname,
                error: error
            )
        case .purgePeer(let identity):
            return purgePeer(
                state: state,
                environment: environment,
                identity: identity
            )
        case .succeedPurgePeer(let identity):
            return succeedPurgePeer(
                state: state,
                environment: environment,
                identity: identity
            )
        case .failPurgePeer(let error):
            return failPurgePeer(
                state: state,
                environment: environment,
                error: error
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
            
        case .submitInviteCodeForm:
            guard let inviteCode = state.inviteCodeFormField.validated else {
                logger.log("Invalid invite code submitted")
                return Update(state: state)
            }
            
            var model = state
            model.inviteCode = inviteCode
            AppDefaults.standard.inviteCode = inviteCode.description
            
            return update(
                state: model,
                action: .requestRedeemInviteCode(inviteCode),
                environment: environment
            )
        case .requestRedeemInviteCode(let inviteCode):
            return requestRedeemInviteCode(
                state: state,
                environment: environment,
                inviteCode: inviteCode
            )
        case .succeedRedeemInviteCode(let gatewayId):
            return succeedRedeemInviteCode(
                state: state,
                environment: environment,
                gatewayId: gatewayId
            )
        case .failRedeemInviteCode(let error):
            return failRedeemInviteCode(
                state: state,
                environment: environment,
                error: error
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
        case let .notifySucceedResolveFollowedUser(petname, cid):
            return notifySucceedResolveFollowedUser(
                state: state,
                environment: environment,
                petname: petname,
                cid: cid
            )
        case let .notifySucceedUnfollow(did, petname):
            return notifySucceedUnfollow(
                state: state,
                environment: environment,
                identity: did,
                petname: petname
            )
        case let .deleteMemo(address):
            return deleteMemo(
                state: state,
                environment: environment,
                address: address
            )
        case let .failDeleteMemo(error):
            return failDeleteMemo(
                state: state,
                environment: environment,
                error: error
            )
        case let .succeedDeleteMemo(address):
            return succeedDeleteMemo(
                state: state,
                environment: environment,
                address: address
            )
        case .setSelectedAppTab(let tab):
            return setSelectedAppTab(
                state: state,
                environment: environment,
                tab: tab
            )
        case .requestNotebookRoot:
            return Update(state: state)
        case .requestFeedRoot:
            return Update(state: state)
        case .setAppTabsEnabled(let enabled):
            return setAppTabsEnabled(
                state: state,
                environment: environment,
                enabled: enabled
            )
        case .checkRecoveryStatus:
            return checkRecoveryStatus(
                state: state,
                environment: environment
            )
        case .presentRecovery(let presented):
            return presentRecovery(
                state: state,
                environment: environment,
                presented: presented
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
        var model = state
        
        model.gatewayURL = AppDefaults.standard.gatewayURL
        model.gatewayId = AppDefaults.standard.gatewayId
        model.inviteCode = InviteCode(AppDefaults.standard.inviteCode ?? "")
        model.appTabsEnabled = AppDefaults.standard.appTabs
        
        // Update model from app defaults
        return update(
            state: model,
            actions: [
                .setSphereIdentity(
                    AppDefaults.standard.sphereIdentity
                ),
                .notifyFirstRunComplete(
                    AppDefaults.standard.firstRunComplete
                ),
                .gatewayURLField(
                    .setValue(input: AppDefaults.standard.gatewayURL)
                )
            ],
            environment: environment
        )
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
        let sphereIdentity = state.sphereIdentity ?? "nil"
        logger.debug(
            "appear",
            metadata: [
                "documents": environment.documentURL.absoluteString,
                "database": environment.database.database.path,
                "sphereIdentity": sphereIdentity
            ]
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
            ],
            environment: environment
        )
    }

    static func submitNickname(
        state: AppModel,
        environment: AppEnvironment,
        nickname: Petname.Name
    ) -> Update<AppModel> {
        // Persist any valid value
        var model = state
        model.nickname = nickname.description
        logger.log("Nickname saved: \(nickname)")
        
        return update(
            state: model,
            actions: [
                .updateOurProfileWithNickname(nickname),
                .nicknameFormField(.setValue(input: nickname.description))
            ],
            environment: environment
        )
    }
    
    static func updateOurProfileWithNickname(
        state: AppModel,
        environment: AppEnvironment,
        nickname: Petname.Name
    ) -> Update<AppModel> {
        let fx: Fx<AppAction> = Future.detached {
            try await environment.userProfile.updateOurNickname(nickname: nickname)
            return AppAction.succeedCreateUpdateNickname
        }
        .recover { error in
            return AppAction.failUpdateNickname(error.localizedDescription)
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
            if let nickname = response.profile.nickname {
                return AppAction.succeedFetchNicknameFromProfile(nickname)
            }
            
            return AppAction.failFetchNicknameFromProfile("No nickname saved in profile")
        }
        .recover { error in
            AppAction.failFetchNicknameFromProfile(error.localizedDescription)
        }
        .eraseToAnyPublisher()
        
        return Update(state: state, fx: fx)
    }
    
    static func submitGatewayURL(
        state: AppModel,
        environment: AppEnvironment,
        url: URL
    ) -> Update<AppModel> {
        // We always ensure the field reflects this value
        // even if nothing changes from a Noosphere perspective
        let actions: [AppAction] = [
            .gatewayURLField(.reset),
            .gatewayURLField(
                .setValue(input: url.absoluteString)
            )
        ]
        
        guard state.gatewayURL != url.absoluteString else {
            logger.log("Gateway URL is identical to current value, doing nothing")
            return update(
                state: state,
                actions: actions,
                environment: environment
            )
        }
        
        var model = state
        model.gatewayURL = url.absoluteString

        // Persist to UserDefaults
        AppDefaults.standard.gatewayURL = url.absoluteString

        // Reset gateway on environment
        let fx: Fx<AppAction> = Future.detached {
            await environment.noosphere.resetGateway(url: url)
            return .succeedResetGatewayURL(url)
        }.eraseToAnyPublisher()
        
        return update(
            state: model,
            actions: actions,
            environment: environment
        )
        .mergeFx(fx)
    }
    
    static func submitGatewayURLForm(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        guard let url = state.gatewayURLField.validated else {
            logger.log("Gateway URL field is invalid, doing nothing")
            return Update(state: state)
        }
        
        return update(
            state: state,
            actions: [
                .submitGatewayURL(url),
                .syncSphereWithGateway
            ],
            environment: environment
        )
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
        guard state.sphereIdentity == nil else {
            logger.log("Attempted to re-create sphere, doing nothing")
            return Update(state: state)
        }
        
        // We always use the default owner key name for the user's default
        // sphere.
        let ownerKeyName = Config.default.noosphere.ownerKeyName
        
        let fx: Fx<AppAction> = Future.detached {
            let receipt = try await environment.data.createSphere(
                ownerKeyName: ownerKeyName
            )
            return AppAction.succeedCreateSphere(receipt)
        }.recover({ error in
            AppAction.failCreateSphere(error.localizedDescription)
        }).eraseToAnyPublisher()
        
        return Update(state: state, fx: fx)
    }
    
    static func succeedCreateSphere(
        state: AppModel,
        environment: AppEnvironment,
        receipt: SphereReceipt
    ) -> Update<AppModel> {
        return update(
            state: state,
            actions: [
                .setSphereIdentity(receipt.identity),
                .setRecoveryPhrase(receipt.mnemonic),
                .followDefaultGeist
            ],
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
        return update(
            state: model,
            action: .recoveryDidField(.setValue(input: sphereIdentity ?? "")),
            environment: environment
        )
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
    
    static func requestOfflineMode(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        var model = state
        model.inviteCode = nil
        model.gatewayId = nil
        
        return update(
            state: model,
            actions: [
                .inviteCodeFormField(.reset),
                .submitFirstRunWelcomeStep
            ],
            environment: environment
        )
    }
    
    static func submitFirstRunWelcomeStep(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        guard state.inviteCode == nil || // Offline mode: no code
              state.gatewayId != nil // Otherwise we need an ID to proceed
        else {
            logger.error("Missing gateway ID but user is trying to use invite code")
            return Update(state: state)
        }
        
        return update(
            state: state,
            actions: [
                .pushFirstRunStep(.profile)
            ],
            environment: environment
        )
    }
    
    static func submitFirstRunProfileStep(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        guard let nickname = state.nicknameFormField.validated else {
            logger.error("Cannot advance, nickname is invalid")
            return Update(state: state)
        }
        
        return update(
            state: state,
            actions: [
                .submitNickname(nickname),
                .pushFirstRunStep(.sphere)
            ],
            environment: environment
        )
    }
    
    static func submitFirstRunSphereStep(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        return update(
            state: state,
            actions: [
                .pushFirstRunStep(.recovery)
            ],
            environment: environment
        )
    }
    
    static func submitFirstRunRecoveryStep(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        return update(
            state: state,
            actions: [
                .pushFirstRunStep(.done)
            ],
            environment: environment
        )
    }
    
    static func submitFirstRunDoneStep(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        return update(
            state: state,
            actions: [
                .inviteCodeFormField(.reset),
                .nicknameFormField(.reset),
                .persistFirstRunComplete(true)
            ],
            environment: environment
        )
    }
    
    /// Reset NoosphereService managed instances of `Noosphere` and `Sphere`.
    static func resetNoosphereService(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        let fx: Fx<AppAction> = Future.detached {
            await environment.noosphere.reset()
            return .succeedResetNoosphereService
        }.eraseToAnyPublisher()
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
            let info: OurSphereRecord = try environment.database
                .readOurSphere()
                .unwrap()
            logger.log(
                "Last index for our sphere",
                metadata: [
                    "identity": info.identity.description,
                    "version": info.since
                ]
            )
        } catch {
            logger.log(
                "Last index for our sphere",
                metadata: [
                    "identity": "nil",
                    "version": "nil"
                ]
            )
        }
        // For now, we just sync everything on ready.
        return update(
            state: state,
            actions: [.syncAll, .checkRecoveryStatus],
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
        logger.log(
            "Syncing with gateway",
            metadata: [
                "url": model.gatewayURL
            ]
        )
        let fx: Fx<AppAction> = environment.noosphere.syncPublisher(
        ).map({ version in
            AppAction.succeedSyncSphereWithGateway(version: version)
        }).catch({ error in
            Just(AppAction.failSyncSphereWithGateway(error.localizedDescription))
        }).eraseToAnyPublisher()
        return Update(state: model, fx: fx)
    }
    
    static func succeedSyncSphereWithGateway(
        state: AppModel,
        environment: AppEnvironment,
        version: String
    ) -> Update<AppModel> {
        logger.log(
            "Synced our sphere with gateway",
            metadata: [
                "version": version
            ]
        )
        
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
        logger.log(
            "Sphere failed to sync with gateway",
            metadata: [
                "error": error
            ]
        )
        
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
        let fx: Fx<AppAction> = Future.detached(priority: .utility) {
            do {
                let record = try await environment.data.indexOurSphere()
                return Action.succeedIndexOurSphere(record)
            } catch {
                return Action.failIndexOurSphere(error.localizedDescription)
            }
        }.eraseToAnyPublisher()
        
        var model = state
        model.sphereSyncStatus = .pending
        return Update(state: model, fx: fx)
    }
    
    static func succeedIndexOurSphere(
        state: AppModel,
        environment: AppEnvironment,
        receipt: OurSphereRecord
    ) -> Update<AppModel> {
        logger.log(
            "Indexed our sphere",
            metadata: [
                "identity": receipt.identity.description,
                "version": receipt.since
            ]
        )
        
        var model = state
        model.sphereSyncStatus = .succeeded
        
        return update(
            state: model,
            actions: [
                .setAppUpgradeComplete(model.isSyncAllResolved),
                .collectPeersToIndex
            ],
            environment: environment
        )
    }
    
    static func failIndexOurSphere(
        state: AppModel,
        environment: AppEnvironment,
        error: String
    ) -> Update<AppModel> {
        logger.log(
            "Failed to index our sphere to database",
            metadata: [
                "error": error
            ]
        )
        
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
    
    /// Index a sphere to the database
    static func collectPeersToIndex(
        state: Self,
        environment: Environment
    ) -> Update<Self> {
        logger.log(
            "Collecting peers to index",
            metadata: [:]
        )
        let fx: Fx<Action> = Future.detached {
            do {
                let peers = try environment.database.listPeers()
                return Action.succeedCollectPeersToIndex(peers)
            } catch {
                return Action.failCollectPeersToIndex(
                    error.localizedDescription
                )
            }
        }.eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }
    
    /// Index a sphere to the database
    static func succeedCollectPeersToIndex(
        state: Self,
        environment: Environment,
        peers: [PeerRecord]
    ) -> Update<Self> {
        // Transform list of peers into fx publisher of actions.
        let fx: Fx<Action> = peers
            .map({ peer in Action.indexPeer(peer.petname) })
            .publisher
            .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }
    
    /// Index a sphere to the database
    static func failCollectPeersToIndex(
        state: Self,
        environment: Environment,
        error: String
    ) -> Update<Self> {
        logger.log(
            "Failed to collect peers to index",
            metadata: [
                "error": error
            ]
        )
        return Update(state: state)
    }
    
    /// Index a sphere to the database
    static func indexPeer(
        state: Self,
        environment: Environment,
        petname: Petname
    ) -> Update<Self> {
        logger.log(
            "Indexing peer",
            metadata: [
                "petname": petname.description
            ]
        )
        let fx: Fx<Action> = Future.detached(priority: .background) {
            do {
                let peer = try await environment.data.indexPeer(
                    petname: petname
                )
                return Action.succeedIndexPeer(peer)
            } catch {
                return Action.failIndexPeer(
                    petname: petname,
                    error: error
                )
            }
            
        }.eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }
    
    static func succeedIndexPeer(
        state: Self,
        environment: Environment,
        peer: PeerRecord
    ) -> Update<Self> {
        logger.log(
            "Indexed peer",
            metadata: [
                "petname": peer.petname.description,
                "identity": peer.identity.description,
                "since": peer.since ?? "nil"
            ]
        )
        return Update(state: state)
    }
    
    static func failIndexPeer(
        state: Self,
        environment: Environment,
        petname: Petname,
        error: Error
    ) -> Update<Self> {
        logger.log(
            "Failed to index peer",
            metadata: [
                "petname": petname.description,
                "error": error.localizedDescription
            ]
        )
        return Update(state: state)
    }
    
    static func purgePeer(
        state: Self,
        environment: Environment,
        identity: Did
    ) -> Update<Self> {
        let fx: Fx<Action> = Future.detached(priority: .utility) {
            do {
                try environment.database.purgePeer(
                    identity: identity
                )
                return Action.succeedPurgePeer(identity)
            } catch {
                return Action.failPurgePeer(error.localizedDescription)
            }
        }.eraseToAnyPublisher()
        logger.log(
            "Purging peer",
            metadata: [
                "identity": identity.description
            ]
        )
        return Update(state: state, fx: fx)
    }
    
    static func succeedPurgePeer(
        state: Self,
        environment: Environment,
        identity: Did
    ) -> Update<Self> {
        logger.log(
            "Purged peer from database",
            metadata: [
                "identity": identity.description
            ]
        )
        return Update(state: state)
    }
    
    static func failPurgePeer(
        state: Self,
        environment: Environment,
        error: String
    ) -> Update<Self> {
        logger.log(
            "Failed to purge peer from database",
            metadata: [
                "error": error
            ]
        )
        return Update(state: state)
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
                petname: Config.default.subconsciousGeistPetname,
                preventOverwrite: true
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
    
    static func requestRedeemInviteCode(
        state: AppModel,
        environment: AppEnvironment,
        inviteCode: InviteCode
    ) -> Update<AppModel> {
        guard let did = state.sphereIdentity,
              let did = Did(did) else {
            // Attempt to create the sphere if it's missing.
            // We could retry redeeming the code automatically but
            // if .createSphere fails we'll end up in an infinite loop
            return update(
                state: state,
                actions: [
                    .failRedeemInviteCode("Missing identity, cannot redeem invite code"),
                    .createSphere
                ],
                environment: environment
           )
        }
        
        let fx: Fx<AppAction> = environment.gatewayProvisioningService
            .redeemInviteCodePublisher(
                inviteCode: inviteCode,
                sphere: did
            )
            .map { res in
                .succeedRedeemInviteCode(res.gateway_id)
            }
            .recover { error in
                .failRedeemInviteCode(error.localizedDescription)
            }
            .eraseToAnyPublisher()
        
        var model = state
        model.inviteCodeRedemptionStatus = .pending
        
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
                
                return AppAction.succeedProvisionGateway(url)
            }
            .recover { err in
                AppAction.failProvisionGateway(err.localizedDescription)
            }
            .eraseToAnyPublisher()
        
        return Update(state: model, fx: fx)
    }
    
    static func succeedRedeemInviteCode(
        state: AppModel,
        environment: AppEnvironment,
        gatewayId: String
    ) -> Update<AppModel> {
        var model = state
        model.gatewayId = gatewayId
        model.inviteCodeRedemptionStatus = .succeeded
        AppDefaults.standard.gatewayId = gatewayId
        
        return update(
            state: model,
            actions: [
                .inviteCodeFormField(.reset),
                .requestGatewayProvisioningStatus
            ],
            environment: environment
        )
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
                .submitGatewayURL(url),
                .syncSphereWithGateway
            ],
            environment: environment
        )
    }
    
    static func failRedeemInviteCode(
        state: AppModel,
        environment: AppEnvironment,
        error: String
    ) -> Update<AppModel> {
        logger.error("Failed to redeem invite code: \(error)")
        var model = state
        model.inviteCodeRedemptionStatus = .failed(error)
        
        return update(
            state: model,
            action: .inviteCodeFormField(.setValidationStatus(valid: false)),
            environment: environment
        )
    }
    
    static func failProvisionGateway(
        state: AppModel,
        environment: AppEnvironment,
        error: String
    ) -> Update<AppModel> {
        logger.error("Failed to check gateway status: \(error)")
        var model = state
        model.gatewayProvisioningStatus = .failed(error)
        
        return Update(state: model)
    }
    
    static func notifySucceedResolveFollowedUser(
        state: Self,
        environment: Environment,
        petname: Petname,
        cid: Cid?
    ) -> Update<Self> {
        logger.log(
            "Notify followed and resolved sphere",
            metadata: [
                "petname": petname.description,
                "version": cid?.description ?? "nil"
            ]
        )
        return update(
            state: state,
            action: .indexPeer(petname),
            environment: environment
        )
    }
    
    static func notifySucceedUnfollow(
        state: Self,
        environment: Environment,
        identity: Did,
        petname: Petname
    ) -> Update<Self> {
        logger.log(
            "Notify unfollowed sphere",
            metadata: [
                "did": identity.description,
                "petname": petname.description
            ]
        )
        return update(
            state: state,
            action: .purgePeer(identity),
            environment: environment
        )
    }
    
    /// Entry delete succeeded
    static func deleteMemo(
        state: Self,
        environment: Environment,
        address: Slashlink?
    ) -> Update<Self> {
        guard let address = address else {
            logger.log(
                "Delete requested for nil address. Doing nothing."
            )
            return Update(state: state)
        }
        let fx: Fx<Action> = environment.data
            .deleteMemoPublisher(address)
            .map({ _ in
                Action.succeedDeleteMemo(address)
            })
            .recover({ error in
                Action.failDeleteMemo(error.localizedDescription)
            })
            .eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }

    /// Entry delete succeeded
    static func failDeleteMemo(
        state: Self,
        environment: Environment,
        error: String
    ) -> Update<Self> {
        logger.log(
            "Failed to delete entry",
            metadata: [
                "error": error
            ]
        )
        return Update(state: state)
    }

    /// Entry delete succeeded
    static func succeedDeleteMemo(
        state: Self,
        environment: Environment,
        address: Slashlink
    ) -> Update<Self> {
        logger.log(
            "Deleted entry",
            metadata: [
                "address": address.description
            ]
        )
        return Update(state: state)
    }
    
    static func setSelectedAppTab(
        state: Self,
        environment: Environment,
        tab: AppTab
    ) -> Update<Self> {
        
        // Double tap on the same tab?
        if tab == state.selectedAppTab {
            let action = Func.run {
                switch (tab) {
                case .feed:
                    return AppAction.requestFeedRoot
                case .notebook:
                    return AppAction.requestNotebookRoot
                }
            }
            
            let fx: Fx<AppAction> = Future.detached {
                return action
            }
            .eraseToAnyPublisher()
            
            // MUST be dispatched as an fx so that it will appear on the `store.actions` stream
            // Which is consumed and replayed on the FeedStore and NotebookStore etc.
            return Update(state: state, fx: fx)
        }
        
        var model = state
        model.selectedAppTab = tab
        return Update(state: model)
    }
    
    static func setAppTabsEnabled(
        state: Self,
        environment: Environment,
        enabled: Bool
    ) -> Update<Self> {
        var model = state
        AppDefaults.standard.appTabs = enabled
        model.appTabsEnabled = enabled
        return Update(state: model)
    }
                
    static func presentRecovery(
        state: Self,
        environment: Environment,
        presented: Bool
    ) -> Update<Self> {
        var model = state
        model.shouldPresentRecovery = presented
        return Update(state: model).animation(.default)
    }
    
    static func checkRecoveryStatus(
        state: Self,
        environment: Environment
    ) -> Update<Self> {
        let fx: Fx<Action> = Future.detached {
            let identity = try await environment.noosphere.identity()
            let did = try environment.database.readOurSphere()?.identity
            
            let uhoh = did != nil && identity != did
            
            return AppAction.presentRecovery(uhoh)
        }
        .recover { error in
            AppAction.presentRecovery(true)
        }
        .eraseToAnyPublisher()
        
        return Update(state: state, fx: fx)
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
    var transclude: TranscludeService
    
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
            addressBook: addressBook,
            userProfile: userProfile
        )
        
        self.feed = FeedService()
        self.gatewayProvisioningService = GatewayProvisioningService()
        self.transclude = TranscludeService(
            database: database,
            noosphere: noosphere,
            userProfile: userProfile
        )
    }
}

