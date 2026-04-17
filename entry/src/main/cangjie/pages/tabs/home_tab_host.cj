package ohos_app_cangjie_entry.pages.tabs

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.*
import ohos.base.UIThread
import std.collection.ArrayList
import ohos_app_cangjie_entry.pages.maps.homePageMap
import ohos_app_cangjie_entry.domain.{GitHubIssueSnapshot, GitHubProfileMetricsSnapshot, GitHubPullRequestSnapshot, GitHubRepositoryCardSnapshot, GitHubRepositoryDetailSnapshot, GitHubViewerSnapshot}
import ohos_app_cangjie_entry.services.app.{createScratchGitHubRepository, refreshGitHubProfileData, refreshGitHubRepositoryBundle, resolveSelectedIssueState, resolveSelectedPullRequestId, resolveSelectedRepositoryId}
import ohos_app_cangjie_entry.services.agent.taskIdForIssue
import ohos_app_cangjie_entry.services.platform.repositorySnapshot

@Component
public class HomeTabHost {
    @Consume var homeStack: NavPathStack = NavPathStack()
    @Consume var themePreference: String = "system"
    @Consume var languagePreference: String = "system"
    @Consume var currentWorkplace: String = "github"
    @Consume var sharedAuthAccessToken: String = ""
    @Consume var viewerAvatarUrl: String = ""
    @Consume var viewerLogin: String = ""
    @Consume var viewerProfileUrl: String = ""
    @Consume var liveRepositories: ArrayList<GitHubRepositoryCardSnapshot> = ArrayList<GitHubRepositoryCardSnapshot>()
    @Consume var liveRepositoryCount: String = "0"
    @Consume var liveStarredCount: String = "0"
    @Consume var liveOrganizationCount: String = "0"
    @Consume var liveRepositoryDetail: GitHubRepositoryDetailSnapshot = GitHubRepositoryDetailSnapshot("", "", "", "", "0", "0", "main")
    @Consume var liveIssues: ArrayList<GitHubIssueSnapshot> = ArrayList<GitHubIssueSnapshot>()
    @Consume var livePullRequests: ArrayList<GitHubPullRequestSnapshot> = ArrayList<GitHubPullRequestSnapshot>()
    @Consume var selectedRepository: String = ""
    @Consume var selectedIssue: String = ""
    @Consume var selectedPullRequest: String = ""
    @Consume var selectedTask: String = ""

    @Provide var pendingPageTitle: String = "Pending"
    @Provide var pendingPageMessage: String = "该页面待开发"
    @Provide var pendingPullRequestReviewEvent: String = "COMMENT"

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @State var homeRefreshing: Bool = false
    @State var homeActionMessage: String = ""

    protected override func aboutToAppear(): Unit {
        this.refreshHomeContent()
    }

    public func build() {
        Navigation(this.homeStack) {
            Stack(alignContent: Alignment.Top) {
                this.buildTabBackground("home")

                Column(space: 0) {
                    this.buildTopBar()

                    Refresh(RefreshOptions(refreshing: @Binder(homeRefreshing))) {
                        Scroll {
                            Column(space: 16) {
                                this.buildHomeContent()
                            }
                            .width(100.percent)
                            .padding(left: 18, right: 18, top: 18, bottom: 100)
                        }
                        .width(100.percent)
                        .height(100.percent)
                        .scrollBar(BarState.Off)
                        .align(Alignment.Top)
                        .expandSafeArea(types: [SafeAreaType.System], edges: [SafeAreaEdge.Bottom])
                    }
                    .layoutWeight(1)
                    .width(100.percent)
                    .onRefreshing({ => this.refreshHomeContent(showRefreshIndicator: true) })
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
        .navDestination(bind(homePageMap, this))
    }

    func refreshHomeContent(showRefreshIndicator!: Bool = false): Unit {
        if (showRefreshIndicator) {
            this.homeRefreshing = true
        }
        if (this.sharedAuthAccessToken == "") {
            this.homeRefreshing = false
            return
        }
        refreshGitHubProfileData(
            this.sharedAuthAccessToken,
            { snapshot => this.applyViewer(snapshot) },
            { snapshot => this.applyMetrics(snapshot) },
            { repositories => this.applyRepositories(repositories) },
            { _ => this.runOnUi({ => this.homeRefreshing = false }) }
        )
        if (this.selectedRepository != "") {
            refreshGitHubRepositoryBundle(
                this.sharedAuthAccessToken,
                this.selectedRepository,
                { snapshot => this.applyRepositoryDetail(snapshot) },
                { items => this.applyIssues(items) },
                { items => this.applyPullRequests(items) },
                { _ => this.runOnUi({ => this.homeRefreshing = false }) }
            )
        } else {
            this.runOnUi({ => this.homeRefreshing = false })
        }
    }

    func runOnUi(task: () -> Unit): Unit {
        spawn(UIThread) { => task() }
    }

    func applyViewer(snapshot: GitHubViewerSnapshot): Unit {
        this.runOnUi({
            =>
            this.viewerLogin = snapshot.login
            this.viewerAvatarUrl = snapshot.avatarUrl
            this.viewerProfileUrl = snapshot.profileUrl
        })
    }

    func applyMetrics(snapshot: GitHubProfileMetricsSnapshot): Unit {
        this.runOnUi({
            =>
            this.liveRepositoryCount = snapshot.repositoryCount
            this.liveStarredCount = snapshot.starredCount
            this.liveOrganizationCount = snapshot.organizationCount
        })
    }

    func applyRepositories(repositories: ArrayList<GitHubRepositoryCardSnapshot>): Unit {
        this.runOnUi({
            =>
            this.liveRepositories = repositories
            this.liveRepositoryCount = "${repositories.size}"
            this.selectedRepository = resolveSelectedRepositoryId(this.selectedRepository, repositories)
            this.homeRefreshing = false
        })
    }

    func applyRepositoryDetail(snapshot: GitHubRepositoryDetailSnapshot): Unit {
        this.runOnUi({ => this.liveRepositoryDetail = snapshot })
    }

    func applyIssues(items: ArrayList<GitHubIssueSnapshot>): Unit {
        this.runOnUi({
            =>
            this.liveIssues = items
            let nextSelection = resolveSelectedIssueState(this.selectedIssue, items)
            if (nextSelection.issueId != "") {
                this.selectedIssue = nextSelection.issueId
                this.selectedTask = nextSelection.taskId
            }
            this.homeRefreshing = false
        })
    }

    func applyPullRequests(items: ArrayList<GitHubPullRequestSnapshot>): Unit {
        this.runOnUi({
            =>
            this.livePullRequests = items
            this.selectedPullRequest = resolveSelectedPullRequestId(this.selectedPullRequest, items)
            this.homeRefreshing = false
        })
    }

    func t(key: String): String { tabText(this.languagePreference, this.systemLanguageCode, key) }
    func isDarkTheme(): Bool { tabIsDarkTheme(this.themePreference, this.systemColorMode) }
    func surfaceColor(): Int64 { tabColor("surface", this.themePreference, this.systemColorMode) }
    func mutedSurfaceColor(): Int64 { tabColor("mutedSurface", this.themePreference, this.systemColorMode) }
    func primaryTextColor(): Int64 { tabColor("primaryText", this.themePreference, this.systemColorMode) }
    func secondaryTextColor(): Int64 { tabColor("secondaryText", this.themePreference, this.systemColorMode) }
    func accentStrongColor(): Int64 { tabColor("accentStrong", this.themePreference, this.systemColorMode) }
    func topBarOverlayColor(): Int64 { if (this.isDarkTheme()) { 0xE0090B10 } else { 0xEAF2F3F7 } }
    func currentHeaderWorkplaceTitle(): String { tabWorkplaceHeaderTitle(this.currentWorkplace, this.languagePreference, this.systemLanguageCode) }
    func canCreateFromCurrentWorkplace(): Bool { this.currentWorkplace != "unified" }

    func openProfilePage(): Unit {
        this.homeStack.pushPath(NavPathInfo(name: "profilePage", param: ""), options: NavigationOptions(animated: true))
    }

    func openPendingPage(title: String, message: String): Unit {
        this.pendingPageTitle = title
        this.pendingPageMessage = message
        this.homeStack.pushPath(NavPathInfo(name: "placeholder", param: ""), options: NavigationOptions(animated: true))
    }

    func openRepository(repositoryId: String): Unit {
        this.selectedRepository = repositoryId
        if (this.sharedAuthAccessToken == "") {
            let repository = repositorySnapshot(repositoryId)
            this.selectedIssue = repository.primaryIssueId
            this.selectedPullRequest = repository.primaryPullRequestId
            this.selectedTask = taskIdForIssue(this.selectedIssue)
        } else {
            this.liveRepositoryDetail = GitHubRepositoryDetailSnapshot(repositoryId, "Loading repository details...", "", "", "0", "0", "main")
            this.liveIssues = ArrayList<GitHubIssueSnapshot>()
            this.livePullRequests = ArrayList<GitHubPullRequestSnapshot>()
            this.selectedIssue = ""
            this.selectedPullRequest = ""
            this.selectedTask = ""
            refreshGitHubRepositoryBundle(
                this.sharedAuthAccessToken,
                repositoryId,
                { snapshot => this.applyRepositoryDetail(snapshot) },
                { items => this.applyIssues(items) },
                { items => this.applyPullRequests(items) },
                { _ => }
            )
        }
        this.homeStack.pushPath(NavPathInfo(name: "repositoryDetail", param: ""), options: NavigationOptions(animated: true))
    }

    func openSelectedIssue(): Unit {
        this.homeStack.pushPath(NavPathInfo(name: "issuesPage", param: ""), options: NavigationOptions(animated: true))
    }

    func openSelectedPullRequest(): Unit {
        this.homeStack.pushPath(NavPathInfo(name: "pullRequestsPage", param: ""), options: NavigationOptions(animated: true))
    }

    func createRepository(): Unit {
        if (this.sharedAuthAccessToken == "") {
            this.homeActionMessage = "Sign in to GitHub before creating a repository."
            return
        }
        createScratchGitHubRepository(
            this.sharedAuthAccessToken,
            { repositoryName =>
                this.runOnUi({
                    =>
                    this.homeActionMessage = "Created ${repositoryName}."
                    this.refreshHomeContent()
                })
            },
            { message =>
                this.runOnUi({ => this.homeActionMessage = message })
            }
        )
    }

    @Builder
    func buildTopBar() {
        Row() {
            Row(space: 12) {
                Button() {
                    if (this.viewerAvatarUrl != "") {
                        Image(this.viewerAvatarUrl)
                            .width(100.percent)
                            .height(100.percent)
                            .borderRadius(20)
                            .objectFit(ImageFit.Cover)
                    } else {
                        Row() { Text("GH").fontSize(15).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor()) }
                            .width(100.percent)
                            .height(100.percent)
                            .justifyContent(FlexAlign.Center)
                    }
                }
                .width(40).height(40).backgroundColor(this.surfaceColor()).borderRadius(20)
                .onClick({ _ => this.openProfilePage() })
                Column(space: 2) {
                    Text(this.currentHeaderWorkplaceTitle())
                        .fontSize(18)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(this.primaryTextColor())
                }
                .alignItems(HorizontalAlign.Start)
            }
            Blank()
            Row(space: 8) {
                if (this.canCreateFromCurrentWorkplace()) {
                    Button(this.t("add_short"))
                        .width(40).height(40).borderRadius(20).backgroundColor(this.surfaceColor()).fontColor(this.primaryTextColor()).fontSize(16)
                        .onClick({ _ => this.createRepository() })
                }
                Button(this.t("find_short"))
                    .width(40).height(40).borderRadius(20).backgroundColor(this.surfaceColor()).fontColor(this.primaryTextColor()).fontSize(16)
                    .onClick({ _ => this.openPendingPage("Search", "该页面待开发") })
            }
        }
        .width(100.percent)
        .padding(left: 18, right: 18, top: 16, bottom: 12)
        .backgroundColor(this.topBarOverlayColor())
    }

    @Builder
    func buildHomeContent() {
        Column(space: 16) {
            if (this.homeActionMessage != "") {
                this.buildActionMessageCard()
            }
            this.buildSectionHeader(this.t("my_work"))
            this.buildHomeWorkPanel()
            this.buildSectionHeader(this.t("favorites"))
            this.buildHomeFavoritesPanel()
            this.buildSectionHeader(this.t("shortcuts"))
            this.buildHomeShortcutsPanel()
            this.buildSectionHeader(this.t("recent"))
            this.buildHomeRecentPanel()
        }
        .width(100.percent)
    }

    @Builder
    func buildActionMessageCard() {
        Text(this.homeActionMessage)
            .width(100.percent)
            .padding(left: 16, right: 16, top: 14, bottom: 14)
            .backgroundColor(this.surfaceColor())
            .borderRadius(18)
            .fontSize(14)
            .fontColor(this.primaryTextColor())
    }

    @Builder
    func buildHomeWorkPanel() {
        Column() {
            this.buildHomeWorkRow(0x68D968, "◎", this.t("issues"), { => this.openSelectedIssue() })
            this.buildDivider()
            this.buildHomeWorkRow(0x4B88FF, "⎇", this.t("pull_requests"), { => this.openSelectedPullRequest() })
            this.buildDivider()
            this.buildHomeWorkRow(0x7B56E8, "◫", this.t("discussions"), { => this.openPendingPage(this.t("discussions"), "该页面待开发") })
            this.buildDivider()
            this.buildHomeWorkRow(0xB0B4C0, "□", this.t("projects"), { => this.openPendingPage(this.t("projects"), "该页面待开发") })
            this.buildDivider()
            this.buildHomeWorkRow(0x4B4F5C, "⌘", this.t("top_repositories"), { => this.homeStack.pushPath(NavPathInfo(name: "topRepositoriesPage", param: ""), options: NavigationOptions(animated: true)) })
            this.buildDivider()
            this.buildHomeWorkRow(0xF4A24B, "⌂", this.t("organizations"), { => this.homeStack.pushPath(NavPathInfo(name: "organizationsPage", param: ""), options: NavigationOptions(animated: true)) })
            this.buildDivider()
            this.buildHomeWorkRow(0xFFD54A, "☆", this.t("starred"), { => this.homeStack.pushPath(NavPathInfo(name: "starredRepositoriesPage", param: ""), options: NavigationOptions(animated: true)) })
        }
        .width(100.percent)
        .backgroundColor(this.surfaceColor())
        .borderRadius(20)
        .padding(top: 2, bottom: 2)
    }

    @Builder
    func buildHomeWorkRow(accentColor: Int64, iconText: String, title: String, onTap: () -> Unit) {
        Row(space: 14) {
            Row() { Text(iconText).fontSize(14).fontWeight(FontWeight.Bold).fontColor(0xF8FAFC) }
                .width(36).height(36).backgroundColor(accentColor).borderRadius(9).justifyContent(FlexAlign.Center)
            Text(title).fontSize(15).fontColor(this.primaryTextColor())
            Blank()
            Text("›").fontSize(20).fontColor(this.secondaryTextColor())
        }
        .width(100.percent)
        .height(58)
        .borderRadius(20)
        .padding(left: 13, right: 13)
        .backgroundColor(this.surfaceColor())
        .onClick({ _ => onTap() })
    }

    @Builder
    func buildHomeFavoritesPanel() {
        Column(space: 14) {
            Text(this.t("favorites_empty")).fontSize(13).lineHeight(20).fontColor(this.primaryTextColor())
            Button(this.t("add_favorites"))
                .width(100.percent).height(44).backgroundColor(this.mutedSurfaceColor()).fontColor(this.accentStrongColor())
                .fontSize(15).borderRadius(12)
                .onClick({ _ => this.openPendingPage(this.t("favorites"), "该页面待开发") })
        }
        .width(100.percent)
        .padding(18)
        .backgroundColor(this.surfaceColor())
        .borderRadius(20)
    }

    @Builder
    func buildHomeShortcutsPanel() {
        Column(space: 12) {
            Row(space: 8) {
                this.buildShortcutDot(0x3D404B, "⚡")
                this.buildShortcutDot(0x3E6D46, "◎")
                this.buildShortcutDot(0x35599A, "⎇")
                this.buildShortcutDot(0x5B46A3, "◫")
                this.buildShortcutDot(0x80573A, "⌂")
                this.buildShortcutDot(0x7A4854, "⌘")
                this.buildShortcutDot(0x5A4C79, "□")
                this.buildShortcutDot(0x42454D, "+")
            }
            .width(100.percent)
            .justifyContent(FlexAlign.Center)
            Text(this.t("shortcuts_title")).fontSize(15).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).fontColor(this.primaryTextColor())
            Text(this.t("shortcuts_desc")).fontSize(13).lineHeight(20).textAlign(TextAlign.Center).fontColor(this.secondaryTextColor())
            Button(this.t("get_started"))
                .width(100.percent).height(44).backgroundColor(this.mutedSurfaceColor()).fontColor(this.accentStrongColor())
                .fontSize(15).borderRadius(12)
                .onClick({ _ => this.openPendingPage(this.t("shortcuts"), "该页面待开发") })
        }
        .width(100.percent)
        .padding(18)
        .backgroundColor(this.surfaceColor())
        .borderRadius(20)
    }

    @Builder
    func buildShortcutDot(color: Int64, text: String) {
        Row() { Text(text).fontSize(12).fontWeight(FontWeight.Bold).fontColor(0xF8FAFC) }
            .width(30).height(30).backgroundColor(color).borderRadius(15).justifyContent(FlexAlign.Center)
    }

    @Builder
    func buildHomeRecentPanel() {
        Column(space: 10) {
            if (this.liveIssues.size > 0) {
                Text(this.t("recent_desc")).fontSize(13).lineHeight(20).fontColor(this.secondaryTextColor())
                this.buildHomeRecentItem(this.liveIssues[0].title, this.liveIssues[0].summary)
                if (this.livePullRequests.size > 0) {
                    this.buildHomeRecentItem(this.livePullRequests[0].title, this.livePullRequests[0].summary)
                }
            } else {
                Text(this.t("recent_empty")).fontSize(13).lineHeight(20).fontColor(this.primaryTextColor()).textAlign(TextAlign.Center)
            }
        }
        .width(100.percent)
        .padding(18)
        .backgroundColor(this.surfaceColor())
        .borderRadius(20)
    }

    @Builder
    func buildHomeRecentItem(title: String, summary: String) {
        Column(space: 8) {
            Text(title).fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
            Text(summary).fontSize(11).lineHeight(17).fontColor(this.secondaryTextColor())
        }
        .width(100.percent)
    }

    @Builder
    func buildTabBackground(tabId: String) {
        Column() {
            Blank()
        }
        .width(100.percent)
        .height(100.percent)
        .backgroundColor(tabColor("pageBackground", this.themePreference, this.systemColorMode))
        .expandSafeArea(types: [SafeAreaType.System], edges: [SafeAreaEdge.Top, SafeAreaEdge.Bottom])
    }

    @Builder
    func buildSectionHeader(title: String) {
        Row() {
            Text(title).fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
            Blank()
            Text("...").fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.secondaryTextColor())
        }
        .width(100.percent)
    }

    @Builder
    func buildDivider() {
        Column() {}
            .width(100.percent)
            .height(1)
            .margin(left: 12, right: 12)
            .backgroundColor(this.mutedSurfaceColor())
    }
}
