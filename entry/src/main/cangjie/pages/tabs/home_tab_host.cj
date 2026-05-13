package ohos_app_cangjie_entry.pages.tabs

import kit.ArkUI.*
import kit.AbilityKit.Want
import ohos.business_exception.BusinessException
import ohos.arkui.state_macro_manage.*
import ohos.base.UIThread
import std.collection.ArrayList
import ohos_app_cangjie_entry.pages.maps.homePageMap
import ohos_app_cangjie_entry.domain.{GitHubCommitDetailSnapshot, GitHubCommitSnapshot, GitHubEventSnapshot, GitHubGistFileSnapshot, GitHubGistSnapshot, GitHubIssueSnapshot, GitHubProfileMetricsSnapshot, GitHubPullRequestSnapshot, GitHubRepositoryCardSnapshot, GitHubRepositoryDetailSnapshot, GitHubSimpleUserSnapshot, GitHubUserProfileSnapshot, GitHubViewerSnapshot}
import ohos_app_cangjie_entry.infra.runtime.getAppAbilityContext
import ohos_app_cangjie_entry.infra.runtime.notifyAppTabChange
import ohos_app_cangjie_entry.services.app.{createScratchGitHubRepository, refreshGitHubProfileData, refreshGitHubRepositoryBundle, resolveSelectedIssueState, resolveSelectedPullRequestId, resolveSelectedRepositoryId}
import ohos_app_cangjie_entry.services.agent.taskIdForIssue
import ohos_app_cangjie_entry.services.github.{fetchGitHubViewerActivity, loadStoredFavoriteRepositories, persistStoredFavoriteRepositories, syncFavoriteRepositories}
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
    @Consume var liveRepositoryReadme: String = ""
    @Consume var liveIssues: ArrayList<GitHubIssueSnapshot> = ArrayList<GitHubIssueSnapshot>()
    @Consume var livePullRequests: ArrayList<GitHubPullRequestSnapshot> = ArrayList<GitHubPullRequestSnapshot>()
    @Consume var selectedRepository: String = ""
    @Consume var selectedIssue: String = ""
    @Consume var selectedPullRequest: String = ""
    @Consume var selectedTask: String = ""

    @Provide var pendingPageTitle: String = "Pending"
    @Provide var pendingPageMessage: String = "该页面待开发"
    @Provide var pendingPullRequestReviewEvent: String = "COMMENT"
    @Provide var selectedGitHubUserLogin: String = ""
    @Provide var selectedGitHubUserProfile: GitHubUserProfileSnapshot = GitHubUserProfileSnapshot("", "", "", "", "", "", "", "", "0", "0", "0", "0")
    @Provide var selectedGitHubUserRepositories: ArrayList<GitHubRepositoryCardSnapshot> = ArrayList<GitHubRepositoryCardSnapshot>()
    @Provide var selectedGitHubUserIssues: ArrayList<GitHubIssueSnapshot> = ArrayList<GitHubIssueSnapshot>()
    @Provide var selectedGitHubUserPullRequests: ArrayList<GitHubPullRequestSnapshot> = ArrayList<GitHubPullRequestSnapshot>()
    @Provide var selectedGitHubUserGists: ArrayList<GitHubGistSnapshot> = ArrayList<GitHubGistSnapshot>()
    @Provide var selectedGitHubGistFiles: ArrayList<GitHubGistFileSnapshot> = ArrayList<GitHubGistFileSnapshot>()
    @Provide var selectedGitHubGistId: String = ""
    @Provide var selectedGitHubFollowers: ArrayList<GitHubSimpleUserSnapshot> = ArrayList<GitHubSimpleUserSnapshot>()
    @Provide var selectedGitHubFollowing: ArrayList<GitHubSimpleUserSnapshot> = ArrayList<GitHubSimpleUserSnapshot>()
    @Provide var liveRepositoryWatchers: ArrayList<GitHubSimpleUserSnapshot> = ArrayList<GitHubSimpleUserSnapshot>()
    @Provide var liveRepositoryStargazers: ArrayList<GitHubSimpleUserSnapshot> = ArrayList<GitHubSimpleUserSnapshot>()
    @Provide var liveRepositoryForks: ArrayList<GitHubRepositoryCardSnapshot> = ArrayList<GitHubRepositoryCardSnapshot>()
    @Provide var liveRepositoryCommits: ArrayList<GitHubCommitSnapshot> = ArrayList<GitHubCommitSnapshot>()
    @Provide var selectedRepositoryCommitSha: String = ""
    @Provide var selectedRepositoryCommitDetail: GitHubCommitDetailSnapshot = GitHubCommitDetailSnapshot("", "", "", "", "", "", 0, 0, "")
    @Provide var favoriteRepositories: ArrayList<GitHubRepositoryCardSnapshot> = ArrayList<GitHubRepositoryCardSnapshot>()

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @State var homeRefreshing: Bool = false
    @State var homeActionMessage: String = ""
    @State var liveActivityEvents: ArrayList<GitHubEventSnapshot> = ArrayList<GitHubEventSnapshot>()

    protected override func aboutToAppear(): Unit {
        this.favoriteRepositories = loadStoredFavoriteRepositories()
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
            { markdown => this.applyRepositoryReadme(markdown) },
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
        this.refreshViewerActivity(snapshot.login)
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
            this.favoriteRepositories = syncFavoriteRepositories(this.favoriteRepositories, repositories)
            this.homeRefreshing = false
        })
    }

    func applyRepositoryDetail(snapshot: GitHubRepositoryDetailSnapshot): Unit {
        this.runOnUi({ => this.liveRepositoryDetail = snapshot })
    }

    func applyRepositoryReadme(markdown: String): Unit {
        this.runOnUi({ => this.liveRepositoryReadme = markdown })
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

    func refreshViewerActivity(login: String): Unit {
        if (this.sharedAuthAccessToken == "" || login == "") {
            this.runOnUi({ => this.liveActivityEvents = ArrayList<GitHubEventSnapshot>() })
            return
        }
        fetchGitHubViewerActivity(
            this.sharedAuthAccessToken,
            login,
            { items => this.runOnUi({ => this.liveActivityEvents = items }) },
            { _ => this.runOnUi({ => this.liveActivityEvents = ArrayList<GitHubEventSnapshot>() }) }
        )
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

    func openRepository(repositoryId: String): Unit {
        this.selectedRepository = repositoryId
        if (this.sharedAuthAccessToken == "") {
            let repository = repositorySnapshot(repositoryId)
            this.selectedIssue = repository.primaryIssueId
            this.selectedPullRequest = repository.primaryPullRequestId
            this.selectedTask = taskIdForIssue(this.selectedIssue)
        } else {
            this.liveRepositoryDetail = GitHubRepositoryDetailSnapshot(repositoryId, "Loading repository details...", "", "", "0", "0", "main")
            this.liveRepositoryReadme = ""
            this.liveIssues = ArrayList<GitHubIssueSnapshot>()
            this.livePullRequests = ArrayList<GitHubPullRequestSnapshot>()
            this.selectedIssue = ""
            this.selectedPullRequest = ""
            this.selectedTask = ""
            refreshGitHubRepositoryBundle(
                this.sharedAuthAccessToken,
                repositoryId,
                { snapshot => this.applyRepositoryDetail(snapshot) },
                { markdown => this.applyRepositoryReadme(markdown) },
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

    func openUrl(url: String): Unit {
        if (url == "") { return }
        try { getAppAbilityContext().startAbility(Want(uri: url, action: "ohos.want.action.viewData")) } catch (_: BusinessException) {}
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
                    .onClick({ _ => notifyAppTabChange("explore") })
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
            this.buildHomeWorkRow(0x7B56E8, "◫", this.t("repositories"), { => this.homeStack.pushPath(NavPathInfo(name: "repositoriesPage", param: ""), options: NavigationOptions(animated: true)) })
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
            if (this.favoriteRepositories.size > 0) {
                ForEach(this.favoriteRepositories, itemGeneratorFunc: { item: GitHubRepositoryCardSnapshot, _: Int64 =>
                    this.buildFavoriteRepositoryRow(item)
                })
                Button(this.t("manage_favorites"))
                    .width(100.percent).height(44).backgroundColor(this.mutedSurfaceColor()).fontColor(this.accentStrongColor())
                    .fontSize(15).borderRadius(12)
                    .onClick({ _ => this.homeStack.pushPath(NavPathInfo(name: "favoriteRepositoriesPickerPage", param: ""), options: NavigationOptions(animated: true)) })
            } else {
                Text(this.t("favorites_empty")).fontSize(13).lineHeight(20).fontColor(this.primaryTextColor())
                Button(this.t("add_favorites"))
                    .width(100.percent).height(44).backgroundColor(this.mutedSurfaceColor()).fontColor(this.accentStrongColor())
                    .fontSize(15).borderRadius(12)
                    .onClick({ _ => this.homeStack.pushPath(NavPathInfo(name: "favoriteRepositoriesPickerPage", param: ""), options: NavigationOptions(animated: true)) })
            }
        }
        .width(100.percent)
        .padding(18)
        .backgroundColor(this.surfaceColor())
        .borderRadius(20)
    }

    @Builder
    func buildFavoriteRepositoryRow(snapshot: GitHubRepositoryCardSnapshot) {
        Row(space: 12) {
            Row() { Text(if (snapshot.viewerStarred) { "★" } else { "☆" }).fontSize(14).fontWeight(FontWeight.Bold).fontColor(if (snapshot.viewerStarred) { 0xF4B400 } else { this.secondaryTextColor() }) }
                .width(36).height(36).backgroundColor(this.mutedSurfaceColor()).borderRadius(10).justifyContent(FlexAlign.Center)
            Column(space: 2) {
                Text(snapshot.name).fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor()).width(100.percent)
                Text(if (snapshot.summary == "") { this.t("repository_summary_empty") } else { snapshot.summary })
                    .fontSize(12)
                    .lineHeight(18)
                    .fontColor(this.secondaryTextColor())
                    .maxLines(2)
                    .width(100.percent)
            }
            .layoutWeight(1)
            Text("›").fontSize(20).fontColor(this.secondaryTextColor())
        }
        .width(100.percent)
        .padding(left: 12, right: 12, top: 10, bottom: 10)
        .backgroundColor(this.mutedSurfaceColor())
        .borderRadius(16)
        .onClick({ _ => this.openRepository(snapshot.name) })
    }

    func saveFavoriteRepositories(items: ArrayList<GitHubRepositoryCardSnapshot>): Unit {
        this.favoriteRepositories = items
        persistStoredFavoriteRepositories(items)
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
                .onClick({ _ => this.homeStack.pushPath(NavPathInfo(name: "repositoriesPage", param: ""), options: NavigationOptions(animated: true)) })
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
            if (this.liveActivityEvents.size > 0) {
                Text(this.t("recent_desc")).fontSize(13).lineHeight(20).fontColor(this.secondaryTextColor())
                ForEach(this.topActivityEvents(), itemGeneratorFunc: { item: GitHubEventSnapshot, _: Int64 =>
                    this.buildHomeRecentItem(item)
                })
            } else if (this.liveIssues.size > 0) {
                Text(this.t("recent_desc")).fontSize(13).lineHeight(20).fontColor(this.secondaryTextColor())
                this.buildHomeRecentFallbackItem(this.liveIssues[0].title, this.liveIssues[0].summary)
                if (this.livePullRequests.size > 0) {
                    this.buildHomeRecentFallbackItem(this.livePullRequests[0].title, this.livePullRequests[0].summary)
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
    func buildHomeRecentItem(item: GitHubEventSnapshot) {
        Column(space: 8) {
            Text(if (item.repoName == "") { item.targetTitle } else { item.repoName }).fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
            Text(this.eventSummary(item)).fontSize(11).lineHeight(17).fontColor(this.secondaryTextColor())
        }
        .width(100.percent)
        .onClick({ _ => this.openUrl(item.targetUrl) })
    }

    @Builder
    func buildHomeRecentFallbackItem(title: String, summary: String) {
        Column(space: 8) {
            Text(title).fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
            Text(summary).fontSize(11).lineHeight(17).fontColor(this.secondaryTextColor())
        }
        .width(100.percent)
    }

    func topActivityEvents(): ArrayList<GitHubEventSnapshot> {
        let top = ArrayList<GitHubEventSnapshot>()
        var index: Int64 = 0
        for (item in this.liveActivityEvents) {
            if (index >= 5) { break }
            top.add(item)
            index += 1
        }
        top
    }

    func eventSummary(item: GitHubEventSnapshot): String {
        if (item.eventType == "IssuesEvent") {
            if (item.action == "opened") { return "${this.t("event_issue_opened")} · ${item.targetTitle}" }
            if (item.action == "closed") { return "${this.t("event_issue_closed")} · ${item.targetTitle}" }
            return "${this.t("event_issue_updated")} · ${item.targetTitle}"
        }
        if (item.eventType == "IssueCommentEvent") {
            return "${this.t("event_issue_commented")} · ${item.targetTitle}"
        }
        if (item.eventType == "PullRequestEvent") {
            if (item.action == "opened") { return "${this.t("event_pr_opened")} · ${item.targetTitle}" }
            if (item.action == "closed") { return "${this.t("event_pr_closed")} · ${item.targetTitle}" }
            return "${this.t("event_pr_updated")} · ${item.targetTitle}"
        }
        if (item.eventType == "PullRequestReviewEvent") {
            return "${this.t("event_pr_reviewed")} · ${item.targetTitle}"
        }
        if (item.eventType == "PullRequestReviewCommentEvent") {
            return "${this.t("event_pr_commented")} · ${item.targetTitle}"
        }
        if (item.eventType == "PushEvent") {
            return "${this.t("event_push")} · ${item.targetTitle}"
        }
        if (item.eventType == "WatchEvent") {
            return "${this.t("event_starred")} · ${item.repoName}"
        }
        if (item.eventType == "ForkEvent") {
            return "${this.t("event_forked")} · ${item.repoName}"
        }
        if (item.eventType == "CreateEvent") {
            return "${this.t("event_created")} · ${item.targetTitle}"
        }
        if (item.eventType == "DeleteEvent") {
            return "${this.t("event_deleted")} · ${item.targetTitle}"
        }
        if (item.eventType == "ReleaseEvent") {
            return "${this.t("event_released")} · ${item.targetTitle}"
        }
        if (item.targetTitle != "") {
            return item.targetTitle
        }
        item.eventType
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
