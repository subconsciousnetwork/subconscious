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
import SentrySwiftUI

/// Top-level view for app
struct AppView: View {
    /// Store for global application state
    @StateObject private var store = Store(
        state: AppModel(),
        action: .start,
        environment: AppEnvironment.default,
        loggingEnabled: true,
        logger: Logger(
            subsystem: Config.default.rdns,
            category: "AppStore"
        )
    )
    @Environment(\.scenePhase) private var scenePhase: ScenePhase
    @Namespace var namespace

    var body: some View {
        ZStack {
            AppTabView(store: store)
                .zIndex(0)
                .disabled(store.state.editorSheet.presented)
            
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
            
            if store.state.isModalEditorEnabled {
                if let _ = store.state.editorSheet.item,
                   let namespace = store.state.namespace {
                    EditorModalSheetView(app: store, namespace: namespace)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 56)
                        .ignoresSafeArea(.all)
                        .zIndex(999)
                        .shadow(style: .editorSheet)
                }
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
        .fullScreenCover(
            isPresented: store.binding(
                get: \.isRecoveryModePresented,
                tag: AppAction.presentRecoveryMode
            )
        ) {
            RecoveryView(
                store: store.viewStore(
                    get: RecoveryModeCursor.get,
                    tag: RecoveryModeCursor.tag
                )
            )
        }
        .onAppear {
            SentryIntegration.start()
            store.send(.appear(namespace: namespace))
        }
        // Track changes to scene phase so we know when app gets
        // foregrounded/backgrounded.
        // See https://developer.apple.com/documentation/swiftui/scenephase
        // 2023-02-16 Gordon Brander
        .onChange(of: self.scenePhase) { _, phase in
            store.send(.scenePhaseChange(phase))
        }
    }
}

typealias InviteCodeFormField = FormField<String, InviteCode>
typealias NicknameFormField = FormField<String, Petname.Name>
typealias GatewayUrlFormField = FormField<String, GatewayURL>

struct PeerIndexError: Error, Hashable {
    let error: String
    let petname: Petname
}

struct PeerIndexSuccess: Hashable {
    let changeCount: Int
    let peer: PeerRecord
}

typealias PeerIndexResult = Result<PeerIndexSuccess, PeerIndexError>

// MARK: Action
enum AppAction: Hashable {
    /// Sent immediately upon store creation
    case start

    case recoveryPhrase(RecoveryPhraseAction)
    case appUpgrade(AppUpgradeAction)
    case nicknameFormField(NicknameFormField.Action)
    case inviteCodeFormField(InviteCodeFormField.Action)
    case gatewayURLField(GatewayUrlFormField.Action)
    case recoveryMode(RecoveryModeModel.Action)
    case toastStack(ToastStackAction)
    case editorSheet(EditorModalSheetAction)

    /// Scene phase events
    /// See https://developer.apple.com/documentation/swiftui/scenephase
    case scenePhaseChange(ScenePhase)

    /// On view appear
    case appear(namespace: Namespace.ID)

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
    case submitGatewayURL(_ url: GatewayURL)
    case submitGatewayURLForm
    case succeedResetGatewayURL(_ url: GatewayURL)

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

    /// Set and persist experimental block editor enabled
    case persistBlockEditorEnabled(Bool)
    /// Set and persist experimental modal editor sheet enabled
    case persistModalEditorEnabled(Bool)
    case persistNoosphereLogLevel(Noosphere.NoosphereLogLevel)
    case persistAiFeaturesEnabled(Bool)
    case persistPreferredLlm(String)
    case loadOpenAIKey(OpenAIKey)
    case persistOpenAIKey(OpenAIKey)

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
    /// Developer utility function, for now
    case resetIndex
    case succeedResetIndex
    case failResetIndex(String)
    
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
    case indexPeers(_ petnames: [Petname])
    case completeIndexPeers(results: [PeerIndexResult])

    /// Purge the contents of a sphere from the database
    case purgePeer(_ petname: Petname)
    case succeedPurgePeer(_ petname: Petname)
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
    case succeedProvisionGateway(_ gatewayURL: GatewayURL)
    case failProvisionGateway(_ error: String)
    
    case setFirstRunPath([FirstRunStep])
    case pushFirstRunStep(FirstRunStep)
    
    case submitFirstRunWelcomeStep
    case submitFirstRunProfileStep
    case submitFirstRunSphereStep
    case submitFirstRunRecoveryStep
    case submitFirstRunInviteStep
    case submitFirstRunDoneStep
    
    case requestOfflineMode

    /// Set settings sheet presented?
    case presentSettingsSheet(_ isPresented: Bool)
    
    /// Dispatched on bootup, check the integrity of the Noosphere database
    case checkRecoveryStatus
    /// Recovery mode can be launched manually (from settings) or automatically
    case requestRecoveryMode(RecoveryModeLaunchContext)
    /// Control the visibility of the recovery mode overlay
    case presentRecoveryMode(_ isPresented: Bool)
    
    // TODO: refactor this as part of https://github.com/subconsciousnetwork/subconscious/pull/996
    /// Notification that a follow happened, and the sphere was resolved
    case notifySucceedResolveFollowedUser(petname: Petname, cid: Cid?)
    
    // Addressbook Management Actions
    case followPeer(identity: Did, petname: Petname)
    case failFollowPeer(error: String)
    case succeedFollowPeer(_ identity: Did, _ petname: Petname)
    
    case renamePeer(from: Petname, to: Petname)
    case failRenamePeer(error: String)
    case succeedRenamePeer(identity: Did, from: Petname, to: Petname)
    
    case unfollowPeer(identity: Did, petname: Petname)
    case failUnfollowPeer(error: String)
    case succeedUnfollowPeer(identity: Did, petname: Petname)
    
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
    case saveEntry(MemoEntry)
    case deleteEntry(Slashlink?)
    case mergeEntry(parent: Slashlink, child: Slashlink)
    case moveEntry(from: Slashlink, to: Slashlink)
    case updateAudience(address: Slashlink, audience: Audience)
    case assignColor(address: Slashlink, color: ThemeColor)
    case setLiked(address: Slashlink, liked: Bool)
    
    // These notifications will be passe down to child stores to update themselves accordingly.
    case succeedSaveEntry(address: Slashlink, modified: Date)
    case succeedDeleteEntry(Slashlink)
    case succeedMoveEntry(from: Slashlink, to: Slashlink)
    case succeedMergeEntry(parent: Slashlink, child: Slashlink)
    case succeedUpdateAudience(MoveReceipt)
    case succeedAssignNoteColor(address: Slashlink, color: ThemeColor)
    case succeedUpdateLikeStatus(address: Slashlink, liked: Bool)
    case failSaveEntry(address: Slashlink, error: String)
    case failDeleteMemo(String)
    case failMoveEntry(from: Slashlink, to: Slashlink, error: String)
    case failMergeEntry(parent: Slashlink, child: Slashlink, error: String)
    case failUpdateAudience(address: Slashlink, audience: Audience, error: String)
    case failAssignNoteColor(address: Slashlink, error: String)
    case failUpdateLikeStatus(address: Slashlink, error: String)
    
    case succeedLogActivity
    case failLogActivity(_ error: String)
    
    case appendToEntry(address: Slashlink, append: String)
    case succeedAppendToEntry(address: Slashlink)
    case failAppendToEntry(address: Slashlink, _ error: String)
    
    case setSelectedAppTab(AppTab)
    case requestNotebookRoot
    case requestProfileRoot
    case requestDeckRoot
    case requestDiscoverRoot
    
    /// Used as a notification that recovery completed
    case succeedRecoverOurSphere
    
    /// Set recovery phrase on recovery phrase component
    static func setRecoveryPhrase(_ phrase: RecoveryPhrase?) -> AppAction {
        .recoveryPhrase(.setPhrase(phrase))
    }

    /// Synonym for AppUpgrade event action.
    static func setAppUpgradeProgressMessage(_ message: String) -> AppAction {
        .appUpgrade(.setProgressMessage(message))
    }

    static func setAppUpgradeComplete(_ isComplete: Bool) -> AppAction {
        .appUpgrade(.setComplete(isComplete))
    }
    
    static func pushToast(message: String, image: String? = nil) -> AppAction {
        return .toastStack(.pushToast(message: message, image: image))
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

struct RecoveryModeCursor: CursorProtocol {
    typealias Model = AppModel
    typealias ViewModel = RecoveryModeModel
    
    static func get(state: Model) -> ViewModel {
        state.recoveryMode
    }
    
    static func set(state: Model, inner: ViewModel) -> Model {
        var model = state
        model.recoveryMode = inner
        return model
    }
    
    static func tag(_ action: ViewModel.Action) -> Model.Action {
        switch action {
        case let .requestPresent(isPresented):
            return .presentRecoveryMode(isPresented)
        case .succeedRecovery:
            return .succeedRecoverOurSphere
        default:
            return .recoveryMode(action)
        }
    }
}

struct ToastStackCursor: CursorProtocol {
    typealias Model = AppModel
    typealias ViewModel = ToastStackModel
    
    static func get(state: Model) -> ViewModel {
        state.toastStack
    }
    
    static func set(state: Model, inner: ViewModel) -> Model {
        var model = state
        model.toastStack = inner
        return model
    }
    
    static func tag(_ action: ViewModel.Action) -> Model.Action {
        switch action {
        default:
            return .toastStack(action)
        }
    }
}

struct EditorModalSheetCursor: CursorProtocol {
    typealias Model = AppModel
    typealias ViewModel = EditorModalSheetModel
    
    static func get(state: Model) -> ViewModel {
        state.editorSheet
    }
    
    static func set(state: Model, inner: ViewModel) -> Model {
        var model = state
        model.editorSheet = inner
        return model
    }
    
    static func tag(_ action: ViewModel.Action) -> Model.Action {
        switch action {
        default:
            return .editorSheet(action)
        }
    }
}

enum AppDatabaseState {
    case initial
    case migrating
    case broken
    case ready
}

enum FirstRunStep: Hashable {
    case sphere
    case recovery
    case profile
    case invite
    case done
}

enum JobStatus {
    case initial
    case running
    case finished
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
    
    var toastStack = ToastStackModel()
    var editorSheet = EditorModalSheetModel()

    /// Should first run show?
    var shouldPresentFirstRun: Bool {
        !isFirstRunComplete
    }
    
    /// Is experimental block editor enabled?
    var isBlockEditorEnabled = false
    var isModalEditorEnabled = false
    var noosphereLogLevel: Noosphere.NoosphereLogLevel = .basic
    var areAiFeaturesEnabled = false
    var openAiApiKey = OpenAIKey(key: "sk-")
    var preferredLlm: String = AppDefaults.standard.preferredLlm

    /// Should recovery mode be presented?
    var isRecoveryModePresented = false
    var recoveryMode = RecoveryModeModel()
    
    /// Is database connected and migrated?
    var databaseMigrationStatus = ResourceStatus.initial
    var localSyncStatus = ResourceStatus.initial
    var sphereSyncStatus = ResourceStatus.initial
    var indexingStatus = JobStatus.initial
    
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
    
    /// Default sphere identity
    ///
    /// This property is updated at `.start` with the corresponding value
    /// stored in `AppDefaults`.
    var sphereIdentity: Did?
    
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
        validate: { value in GatewayURL(value) }
    )
    var lastGatewaySyncStatus = ResourceStatus.initial
    
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
    
    var selectedAppTab: AppTab = .notebook
    var namespace: Namespace.ID? = nil
    
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
        case .recoveryMode(let action):
            return RecoveryModeCursor.update(
                state: state,
                action: action,
                environment: environment
            )
        case .authorization(let action):
            return AuthorizationSettingsCursor.update(
                state: state,
                action: action,
                environment: environment
            )
        case .toastStack(let action):
            return ToastStackCursor.update(
                state: state,
                action: action,
                environment: environment
            )
        case .editorSheet(let action):
            return EditorModalSheetCursor.update(
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
        case let .appear(namespace):
            return appear(
                state: state,
                environment: environment,
                namespace: namespace
            )
        case let .setFirstRunPath(path):
            return setFirstRunPath(
                state: state,
                environment: environment,
                path: path
            )
        case let .pushFirstRunStep(step):
            return pushFirstRunStep(
                state: state,
                environment: environment,
                step: step
            )
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
        case .submitFirstRunInviteStep:
            return submitFirstRunInviteStep(
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
            return succeedFetchNicknameFromProfile(
                state: state,
                environment: environment,
                nickname: nickname
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
        case let .persistBlockEditorEnabled(isBlockEditorEnabled):
            return persistBlockEditorEnabled(
                state: state,
                environment: environment,
                isBlockEditorEnabled: isBlockEditorEnabled
            )
        case let .persistAiFeaturesEnabled(areAiFeaturesEnabled):
            return persistAiFeaturesEnabled(
                state: state,
                environment: environment,
                areAiFeaturesEnabled: areAiFeaturesEnabled
            )
        case let .loadOpenAIKey(key):
            return loadOpenAIKey(
                state: state,
                environment: environment,
                key: key
            )
        case let .persistOpenAIKey(key):
            return persistOpenAIKey(
                state: state,
                environment: environment,
                key: key
            )
        case let .persistPreferredLlm(llm):
            return persistPreferredLlm(
                state: state,
                environment: environment,
                llm: llm
            )
        case let .persistModalEditorEnabled(isModalEditorEnabled):
            return persistModalEditorEnabled(
                state: state,
                environment: environment,
                isModalEditorEnabled: isModalEditorEnabled
            )
        case let .persistNoosphereLogLevel(level):
            return persistNoosphereLogLevel(
                state: state,
                environment: environment,
                level: level
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
        case .resetIndex:
            return resetIndex(
                state: state,
                environment: environment
            )
        case .succeedResetIndex:
            return succeedResetIndex(
                state: state,
                environment: environment
            )
        case .failResetIndex(let error):
            return failResetIndex(
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
        case .indexPeers(let petnames):
            return indexPeers(
                state: state,
                environment: environment,
                petnames: petnames
            )
        case let .completeIndexPeers(results):
            return completeIndexPeers(
                state: state,
                environment: environment,
                results: results
            )
        case .purgePeer(let petname):
            return purgePeer(
                state: state,
                environment: environment,
                petname: petname
            )
        case .succeedPurgePeer(let petname):
            return succeedPurgePeer(
                state: state,
                environment: environment,
                petname: petname
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
            return submitInviteCodeForm(
                state: state,
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
        // MARK: Address book actions
        case .followPeer(let identity, let petname):
            return followPeer(
                state: state,
                environment: environment,
                identity: identity,
                petname: petname
            )
        case .failFollowPeer(let error):
            return failFollowPeer(
                state: state,
                environment: environment,
                error: error
            )
        case let .succeedFollowPeer(did, petname):
            return succeedFollowPeer(
                state: state,
                environment: environment,
                identity: did,
                petname: petname
            )
        case .renamePeer(let from, let to):
            return renamePeer(
                state: state,
                environment: environment,
                from: from,
                to: to
            )
        case .failRenamePeer(let error):
            return failRenamePeer(
                state: state,
                environment: environment,
                error: error
            )
        case .succeedRenamePeer(let identity, let from, let to):
            return succeedRenamePeer(
                state: state,
                environment: environment,
                identity: identity,
                from: from,
                to: to
            )
        case .unfollowPeer(let identity, let petname):
            return unfollowPeer(
                state: state,
                environment: environment,
                identity: identity,
                petname: petname
            )
        case .failUnfollowPeer(let error):
            return failUnfollowPeer(
                state: state,
                environment: environment,
                error: error
            )
        case .succeedUnfollowPeer(let identity, let petname):
            return succeedUnfollowPeer(
                state: state,
                environment: environment,
                identity: identity,
                petname: petname
            )
        // MARK: Note management
        case let .deleteEntry(address):
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
        case let .succeedDeleteEntry(address):
            return succeedDeleteEntry(
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
        case .requestNotebookRoot,
                .requestProfileRoot,
                .requestDeckRoot,
                .requestDiscoverRoot:
            return Update(state: state)
        case .checkRecoveryStatus:
            return checkRecoveryStatus(
                state: state,
                environment: environment
            )
        case .requestRecoveryMode(let context):
            return requestRecoveryMode(
                state: state,
                environment: environment,
                context: context
            )
        case .presentRecoveryMode(let isPresented):
            return presentRecoveryMode(
                state: state,
                environment: environment,
                isPresented: isPresented
            )
        case .succeedRecoverOurSphere:
            return succeedRecoverOurSphere(
                state: state,
                environment: environment
            )
        case .succeedMoveEntry,
                .succeedMergeEntry,
                .succeedLogActivity,
                .succeedUpdateAudience,
                .succeedAssignNoteColor,
                .succeedAppendToEntry,
                .succeedUpdateLikeStatus:
            return Update(state: state)
        case .succeedSaveEntry(address: let address, modified: let modified):
            return succeedSaveEntry(
                state: state,
                environment: environment,
                address: address,
                modified: modified
            )
        case let .saveEntry(entry):
            return saveEntry(
                state: state,
                environment: environment,
                entry: entry
            )
        case let .appendToEntry(address, append):
            return appendToEntry(
                state: state,
                environment: environment,
                address: address,
                append: append
            )
        case let .moveEntry(from, to):
            return moveEntry(
                state: state,
                environment: environment,
                from: from,
                to: to
            )
        case let .mergeEntry(parent, child):
            return mergeEntry(
                state: state,
                environment: environment,
                parent: parent,
                child: child
            )
        case let .updateAudience(address, audience):
            return updateAudience(
                state: state,
                environment: environment,
                address: address,
                audience: audience
            )
        case let .assignColor(address, color):
            return assignNoteColor(
                state: state,
                environment: environment,
                address: address,
                color: color
            )
        case let .setLiked(address, liked):
            return setLiked(
                state: state,
                environment: environment,
                address: address,
                liked: liked
            )
        case let .failSaveEntry(address, error):
            return operationFailed(
                state: state,
                environment: environment,
                error:
                   """
                   Failed to save entry: \(address)
                   \(error)
                   """,
                notification: "Could not save note"
            )
        case let .failAppendToEntry(address, error):
            return operationFailed(
                state: state,
                environment: environment,
                error:
                   """
                   Failed to append to entry: \(address)
                   \(error)
                   """,
                notification: "Could not append to note"
            )
        case let .failMoveEntry(from, to, error):
            return operationFailed(
                state: state,
                environment: environment,
                error:
                   """
                   Failed to move entry: \(from) -> \(to)
                   \(error)
                   """,
                notification: "Could not move note"
            )
        case let .failMergeEntry(parent, child, error):
            return operationFailed(
                state: state,
                environment: environment,
                error:
                   """
                   Failed to merge entries: \(child) -> \(parent)
                   \(error)
                   """,
                notification: "Could not merge notes"
            )
        case let .failUpdateAudience(address, audience, error):
            return operationFailed(
                state: state,
                environment: environment,
                error:
                   """
                   Failed to update audience for entry: \(address) \(audience)
                   \(error)
                   """,
                notification: "Could not change audience"
            )
        case let .failLogActivity(error):
            logger.warning(
                """
                Failed to log activity: \(error)
                """
            )
            return Update(state: state)
        case let .failAssignNoteColor(address, error):
            return operationFailed(
                state: state,
                environment: environment,
                error:
                   """
                   Failed to assign color for entry: \(address)
                   \(error)
                   """,
                notification: "Could not set color"
            )
        case let .failUpdateLikeStatus(address, error):
            return operationFailed(
                state: state,
                environment: environment,
                error: 
                   """
                   Failed to update like status entry: \(address)
                   \(error)
                   """,
                notification: "Could not update status"
            )
        }
    }
    
    static func operationFailed(
        state: Self,
        environment: Environment,
        error: String,
        notification: String
    ) -> Update<Self> {
        logger.warning("\(error)")
        
        return update(
            state: state,
            action: .pushToast(
                message: notification
            ),
            environment: environment
        )
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
        model.selectedAppTab = AppTab(rawValue: AppDefaults.standard.selectedAppTab) ?? state.selectedAppTab
        model.noosphereLogLevel = Noosphere.NoosphereLogLevel(description: AppDefaults.standard.noosphereLogLevel)
        model.isBlockEditorEnabled = AppDefaults.standard.isBlockEditorEnabled
        model.areAiFeaturesEnabled = AppDefaults.standard.areAiFeaturesEnabled
        model.preferredLlm = AppDefaults.standard.preferredLlm
        
        let fx: Fx<AppAction> = Future.detached {
            let key = await environment.keychainService.getApiKey() ?? ""
            return .loadOpenAIKey(OpenAIKey(key: key))
        }.eraseToAnyPublisher()
        
        model.isModalEditorEnabled = AppDefaults.standard.isModalEditorEnabled

        // Update model from app defaults
        return update(
            state: model,
            actions: [
                .setSphereIdentity(
                    AppDefaults.standard.sphereIdentity
                ),
                .checkRecoveryStatus,
                .notifyFirstRunComplete(
                    AppDefaults.standard.firstRunComplete
                ),
                .gatewayURLField(
                    .setValue(input: AppDefaults.standard.gatewayURL)
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
        environment: AppEnvironment,
        namespace: Namespace.ID
    ) -> Update<AppModel> {
        let sphereIdentity = state.sphereIdentity?.description ?? "nil"
        logger.debug(
            "appear",
            metadata: [
                "documents": environment.documentURL.absoluteString,
                "database": environment.database.database.path,
                "sphereIdentity": sphereIdentity
            ]
        )
        
        var model = state
        model.namespace = namespace
        
        return update(
            state: model,
            actions: [
                .migrateDatabase,
                .refreshSphereVersion,
                .fetchNicknameFromProfile
            ],
            environment: environment
        )
    }
    
    static func setFirstRunPath(
        state: AppModel,
        environment: AppEnvironment,
        path: [FirstRunStep]
    ) -> Update<AppModel> {
        var model = state
        model.firstRunPath = path
        return Update(state: model)
    }
    
    static func pushFirstRunStep(
        state: AppModel,
        environment: AppEnvironment,
        step: FirstRunStep
    ) -> Update<AppModel> {
        var model = state
        model.firstRunPath.append(step)
        return Update(state: model)
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
    
    static func succeedFetchNicknameFromProfile(
        state: AppModel,
        environment: AppEnvironment,
        nickname: Petname.Name
    ) -> Update<AppModel> {
        return update(
            state: state,
            action: .setNickname(nickname.verbatim),
            environment: environment
        )
    }
    
    static func fetchNicknameFromProfileMemo(
        state: AppModel, 
        environment: AppEnvironment
    ) -> Update<AppModel> {
        let fx: Fx<AppAction> = Future.detached {
            let response = try await environment.userProfile.readOurProfile(alias: nil)
            if let nickname = response.nickname {
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
        url: GatewayURL
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
        url: GatewayURL
    ) -> Update<AppModel> {
        logger.log("Reset gateway URL: \(url.description)")
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
                .setRecoveryPhrase(RecoveryPhrase(receipt.mnemonic)),
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
        model.sphereIdentity = Did(sphereIdentity ?? "")
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
    
    static func persistBlockEditorEnabled(
        state: AppModel,
        environment: AppEnvironment,
        isBlockEditorEnabled: Bool
    ) -> Update<AppModel> {
        // Persist value
        AppDefaults.standard.isBlockEditorEnabled = isBlockEditorEnabled
        var model = state
        model.isBlockEditorEnabled = isBlockEditorEnabled
        return Update(state: model)
    }
    
    static func persistAiFeaturesEnabled(
        state: AppModel,
        environment: AppEnvironment,
        areAiFeaturesEnabled: Bool
    ) -> Update<AppModel> {
        // Persist value
        AppDefaults.standard.areAiFeaturesEnabled = areAiFeaturesEnabled
        var model = state
        model.areAiFeaturesEnabled = areAiFeaturesEnabled
        return Update(state: model)
    }
    
    static func persistPreferredLlm(
        state: AppModel,
        environment: AppEnvironment,
        llm: String
    ) -> Update<AppModel> {
        AppDefaults.standard.preferredLlm = llm
        var model = state
        model.preferredLlm = llm
        return Update(state: model)
    }
    
    static func loadOpenAIKey(
        state: AppModel,
        environment: AppEnvironment,
        key: OpenAIKey
    ) -> Update<AppModel> {
        var model = state
        model.openAiApiKey = key
        
        return Update(state: model)
    }
    
    static func persistOpenAIKey(
        state: AppModel,
        environment: AppEnvironment,
        key: OpenAIKey
    ) -> Update<AppModel> {
        let fx: Fx<AppAction> = Future.detached {
            await environment.keychainService.setApiKey(key.key)
            return .loadOpenAIKey(key)
        }.eraseToAnyPublisher()
        
        return Update(state: state).mergeFx(fx)
    }
    
    static func persistModalEditorEnabled(
        state: AppModel,
        environment: AppEnvironment,
        isModalEditorEnabled: Bool
    ) -> Update<AppModel> {
        // Persist value
        AppDefaults.standard.isModalEditorEnabled = isModalEditorEnabled
        var model = state
        model.isModalEditorEnabled = isModalEditorEnabled
        return Update(state: model)
    }
    
    static func persistNoosphereLogLevel(
        state: AppModel,
        environment: AppEnvironment,
        level: Noosphere.NoosphereLogLevel
    ) -> Update<AppModel> {
        // Persist value
        AppDefaults.standard.noosphereLogLevel = level.description
        var model = state
        model.noosphereLogLevel = level
        return Update(state: model)
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
                .submitFirstRunInviteStep
            ],
            environment: environment
        )
    }
    
    static func submitFirstRunWelcomeStep(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        return update(
            state: state,
            actions: [
                .pushFirstRunStep(.sphere)
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
                .pushFirstRunStep(.invite)
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
                .createSphere,
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
                .pushFirstRunStep(.profile)
            ],
            environment: environment
        )
    }
    
    static func submitFirstRunInviteStep(
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
        return Update(state: model, fx: fx).animation()
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
            actions: [
                .indexOurSphere
            ],
            environment: environment
        ).animation()
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
        
        
        var actions: [AppAction] = [
            .indexOurSphere,
            .toastStack(
                .pushToast(
                    message: "Sync failed",
                    image: "exclamationmark.arrow.triangle.2.circlepath"
                )
            )
        ]
        
        // If we have a gateway ID but sync failed and we are using the default gateway,
        // then provisioning may have failed / timed out.
        // Let's retry in-case it suddenly resolves the issue.
        if let _ = state.gatewayId,
           state.gatewayURL == AppDefaults.defaultGatewayURL,
           state.gatewayProvisioningStatus != .succeeded {
            actions.append(.requestGatewayProvisioningStatus)
        }
        
        return update(
            state: model,
            actions: actions,
            environment: environment
        ).animation()
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
    
    static func resetIndex(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        let fx: Fx<AppAction> = Future.detached(priority: .utility) {
            do {
                try await environment.data.resetIndex()
                return AppAction.succeedResetIndex
            } catch {
                return AppAction.failResetIndex(error.localizedDescription)
            }
        }.eraseToAnyPublisher()
        
        return Update(state: state, fx: fx)
    }
    
    static func succeedResetIndex(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
        logger.log("Cleared index")
        return Update(state: state)
    }
    
    static func failResetIndex(
        state: AppModel,
        environment: AppEnvironment,
        error: String
    ) -> Update<AppModel> {
        logger.log(
            "Failed to clear index",
            metadata: [
                "error": error
            ]
        )
        return Update(state: state)
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
        let fx: Fx<Action> = Just(
            AppAction.indexPeers(
                peers.map({ peer in peer.petname })
            )
        )
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
    static func indexPeers(
        state: Self,
        environment: Environment,
        petnames: [Petname]
    ) -> Update<Self> {
        if state.indexingStatus == .running {
            return Update(state: state)
        }
        
        var model = state
        model.indexingStatus = .running
        
        let fx: Fx<Action> = Future.detached(priority: .background) {
            let results = await environment.data.indexPeers(petnames: petnames)
            return AppAction.completeIndexPeers(results: results)
        }
        .eraseToAnyPublisher()
        
        return Update(state: model, fx: fx)
    }
    
    static func completeIndexPeers(
        state: Self,
        environment: Environment,
        results: [PeerIndexResult]
    ) -> Update<Self> {
        for result in results {
            switch (result) {
            case .success(let result):
                logger.log(
                    "Indexed peer",
                    metadata: [
                        "petname": result.peer.petname.description,
                        "identity": result.peer.identity.description,
                        "since": result.peer.since ?? "nil"
                    ]
                )
                break
            case .failure(let error):
                logger.log(
                    "Failed to index peer",
                    metadata: [
                        "petname": error.petname.description,
                        "error": error.localizedDescription
                    ]
                )
                break
            }
        }
        
        var model = state
        model.indexingStatus = .finished
        
        return Update(state: model)
    }
    
    static func purgePeer(
        state: Self,
        environment: Environment,
        petname: Petname
    ) -> Update<Self> {
        let fx: Fx<Action> = Future.detached(priority: .utility) {
            do {
                try environment.database.purgePeer(
                    petname: petname
                )
                return Action.succeedPurgePeer(petname)
            } catch {
                return Action.failPurgePeer(error.localizedDescription)
            }
        }.eraseToAnyPublisher()
        logger.log(
            "Purging peer",
            metadata: [
                "petname": petname.description
            ]
        )
        return Update(state: state, fx: fx)
    }
    
    static func succeedPurgePeer(
        state: Self,
        environment: Environment,
        petname: Petname
    ) -> Update<Self> {
        logger.log(
            "Purged peer from database",
            metadata: [
                "petname": petname.description
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
    
    static func submitInviteCodeForm(
        state: AppModel,
        environment: AppEnvironment
    ) -> Update<AppModel> {
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
    }
    
    static func requestRedeemInviteCode(
        state: AppModel,
        environment: AppEnvironment,
        inviteCode: InviteCode
    ) -> Update<AppModel> {
        guard let did = state.sphereIdentity else {
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
        url: GatewayURL
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
            action: .indexPeers([petname]),
            environment: environment
        )
    }
    
    static func followPeer(
        state: AppModel,
        environment: AppEnvironment,
        identity: Did,
        petname: Petname
    ) -> Update<AppModel> {
        let fx: Fx<AppAction> =
            environment.addressBook
                .followUserPublisher(
                    did: identity,
                    petname: petname,
                    preventOverwrite: true
                )
                .map({ _ in
                    .succeedFollowPeer(identity, petname)
                })
                .recover { error in
                    .failFollowPeer(
                        error: error.localizedDescription
                    )
                }
                .eraseToAnyPublisher()
        
        return Update(state: state, fx: fx)
    }

    static func failFollowPeer(
        state: AppModel,
        environment: AppEnvironment,
        error: String
    ) -> Update<AppModel> {
        logger.warning("Failed to follow user: \(error)")
        return update(
            state: state,
            action: .pushToast(message: String(localized: "Failed to follow user")),
            environment: environment
        )
    }

    static func succeedFollowPeer(
        state: AppModel,
        environment: AppEnvironment,
        identity: Did,
        petname: Petname
    ) -> Update<AppModel> {
        logger.log(
            "Followed sphere",
            metadata: [
                "petname": petname.description
            ]
        )
        
        return update(
            state: state,
            actions: [
                .pushToast(message: "Followed \(petname.markup)"),
                .indexPeers([petname]),
                .syncAll
            ],
            environment: environment
        )
    }

    static func renamePeer(
        state: AppModel,
        environment: AppEnvironment,
        from: Petname,
        to: Petname
    ) -> Update<AppModel> {
        let fx: Fx<AppAction> =
        Future.detached {
            let did = try await environment.addressBook.unfollowUser(petname: from)
            try await environment.addressBook.followUser(did: did, petname: to)
            
            return .succeedRenamePeer(identity: did, from: from, to: to)
        }
        .recover { error in
            .failRenamePeer(error: error.localizedDescription)
        }
        .eraseToAnyPublisher()
        
        // Implement functionality
        return Update(state: state, fx: fx)
    }

    static func failRenamePeer(
        state: AppModel,
        environment: AppEnvironment,
        error: String
    ) -> Update<AppModel> {
        logger.warning("Failed to rename user: \(error)")
        return update(
            state: state,
            action: .pushToast(message: String(localized: "Failed to rename user")),
            environment: environment
        )
    }

    static func succeedRenamePeer(
        state: AppModel,
        environment: AppEnvironment,
        identity: Did,
        from: Petname,
        to: Petname
    ) -> Update<AppModel> {
        return update(
            state: state,
            action: .pushToast(message: String(localized: "Renamed to \(to.markup)")),
            environment: environment
        )
    }

    static func unfollowPeer(
        state: AppModel,
        environment: AppEnvironment,
        identity: Did,
        petname: Petname
    ) -> Update<AppModel> {
        let fx: Fx<AppAction> = environment.addressBook
            .unfollowUserPublisher(petname: petname)
            .map({ identity in
                .succeedUnfollowPeer(identity: identity, petname: petname)
            })
            .recover({ error in
                .failUnfollowPeer(error: error.localizedDescription)
            })
            .eraseToAnyPublisher()
        
        return Update(state: state, fx: fx)
    }

    static func failUnfollowPeer(
        state: AppModel,
        environment: AppEnvironment,
        error: String
    ) -> Update<AppModel> {
        logger.warning("Failed to unfollow user: \(error)")
        return update(
            state: state,
            action: .pushToast(message: String(localized: "Failed to unfollow user")),
            environment: environment
        )
    }
    
    static func succeedUnfollowPeer(
        state: Self,
        environment: Environment,
        identity: Did,
        petname: Petname
    ) -> Update<Self> {
        logger.log(
            "Unfollowed sphere",
            metadata: [
                "did": identity.description,
                "petname": petname.description
            ]
        )
        return update(
            state: state,
            actions: [
                .pushToast(message: "Unfollowed \(petname.markup)"),
                .purgePeer(petname),
                .syncAll
            ],
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
                Action.succeedDeleteEntry(address)
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
    static func succeedDeleteEntry(
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
                case .deck:
                    return AppAction.requestDeckRoot
                case .notebook:
                    return AppAction.requestNotebookRoot
                case .discover:
                    return AppAction.requestDiscoverRoot
                case .profile:
                    return AppAction.requestProfileRoot
                }
            }
            
            let fx: Fx<AppAction> = Future.detached {
                return action
            }
            .eraseToAnyPublisher()
            
            environment.feedback.prepare()
            environment.feedback.impactOccurred()
            
            // MUST be dispatched as an fx so that it will appear on the `store.actions` stream
            // Which is consumed and replayed on the FeedStore and NotebookStore etc.
            return Update(state: state, fx: fx)
        }
        
        var model = state
        model.selectedAppTab = tab
        AppDefaults.standard.selectedAppTab = tab.rawValue
        environment.selectionFeedback.prepare()
        environment.selectionFeedback.selectionChanged()
        
        return Update(state: model)
    }
    
    static func requestRecoveryMode(
        state: Self,
        environment: Environment,
        context: RecoveryModeLaunchContext
    ) -> Update<Self> {
        return update(
            state: state,
            actions: [
                .presentRecoveryMode(true),
                .recoveryMode(
                    .populate(
                        state.sphereIdentity,
                        GatewayURL(state.gatewayURL),
                        context
                    )
                )
            ],
            environment: environment
        )
    }
    
    static func presentRecoveryMode(
        state: Self,
        environment: Environment,
        isPresented: Bool
    ) -> Update<Self> {
        var model = state
        model.isRecoveryModePresented = isPresented
        return update(
            state: model,
            actions: [
                .presentSettingsSheet(false),
                .recoveryMode(.requestPresent(isPresented))
            ],
            environment: environment
        )
    }
    
    static func checkRecoveryStatus(
        state: Self,
        environment: Environment
    ) -> Update<Self> {
        let fx: Fx<Action> = Future.detached {
            // Get any existing sphere identity stored in UserDefaults
            // If none, it's the first run, nothing to recover
            guard let userDefaultsIdentity = AppDefaults.standard.sphereIdentity?
                .toDid() else {
                return AppAction.presentRecoveryMode(false)
            }
            
            let noosphereIdentity = try await environment.noosphere.identity()

            // If we have an identity in the UserDefaults, but it doesn't
            // match the identity in Noosphere, we need to perform a
            // a recovery.
            guard noosphereIdentity == userDefaultsIdentity else {
                return AppAction.requestRecoveryMode(
                    .unreadableDatabase("Mismatched identity")
                )
            }
            
            return AppAction.presentRecoveryMode(false)
        }
        .recover { error in
            AppAction.requestRecoveryMode(
                .unreadableDatabase(error.localizedDescription)
            )
        }
        .eraseToAnyPublisher()
        
        return Update(state: state, fx: fx)
    }
    
    static func succeedRecoverOurSphere(
        state: Self,
        environment: Environment
    ) -> Update<Self> {
        return RecoveryModeCursor.update(
            state: state,
            action: .succeedRecovery,
            environment: environment
        )
    }
    
    static func saveEntry(
        state: Self,
        environment: AppEnvironment,
        entry: MemoEntry
    ) -> Update<Self> {
        let fx: Fx<AppAction> = environment.data.writeEntryPublisher(
            entry
        ).map({ _ in
            .succeedSaveEntry(address: entry.address, modified: entry.contents.modified)
        }).recover({ error in
            .failSaveEntry(
                address: entry.address,
                error: error.localizedDescription
            )
        }).eraseToAnyPublisher()
        
        return Update(state: state, fx: fx)
    }
    
    static func appendToEntry(
        state: Self,
        environment: AppEnvironment,
        address: Slashlink,
        append: String
    ) -> Update<Self> {
        let fx: Fx<AppAction> = Future.detached {
            try await environment.data.appendToEntry(address: address, append: append)
            return .succeedAppendToEntry(address: address)
        }
        .recover { error in
            .failAppendToEntry(address: address, error.localizedDescription)
        }
        .eraseToAnyPublisher()
        
        return Update(state: state, fx: fx)
    }
    
    struct SucceedSaveEntryActivityEvent: Codable {
        public static let event = "save_entry"
        public let address: String
    }
    
    static func succeedSaveEntry(
        state: Self,
        environment: AppEnvironment,
        address: Slashlink,
        modified: Date
    ) -> Update<Self> {
        let fx: Fx<AppAction> = Future.detached {
            try environment.database.writeActivity(
                event: ActivityEvent(
                    category: .system,
                    event: SucceedSaveEntryActivityEvent.event,
                    message: "",
                    metadata: SucceedSaveEntryActivityEvent(address: address.description)
                )
            )
            
            return .succeedLogActivity
        }
        .recover { error in 
            .failLogActivity(error.localizedDescription)
        }
        .eraseToAnyPublisher()
        
        logger.log(
            "Saved entry",
            metadata: [
                "address": address.description
            ]
        )
        return Update(state: state, fx: fx)
    }
    
    static func mergeEntry(
        state: Self,
        environment: AppEnvironment,
        parent: Slashlink,
        child: Slashlink
    ) -> Update<Self> {
        let fx: Fx<AppAction> = environment.data.mergeEntryPublisher(
            parent: parent,
            child: child
        ).map({ _ in
            .succeedMergeEntry(parent: parent, child: child)
        }).recover{ error in
            .failMergeEntry(
                parent: parent,
                child: child,
                error: error.localizedDescription
            )
        }.eraseToAnyPublisher()
        return Update(state: state, fx: fx)
    }
    
    static func moveEntry(
        state: Self,
        environment: AppEnvironment,
        from: Slashlink,
        to: Slashlink
    ) -> Update<Self> {
        let fx: Fx<AppAction> = environment.data.moveEntryPublisher(
            from: from,
            to: to
        )
        .map({ _ in
            .succeedMoveEntry(from: from, to: to)
        })
        .recover{ error in
            .failMoveEntry(
                from: from,
                to: to,
                error: error.localizedDescription
            )
        }.eraseToAnyPublisher()
        
        return Update(
            state: state,
            fx: fx
        )
        .animation(.easeOutCubic(duration: Duration.keyboard))
    }
    
    static func updateAudience(
        state: Self,
        environment: AppEnvironment,
        address: Slashlink,
        audience: Audience
    ) -> Update<Self> {
        let from = address
        let to = from.withAudience(audience)

        let fx: Fx<AppAction> = environment.data.moveEntryPublisher(
            from: from,
            to: to
        ).map({ receipt in
            .succeedUpdateAudience(receipt)
        }).recover{ error in
            .failUpdateAudience(
                address: address,
                audience: audience,
                error: error.localizedDescription
            )
        }.eraseToAnyPublisher()

        return Update(
            state: state,
            fx: fx
        )
    }
    
    static func assignNoteColor(
        state: Self,
        environment: Environment,
        address: Slashlink,
        color: ThemeColor
    ) -> Update<Self> {
        let fx: Fx<Action> = Future.detached {
            try await environment.data.assignNoteColor(
                address: address,
                color: color
            )
            
            return .succeedAssignNoteColor(
                address: address,
                color: color
            )
        }
        .recover { error in
            return .failAssignNoteColor(
                address: address,
                error: error.localizedDescription
            )
        }
        .eraseToAnyPublisher()
        
        return Update(state: state, fx: fx)
    }
    
    static func setLiked(
        state: Self,
        environment: Environment,
        address: Slashlink,
        liked: Bool
    ) -> Update<Self> {
        let fx: Fx<Action> = Future.detached {
            if liked {
                try await environment.userLikes.persistLike(for: address)
            } else {
                try await environment.userLikes.removeLike(for: address)
            }
            
            return .succeedUpdateLikeStatus(address: address, liked: liked)
        }
        .recover { error in
            return .failUpdateLikeStatus(
                address: address,
                error: error.localizedDescription
            )
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
    var transclude: TranscludeService
    
    var recoveryPhrase: RecoveryPhraseEnvironment = RecoveryPhraseEnvironment()
    
    var addressBook: AddressBookService
    var userProfile: UserProfileService
    var userLikes: UserLikesService
    
    var gatewayProvisioningService: GatewayProvisioningService
    
    var openAiService: OpenAIService
    var keychainService: KeychainService
    
    var pasteboard = UIPasteboard.general

    /// Service for generating creative prompts and oblique strategies
    var prompt = PromptService.default
    
    var feedback = UIImpactFeedbackGenerator()
    var selectionFeedback = UISelectionFeedbackGenerator()

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
        let defaultGateway = GatewayURL(AppDefaults.standard.gatewayURL)
        let defaultSphereIdentity = AppDefaults.standard.sphereIdentity
        let defaultLogLevel = Noosphere.NoosphereLogLevel(description: AppDefaults.standard.noosphereLogLevel)
        
        let sentry = SentryIntegration()

        // If we're in debug, we want detailed logs from Noosphere.
        let noosphereLogLevel: Noosphere.NoosphereLogLevel = (
            Config.default.debug ?
                .academic :
                defaultLogLevel
        )

        let noosphere = NoosphereService(
            globalStorageURL: globalStorageURL,
            sphereStorageURL: sphereStorageURL,
            gatewayURL: defaultGateway,
            sphereIdentity: defaultSphereIdentity,
            noosphereLogLevel: noosphereLogLevel,
            errorLoggingService: sentry
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
        
        self.userLikes = UserLikesService(
            noosphere: noosphere
        )
        
        self.userProfile = UserProfileService(
            noosphere: noosphere,
            database: database,
            addressBook: addressBook,
            userLikes: userLikes
        )
        
        self.data = DataService(
            noosphere: noosphere,
            database: database,
            local: local,
            addressBook: addressBook,
            userProfile: userProfile,
            userLikes: userLikes
        )
        
        self.gatewayProvisioningService = GatewayProvisioningService()
        self.transclude = TranscludeService(
            database: database,
            noosphere: noosphere,
            userProfile: userProfile
        )
        
        self.keychainService = KeychainService()
        self.openAiService = OpenAIService(keychain: self.keychainService)
    }
}

