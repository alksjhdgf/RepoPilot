package ohos_app_cangjie_entry.pages.tabs

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.*
import ohos.base.UIThread
import std.collection.ArrayList
import ohos_app_cangjie_entry.pages.maps.explorePageMap
import ohos_app_cangjie_entry.domain.{GitHubCommitDetailSnapshot, GitHubCommitSnapshot, GitHubGistFileSnapshot, GitHubGistSnapshot, GitHubIssueSnapshot, GitHubPullRequestSnapshot, GitHubRepositoryCardSnapshot, GitHubRepositoryDetailSnapshot, GitHubSimpleUserSnapshot, GitHubUserProfileSnapshot}
import ohos_app_cangjie_entry.pages.common.detailCardCommon
import ohos_app_cangjie_entry.services.app.refreshGitHubRepositoryBundle
import ohos_app_cangjie_entry.services.agent.taskIdForIssue
import ohos_app_cangjie_entry.services.github.{repositoryNameFromApiUrl, resourceNumberFromApiUrl}

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
    @Provide var selectedGitHubGistUrl: String = ""
    @Provide var selectedGitHubGistFile: GitHubGistFileSnapshot = GitHubGistFileSnapshot("", "", "", "0", "", "")
    @Provide var exploreSearchQuery: String = ""
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
    @State var actionMessage: String = ""

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
                            this.buildSearchEntrySection()
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
        this.actionMessage = ""
        this.exploreSearchQuery = trimmed
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
            Button(this.t("explore"))
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
    func buildSearchEntrySection() {
        Column(space: 12) {
            if (this.exploreSearchQuery == "") {
                detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("explore"), this.t("search_placeholder"))
            } else {
                this.buildSearchCategoryRow(this.t("repositories"), { =>
                    this.performSearch()
                    this.exploreStack.pushPath(NavPathInfo(name: "searchRepositoriesPage", param: ""), options: NavigationOptions(animated: true))
                })
                this.buildSearchCategoryRow(this.t("issues"), { =>
                    this.performSearch()
                    this.exploreStack.pushPath(NavPathInfo(name: "searchIssuesPage", param: ""), options: NavigationOptions(animated: true))
                })
                this.buildSearchCategoryRow(this.t("pull_requests"), { =>
                    this.performSearch()
                    this.exploreStack.pushPath(NavPathInfo(name: "searchPullRequestsPage", param: ""), options: NavigationOptions(animated: true))
                })
                this.buildSearchCategoryRow(this.t("people"), { =>
                    this.performSearch()
                    this.exploreStack.pushPath(NavPathInfo(name: "searchUsersPage", param: ""), options: NavigationOptions(animated: true))
                })
                this.buildSearchCategoryRow(this.t("organizations"), { =>
                    this.pendingPageTitle = this.t("organizations")
                    this.pendingPageMessage = this.t("not_available")
                    this.exploreStack.pushPath(NavPathInfo(name: "placeholder", param: ""), options: NavigationOptions(animated: true))
                })
            }
        }
        .width(100.percent)
    }

    @Builder
    func buildSearchCategoryRow(title: String, onTap: () -> Unit) {
        Button() {
            Row(space: 12) {
                Text(title)
                    .fontSize(15)
                    .fontColor(this.primaryTextColor())
                    .layoutWeight(1)
                    .textAlign(TextAlign.Start)
                Text("›").fontSize(18).fontColor(this.secondaryTextColor())
            }
            .width(100.percent)
            .alignItems(VerticalAlign.Center)
        }
        .width(100.percent)
        .padding(18)
        .backgroundColor(this.surfaceColor())
        .borderRadius(18)
        .onClick({ _ => onTap() })
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
