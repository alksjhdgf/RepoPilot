package ohos_app_cangjie_entry.app

import kit.ArkUI.*
import kit.AbilityKit.Want
import ohos.business_exception.BusinessException
import ohos.base.UIThread
import std.collection.ArrayList
import ohos.arkui.state_macro_manage.*
import ohos_app_cangjie_entry.domain.{ExploreLaneSnapshot, GitHubAccessTokenSnapshot, GitHubDeviceCodeSnapshot, GitHubRepositoryCardSnapshot, GitHubViewerSnapshot, InboxItemSnapshot, PullRequestSnapshot, RepositorySnapshot, TaskSnapshot}
import ohos_app_cangjie_entry.infra.logging.{logDebug, logInfo, logWarn}
import ohos_app_cangjie_entry.infra.runtime.{clearAppForegroundHandler, getAppAbilityContext, setAppForegroundHandler}
import ohos_app_cangjie_entry.services.platform.{activeAccountSnapshot, defaultWorkplace, exploreLane, inboxItem, primaryRepositoryId, pullRequestSnapshot, repositorySnapshot, workplaceSnapshot}
import ohos_app_cangjie_entry.services.github.{exchangeGitHubDeviceCode, requestGitHubDeviceCode}
import ohos_app_cangjie_entry.services.github.{fetchGitHubRepositories, fetchGitHubViewer}
import ohos_app_cangjie_entry.services.agent.{taskIdForIssue, taskSnapshot}
import ohos_app_cangjie_entry.ui.theme.{appResolveIsDarkTheme, appThemeColor}
import ohos_app_cangjie_entry.ui.i18n.{appLocalizedText, appResolveLanguage}

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
    var stack: NavPathStack = NavPathStack()

    @Provide
    var selectedRepository: String = ""

    @Provide
    var selectedIssue: String = ""

    @Provide
    var selectedPullRequest: String = ""

    @Provide
    var selectedTask: String = ""

    @Provide
    var draftPrStatusKey: String = "draft_pr_pending"

    @State
    var authMessage: String = ""

    @State
    var authVerificationUri: String = ""

    @State
    var authUserCode: String = ""

    @State
    var authDeviceCode: String = ""

    @State
    var authAccessToken: String = ""

    @State
    var viewerLogin: String = ""

    @State
    var viewerDisplayName: String = ""

    @State
    var liveRepositories: ArrayList<GitHubRepositoryCardSnapshot> = ArrayList<GitHubRepositoryCardSnapshot>()

    @State
    var authCheckingToken: Bool = false

    /**
     * 初始化顶层选中态，避免页面首次渲染时出现空引用状态。
     * Initializes top-level selections so the first render does not depend on empty state.
     */
    protected override func aboutToAppear(): Unit {
        setAppForegroundHandler({ => this.handleAppForeground() })
        this.ensureInitialSelection()
    }

    /**
     * 页面销毁前解除全局前台监听，避免旧组件继续接收生命周期回调。
     * Clears the app foreground listener before the shell disappears.
     */
    protected override func aboutToDisappear(): Unit {
        clearAppForegroundHandler()
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
        Navigation(this.stack) {
            Stack() {
                this.buildRootBackground()

                Scroll {
                    Column(space: 18) {
                        buildTopBar(this)
                        buildActiveTabContent(this)
                    }
                    .width(100.percent)
                    .padding(left: 18, right: 18, top: 16, bottom: 132)
                }
                .width(100.percent)
                .height(100.percent)
                .scrollBar(BarState.Off)

                if (this.showWorkplacePicker) {
                    Column() {}
                        .width(100.percent)
                        .height(100.percent)
                        .backgroundColor(0x33000000)
                        .onClick({ _ => this.toggleWorkplacePicker(false) })

                    buildWorkplacePicker(this)
                }

                Column() {
                    Blank()
                    buildFloatingNavigation(this)
                }
                .width(100.percent)
                .height(100.percent)
            }
            .width(100.percent)
            .height(100.percent)
        }
        .width(100.percent)
        .height(100.percent)
        .hideTitleBar(true)
        .navDestination(bind(pageMap, this))
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
    func buildRootBackground() {
        Column() {
            Column() {}
                .width(100.percent)
                .height(260)
                .backgroundColor(this.heroStartColor())
                .opacity(0.96)

            Blank()
        }
        .width(100.percent)
        .height(100.percent)
        .backgroundColor(this.pageBackgroundColor())
    }

    /**
     * 开始 GitHub 登录流程，先请求 device code，再展示给用户。
     * Starts GitHub sign-in by requesting a device code before showing it in the auth sheet.
     */
    func beginAuth(): Unit {
        logInfo("AppShell", "Begin GitHub authentication flow.")
        getUIContext().animateTo(AnimateParam(duration: 220, curve: Curve.Ease), { =>
            this.authStage = "credentials"
            this.authMessage = "Preparing GitHub sign-in..."
            this.authVerificationUri = ""
            this.authUserCode = ""
            this.authDeviceCode = ""
            this.authCheckingToken = false
        })
        requestGitHubDeviceCode(
            { snapshot => this.applyDeviceCode(snapshot) },
            { message => this.applyAuthFailure(message) }
        )
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
            this.authDeviceCode = ""
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
     * 应用重新回到前台时尝试检查授权结果，避免在后台持续轮询 GitHub。
     * Checks auth completion when the app returns to foreground instead of polling in the background.
     */
    func handleAppForeground(): Unit {
        if (this.authStage != "credentials" || this.authDeviceCode == "") {
            return
        }
        logInfo("AppShell", "App returned to foreground during auth.")
        this.checkAuthAuthorization("app_foreground")
    }

    /**
     * 拉起 GitHub 授权页；当前优先使用 GitHub 返回的完整验证链接，减少用户手工输入 code。
     * Opens GitHub authorization in the system browser, preferring the complete verification link when available.
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
            this.authMessage = "Finish authorization in GitHub, then return to RepoPilot."
            logInfo("AppShell", "Opened GitHub verification page.")
        } catch (e: BusinessException) {
            logWarn("AppShell", "Failed to open GitHub verification page: ${e.code} ${e.message}")
            this.applyAuthFailure("Unable to open GitHub. Please try again.")
        }
    }

    /**
     * 在关键时刻单次向 GitHub 交换 access token，避免高频轮询导致限流。
     * Performs a one-shot token exchange at key moments instead of high-frequency polling.
     */
    func checkAuthAuthorization(trigger: String): Unit {
        if (this.authDeviceCode == "" || this.authAccessToken != "" || this.authCheckingToken) {
            return
        }
        this.authCheckingToken = true
        logInfo("AppShell", "Checking GitHub authorization after ${trigger}.")
        exchangeGitHubDeviceCode(
            this.authDeviceCode,
            { token => this.applyAccessToken(token) },
            { code, description => this.handlePendingAuth(code, description) },
            { message => this.applyAuthFailure(message) }
        )
    }

    /**
     * 重新拉起 GitHub 验证页面，减少用户手动复制地址的步骤。
     * Opens the GitHub verification page through the system browser or web handler.
     */
    func handlePendingAuth(code: String, description: String): Unit {
        this.runOnUi({
            =>
            this.authCheckingToken = false
            if (code == "slow_down") {
                this.authMessage = "GitHub asked RepoPilot to slow down. Return later to continue sign-in."
            } else {
                this.authMessage = "Finish authorization in GitHub, then return to RepoPilot."
            }
            logDebug("AppShell", "Auth still pending after ${description}: ${code}")
        })
    }

    /**
     * 将 device code 请求结果写回 UI 状态。
     * Writes the device code response back into the auth UI state.
     */
    func applyDeviceCode(snapshot: GitHubDeviceCodeSnapshot): Unit {
        this.runOnUi({
            =>
            logInfo("AppShell", "Device code received. userCode=${snapshot.userCode} authVerificationUri=${snapshot.verificationUri}")
            this.authMessage = "Continue in GitHub to sign in and authorize RepoPilot."
            this.authVerificationUri = snapshot.verificationUri
            this.authUserCode = snapshot.userCode
            this.authDeviceCode = snapshot.deviceCode
            this.authCheckingToken = false
            logDebug("AppShell", "Device code state applied on UI thread.")
            this.reopenGitHubVerification()
        })
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
            this.authStage = "connected"
            this.authMessage = this.t("auth_connected_body")
            this.authCheckingToken = false
            logDebug("AppShell", "Access token state applied on UI thread.")
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

    func enterWorkspace(): Unit {
        getUIContext().animateTo(AnimateParam(duration: 240, curve: Curve.Ease), { =>
            this.isAuthenticated = true
            this.activeTab = "home"
            this.showWorkplacePicker = false
            this.selectedRepository = primaryRepositoryId(this.currentWorkplace)
            this.selectedIssue = repositorySnapshot(this.selectedRepository).primaryIssueId
            this.selectedPullRequest = repositorySnapshot(this.selectedRepository).primaryPullRequestId
            this.selectedTask = taskIdForIssue(this.selectedIssue)
            this.draftPrStatusKey = "draft_pr_pending"
        })
    }

    func signOut(): Unit {
        logInfo("AppShell", "Signing out and clearing live GitHub state.")
        getUIContext().animateTo(AnimateParam(duration: 220, curve: Curve.Ease), { =>
            this.isAuthenticated = false
            this.authStage = "welcome"
            this.authMessage = ""
            this.authVerificationUri = ""
            this.authUserCode = ""
            this.authDeviceCode = ""
            this.authAccessToken = ""
            this.authCheckingToken = false
            this.viewerLogin = ""
            this.viewerDisplayName = ""
            this.liveRepositories = ArrayList<GitHubRepositoryCardSnapshot>()
        })
    }

    func handleTabTap(tab: String): Unit {
        if (tab == "home" && this.activeTab == "home") {
            this.toggleWorkplacePicker(!this.showWorkplacePicker)
            return
        }
        getUIContext().animateTo(AnimateParam(duration: 200, curve: Curve.Ease), { =>
            this.activeTab = tab
            this.showWorkplacePicker = false
        })
    }

    func toggleWorkplacePicker(show: Bool): Unit {
        getUIContext().animateTo(AnimateParam(duration: 180, curve: Curve.Ease), { =>
            this.showWorkplacePicker = show
        })
    }

    func switchWorkplace(workplaceId: String): Unit {
        let repositoryId = primaryRepositoryId(workplaceId)
        let repository = repositorySnapshot(repositoryId)
        getUIContext().animateTo(AnimateParam(duration: 200, curve: Curve.Ease), { =>
            this.currentWorkplace = workplaceId
            this.selectedRepository = repositoryId
            this.selectedIssue = repository.primaryIssueId
            this.selectedPullRequest = repository.primaryPullRequestId
            this.selectedTask = taskIdForIssue(repository.primaryIssueId)
            this.showWorkplacePicker = false
        })
    }

    func createScratchRepository(): Unit {
        this.authMessage = this.t("draft_pr_pending")
    }

    func ensureInitialSelection(): Unit {
        if (this.currentWorkplace == "") {
            this.currentWorkplace = defaultWorkplace()
        }
        if (this.selectedRepository == "") {
            this.selectedRepository = primaryRepositoryId(this.currentWorkplace)
        }
        if (this.selectedIssue == "") {
            this.selectedIssue = repositorySnapshot(this.selectedRepository).primaryIssueId
        }
        if (this.selectedPullRequest == "") {
            this.selectedPullRequest = repositorySnapshot(this.selectedRepository).primaryPullRequestId
        }
        if (this.selectedTask == "") {
            this.selectedTask = taskIdForIssue(this.selectedIssue)
        }
    }

    func currentWorkplaceTitle(): String { this.t(workplaceSnapshot(this.currentWorkplace).titleKey) }
    func currentWorkplaceSummary(): String { this.t(workplaceSnapshot(this.currentWorkplace).summaryKey) }
    func currentWorkplaceHeroTitle(): String { this.t(workplaceSnapshot(this.currentWorkplace).heroTitleKey) }
    func primaryHomeRepository(): RepositorySnapshot { repositorySnapshot(primaryRepositoryId(this.currentWorkplace)) }
    func secondaryHomeRepository(): RepositorySnapshot { repositorySnapshot("bff") }
    func tertiaryHomeRepository(): RepositorySnapshot { repositorySnapshot("orchestrator") }
    func visibleRepositories(): ArrayList<RepositorySnapshot> {
        let items = ArrayList<RepositorySnapshot>()
        items.add(this.primaryHomeRepository())
        items.add(this.secondaryHomeRepository())
        items.add(this.tertiaryHomeRepository())
        items
    }
    func focusedTask(): TaskSnapshot { taskSnapshot(this.selectedTask) }
    func reviewTask(): TaskSnapshot { taskSnapshot("repoPolish") }
    func highlightedPullRequest(): PullRequestSnapshot { pullRequestSnapshot(this.selectedPullRequest) }
    func inboxPrimary(): InboxItemSnapshot { inboxItem(1) }
    func inboxSecondary(): InboxItemSnapshot { inboxItem(2) }
    func inboxTertiary(): InboxItemSnapshot { inboxItem(3) }
    func firstExploreLane(): ExploreLaneSnapshot { exploreLane(1) }
    func secondExploreLane(): ExploreLaneSnapshot { exploreLane(2) }
    func isActiveTab(tab: String): Bool { this.activeTab == tab }
    func isCurrentWorkplace(workplaceId: String): Bool { this.currentWorkplace == workplaceId }
    func themePreferenceValue(): String { this.themePreference }
    func languagePreferenceValue(): String { this.languagePreference }
    func mainTitle(): String {
        if (this.activeTab == "home") {
            this.currentWorkplaceTitle()
        } else if (this.activeTab == "inbox") {
            this.t("inbox")
        } else if (this.activeTab == "explore") {
            this.t("explore")
        } else {
            this.t("profile")
        }
    }
    func mainSubtitle(): String {
        if (this.activeTab == "home") {
            this.currentWorkplaceSummary()
        } else if (this.activeTab == "inbox") {
            this.t("inbox_subtitle")
        } else if (this.activeTab == "explore") {
            this.t("explore_subtitle")
        } else {
            this.t("profile_subtitle")
        }
    }
    func accountCaption(): String {
        if (this.viewerLogin != "") {
            return "GitHub / ${this.viewerDisplayName} (@${this.viewerLogin})"
        }
        let account = activeAccountSnapshot()
        "${this.t("profile_account_prefix")}: ${this.t(account.providerKey)} / ${account.accountLabel}"
    }
    func hasLiveRepositories(): Bool { this.liveRepositories.size > 0 }
    func visibleLiveRepositories(): ArrayList<GitHubRepositoryCardSnapshot> { this.liveRepositories }
    func applyRootPreference(kind: String, value: String): Unit {
        getUIContext().animateTo(AnimateParam(duration: 180, curve: Curve.Ease), { =>
            if (kind == "theme") {
                this.themePreference = value
            } else {
                this.languagePreference = value
            }
        })
    }
    func refreshGitHubProfile(): Unit {
        if (this.authAccessToken == "") {
            return
        }
        logInfo("AppShell", "Refreshing GitHub viewer and repository summaries.")
        fetchGitHubViewer(
            this.authAccessToken,
            { snapshot => this.applyViewer(snapshot) },
            { message => this.applyAuthFailure(message) }
        )
        fetchGitHubRepositories(
            this.authAccessToken,
            { repositories => this.applyLiveRepositories(repositories) },
            { message => this.applyAuthFailure(message) }
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
            this.viewerDisplayName = snapshot.displayName
            logDebug("AppShell", "Viewer state applied on UI thread.")
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
            logDebug("AppShell", "Live repository state applied on UI thread.")
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
    func navSelectionColor(): Int64 { appThemeColor("navSelection", this.isDarkTheme()) }
    func shadowColor(): Int64 { appThemeColor("shadow", this.isDarkTheme()) }

    func openRepository(repositoryId: String): Unit {
        this.selectedRepository = repositoryId
        let repository = repositorySnapshot(repositoryId)
        this.selectedIssue = repository.primaryIssueId
        this.selectedPullRequest = repository.primaryPullRequestId
        this.selectedTask = taskIdForIssue(this.selectedIssue)
        this.stack.pushPath(NavPathInfo(name: "repositoryDetail", param: ""), options: NavigationOptions(animated: true))
    }

    func openSelectedIssue(): Unit {
        this.stack.pushPath(NavPathInfo(name: "issueDetail", param: ""), options: NavigationOptions(animated: true))
    }

    func openSelectedPullRequest(): Unit {
        this.stack.pushPath(NavPathInfo(name: "pullRequestDetail", param: ""), options: NavigationOptions(animated: true))
    }

    func openCreateTask(): Unit {
        this.stack.pushPath(NavPathInfo(name: "createTask", param: ""), options: NavigationOptions(animated: true))
    }

    func openTaskDetail(taskId: String): Unit {
        this.selectedTask = taskId
        this.stack.pushPath(NavPathInfo(name: "taskDetail", param: ""), options: NavigationOptions(animated: true))
    }

    func openDiffReview(): Unit {
        this.stack.pushPath(NavPathInfo(name: "diffReview", param: ""), options: NavigationOptions(animated: true))
    }

    func openSettings(): Unit {
        this.stack.pushPath(NavPathInfo(name: "settings", param: ""), options: NavigationOptions(animated: true))
    }
}
