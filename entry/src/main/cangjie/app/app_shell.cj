package ohos_app_cangjie_entry.app

import kit.ArkUI.*
import kit.AbilityKit.Want
import ohos.business_exception.BusinessException
import ohos.base.UIThread
import std.collection.ArrayList
import ohos.arkui.state_macro_manage.*
import ohos_app_cangjie_entry.domain.{GitHubAccessTokenSnapshot, GitHubIssueSnapshot, GitHubProfileMetricsSnapshot, GitHubPullRequestSnapshot, GitHubRepositoryCardSnapshot, GitHubRepositoryDetailSnapshot, GitHubViewerSnapshot}
import ohos_app_cangjie_entry.infra.logging.{logDebug, logInfo, logWarn}
import ohos_app_cangjie_entry.infra.runtime.{applyAppStatusBarStyle, clearAppAuthCallbackHandler, clearAppForegroundHandler, clearAppPreferenceHandler, clearAppSignOutHandler, clearAppTabChangeHandler, consumePendingAuthCallback, getAppAbilityContext, setAppAuthCallbackHandler, setAppForegroundHandler, setAppPreferenceHandler, setAppSignOutHandler, setAppTabChangeHandler}
import ohos_app_cangjie_entry.services.platform.{defaultWorkplace, workplaceSnapshot}
import ohos_app_cangjie_entry.services.app.{buildGitHubAuthLaunchSnapshot, createScratchGitHubRepository, ensureSelectionSnapshot, exchangeGitHubAuthCode, loadStoredLanguagePreference, loadStoredThemePreference, persistLanguagePreference, persistThemePreference, refreshGitHubProfileData, refreshGitHubRepositoryBundle, refreshStoredGitHubSession, resolveSelectedIssueState, resolveSelectedPullRequestId, resolveSelectedRepositoryId, restoreMockWorkplaceSelection}
import ohos_app_cangjie_entry.services.github.{clearStoredGitHubSession, extractUrlQueryParameter, persistStoredGitHubSession, restoreStoredGitHubSession}
import ohos_app_cangjie_entry.ui.theme.{appResolveIsDarkTheme, appThemeColor}
import ohos_app_cangjie_entry.ui.i18n.{appLocalizedText, appResolveLanguage}
import ohos_app_cangjie_entry.pages.maps.shellPageMap
import ohos_app_cangjie_entry.pages.tabs.{CursorTabHost, ExploreTabHost, HomeTabHost, InboxTabHost}

@Component
public class AppShell {
    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @State
    var isAuthenticated: Bool = false

    @State
    var authStage: String = "welcome"

    @State
    var activeTab: String = "home"

    @State
    var showWorkplacePicker: Bool = false

    @Provide
    var themePreference: String = "system"

    @Provide
    var languagePreference: String = "system"

    @Provide
    var currentWorkplace: String = "github"

    @Provide
    var shellStack: NavPathStack = NavPathStack()

    @Provide
    var homeStack: NavPathStack = NavPathStack()

    @Provide
    var inboxStack: NavPathStack = NavPathStack()

    @Provide
    var exploreStack: NavPathStack = NavPathStack()

    @Provide
    var cursorStack: NavPathStack = NavPathStack()

    @Provide
    var hideFloatingNavigation: Bool = false

    @Provide
    var selectedRepository: String = ""

    @Provide
    var selectedIssue: String = ""

    @Provide
    var selectedPullRequest: String = ""

    @Provide
    var selectedTask: String = ""

    @State
    var draftPrStatusKey: String = "draft_pr_pending"

    @State
    var authMessage: String = ""

    @State
    var authVerificationUri: String = ""

    @State
    var authUserCode: String = ""

    @State
    var authRequestState: String = ""

    @State
    var authAccessToken: String = ""

    @Provide
    var sharedAuthAccessToken: String = ""

    @Provide
    var viewerLogin: String = ""

    @Provide
    var viewerAvatarUrl: String = ""

    @Provide
    var viewerProfileUrl: String = ""

    @Provide
    var liveRepositories: ArrayList<GitHubRepositoryCardSnapshot> = ArrayList<GitHubRepositoryCardSnapshot>()

    @Provide
    var liveRepositoryCount: String = "0"

    @Provide
    var liveStarredCount: String = "0"

    @Provide
    var liveOrganizationCount: String = "0"

    @Provide
    var liveGistCount: String = "0"

    @Provide
    var liveFollowerCount: String = "0"

    @Provide
    var liveFollowingCount: String = "0"

    @Provide
    var liveRepositoryDetail: GitHubRepositoryDetailSnapshot = GitHubRepositoryDetailSnapshot(
        "",
        "Connect GitHub to load repository details.",
        "",
        "",
        "0",
        "0",
        "main"
    )

    @Provide
    var liveRepositoryReadme: String = ""

    @Provide
    var liveIssues: ArrayList<GitHubIssueSnapshot> = ArrayList<GitHubIssueSnapshot>()

    @Provide
    var livePullRequests: ArrayList<GitHubPullRequestSnapshot> = ArrayList<GitHubPullRequestSnapshot>()

    @State
    var authCheckingToken: Bool = false

    @State
    var hasAttemptedSessionRestore: Bool = false

    var hasRestoredPreferences: Bool = false

    var authRequestSequence: Int64 = 0

    /**
     * 初始化顶层选中态，避免页面首次渲染时出现空引用状态。
     * Initializes top-level selections so the first render does not depend on empty state.
     */
    protected override func aboutToAppear(): Unit {
        this.restorePersistedPreferencesIfNeeded()
        setAppForegroundHandler({ => this.handleAppForeground() })
        setAppAuthCallbackHandler({ uri => this.handleAuthCallbackUri(uri) })
        setAppPreferenceHandler({ kind, value => this.applyRootPreference(kind, value) })
        setAppTabChangeHandler({ tab => this.handleTabTap(tab) })
        setAppSignOutHandler({ => this.signOut() })
        applyAppStatusBarStyle(this.isDarkTheme())
        if (let Some(pendingUri) <- consumePendingAuthCallback()) {
            this.handleAuthCallbackUri(pendingUri)
        }
        this.ensureInitialSelection()
        this.restorePersistedAuthSessionIfNeeded()
    }

    /**
     * 页面销毁前解除全局前台监听，避免旧组件继续接收生命周期回调。
     * Clears the app foreground listener before the shell disappears.
     */
    protected override func aboutToDisappear(): Unit {
        clearAppForegroundHandler()
        clearAppAuthCallbackHandler()
        clearAppPreferenceHandler()
        clearAppTabChangeHandler()
        clearAppSignOutHandler()
    }

    public func build() {
        if (this.isAuthenticated) {
            this.buildMainScene()
        } else {
            this.buildAuthScene()
        }
    }

    @Builder
    func buildAuthScene() {
        Stack() {
            Column() {}
                .width(100.percent)
                .height(100.percent)
                .backgroundColor(0x05070A)
                .expandSafeArea(types: [SafeAreaType.System], edges: [SafeAreaEdge.Top, SafeAreaEdge.Bottom])

            if (this.authStage == "welcome") {
                buildAuthWelcome(this)
            } else if (this.authStage == "credentials") {
                this.buildAuthCredentials()
            } else {
                buildAuthConnected(this)
            }

        }
        .width(100.percent)
        .height(100.percent)
    }

    @Builder
    func buildMainScene() {
        // The shell keeps one global Navigation for rare cross-tab routes, while each tab host
        // stays mounted with its own independent Navigation stack so tab switches preserve state.
        Navigation(this.shellStack) {
            Stack(alignContent: Alignment.Bottom) {
                Column() {
                    HomeTabHost()
                }
                .width(100.percent)
                .height(100.percent)
                .visibility(if (this.activeTab == "home") { Visibility.Visible } else { Visibility.None })

                Column() {
                    InboxTabHost()
                }
                .width(100.percent)
                .height(100.percent)
                .visibility(if (this.activeTab == "inbox") { Visibility.Visible } else { Visibility.None })

                Column() {
                    ExploreTabHost()
                }
                .width(100.percent)
                .height(100.percent)
                .visibility(if (this.activeTab == "explore") { Visibility.Visible } else { Visibility.None })

                Column() {
                    CursorTabHost()
                }
                .width(100.percent)
                .height(100.percent)
                .visibility(if (this.activeTab == "cursor") { Visibility.Visible } else { Visibility.None })

                Column(space: 10) {
                    if (this.showWorkplacePicker && !this.hideFloatingNavigation) {
                        buildWorkplacePicker(this)
                    }
                    if (!this.hideFloatingNavigation) {
                        Row() {
                            buildFloatingNavigation(this)
                        }
                        .width(100.percent)
                        .justifyContent(FlexAlign.Center)
                    }
                }
                .width(100.percent)
                .align(Alignment.Bottom)
                .padding(bottom: 0)
            }
            .width(100.percent)
            .height(100.percent)
        }
        .width(100.percent)
        .height(100.percent)
        .hideTitleBar(true)
        .navDestination(bind(shellPageMap, this))
    }

    /**
     * 认证页直接读取组件状态，确保 ArkUI 能建立状态到节点的依赖关系。
     * Reads auth state directly inside the component so ArkUI can bind state to render nodes.
     */
    @Builder
    func buildAuthCredentials() {
        Column() {
            Row() {
                Button("X")
                    .width(40).height(40).backgroundColor(0x1E232C).fontColor(0xF8FAFC).borderRadius(20)
                    .onClick({ _ => this.returnToAuthWelcome() })
                Blank()
                Text(this.t("auth_web_title")).fontSize(20).fontWeight(FontWeight.Bold).fontColor(0xF8FAFC)
                Blank()
                Button("...").width(40).height(40).backgroundColor(0x1E232C).fontColor(0xF8FAFC).borderRadius(20)
                    .onClick({ _ => this.setAuthMessage("More sign-in actions are not implemented yet.") })
            }
            .width(100.percent)
            .padding(left: 18, right: 18, top: 16)

            Column(space: 18) {
                Blank().height(32)
                Text(this.t("auth_web_subtitle")).fontSize(16).fontColor(0xE5E7EB).textAlign(TextAlign.Center)
                Text(if (this.authMessage == "") { this.t("auth_subtitle") } else { this.authMessage })
                    .fontSize(14).fontColor(0x98A2B3).textAlign(TextAlign.Center)

                Button("Open GitHub")
                    .width(100.percent).height(48).backgroundColor(0x458D45).fontColor(0xF8FAFC).fontSize(18).borderRadius(10)
                    .onClick({ _ => this.reopenGitHubVerification() })
            }
            .width(100.percent)
            .padding(left: 18, right: 18, top: 24)
        }
        .width(100.percent)
        .height(100.percent)
        .backgroundColor(0x11151B)
    }

    @Builder
    func buildRootBackgroundForTab(tabId: String) {
        Column() {
            if (tabId != "home" && tabId != "cursor") {
                Column() {}
                    .width(100.percent)
                    .height(260)
                    .backgroundColor(this.heroStartColor())
                    .opacity(0.96)
            }

            Blank()
        }
        .width(100.percent)
        .height(100.percent)
        .backgroundColor(this.pageBackgroundColor())
        .expandSafeArea(types: [SafeAreaType.System], edges: [SafeAreaEdge.Top, SafeAreaEdge.Bottom])
    }

    /**
     * 开始 GitHub Web 授权流程，构建授权链接并直接拉起 GitHub 登录页。
     * Starts the GitHub web authorization flow by building and opening the login URL.
     */
    func beginAuth(): Unit {
        logInfo("AppShell", "Begin GitHub authentication flow.")
        this.authRequestSequence += 1
        let launchSnapshot = buildGitHubAuthLaunchSnapshot(this.authRequestSequence)
        getUIContext().animateTo(AnimateParam(duration: 220, curve: Curve.Ease), { =>
            this.authStage = "credentials"
            this.authMessage = "Opening GitHub sign-in..."
            this.authVerificationUri = launchSnapshot.authorizationUri
            this.authUserCode = ""
            this.authRequestState = launchSnapshot.authState
            this.authCheckingToken = false
        })
        this.reopenGitHubVerification()
    }

    /**
     * 返回认证欢迎页，并清理当前这轮认证上下文。
     * Returns to the auth welcome stage and clears the current auth context.
     */
    func returnToAuthWelcome(): Unit {
        logInfo("AppShell", "Return to auth welcome stage.")
        getUIContext().animateTo(AnimateParam(duration: 220, curve: Curve.Ease), { =>
            this.authStage = "welcome"
            this.authMessage = ""
            this.authVerificationUri = ""
            this.authUserCode = ""
            this.authRequestState = ""
            this.authCheckingToken = false
        })
    }

    /**
     * 允许用户在等待页再次拉起 GitHub 验证页面。
     * Reopens the GitHub verification page from the waiting screen.
     */
    func confirmAuth(): Unit {
        this.reopenGitHubVerification()
    }

    func setAuthMessage(message: String): Unit {
        this.authMessage = message
    }

    func authMessageValue(): String {
        this.authMessage
    }

    /**
     * 将异步回调中的 UI 写操作切回主线程执行。
     * Moves UI mutations from async callbacks back onto the UI thread.
     */
    func runOnUi(task: () -> Unit): Unit {
        spawn(UIThread) { =>
            task()
        }
    }

    /**
     * 应用回前台时不主动轮询，只保留日志方便确认授权页面返回路径。
     * Keeps foreground handling lightweight because the auth callback should return through the deep link.
     */
    func handleAppForeground(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
        if (this.authStage != "credentials") {
            return
        }
        logInfo("AppShell", "App returned to foreground during auth.")
    }

    /**
     * 拉起 GitHub Web 授权页，等待浏览器通过 deep link 回调应用。
     * Opens the GitHub web authorization page and waits for the browser deep-link callback.
     */
    func reopenGitHubVerification(): Unit {
        if (this.authVerificationUri == "") {
            logWarn("AppShell", "Verification page requested before the URI was ready.")
            return
        }
        try {
            getAppAbilityContext().startAbility(
                Want(
                    uri: this.authVerificationUri,
                    action: "ohos.want.action.viewData"
                )
            )
            this.authMessage = "Sign in to GitHub, authorize RepoPilot, and it will return automatically."
            logInfo("AppShell", "Opened GitHub authorization page.")
        } catch (e: BusinessException) {
            logWarn("AppShell", "Failed to open GitHub authorization page: ${e.code} ${e.message}")
            this.applyAuthFailure("Unable to open GitHub. Please try again.")
        }
    }

    /**
     * 处理 GitHub 的 deep link 回调，提取 code 并交换 access token。
     * Handles the GitHub deep-link callback, extracts the code, and exchanges it for a token.
     */
    func handleAuthCallbackUri(uri: String): Unit {
        this.runOnUi({
            =>
            logInfo("AppShell", "Received GitHub callback URI in shell.")
            let authCode = extractUrlQueryParameter(uri, "code")
            let authState = extractUrlQueryParameter(uri, "state")
            let authError = extractUrlQueryParameter(uri, "error")
            if (authError != "") {
                this.applyAuthFailure("GitHub authorization failed: ${authError}")
                return
            }
            if (authCode == "") {
                this.applyAuthFailure("GitHub did not return an authorization code.")
                return
            }
            if (this.authRequestState != "" && authState != "" && authState != this.authRequestState) {
                this.applyAuthFailure("GitHub authorization state did not match the current request.")
                return
            }
            this.exchangeGitHubCallbackCode(authCode)
        })
    }

    /**
     * 使用授权回调里的 code 换取 access token，并在成功后继续加载真实 GitHub 数据。
     * Exchanges the callback code for an access token and continues loading live GitHub data.
     */
    func exchangeGitHubCallbackCode(authCode: String): Unit {
        if (this.authAccessToken != "" || this.authCheckingToken) {
            return
        }
        this.authCheckingToken = true
        this.authMessage = "Finishing GitHub authorization..."
        logInfo("AppShell", "Exchanging GitHub callback code.")
        exchangeGitHubAuthCode(
            authCode,
            { token => this.applyAccessToken(token) },
            { message => this.applyAuthFailure(message) }
        )
    }

    /**
     * 认证成功后保存访问令牌，并继续拉取真实 GitHub 用户数据。
     * Stores the access token after auth and continues loading live GitHub user data.
     */
    func applyAccessToken(snapshot: GitHubAccessTokenSnapshot): Unit {
        this.runOnUi({
            =>
            logInfo("AppShell", "GitHub access token stored in memory.")
            this.authAccessToken = snapshot.accessToken
            this.sharedAuthAccessToken = snapshot.accessToken
            this.authStage = "connected"
            this.authMessage = this.t("auth_connected_body")
            this.authRequestState = ""
            this.authCheckingToken = false
            logDebug("AppShell", "Access token state applied on UI thread.")
            spawn { => persistStoredGitHubSession(snapshot) }
            this.enterWorkspace()
            this.refreshGitHubProfile()
        })
    }

    /**
     * 将认证或网络错误反馈到认证界面。
     * Pushes auth or network failures into the auth UI.
     */
    func applyAuthFailure(message: String): Unit {
        this.runOnUi({
            =>
            logWarn("AppShell", "Auth flow failed: ${message}")
            this.authMessage = message
            this.authCheckingToken = false
            logDebug("AppShell", "Failure state applied on UI thread.")
        })
    }

    /**
     * 统一处理 GitHub API 失败；401 会清理持久化会话并退回登录态，其余错误只更新提示。
     * Handles GitHub API failures centrally; 401 clears the stored session and falls back to sign-in.
     */
    func handleGitHubApiFailure(message: String): Unit {
        if (message.contains("401")) {
            spawn { => clearStoredGitHubSession() }
            this.runOnUi({
                =>
                logWarn("AppShell", "GitHub session expired.")
                this.isAuthenticated = false
                this.authStage = "welcome"
                this.authMessage = "GitHub session expired. Please sign in again."
                this.authVerificationUri = ""
                this.authUserCode = ""
                this.authRequestState = ""
                this.authAccessToken = ""
                this.sharedAuthAccessToken = ""
                this.authCheckingToken = false
                this.viewerLogin = ""
                this.viewerAvatarUrl = ""
                this.viewerProfileUrl = ""
                this.liveRepositoryCount = "0"
                this.liveStarredCount = "0"
                this.liveOrganizationCount = "0"
                this.liveGistCount = "0"
                this.liveFollowerCount = "0"
                this.liveFollowingCount = "0"
                this.liveRepositories = ArrayList<GitHubRepositoryCardSnapshot>()
                this.liveRepositoryDetail = GitHubRepositoryDetailSnapshot("", "Connect GitHub to load repository details.", "", "", "0", "0", "main")
                this.liveRepositoryReadme = ""
                this.liveIssues = ArrayList<GitHubIssueSnapshot>()
                this.livePullRequests = ArrayList<GitHubPullRequestSnapshot>()
            })
            return
        }
        this.applyAuthFailure(message)
    }

    func enterWorkspace(): Unit {
        getUIContext().animateTo(AnimateParam(duration: 240, curve: Curve.Ease), { =>
            this.isAuthenticated = true
            this.activeTab = "home"
            this.showWorkplacePicker = false
            this.selectedRepository = ""
            this.selectedIssue = ""
            this.selectedPullRequest = ""
            this.selectedTask = ""
            this.draftPrStatusKey = "draft_pr_pending"
        })
    }

    func signOut(): Unit {
        logInfo("AppShell", "Signing out and clearing live GitHub state.")
        spawn { => clearStoredGitHubSession() }
        getUIContext().animateTo(AnimateParam(duration: 220, curve: Curve.Ease), { =>
            this.isAuthenticated = false
            this.authStage = "welcome"
            this.activeTab = "home"
            this.showWorkplacePicker = false
            this.authMessage = ""
            this.authVerificationUri = ""
            this.authUserCode = ""
            this.authRequestState = ""
            this.authAccessToken = ""
            this.sharedAuthAccessToken = ""
            this.shellStack = NavPathStack()
            this.homeStack = NavPathStack()
            this.inboxStack = NavPathStack()
            this.exploreStack = NavPathStack()
            this.cursorStack = NavPathStack()
            this.hideFloatingNavigation = false
            this.authCheckingToken = false
            this.viewerLogin = ""
            this.viewerAvatarUrl = ""
            this.viewerProfileUrl = ""
            this.liveRepositoryCount = "0"
            this.liveStarredCount = "0"
            this.liveOrganizationCount = "0"
            this.liveGistCount = "0"
            this.liveFollowerCount = "0"
            this.liveFollowingCount = "0"
            this.liveRepositories = ArrayList<GitHubRepositoryCardSnapshot>()
            this.liveRepositoryDetail = GitHubRepositoryDetailSnapshot("", "Connect GitHub to load repository details.", "", "", "0", "0", "main")
            this.liveRepositoryReadme = ""
            this.liveIssues = ArrayList<GitHubIssueSnapshot>()
            this.livePullRequests = ArrayList<GitHubPullRequestSnapshot>()
            this.hasAttemptedSessionRestore = true
        })
    }

    /**
     * 首次挂载时从 databoard 恢复登录态；若 access token 已过期，则尝试 refresh token。
     * Restores the persisted login session on first mount and refreshes it when needed.
     */
    func restorePersistedAuthSessionIfNeeded(): Unit {
        if (this.hasAttemptedSessionRestore) {
            return
        }
        this.hasAttemptedSessionRestore = true
        spawn {
            =>
            restoreStoredGitHubSession(
                { accessToken => this.restoreStoredAccessToken(accessToken) },
                { refreshToken => this.refreshStoredAccessToken(refreshToken) },
                { =>
                    logInfo("AppShell", "No restorable persisted GitHub session found.")
                }
            )
        }
    }

    func restoreStoredAccessToken(accessToken: String): Unit {
        this.runOnUi({
            =>
            logInfo("AppShell", "Restoring persisted GitHub session.")
            this.authAccessToken = accessToken
            this.sharedAuthAccessToken = accessToken
            this.authStage = "connected"
            this.authMessage = this.t("auth_connected_body")
            this.enterWorkspace()
            this.refreshGitHubProfile()
        })
    }

    func refreshStoredAccessToken(refreshToken: String): Unit {
        logInfo("AppShell", "Refreshing persisted GitHub session.")
        refreshStoredGitHubSession(
            refreshToken,
            { snapshot => this.applyAccessToken(snapshot) },
            {
                message =>
                logWarn("AppShell", "Stored session refresh failed: ${message}")
                clearStoredGitHubSession()
                this.applyAuthFailure("GitHub sign-in expired. Please sign in again.")
            }
        )
    }

    /**
     * 首次挂载时同步恢复主题和语言偏好，避免页面先按默认值渲染再跳变。
     * Restores theme and language preferences synchronously on first mount to avoid a flash of defaults.
     */
    func restorePersistedPreferencesIfNeeded(): Unit {
        if (this.hasRestoredPreferences) {
            return
        }
        this.hasRestoredPreferences = true

        this.themePreference = loadStoredThemePreference()
        this.languagePreference = loadStoredLanguagePreference()

    }

    func handleTabTap(tab: String): Unit {
        if (tab == "home" && this.activeTab == "home") {
            this.toggleWorkplacePicker(!this.showWorkplacePicker)
            return
        }
        this.activeTab = tab
        this.showWorkplacePicker = false
    }

    func toggleWorkplacePicker(show: Bool): Unit {
        getUIContext().animateTo(AnimateParam(duration: 180, curve: Curve.Ease), { =>
            this.showWorkplacePicker = show
        })
    }
    func switchWorkplace(workplaceId: String): Unit {
        let nextSelection = restoreMockWorkplaceSelection(workplaceId)
        getUIContext().animateTo(AnimateParam(duration: 200, curve: Curve.Ease), { =>
            this.currentWorkplace = workplaceId
            if (this.authAccessToken == "") {
                this.selectedRepository = nextSelection.repositoryId
                this.selectedIssue = nextSelection.issueId
                this.selectedPullRequest = nextSelection.pullRequestId
                this.selectedTask = nextSelection.taskId
            } else {
                this.selectedRepository = ""
                this.selectedIssue = ""
                this.selectedPullRequest = ""
                this.selectedTask = ""
            }
            this.showWorkplacePicker = false
        })
    }

    func createScratchRepository(): Unit {
        if (this.authAccessToken == "") {
            this.authMessage = this.t("repository_create_sign_in_required")
            return
        }
        createScratchGitHubRepository(
            this.authAccessToken,
            { repositoryName =>
                this.runOnUi({
                    =>
            this.authMessage = this.t("repository_created")
            this.activeTab = "home"
            this.refreshGitHubProfile()
        })
    },
            { message => this.applyAuthFailure(message) }
        )
    }

    func ensureInitialSelection(): Unit {
        if (this.currentWorkplace == "") {
            this.currentWorkplace = defaultWorkplace()
        }
        let nextSelection = ensureSelectionSnapshot(
            this.currentWorkplace,
            this.authAccessToken != "",
            this.selectedRepository,
            this.selectedIssue,
            this.selectedPullRequest,
            this.selectedTask,
            this.liveRepositories.size > 0,
            this.liveIssues.size > 0,
            this.livePullRequests.size > 0
        )
        this.selectedRepository = nextSelection.repositoryId
        this.selectedIssue = nextSelection.issueId
        this.selectedPullRequest = nextSelection.pullRequestId
        this.selectedTask = nextSelection.taskId
    }

    func isActiveTab(tab: String): Bool { this.activeTab == tab }
    func isCurrentWorkplace(workplaceId: String): Bool { this.currentWorkplace == workplaceId }
    func canCreateFromCurrentWorkplace(): Bool { this.currentWorkplace != "unified" }
    func applyRootPreference(kind: String, value: String): Unit {
        getUIContext().animateTo(AnimateParam(duration: 180, curve: Curve.Ease), { =>
            if (kind == "theme") {
                this.themePreference = value
                applyAppStatusBarStyle(this.isDarkTheme())
                spawn { => persistThemePreference(value) }
            } else {
                this.languagePreference = value
                spawn { => persistLanguagePreference(value) }
            }
        })
    }
    func refreshGitHubProfile(): Unit {
        if (this.authAccessToken == "") {
            return
        }
        logInfo("AppShell", "Refreshing GitHub viewer and repository summaries.")
        refreshGitHubProfileData(
            this.authAccessToken,
            { snapshot => this.applyViewer(snapshot) },
            { snapshot => this.applyProfileMetrics(snapshot) },
            { repositories => this.applyLiveRepositories(repositories) },
            { message => this.handleGitHubApiFailure(message) }
        )
    }
    /**
     * 更新当前登录用户的展示信息。
     * Updates the display metadata of the current GitHub viewer.
     */
    func applyViewer(snapshot: GitHubViewerSnapshot): Unit {
        this.runOnUi({
            =>
            logInfo("AppShell", "Viewer applied: ${snapshot.login}")
            this.viewerLogin = snapshot.login
            this.viewerAvatarUrl = snapshot.avatarUrl
            this.viewerProfileUrl = snapshot.profileUrl
            logDebug("AppShell", "Viewer state applied on UI thread.")
        })
    }

    /**
     * 更新个人页上展示的真实计数摘要。
     * Updates the live counters shown on the standalone profile page.
     */
    func applyProfileMetrics(snapshot: GitHubProfileMetricsSnapshot): Unit {
        this.runOnUi({
            =>
            this.liveRepositoryCount = snapshot.repositoryCount
            this.liveStarredCount = snapshot.starredCount
            this.liveOrganizationCount = snapshot.organizationCount
            this.liveGistCount = snapshot.gistCount
            this.liveFollowerCount = snapshot.followersCount
            this.liveFollowingCount = snapshot.followingCount
            logInfo("AppShell", "Applied live profile metrics.")
        })
    }
    /**
     * 更新个人页上的真实仓库摘要列表。
     * Updates the live repository summary list shown on the profile tab.
     */
    func applyLiveRepositories(repositories: ArrayList<GitHubRepositoryCardSnapshot>): Unit {
        this.runOnUi({
            =>
            logInfo("AppShell", "Applied ${repositories.size} live repositories.")
            this.liveRepositories = repositories
            this.liveRepositoryCount = "${repositories.size}"
            this.selectedRepository = resolveSelectedRepositoryId(this.selectedRepository, repositories)
            if (repositories.size > 0 && this.selectedRepository != "") {
                this.refreshSelectedRepositoryData()
            }
            logDebug("AppShell", "Live repository state applied on UI thread.")
        })
    }

    /**
     * 刷新当前选中仓库的真实详情、Issue 与 Pull Request 列表。
     * Refreshes the selected repository detail plus live issues and pull requests.
     */
    func refreshSelectedRepositoryData(): Unit {
        if (this.authAccessToken == "" || this.selectedRepository == "") {
            return
        }
        let repositoryName = this.selectedRepository
        logInfo("AppShell", "Refreshing selected repository data for ${repositoryName}.")
        refreshGitHubRepositoryBundle(
            this.authAccessToken,
            repositoryName,
            { snapshot => this.applyLiveRepositoryDetail(repositoryName, snapshot) },
            { markdown => this.applyLiveRepositoryReadme(repositoryName, markdown) },
            { items => this.applyLiveIssues(repositoryName, items) },
            { items => this.applyLivePullRequests(repositoryName, items) },
            { message => this.handleGitHubApiFailure(message) }
        )
    }

    /**
     * 更新当前仓库的真实详情卡片。
     * Updates the selected live repository detail card.
     */
    func applyLiveRepositoryDetail(repositoryName: String, snapshot: GitHubRepositoryDetailSnapshot): Unit {
        this.runOnUi({
            =>
            if (repositoryName != this.selectedRepository) {
                return
            }
            this.liveRepositoryDetail = snapshot
            logInfo("AppShell", "Applied live repository detail for ${repositoryName}.")
        })
    }

    func applyLiveRepositoryReadme(repositoryName: String, markdown: String): Unit {
        this.runOnUi({
            =>
            if (repositoryName != this.selectedRepository) {
                return
            }
            this.liveRepositoryReadme = markdown
        })
    }

    /**
     * 更新当前仓库的真实 Issue 列表，并同步默认选中项。
     * Updates the live issue list for the selected repository and syncs the default selection.
     */
    func applyLiveIssues(repositoryName: String, items: ArrayList<GitHubIssueSnapshot>): Unit {
        this.runOnUi({
            =>
            if (repositoryName != this.selectedRepository) {
                return
            }
            this.liveIssues = items
            let nextSelection = resolveSelectedIssueState(this.selectedIssue, items)
            if (nextSelection.issueId != "") {
                this.selectedIssue = nextSelection.issueId
                this.selectedTask = nextSelection.taskId
            }
            logInfo("AppShell", "Applied ${items.size} live issues for ${repositoryName}.")
        })
    }

    /**
     * 更新当前仓库的真实 Pull Request 列表，并同步默认选中项。
     * Updates the live pull request list for the selected repository and syncs the default selection.
     */
    func applyLivePullRequests(repositoryName: String, items: ArrayList<GitHubPullRequestSnapshot>): Unit {
        this.runOnUi({
            =>
            if (repositoryName != this.selectedRepository) {
                return
            }
            this.livePullRequests = items
            let nextDetail = this.liveRepositoryDetail
            this.liveRepositoryDetail = GitHubRepositoryDetailSnapshot(
                nextDetail.name,
                nextDetail.summary,
                nextDetail.repoUrl,
                nextDetail.visibilityLabel,
                nextDetail.issueCount,
                "${items.size}",
                nextDetail.defaultBranch
            )
            this.selectedPullRequest = resolveSelectedPullRequestId(this.selectedPullRequest, items)
            logInfo("AppShell", "Applied ${items.size} live pull requests for ${repositoryName}.")
        })
    }
    func preferenceLabel(kind: String, value: String): String {
        if (value == "system") {
            this.t("system")
        } else if (kind == "theme" && value == "dark") {
            this.t("dark")
        } else if (kind == "theme") {
            this.t("light")
        } else if (value == "zh") {
            this.t("lang_zh")
        } else {
            this.t("lang_en")
        }
    }
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func surfaceStrongColor(): Int64 { appThemeColor("surfaceStrong", this.isDarkTheme()) }
    func mutedSurfaceColor(): Int64 { appThemeColor("mutedSurface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
    func accentStrongColor(): Int64 { appThemeColor("accentStrong", this.isDarkTheme()) }
    func heroStartColor(): Int64 { appThemeColor("heroStart", this.isDarkTheme()) }
    func heroCardColor(): Int64 { appThemeColor("heroCard", this.isDarkTheme()) }
    func heroTextColor(): Int64 { appThemeColor("heroText", this.isDarkTheme()) }
    func heroSubTextColor(): Int64 { appThemeColor("heroSubText", this.isDarkTheme()) }
    func navBarColor(): Int64 { appThemeColor("navBar", this.isDarkTheme()) }
    func navBarOverlayColor(): Int64 { if (this.isDarkTheme()) { 0xD911151C } else { 0xDDF7F8FB } }
    func navSelectionColor(): Int64 { appThemeColor("navSelection", this.isDarkTheme()) }
    func topBarOverlayColor(): Int64 { if (this.isDarkTheme()) { 0xE0090B10 } else { 0xEAF2F3F7 } }
    func shadowColor(): Int64 { appThemeColor("shadow", this.isDarkTheme()) }
}
