package ohos_app_cangjie_entry.pages.tabs

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.*
import ohos.base.UIThread
import std.collection.ArrayList
import ohos_app_cangjie_entry.pages.maps.explorePageMap
import ohos_app_cangjie_entry.domain.{GitHubCommitDetailSnapshot, GitHubCommitSnapshot, GitHubGistFileSnapshot, GitHubGistSnapshot, GitHubIssueSnapshot, GitHubPullRequestSnapshot, GitHubRepositoryCardSnapshot, GitHubRepositoryDetailSnapshot, GitHubSearchUserSnapshot, GitHubSimpleUserSnapshot, GitHubUserProfileSnapshot}
import ohos_app_cangjie_entry.pages.common.detailCardCommon
import ohos_app_cangjie_entry.services.app.refreshGitHubRepositoryBundle
import ohos_app_cangjie_entry.services.agent.taskIdForIssue
import ohos_app_cangjie_entry.services.github.{repositoryNameFromApiUrl, resourceNumberFromApiUrl, searchGitHubIssuesAndPullRequests, searchGitHubRepositories, searchGitHubUsers}

@Component
public class ExploreTabHost {
    @Consume var exploreStack: NavPathStack = NavPathStack()
    @Consume var themePreference: String = "system"
    @Consume var languagePreference: String = "system"
    @Consume var sharedAuthAccessToken: String = ""
    @Consume var selectedRepository: String = ""
    @Consume var selectedIssue: String = ""
    @Consume var selectedPullRequest: String = ""
    @Consume var selectedTask: String = ""
    @Consume var liveRepositoryDetail: GitHubRepositoryDetailSnapshot
    @Consume var liveRepositoryReadme: String = ""
    @Consume var liveIssues: ArrayList<GitHubIssueSnapshot>
    @Consume var livePullRequests: ArrayList<GitHubPullRequestSnapshot>

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

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @State var searchQuery: String = ""
    @State var searching: Bool = false
    @State var actionMessage: String = ""
    @State var searchRepositories: ArrayList<GitHubRepositoryCardSnapshot> = ArrayList<GitHubRepositoryCardSnapshot>()
    @State var searchIssues: ArrayList<GitHubIssueSnapshot> = ArrayList<GitHubIssueSnapshot>()
    @State var searchPullRequests: ArrayList<GitHubPullRequestSnapshot> = ArrayList<GitHubPullRequestSnapshot>()
    @State var searchUsers: ArrayList<GitHubSearchUserSnapshot> = ArrayList<GitHubSearchUserSnapshot>()

    public func build() {
        Navigation(this.exploreStack) {
            Stack(alignContent: Alignment.Top) {
                this.buildTabBackground()
                Column(space: 0) {
                    this.buildTopBar()
                    Scroll {
                        Column(space: 18) {
                            this.buildSearchComposer()
                            if (this.actionMessage != "") {
                                this.buildActionMessage()
                            }
                            this.buildRepositoryResults()
                            this.buildIssueResults()
                            this.buildPullRequestResults()
                            this.buildUserResults()
                        }
                        .width(100.percent)
                        .padding(left: 18, right: 18, top: 18, bottom: 100)
                    }
                    .width(100.percent)
                    .height(100.percent)
                    .scrollBar(BarState.Off)
                    .layoutWeight(1)
                    .expandSafeArea(types: [SafeAreaType.System], edges: [SafeAreaEdge.Bottom])
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
        .navDestination(bind(explorePageMap, this))
    }

    func t(key: String): String { tabText(this.languagePreference, this.systemLanguageCode, key) }
    func isDarkTheme(): Bool { tabIsDarkTheme(this.themePreference, this.systemColorMode) }
    func surfaceColor(): Int64 { tabColor("surface", this.themePreference, this.systemColorMode) }
    func primaryTextColor(): Int64 { tabColor("primaryText", this.themePreference, this.systemColorMode) }
    func secondaryTextColor(): Int64 { tabColor("secondaryText", this.themePreference, this.systemColorMode) }
    func topBarOverlayColor(): Int64 { if (this.isDarkTheme()) { 0xE0090B10 } else { 0xEAF2F3F7 } }

    func runOnUi(task: () -> Unit): Unit {
        spawn(UIThread) { => task() }
    }

    func openRepository(repositoryId: String): Unit {
        this.selectedRepository = repositoryId
        this.exploreStack.pushPath(NavPathInfo(name: "repositoryDetail", param: ""), options: NavigationOptions(animated: true))
    }

    func openIssue(snapshot: GitHubIssueSnapshot): Unit {
        let repositoryName = repositoryNameFromApiUrl(snapshot.issueUrl.replace("/issues/${snapshot.id}", ""))
        if (repositoryName == "") {
            this.actionMessage = this.t("not_available")
            return
        }
        this.selectedRepository = repositoryName
        this.selectedIssue = snapshot.id
        this.selectedTask = taskIdForIssue(snapshot.id)
        this.liveRepositoryDetail = GitHubRepositoryDetailSnapshot(repositoryName, "Loading repository details...", "", "", "0", "0", "main")
        this.liveIssues = ArrayList<GitHubIssueSnapshot>()
        this.livePullRequests = ArrayList<GitHubPullRequestSnapshot>()
        if (this.sharedAuthAccessToken != "") {
            refreshGitHubRepositoryBundle(
                this.sharedAuthAccessToken,
                repositoryName,
                { detail => this.liveRepositoryDetail = detail },
                { markdown => this.liveRepositoryReadme = markdown },
                { items => this.liveIssues = items },
                { items => this.livePullRequests = items },
                { _ => }
            )
        }
        this.exploreStack.pushPath(NavPathInfo(name: "issueDetail", param: ""), options: NavigationOptions(animated: true))
    }

    func openPullRequest(snapshot: GitHubPullRequestSnapshot): Unit {
        let repositoryName = repositoryNameFromApiUrl(snapshot.pullRequestUrl.replace("/pull/${snapshot.id}", "").replace("/pulls/${snapshot.id}", ""))
        if (repositoryName == "") {
            this.actionMessage = this.t("not_available")
            return
        }
        this.selectedRepository = repositoryName
        this.selectedPullRequest = snapshot.id
        this.liveRepositoryDetail = GitHubRepositoryDetailSnapshot(repositoryName, "Loading repository details...", "", "", "0", "0", "main")
        this.liveIssues = ArrayList<GitHubIssueSnapshot>()
        this.livePullRequests = ArrayList<GitHubPullRequestSnapshot>()
        if (this.sharedAuthAccessToken != "") {
            refreshGitHubRepositoryBundle(
                this.sharedAuthAccessToken,
                repositoryName,
                { detail => this.liveRepositoryDetail = detail },
                { markdown => this.liveRepositoryReadme = markdown },
                { items => this.liveIssues = items },
                { items => this.livePullRequests = items },
                { _ => }
            )
        }
        this.exploreStack.pushPath(NavPathInfo(name: "pullRequestDetail", param: ""), options: NavigationOptions(animated: true))
    }

    func performSearch(): Unit {
        if (this.sharedAuthAccessToken == "") {
            this.actionMessage = this.t("connect_github_first")
            return
        }
        let trimmed = this.searchQuery.replace(" ", "").replace("\n", "")
        if (trimmed == "") {
            this.actionMessage = this.t("search_placeholder")
            return
        }
        this.searching = true
        this.actionMessage = ""
        searchGitHubRepositories(
            this.sharedAuthAccessToken,
            trimmed,
            { items =>
                this.runOnUi({
                    =>
                    this.searchRepositories = items
                })
            },
            { message =>
                this.runOnUi({
                    =>
                    this.searching = false
                    this.actionMessage = message
                })
            }
        )
        searchGitHubIssuesAndPullRequests(
            this.sharedAuthAccessToken,
            trimmed,
            { items =>
                this.runOnUi({
                    =>
                    this.searchIssues = items
                })
            },
            { items =>
                this.runOnUi({
                    =>
                    this.searchPullRequests = items
                    this.searching = false
                })
            },
            { message =>
                this.runOnUi({
                    =>
                    this.searching = false
                    this.actionMessage = message
                })
            }
        )
        searchGitHubUsers(
            this.sharedAuthAccessToken,
            trimmed,
            { items =>
                this.runOnUi({
                    =>
                    this.searchUsers = items
                })
            },
            { _ => }
        )
    }

    func openUserProfile(login: String): Unit {
        if (login == "") {
            this.actionMessage = this.t("not_available")
            return
        }
        this.selectedGitHubUserLogin = login
        this.selectedGitHubUserProfile = GitHubUserProfileSnapshot("", "", "", "", "", "", "", "", "0", "0", "0", "0")
        this.selectedGitHubUserRepositories = ArrayList<GitHubRepositoryCardSnapshot>()
        this.selectedGitHubUserGists = ArrayList<GitHubGistSnapshot>()
        this.selectedGitHubFollowers = ArrayList<GitHubSimpleUserSnapshot>()
        this.selectedGitHubFollowing = ArrayList<GitHubSimpleUserSnapshot>()
        this.exploreStack.pushPath(NavPathInfo(name: "userProfilePage", param: ""), options: NavigationOptions(animated: true))
    }

    @Builder
    func buildTopBar() {
        Row() {
            Column(space: 4) {
                Text(this.t("explore")).fontSize(30).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
                Text(this.t("explore_subtitle")).fontSize(12).fontColor(this.secondaryTextColor())
            }.alignItems(HorizontalAlign.Start)
            Blank()
        }
        .width(100.percent)
        .padding(left: 18, right: 18, top: 16, bottom: 12)
        .backgroundColor(this.topBarOverlayColor())
    }

    @Builder
    func buildSearchComposer() {
        Column(space: 12) {
            TextInput(placeholder: this.t("find_short"), text: this.searchQuery)
                .width(100.percent)
                .height(48)
                .fontSize(15)
                .backgroundColor(this.surfaceColor())
                .borderRadius(14)
                .padding(left: 16, right: 16)
                .onChange({ value => this.searchQuery = value })
            Button(if (this.searching) { this.t("status") } else { this.t("explore") })
                .width(100.percent)
                .height(48)
                .backgroundColor(this.surfaceColor())
                .fontColor(this.primaryTextColor())
                .borderRadius(14)
                .onClick({ _ => this.performSearch() })
        }
        .width(100.percent)
    }

    @Builder
    func buildActionMessage() {
        Text(this.actionMessage)
            .width(100.percent)
            .padding(left: 16, right: 16, top: 14, bottom: 14)
            .backgroundColor(this.surfaceColor())
            .borderRadius(18)
            .fontSize(14)
            .fontColor(this.primaryTextColor())
    }

    @Builder
    func buildRepositoryResults() {
        Column(space: 12) {
            this.buildSectionTitle(this.t("repositories"))
            if (this.searchRepositories.size > 0) {
                ForEach(this.searchRepositories, itemGeneratorFunc: { item: GitHubRepositoryCardSnapshot, _: Int64 =>
                    Button() {
                        Column(space: 8) {
                            Text(item.name).fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
                            Text(item.summary).fontSize(12).fontColor(this.secondaryTextColor())
                        }
                        .width(100.percent)
                        .alignItems(HorizontalAlign.Start)
                    }
                    .width(100.percent)
                    .padding(18)
                    .backgroundColor(this.surfaceColor())
                    .borderRadius(24)
                    .onClick({ _ => this.openRepository(item.name) })
                })
            } else {
                detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("repositories"), this.t("repositories_empty"))
            }
        }
        .width(100.percent)
    }

    @Builder
    func buildIssueResults() {
        Column(space: 12) {
            this.buildSectionTitle(this.t("issues"))
            if (this.searchIssues.size > 0) {
                ForEach(this.searchIssues, itemGeneratorFunc: { item: GitHubIssueSnapshot, _: Int64 =>
                    Button() {
                        Column(space: 8) {
                            Text(item.title).fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
                            Text(item.summary).fontSize(12).fontColor(this.secondaryTextColor())
                        }
                        .width(100.percent)
                        .alignItems(HorizontalAlign.Start)
                    }
                    .width(100.percent)
                    .padding(18)
                    .backgroundColor(this.surfaceColor())
                    .borderRadius(24)
                    .onClick({ _ => this.openIssue(item) })
                })
            } else {
                detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("issues"), this.t("issues_empty"))
            }
        }
        .width(100.percent)
    }

    @Builder
    func buildPullRequestResults() {
        Column(space: 12) {
            this.buildSectionTitle(this.t("pull_requests"))
            if (this.searchPullRequests.size > 0) {
                ForEach(this.searchPullRequests, itemGeneratorFunc: { item: GitHubPullRequestSnapshot, _: Int64 =>
                    Button() {
                        Column(space: 8) {
                            Text(item.title).fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
                            Text(item.summary).fontSize(12).fontColor(this.secondaryTextColor())
                        }
                        .width(100.percent)
                        .alignItems(HorizontalAlign.Start)
                    }
                    .width(100.percent)
                    .padding(18)
                    .backgroundColor(this.surfaceColor())
                    .borderRadius(24)
                    .onClick({ _ => this.openPullRequest(item) })
                })
            } else {
                detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("pull_requests"), this.t("pull_requests_empty"))
            }
        }
        .width(100.percent)
    }

    @Builder
    func buildUserResults() {
        if (this.searchUsers.size > 0) {
            Column(space: 12) {
                this.buildSectionTitle(this.t("people"))
                ForEach(this.searchUsers, itemGeneratorFunc: { item: GitHubSearchUserSnapshot, _: Int64 =>
                    Button() {
                        Column(space: 8) {
                            Text(item.login).fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
                            Text(item.profileUrl).fontSize(12).fontColor(this.secondaryTextColor())
                        }
                        .width(100.percent)
                        .alignItems(HorizontalAlign.Start)
                    }
                    .width(100.percent)
                    .padding(18)
                    .backgroundColor(this.surfaceColor())
                    .borderRadius(24)
                    .onClick({ _ => this.openUserProfile(item.login) })
                })
            }
            .width(100.percent)
        }
    }

    @Builder
    func buildSectionTitle(title: String) {
        Text(title).fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
            .width(100.percent)
    }

    @Builder
    func buildTabBackground() {
        Column() { Blank() }
            .width(100.percent)
            .height(100.percent)
            .backgroundColor(tabColor("pageBackground", this.themePreference, this.systemColorMode))
            .expandSafeArea(types: [SafeAreaType.System], edges: [SafeAreaEdge.Top, SafeAreaEdge.Bottom])
    }
}
