package ohos_app_cangjie_entry.pages.repository

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.*
import ohos.base.UIThread
import std.collection.ArrayList
import ohos_app_cangjie_entry.domain.{GitHubGistSnapshot, GitHubIssueSnapshot, GitHubPullRequestSnapshot, GitHubRepositoryCardSnapshot, GitHubRepositoryDetailSnapshot, GitHubSearchUserSnapshot, GitHubSimpleUserSnapshot, GitHubUserProfileSnapshot}
import ohos_app_cangjie_entry.infra.runtime.applyAppStatusBarStyle
import ohos_app_cangjie_entry.pages.common.{detailBackgroundCommon, detailCardCommon, detailHeaderCommon}
import ohos_app_cangjie_entry.services.agent.taskIdForIssue
import ohos_app_cangjie_entry.services.app.refreshGitHubRepositoryBundle
import ohos_app_cangjie_entry.services.github.{repositoryNameFromApiUrl, searchGitHubIssuesAndPullRequests, searchGitHubRepositories, searchGitHubUsers}
import ohos_app_cangjie_entry.ui.i18n.{appLocalizedText, appResolveLanguage}
import ohos_app_cangjie_entry.ui.theme.{appResolveIsDarkTheme, appThemeColor}

@Component
public class ExploreSearchRepositoriesPage {
    @Consume var exploreStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var exploreSearchQuery: String
    @Consume var selectedRepository: String
    @Consume var liveRepositoryDetail: GitHubRepositoryDetailSnapshot
    @Consume var liveIssues: ArrayList<GitHubIssueSnapshot>
    @Consume var livePullRequests: ArrayList<GitHubPullRequestSnapshot>
    @Consume var selectedIssue: String
    @Consume var selectedPullRequest: String
    @Consume var selectedTask: String

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light
    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @State var items: ArrayList<GitHubRepositoryCardSnapshot> = ArrayList<GitHubRepositoryCardSnapshot>()
    @State var loading: Bool = false
    @State var loadingMore: Bool = false
    @State var page: Int64 = 1
    @State var hasMore: Bool = true
    @State var actionMessage: String = ""

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
        this.loadItems()
    }

    public func build() {
        NavDestination() {
            Stack(alignContent: Alignment.TopStart) {
                detailBackgroundCommon(this.pageBackgroundColor())
                Scroll {
                    Column(space: 12) {
                        detailHeaderCommon(this.exploreStack, this.t("back"), this.t("repositories"), this.primaryTextColor(), this.surfaceColor())
                        if (this.actionMessage != "") {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("repositories"), this.actionMessage)
                        }
                        if (this.items.size > 0) {
                            ForEach(this.items, itemGeneratorFunc: { item: GitHubRepositoryCardSnapshot, _: Int64 =>
                                buildRepositoryCardRow(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), item, this.t("public"), this.t("private"), { => this.openRepository(item.name) })
                            })
                        } else if (!this.loading) {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("repositories"), this.t("repositories_empty"))
                        }
                    }
                    .width(100.percent)
                    .padding(left: 18, right: 18, top: 18, bottom: 120)
                }
                .width(100.percent)
                .height(100.percent)
                .scrollBar(BarState.Off)
                .align(Alignment.Top)
                .onReachEnd({ => this.loadMore() })
            }
            .width(100.percent)
            .height(100.percent)
        }
        .hideTitleBar(true)
        .backgroundColor(this.pageBackgroundColor())
    }

    func loadItems(reset!: Bool = true): Unit {
        if (this.sharedAuthAccessToken == "" || this.exploreSearchQuery == "") {
            this.actionMessage = this.t("search_placeholder")
            return
        }
        let targetPage = if (reset) { 1 } else { this.page + 1 }
        if (reset) {
            this.loading = true
            this.page = 1
            this.hasMore = true
        } else {
            if (this.loadingMore || !this.hasMore) { return }
            this.loadingMore = true
        }
        searchGitHubRepositories(
            this.sharedAuthAccessToken,
            this.exploreSearchQuery,
            { result => spawn(UIThread) {
                if (reset) {
                    this.items = result
                } else {
                    let merged = ArrayList<GitHubRepositoryCardSnapshot>()
                    for (item in this.items) { merged.add(item) }
                    for (item in result) { merged.add(item) }
                    this.items = merged
                }
                this.page = targetPage
                this.hasMore = result.size >= 20
                this.actionMessage = ""
                this.loading = false
                this.loadingMore = false
            } },
            { message => spawn(UIThread) {
                if (reset) {
                    this.items = ArrayList<GitHubRepositoryCardSnapshot>()
                }
                this.actionMessage = message
                this.loading = false
                this.loadingMore = false
            } },
            page: targetPage
        )
    }

    func loadMore(): Unit { this.loadItems(reset: false) }

    func openRepository(repositoryId: String): Unit {
        if (repositoryId == "") { return }
        this.selectedRepository = repositoryId
        this.liveRepositoryDetail = GitHubRepositoryDetailSnapshot(repositoryId, "Loading repository details...", "", "", "0", "0", "main")
        this.liveIssues = ArrayList<GitHubIssueSnapshot>()
        this.livePullRequests = ArrayList<GitHubPullRequestSnapshot>()
        this.selectedIssue = ""
        this.selectedPullRequest = ""
        this.selectedTask = ""
        refreshGitHubRepositoryBundle(
            this.sharedAuthAccessToken,
            repositoryId,
            { snapshot => this.liveRepositoryDetail = snapshot },
            { _ => },
            { list =>
                this.liveIssues = list
                if (list.size > 0) {
                    this.selectedIssue = list[0].id
                    this.selectedTask = taskIdForIssue(list[0].id)
                }
            },
            { list =>
                this.livePullRequests = list
                if (list.size > 0) {
                    this.selectedPullRequest = list[0].id
                }
            },
            { _ => }
        )
        this.exploreStack.pushPath(NavPathInfo(name: "repositoryDetail", param: ""), options: NavigationOptions(animated: true))
    }

    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
}

@Component
public class ExploreSearchIssuesPage {
    @Consume var exploreStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var exploreSearchQuery: String
    @Consume var selectedRepository: String
    @Consume var selectedIssue: String
    @Consume var selectedTask: String
    @Consume var liveRepositoryDetail: GitHubRepositoryDetailSnapshot
    @Consume var liveIssues: ArrayList<GitHubIssueSnapshot>
    @Consume var livePullRequests: ArrayList<GitHubPullRequestSnapshot>

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light
    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @State var items: ArrayList<GitHubIssueSnapshot> = ArrayList<GitHubIssueSnapshot>()
    @State var loading: Bool = false
    @State var loadingMore: Bool = false
    @State var page: Int64 = 1
    @State var hasMore: Bool = true
    @State var actionMessage: String = ""

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
        this.loadItems()
    }

    public func build() {
        NavDestination() {
            Stack(alignContent: Alignment.TopStart) {
                detailBackgroundCommon(this.pageBackgroundColor())
                Scroll {
                    Column(space: 12) {
                        detailHeaderCommon(this.exploreStack, this.t("back"), this.t("issues"), this.primaryTextColor(), this.surfaceColor())
                        if (this.actionMessage != "") {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("issues"), this.actionMessage)
                        }
                        if (this.items.size > 0) {
                            ForEach(this.items, itemGeneratorFunc: { item: GitHubIssueSnapshot, _: Int64 =>
                                buildSearchIssueRow(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), item, { => this.openIssue(item) })
                            })
                        } else if (!this.loading) {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("issues"), this.t("issues_empty"))
                        }
                    }
                    .width(100.percent)
                    .padding(left: 18, right: 18, top: 18, bottom: 120)
                }
                .width(100.percent)
                .height(100.percent)
                .scrollBar(BarState.Off)
                .align(Alignment.Top)
                .onReachEnd({ => this.loadMore() })
            }
            .width(100.percent)
            .height(100.percent)
        }
        .hideTitleBar(true)
        .backgroundColor(this.pageBackgroundColor())
    }

    func loadItems(reset!: Bool = true): Unit {
        if (this.sharedAuthAccessToken == "" || this.exploreSearchQuery == "") {
            this.actionMessage = this.t("search_placeholder")
            return
        }
        let targetPage = if (reset) { 1 } else { this.page + 1 }
        if (reset) {
            this.loading = true
            this.page = 1
            this.hasMore = true
        } else {
            if (this.loadingMore || !this.hasMore) { return }
            this.loadingMore = true
        }
        searchGitHubIssuesAndPullRequests(
            this.sharedAuthAccessToken,
            "is:issue ${this.exploreSearchQuery}",
            { result => spawn(UIThread) {
                if (reset) {
                    this.items = result
                } else {
                    let merged = ArrayList<GitHubIssueSnapshot>()
                    for (item in this.items) { merged.add(item) }
                    for (item in result) { merged.add(item) }
                    this.items = merged
                }
                this.page = targetPage
                this.hasMore = result.size >= 20
                this.actionMessage = ""
                this.loading = false
                this.loadingMore = false
            } },
            { _ => },
            { message => spawn(UIThread) {
                if (reset) {
                    this.items = ArrayList<GitHubIssueSnapshot>()
                }
                this.actionMessage = message
                this.loading = false
                this.loadingMore = false
            } },
            page: targetPage
        )
    }

    func loadMore(): Unit { this.loadItems(reset: false) }

    func openIssue(snapshot: GitHubIssueSnapshot): Unit {
        let repositoryName = repositoryNameFromApiUrl(snapshot.issueUrl.replace("/issues/${snapshot.id}", ""))
        if (repositoryName == "") { return }
        this.selectedRepository = repositoryName
        this.selectedIssue = snapshot.id
        this.selectedTask = taskIdForIssue(snapshot.id)
        this.liveRepositoryDetail = GitHubRepositoryDetailSnapshot(repositoryName, "Loading repository details...", "", "", "0", "0", "main")
        this.liveIssues = ArrayList<GitHubIssueSnapshot>()
        this.livePullRequests = ArrayList<GitHubPullRequestSnapshot>()
        refreshGitHubRepositoryBundle(
            this.sharedAuthAccessToken,
            repositoryName,
            { snapshot => this.liveRepositoryDetail = snapshot },
            { _ => },
            { list => this.liveIssues = list },
            { list => this.livePullRequests = list },
            { _ => }
        )
        this.exploreStack.pushPath(NavPathInfo(name: "issueDetail", param: ""), options: NavigationOptions(animated: true))
    }

    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
}

@Component
public class ExploreSearchPullRequestsPage {
    @Consume var exploreStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var exploreSearchQuery: String
    @Consume var selectedRepository: String
    @Consume var selectedPullRequest: String
    @Consume var liveRepositoryDetail: GitHubRepositoryDetailSnapshot
    @Consume var liveIssues: ArrayList<GitHubIssueSnapshot>
    @Consume var livePullRequests: ArrayList<GitHubPullRequestSnapshot>

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light
    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @State var items: ArrayList<GitHubPullRequestSnapshot> = ArrayList<GitHubPullRequestSnapshot>()
    @State var loading: Bool = false
    @State var loadingMore: Bool = false
    @State var page: Int64 = 1
    @State var hasMore: Bool = true
    @State var actionMessage: String = ""

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
        this.loadItems()
    }

    public func build() {
        NavDestination() {
            Stack(alignContent: Alignment.TopStart) {
                detailBackgroundCommon(this.pageBackgroundColor())
                Scroll {
                    Column(space: 12) {
                        detailHeaderCommon(this.exploreStack, this.t("back"), this.t("pull_requests"), this.primaryTextColor(), this.surfaceColor())
                        if (this.actionMessage != "") {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("pull_requests"), this.actionMessage)
                        }
                        if (this.items.size > 0) {
                            ForEach(this.items, itemGeneratorFunc: { item: GitHubPullRequestSnapshot, _: Int64 =>
                                buildSearchPullRequestRow(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), item, { => this.openPullRequest(item) })
                            })
                        } else if (!this.loading) {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("pull_requests"), this.t("pull_requests_empty"))
                        }
                    }
                    .width(100.percent)
                    .padding(left: 18, right: 18, top: 18, bottom: 120)
                }
                .width(100.percent)
                .height(100.percent)
                .scrollBar(BarState.Off)
                .align(Alignment.Top)
                .onReachEnd({ => this.loadMore() })
            }
            .width(100.percent)
            .height(100.percent)
        }
        .hideTitleBar(true)
        .backgroundColor(this.pageBackgroundColor())
    }

    func loadItems(reset!: Bool = true): Unit {
        if (this.sharedAuthAccessToken == "" || this.exploreSearchQuery == "") {
            this.actionMessage = this.t("search_placeholder")
            return
        }
        let targetPage = if (reset) { 1 } else { this.page + 1 }
        if (reset) {
            this.loading = true
            this.page = 1
            this.hasMore = true
        } else {
            if (this.loadingMore || !this.hasMore) { return }
            this.loadingMore = true
        }
        searchGitHubIssuesAndPullRequests(
            this.sharedAuthAccessToken,
            "is:pr ${this.exploreSearchQuery}",
            { _ => },
            { result => spawn(UIThread) {
                if (reset) {
                    this.items = result
                } else {
                    let merged = ArrayList<GitHubPullRequestSnapshot>()
                    for (item in this.items) { merged.add(item) }
                    for (item in result) { merged.add(item) }
                    this.items = merged
                }
                this.page = targetPage
                this.hasMore = result.size >= 20
                this.actionMessage = ""
                this.loading = false
                this.loadingMore = false
            } },
            { message => spawn(UIThread) {
                if (reset) {
                    this.items = ArrayList<GitHubPullRequestSnapshot>()
                }
                this.actionMessage = message
                this.loading = false
                this.loadingMore = false
            } },
            page: targetPage
        )
    }

    func loadMore(): Unit { this.loadItems(reset: false) }

    func openPullRequest(snapshot: GitHubPullRequestSnapshot): Unit {
        let repositoryName = repositoryNameFromApiUrl(snapshot.pullRequestUrl.replace("/pull/${snapshot.id}", "").replace("/pulls/${snapshot.id}", ""))
        if (repositoryName == "") { return }
        this.selectedRepository = repositoryName
        this.selectedPullRequest = snapshot.id
        this.liveRepositoryDetail = GitHubRepositoryDetailSnapshot(repositoryName, "Loading repository details...", "", "", "0", "0", "main")
        this.liveIssues = ArrayList<GitHubIssueSnapshot>()
        this.livePullRequests = ArrayList<GitHubPullRequestSnapshot>()
        refreshGitHubRepositoryBundle(
            this.sharedAuthAccessToken,
            repositoryName,
            { snapshot => this.liveRepositoryDetail = snapshot },
            { _ => },
            { list => this.liveIssues = list },
            { list => this.livePullRequests = list },
            { _ => }
        )
        this.exploreStack.pushPath(NavPathInfo(name: "pullRequestDetail", param: ""), options: NavigationOptions(animated: true))
    }

    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
}

@Component
public class ExploreSearchUsersPage {
    @Consume var exploreStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var exploreSearchQuery: String
    @Consume var selectedGitHubUserLogin: String
    @Consume var selectedGitHubUserProfile: GitHubUserProfileSnapshot
    @Consume var selectedGitHubUserRepositories: ArrayList<GitHubRepositoryCardSnapshot>
    @Consume var selectedGitHubUserIssues: ArrayList<GitHubIssueSnapshot>
    @Consume var selectedGitHubUserPullRequests: ArrayList<GitHubPullRequestSnapshot>
    @Consume var selectedGitHubUserGists: ArrayList<GitHubGistSnapshot>
    @Consume var selectedGitHubFollowers: ArrayList<GitHubSimpleUserSnapshot>
    @Consume var selectedGitHubFollowing: ArrayList<GitHubSimpleUserSnapshot>

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light
    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @State var items: ArrayList<GitHubSearchUserSnapshot> = ArrayList<GitHubSearchUserSnapshot>()
    @State var loading: Bool = false
    @State var loadingMore: Bool = false
    @State var page: Int64 = 1
    @State var hasMore: Bool = true
    @State var actionMessage: String = ""

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
        this.loadItems()
    }

    public func build() {
        NavDestination() {
            Stack(alignContent: Alignment.TopStart) {
                detailBackgroundCommon(this.pageBackgroundColor())
                Scroll {
                    Column(space: 12) {
                        detailHeaderCommon(this.exploreStack, this.t("back"), this.t("people"), this.primaryTextColor(), this.surfaceColor())
                        if (this.actionMessage != "") {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("people"), this.actionMessage)
                        }
                        if (this.items.size > 0) {
                            ForEach(this.items, itemGeneratorFunc: { item: GitHubSearchUserSnapshot, _: Int64 =>
                                buildSearchUserRow(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), item, { => this.openUser(item.login) })
                            })
                        } else if (!this.loading) {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("people"), this.t("not_available"))
                        }
                    }
                    .width(100.percent)
                    .padding(left: 18, right: 18, top: 18, bottom: 120)
                }
                .width(100.percent)
                .height(100.percent)
                .scrollBar(BarState.Off)
                .align(Alignment.Top)
                .onReachEnd({ => this.loadMore() })
            }
            .width(100.percent)
            .height(100.percent)
        }
        .hideTitleBar(true)
        .backgroundColor(this.pageBackgroundColor())
    }

    func loadItems(reset!: Bool = true): Unit {
        if (this.sharedAuthAccessToken == "" || this.exploreSearchQuery == "") {
            this.actionMessage = this.t("search_placeholder")
            return
        }
        let targetPage = if (reset) { 1 } else { this.page + 1 }
        if (reset) {
            this.loading = true
            this.page = 1
            this.hasMore = true
        } else {
            if (this.loadingMore || !this.hasMore) { return }
            this.loadingMore = true
        }
        searchGitHubUsers(
            this.sharedAuthAccessToken,
            this.exploreSearchQuery,
            { result => spawn(UIThread) {
                if (reset) {
                    this.items = result
                } else {
                    let merged = ArrayList<GitHubSearchUserSnapshot>()
                    for (item in this.items) { merged.add(item) }
                    for (item in result) { merged.add(item) }
                    this.items = merged
                }
                this.page = targetPage
                this.hasMore = result.size >= 20
                this.actionMessage = ""
                this.loading = false
                this.loadingMore = false
            } },
            { message => spawn(UIThread) {
                if (reset) {
                    this.items = ArrayList<GitHubSearchUserSnapshot>()
                }
                this.actionMessage = message
                this.loading = false
                this.loadingMore = false
            } },
            page: targetPage
        )
    }

    func loadMore(): Unit { this.loadItems(reset: false) }

    func openUser(login: String): Unit {
        if (login == "") { return }
        this.selectedGitHubUserLogin = login
        this.selectedGitHubUserProfile = GitHubUserProfileSnapshot("", "", "", "", "", "", "", "", "0", "0", "0", "0")
        this.selectedGitHubUserRepositories = ArrayList<GitHubRepositoryCardSnapshot>()
        this.selectedGitHubUserIssues = ArrayList<GitHubIssueSnapshot>()
        this.selectedGitHubUserPullRequests = ArrayList<GitHubPullRequestSnapshot>()
        this.selectedGitHubUserGists = ArrayList<GitHubGistSnapshot>()
        this.selectedGitHubFollowers = ArrayList<GitHubSimpleUserSnapshot>()
        this.selectedGitHubFollowing = ArrayList<GitHubSimpleUserSnapshot>()
        this.exploreStack.pushPath(NavPathInfo(name: "userProfilePage", param: ""), options: NavigationOptions(animated: true))
    }

    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
}

@Builder
func buildSearchIssueRow(surfaceColor: Int64, primaryTextColor: Int64, secondaryTextColor: Int64, item: GitHubIssueSnapshot, onTap: () -> Unit) {
    Button() {
        Column(space: 8) {
            Text(item.title).fontSize(16).fontWeight(FontWeight.Bold).fontColor(primaryTextColor)
            Text(item.summary).fontSize(12).fontColor(secondaryTextColor)
            Text("${item.status} / @${item.authorLogin}").fontSize(12).fontColor(secondaryTextColor)
        }
        .width(100.percent)
        .alignItems(HorizontalAlign.Start)
    }
    .width(100.percent)
    .padding(18)
    .backgroundColor(surfaceColor)
    .borderRadius(24)
    .onClick({ _ => onTap() })
}

@Builder
func buildSearchPullRequestRow(surfaceColor: Int64, primaryTextColor: Int64, secondaryTextColor: Int64, item: GitHubPullRequestSnapshot, onTap: () -> Unit) {
    Button() {
        Column(space: 8) {
            Text(item.title).fontSize(16).fontWeight(FontWeight.Bold).fontColor(primaryTextColor)
            Text(item.summary).fontSize(12).fontColor(secondaryTextColor)
            Text("${item.status} / @${item.authorLogin}").fontSize(12).fontColor(secondaryTextColor)
        }
        .width(100.percent)
        .alignItems(HorizontalAlign.Start)
    }
    .width(100.percent)
    .padding(18)
    .backgroundColor(surfaceColor)
    .borderRadius(24)
    .onClick({ _ => onTap() })
}

@Builder
func buildSearchUserRow(surfaceColor: Int64, primaryTextColor: Int64, secondaryTextColor: Int64, item: GitHubSearchUserSnapshot, onTap: () -> Unit) {
    Button() {
        Row(space: 12) {
            Text("◉").fontSize(18).fontColor(secondaryTextColor)
            Column(space: 6) {
                Text(item.login).fontSize(16).fontWeight(FontWeight.Bold).fontColor(primaryTextColor)
                Text(item.profileUrl).fontSize(12).fontColor(secondaryTextColor)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
        }
        .width(100.percent)
        .alignItems(VerticalAlign.Center)
    }
    .width(100.percent)
    .padding(18)
    .backgroundColor(surfaceColor)
    .borderRadius(24)
    .onClick({ _ => onTap() })
}
