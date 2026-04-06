package ohos_app_cangjie_entry.app

import kit.ArkUI.*
import kit.AbilityKit.Want
import ohos.business_exception.BusinessException
import ohos.base.UIThread
import std.collection.ArrayList
import ohos.arkui.state_macro_manage.*
import ohos_app_cangjie_entry.domain.{ExploreLaneSnapshot, GitHubAccessTokenSnapshot, GitHubRepositoryCardSnapshot, GitHubViewerSnapshot, InboxItemSnapshot, PullRequestSnapshot, RepositorySnapshot, TaskSnapshot}
import ohos_app_cangjie_entry.infra.logging.{logDebug, logInfo, logWarn}
import ohos_app_cangjie_entry.infra.runtime.{clearAppAuthCallbackHandler, clearAppForegroundHandler, consumePendingAuthCallback, getAppAbilityContext, setAppAuthCallbackHandler, setAppForegroundHandler}
import ohos_app_cangjie_entry.services.platform.{activeAccountSnapshot, defaultWorkplace, exploreLane, inboxItem, primaryRepositoryId, pullRequestSnapshot, repositorySnapshot, workplaceSnapshot}
import ohos_app_cangjie_entry.services.github.{buildGitHubAuthorizationUri, exchangeGitHubWebCode, extractUrlQueryParameter}
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
    var authRequestState: String = ""

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

    var authRequestSequence: Int64 = 0

    /**
     * 初始化顶层选中态，避免页面首次渲染时出现空引用状态。
     * Initializes top-level selections so the first render does not depend on empty state.
     */
    protected override func aboutToAppear(): Unit {
        setAppForegroundHandler({ => this.handleAppForeground() })
        setAppAuthCallbackHandler({ uri => this.handleAuthCallbackUri(uri) })
        if (let Some(pendingUri) <- consumePendingAuthCallback()) {
            this.handleAuthCallbackUri(pendingUri)
        }
        this.ensureInitialSelection()
    }

    /**
     * 页面销毁前解除全局前台监听，避免旧组件继续接收生命周期回调。
     * Clears the app foreground listener before the shell disappears.
     */
    protected override func aboutToDisappear(): Unit {
        clearAppForegroundHandler()
        clearAppAuthCallbackHandler()
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
     * 开始 GitHub Web 授权流程，构建授权链接并直接拉起 GitHub 登录页。
     * Starts the GitHub web authorization flow by building and opening the login URL.
     */
    func beginAuth(): Unit {
        logInfo("AppShell", "Begin GitHub authentication flow.")
        this.authRequestSequence += 1
        let authState = "repopilot-auth-${this.authRequestSequence}"
        let authorizationUri = buildGitHubAuthorizationUri(authState)
        getUIContext().animateTo(AnimateParam(duration: 220, curve: Curve.Ease), { =>
            this.authStage = "credentials"
            this.authMessage = "Opening GitHub sign-in..."
            this.authVerificationUri = authorizationUri
            this.authUserCode = ""
            this.authRequestState = authState
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
        exchangeGitHubWebCode(
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
            this.authStage = "connected"
            this.authMessage = this.t("auth_connected_body")
            this.authRequestState = ""
            this.authCheckingToken = false
            logDebug("AppShell", "Access token state applied on UI thread.")
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
            this.authRequestState = ""
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
