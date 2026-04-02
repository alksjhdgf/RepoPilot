package ohos_app_cangjie_entry.app

import kit.ArkUI.*
import std.collection.ArrayList
import ohos.arkui.state_macro_manage.*
import ohos_app_cangjie_entry.domain.{ExploreLaneSnapshot, GitHubAccessTokenSnapshot, GitHubDeviceCodeSnapshot, GitHubRepositoryCardSnapshot, GitHubViewerSnapshot, InboxItemSnapshot, PullRequestSnapshot, RepositorySnapshot, TaskSnapshot}
import ohos_app_cangjie_entry.infra.logging.{logInfo, logWarn}
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

    /**
     * 初始化顶层选中态，避免页面首次渲染时出现空引用状态。
     * Initializes top-level selections so the first render does not depend on empty state.
     */
    protected override func aboutToAppear(): Unit {
        this.ensureInitialSelection()
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
                buildAuthCredentials(this)
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
            this.authMessage = "Requesting a GitHub device code..."
            this.authVerificationUri = ""
            this.authUserCode = ""
            this.authDeviceCode = ""
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
        })
    }

    /**
     * 在用户完成网页授权后继续轮询 GitHub 访问令牌。
     * Continues token polling after the user finishes authorization in GitHub.
     */
    func confirmAuth(): Unit {
        if (this.authDeviceCode == "") {
            logWarn("AppShell", "Confirm auth tapped before device code was ready.")
            this.authMessage = "Device code not ready yet."
            return
        }
        logInfo("AppShell", "Confirming GitHub authorization with device code.")
        this.authMessage = "Checking GitHub authorization..."
        exchangeGitHubDeviceCode(
            this.authDeviceCode,
            { token => this.applyAccessToken(token) },
            { message => this.applyAuthFailure(message) }
        )
    }

    /**
     * 将 device code 请求结果写回 UI 状态。
     * Writes the device code response back into the auth UI state.
     */
    func applyDeviceCode(snapshot: GitHubDeviceCodeSnapshot): Unit {
        logInfo("AppShell", "Device code received. userCode=${snapshot.userCode}")
        getUIContext().animateTo(AnimateParam(duration: 220, curve: Curve.Ease), { =>
            this.authMessage = "Open the GitHub page below and enter the code."
            this.authVerificationUri = snapshot.verificationUri
            this.authUserCode = snapshot.userCode
            this.authDeviceCode = snapshot.deviceCode
        })
    }

    /**
     * 认证成功后保存访问令牌，并继续拉取真实 GitHub 用户数据。
     * Stores the access token after auth and continues loading live GitHub user data.
     */
    func applyAccessToken(snapshot: GitHubAccessTokenSnapshot): Unit {
        logInfo("AppShell", "GitHub access token stored in memory.")
        getUIContext().animateTo(AnimateParam(duration: 220, curve: Curve.Ease), { =>
            this.authAccessToken = snapshot.accessToken
            this.authStage = "connected"
            this.authMessage = this.t("auth_connected_body")
        })
        this.refreshGitHubProfile()
    }

    /**
     * 将认证或网络错误反馈到认证界面。
     * Pushes auth or network failures into the auth UI.
     */
    func applyAuthFailure(message: String): Unit {
        logWarn("AppShell", "Auth flow failed: ${message}")
        getUIContext().animateTo(AnimateParam(duration: 220, curve: Curve.Ease), { =>
            this.authMessage = message
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
    func authVerificationHint(): String {
        if (this.authVerificationUri == "") { "Waiting for GitHub..." } else { this.authVerificationUri }
    }
    func authUserCodeValue(): String {
        if (this.authUserCode == "") { "---- ----" } else { this.authUserCode }
    }
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
        logInfo("AppShell", "Viewer applied: ${snapshot.login}")
        getUIContext().animateTo(AnimateParam(duration: 180, curve: Curve.Ease), { =>
            this.viewerLogin = snapshot.login
            this.viewerDisplayName = snapshot.displayName
        })
    }
    /**
     * 更新个人页上的真实仓库摘要列表。
     * Updates the live repository summary list shown on the profile tab.
     */
    func applyLiveRepositories(repositories: ArrayList<GitHubRepositoryCardSnapshot>): Unit {
        logInfo("AppShell", "Applied ${repositories.size} live repositories.")
        getUIContext().animateTo(AnimateParam(duration: 180, curve: Curve.Ease), { =>
            this.liveRepositories = repositories
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
    func authMessageText(): String { if (this.authMessage == "") { this.t("auth_subtitle") } else { this.authMessage } }
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
