package ohos_app_cangjie_entry.pages.repository

import kit.AbilityKit.Want
import kit.ArkUI.*
import ohos.arkui.state_macro_manage.*
import ohos.base.UIThread
import ohos.business_exception.BusinessException
import std.collection.ArrayList
import ohos_app_cangjie_entry.domain.{GitHubCommitDetailSnapshot, GitHubCommitSnapshot, GitHubEventSnapshot, GitHubGistFileSnapshot, GitHubGistSnapshot, GitHubIssueSnapshot, GitHubPullRequestSnapshot, GitHubRepositoryCardSnapshot, GitHubRepositoryDetailSnapshot, GitHubSimpleUserSnapshot, GitHubUserProfileSnapshot}
import ohos_app_cangjie_entry.infra.runtime.{applyAppStatusBarStyle, getAppAbilityContext}
import ohos_app_cangjie_entry.pages.common.{detailBackgroundCommon, detailCardCommon, detailHeaderCommon}
import ohos_app_cangjie_entry.services.github.{fetchGitHubGistFiles, fetchGitHubRepositoryCommitDetail, fetchGitHubRepositoryCommits, fetchGitHubRepositoryForks, fetchGitHubRepositoryStargazers, fetchGitHubRepositoryWatchers, fetchGitHubRepositories, fetchGitHubUserActivity, fetchGitHubUserFollowers, fetchGitHubUserFollowing, fetchGitHubUserGists, fetchGitHubUserIssues, fetchGitHubUserProfile, fetchGitHubUserPullRequests, fetchGitHubUserRepositories, repositoryNameFromApiUrl}
import ohos_app_cangjie_entry.services.agent.taskIdForIssue
import ohos_app_cangjie_entry.services.app.refreshGitHubRepositoryBundle
import ohos_app_cangjie_entry.ui.i18n.{appLocalizedText, appResolveLanguage}
import ohos_app_cangjie_entry.ui.theme.{appResolveIsDarkTheme, appThemeColor}

@Component
public class HomeRepositoryWatchersPage {
    @Consume var homeStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var selectedRepository: String
    @Consume var liveRepositoryWatchers: ArrayList<GitHubSimpleUserSnapshot>
    @Consume var selectedGitHubUserLogin: String
    @Consume var selectedGitHubUserProfile: GitHubUserProfileSnapshot
    @Consume var selectedGitHubUserRepositories: ArrayList<GitHubRepositoryCardSnapshot>
    @Consume var selectedGitHubFollowers: ArrayList<GitHubSimpleUserSnapshot>
    @Consume var selectedGitHubFollowing: ArrayList<GitHubSimpleUserSnapshot>

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

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
                        detailHeaderCommon(this.homeStack, this.t("back"), this.t("watchers"), this.primaryTextColor(), this.surfaceColor())
                        if (this.actionMessage != "") {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("watchers"), this.actionMessage)
                        }
                        if (this.liveRepositoryWatchers.size > 0) {
                            ForEach(this.liveRepositoryWatchers, itemGeneratorFunc: { item: GitHubSimpleUserSnapshot, _: Int64 =>
                                buildSimpleUserRow(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), item, { => this.openUser(item.login) })
                            })
                        } else if (!this.loading) {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("watchers"), this.t("watchers_empty"))
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
        if (this.sharedAuthAccessToken == "" || this.selectedRepository == "") {
            this.actionMessage = this.t("sign_in_required")
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
        fetchGitHubRepositoryWatchers(
            this.sharedAuthAccessToken,
            this.selectedRepository,
            { items => spawn(UIThread) {
                if (reset) {
                    this.liveRepositoryWatchers = items
                } else {
                    let merged = ArrayList<GitHubSimpleUserSnapshot>()
                    for (item in this.liveRepositoryWatchers) { merged.add(item) }
                    for (item in items) { merged.add(item) }
                    this.liveRepositoryWatchers = merged
                }
                this.page = targetPage
                this.hasMore = items.size >= 50
                this.loading = false
                this.loadingMore = false
                this.actionMessage = ""
            } },
            { message => spawn(UIThread) {
                if (reset) {
                    this.liveRepositoryWatchers = ArrayList<GitHubSimpleUserSnapshot>()
                }
                this.loading = false
                this.loadingMore = false
                this.actionMessage = message
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
        this.selectedGitHubFollowers = ArrayList<GitHubSimpleUserSnapshot>()
        this.selectedGitHubFollowing = ArrayList<GitHubSimpleUserSnapshot>()
        this.homeStack.pushPath(NavPathInfo(name: "userProfilePage", param: ""), options: NavigationOptions(animated: true))
    }

    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
}

@Component
public class HomeRepositoryStargazersPage {
    @Consume var homeStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var selectedRepository: String
    @Consume var liveRepositoryStargazers: ArrayList<GitHubSimpleUserSnapshot>
    @Consume var selectedGitHubUserLogin: String
    @Consume var selectedGitHubUserProfile: GitHubUserProfileSnapshot
    @Consume var selectedGitHubUserRepositories: ArrayList<GitHubRepositoryCardSnapshot>
    @Consume var selectedGitHubFollowers: ArrayList<GitHubSimpleUserSnapshot>
    @Consume var selectedGitHubFollowing: ArrayList<GitHubSimpleUserSnapshot>

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

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
                        detailHeaderCommon(this.homeStack, this.t("back"), this.t("stargazers"), this.primaryTextColor(), this.surfaceColor())
                        if (this.actionMessage != "") {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("stargazers"), this.actionMessage)
                        }
                        if (this.liveRepositoryStargazers.size > 0) {
                            ForEach(this.liveRepositoryStargazers, itemGeneratorFunc: { item: GitHubSimpleUserSnapshot, _: Int64 =>
                                buildSimpleUserRow(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), item, { => this.openUser(item.login) })
                            })
                        } else if (!this.loading) {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("stargazers"), this.t("stargazers_empty"))
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
        if (this.sharedAuthAccessToken == "" || this.selectedRepository == "") {
            this.actionMessage = this.t("sign_in_required")
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
        fetchGitHubRepositoryStargazers(
            this.sharedAuthAccessToken,
            this.selectedRepository,
            { items => spawn(UIThread) {
                if (reset) {
                    this.liveRepositoryStargazers = items
                } else {
                    let merged = ArrayList<GitHubSimpleUserSnapshot>()
                    for (item in this.liveRepositoryStargazers) { merged.add(item) }
                    for (item in items) { merged.add(item) }
                    this.liveRepositoryStargazers = merged
                }
                this.page = targetPage
                this.hasMore = items.size >= 50
                this.loading = false
                this.loadingMore = false
                this.actionMessage = ""
            } },
            { message => spawn(UIThread) {
                if (reset) {
                    this.liveRepositoryStargazers = ArrayList<GitHubSimpleUserSnapshot>()
                }
                this.loading = false
                this.loadingMore = false
                this.actionMessage = message
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
        this.selectedGitHubFollowers = ArrayList<GitHubSimpleUserSnapshot>()
        this.selectedGitHubFollowing = ArrayList<GitHubSimpleUserSnapshot>()
        this.homeStack.pushPath(NavPathInfo(name: "userProfilePage", param: ""), options: NavigationOptions(animated: true))
    }

    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
}

@Component
public class HomeRepositoryForksPage {
    @Consume var homeStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var selectedRepository: String
    @Consume var liveRepositoryForks: ArrayList<GitHubRepositoryCardSnapshot>
    @Consume var liveRepositoryDetail: GitHubRepositoryDetailSnapshot
    @Consume var liveRepositoryReadme: String
    @Consume var liveIssues: ArrayList<GitHubIssueSnapshot>
    @Consume var livePullRequests: ArrayList<GitHubPullRequestSnapshot>

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

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
                        detailHeaderCommon(this.homeStack, this.t("back"), this.t("forks"), this.primaryTextColor(), this.surfaceColor())
                        if (this.actionMessage != "") {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("forks"), this.actionMessage)
                        }
                        if (this.liveRepositoryForks.size > 0) {
                            ForEach(this.liveRepositoryForks, itemGeneratorFunc: { item: GitHubRepositoryCardSnapshot, _: Int64 =>
                                buildRepositoryCardRow(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), item, this.t("public"), this.t("private"), { => this.openRepository(item.name) })
                            })
                        } else if (!this.loading) {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("forks"), this.t("forks_empty"))
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
        if (this.sharedAuthAccessToken == "" || this.selectedRepository == "") {
            this.actionMessage = this.t("sign_in_required")
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
        fetchGitHubRepositoryForks(
            this.sharedAuthAccessToken,
            this.selectedRepository,
            { items => spawn(UIThread) {
                if (reset) {
                    this.liveRepositoryForks = items
                } else {
                    let merged = ArrayList<GitHubRepositoryCardSnapshot>()
                    for (item in this.liveRepositoryForks) { merged.add(item) }
                    for (item in items) { merged.add(item) }
                    this.liveRepositoryForks = merged
                }
                this.page = targetPage
                this.hasMore = items.size >= 50
                this.loading = false
                this.loadingMore = false
                this.actionMessage = ""
            } },
            { message => spawn(UIThread) {
                if (reset) {
                    this.liveRepositoryForks = ArrayList<GitHubRepositoryCardSnapshot>()
                }
                this.loading = false
                this.loadingMore = false
                this.actionMessage = message
            } },
            page: targetPage
        )
    }

    func loadMore(): Unit { this.loadItems(reset: false) }

    func runOnUi(task: () -> Unit): Unit { spawn(UIThread) { => task() } }
    func openRepository(repositoryId: String): Unit {
        if (repositoryId == "") { return }
        this.selectedRepository = repositoryId
        this.liveRepositoryDetail = GitHubRepositoryDetailSnapshot(repositoryId, "Loading repository details...", "", "", "0", "0", "main")
        this.liveRepositoryReadme = ""
        this.liveIssues = ArrayList<GitHubIssueSnapshot>()
        this.livePullRequests = ArrayList<GitHubPullRequestSnapshot>()
        if (this.sharedAuthAccessToken != "") {
            refreshGitHubRepositoryBundle(
                this.sharedAuthAccessToken,
                repositoryId,
                { snapshot => this.runOnUi({ => this.liveRepositoryDetail = snapshot }) },
                { markdown => this.runOnUi({ => this.liveRepositoryReadme = markdown }) },
                { items => this.runOnUi({ => this.liveIssues = items }) },
                { items => this.runOnUi({ => this.livePullRequests = items }) },
                { message => this.runOnUi({ => this.actionMessage = message }) }
            )
        }
        this.homeStack.pushPath(NavPathInfo(name: "repositoryDetail", param: ""), options: NavigationOptions(animated: true))
    }

    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
}

@Component
public class HomeRepositoryCommitsPage {
    @Consume var homeStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var selectedRepository: String
    @Consume var liveRepositoryCommits: ArrayList<GitHubCommitSnapshot>
    @Consume var selectedRepositoryCommitSha: String
    @Consume var selectedRepositoryCommitDetail: GitHubCommitDetailSnapshot

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

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
                        detailHeaderCommon(this.homeStack, this.t("back"), this.t("commits"), this.primaryTextColor(), this.surfaceColor())
                        if (this.actionMessage != "") {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("commits"), this.actionMessage)
                        }
                        if (this.liveRepositoryCommits.size > 0) {
                            ForEach(this.liveRepositoryCommits, itemGeneratorFunc: { item: GitHubCommitSnapshot, _: Int64 =>
                                buildCommitRow(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), item, { => this.openCommit(item) })
                            })
                        } else if (!this.loading) {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("commits"), this.t("commits_empty"))
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
        if (this.sharedAuthAccessToken == "" || this.selectedRepository == "") {
            this.actionMessage = this.t("sign_in_required")
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
        fetchGitHubRepositoryCommits(
            this.sharedAuthAccessToken,
            this.selectedRepository,
            { items => spawn(UIThread) {
                if (reset) {
                    this.liveRepositoryCommits = items
                } else {
                    let merged = ArrayList<GitHubCommitSnapshot>()
                    for (item in this.liveRepositoryCommits) { merged.add(item) }
                    for (item in items) { merged.add(item) }
                    this.liveRepositoryCommits = merged
                }
                this.page = targetPage
                this.hasMore = items.size >= 50
                this.loading = false
                this.loadingMore = false
                this.actionMessage = ""
            } },
            { message => spawn(UIThread) {
                if (reset) {
                    this.liveRepositoryCommits = ArrayList<GitHubCommitSnapshot>()
                }
                this.loading = false
                this.loadingMore = false
                this.actionMessage = message
            } },
            page: targetPage
        )
    }

    func loadMore(): Unit { this.loadItems(reset: false) }

    func openCommit(item: GitHubCommitSnapshot): Unit {
        if (item.sha == "") { return }
        this.selectedRepositoryCommitSha = item.sha
        this.selectedRepositoryCommitDetail = GitHubCommitDetailSnapshot(item.sha, item.message, item.authorLogin, "", "", "", 0, 0, item.commitUrl)
        this.homeStack.pushPath(NavPathInfo(name: "commitDetailPage", param: ""), options: NavigationOptions(animated: true))
    }

    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
}

@Component
public class HomeRepositoryCommitDetailPage {
    @Consume var homeStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var selectedRepository: String
    @Consume var selectedRepositoryCommitSha: String
    @Consume var selectedRepositoryCommitDetail: GitHubCommitDetailSnapshot
    @Consume var selectedGitHubUserLogin: String
    @Consume var selectedGitHubUserProfile: GitHubUserProfileSnapshot
    @Consume var selectedGitHubUserRepositories: ArrayList<GitHubRepositoryCardSnapshot>
    @Consume var selectedGitHubFollowers: ArrayList<GitHubSimpleUserSnapshot>
    @Consume var selectedGitHubFollowing: ArrayList<GitHubSimpleUserSnapshot>

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @State var loading: Bool = false
    @State var actionMessage: String = ""

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
        this.loadDetail()
    }

    public func build() {
        NavDestination() {
            Stack(alignContent: Alignment.TopStart) {
                detailBackgroundCommon(this.pageBackgroundColor())
                Scroll {
                    Column(space: 12) {
                        detailHeaderCommon(this.homeStack, this.t("back"), this.t("commits"), this.primaryTextColor(), this.surfaceColor())
                        if (this.actionMessage != "") {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("commits"), this.actionMessage)
                        }
                        this.buildAuthorCard()
                        this.buildStatsCard()
                        this.buildMessageCard()
                    }
                    .width(100.percent)
                    .padding(left: 18, right: 18, top: 18, bottom: 120)
                }
                .width(100.percent)
                .height(100.percent)
                .scrollBar(BarState.Off)
                .align(Alignment.Top)
            }
            .width(100.percent)
            .height(100.percent)
        }
        .hideTitleBar(true)
        .backgroundColor(this.pageBackgroundColor())
    }

    func loadDetail(): Unit {
        if (this.sharedAuthAccessToken == "" || this.selectedRepository == "" || this.selectedRepositoryCommitSha == "") {
            this.actionMessage = this.t("sign_in_required")
            return
        }
        this.loading = true
        fetchGitHubRepositoryCommitDetail(
            this.sharedAuthAccessToken,
            this.selectedRepository,
            this.selectedRepositoryCommitSha,
            { snapshot => spawn(UIThread) { this.selectedRepositoryCommitDetail = snapshot; this.loading = false; this.actionMessage = "" } },
            { message => spawn(UIThread) { this.loading = false; this.actionMessage = message } }
        )
    }

    @Builder
    func buildAuthorCard() {
        Button() {
            Row(space: 12) {
                Text("◉")
                    .fontSize(22)
                    .fontColor(this.secondaryTextColor())
                Column(space: 6) {
                    Text(if (this.selectedRepositoryCommitDetail.authorLogin == "") { this.selectedRepositoryCommitDetail.authorName } else { this.selectedRepositoryCommitDetail.authorLogin })
                        .fontSize(16)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(this.primaryTextColor())
                    if (this.selectedRepositoryCommitDetail.committedAt != "") {
                        Text("${this.t("commit_date")}: ${this.selectedRepositoryCommitDetail.committedAt}")
                            .fontSize(12)
                            .fontColor(this.secondaryTextColor())
                    }
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
            }
            .width(100.percent)
            .alignItems(VerticalAlign.Center)
        }
        .width(100.percent)
        .padding(18)
        .backgroundColor(this.surfaceColor())
        .borderRadius(24)
        .enabled(this.selectedRepositoryCommitDetail.authorLogin != "")
        .onClick({ _ => this.openAuthor() })
    }

    @Builder
    func buildStatsCard() {
        Column(space: 10) {
            Text("${this.t("commit_sha")}: ${this.selectedRepositoryCommitDetail.sha}")
                .fontSize(13)
                .fontColor(this.secondaryTextColor())
            Row(space: 18) {
                Text("+${this.selectedRepositoryCommitDetail.additions} ${this.t("additions")}")
                    .fontSize(13)
                    .fontColor(0x2F9E44)
                Text("-${this.selectedRepositoryCommitDetail.deletions} ${this.t("deletions")}")
                    .fontSize(13)
                    .fontColor(0xE03131)
            }
        }
        .width(100.percent)
        .padding(18)
        .backgroundColor(this.surfaceColor())
        .borderRadius(24)
    }

    @Builder
    func buildMessageCard() {
        Column(space: 10) {
            Text(this.t("commit_message"))
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.primaryTextColor())
            Text(this.selectedRepositoryCommitDetail.message)
                .fontSize(15)
                .fontColor(this.primaryTextColor())
        }
        .width(100.percent)
        .padding(18)
        .backgroundColor(this.surfaceColor())
        .borderRadius(24)
    }

    func openAuthor(): Unit {
        if (this.selectedRepositoryCommitDetail.authorLogin == "") { return }
        this.selectedGitHubUserLogin = this.selectedRepositoryCommitDetail.authorLogin
        this.selectedGitHubUserProfile = GitHubUserProfileSnapshot("", "", "", "", "", "", "", "", "0", "0", "0", "0")
        this.selectedGitHubUserRepositories = ArrayList<GitHubRepositoryCardSnapshot>()
        this.selectedGitHubFollowers = ArrayList<GitHubSimpleUserSnapshot>()
        this.selectedGitHubFollowing = ArrayList<GitHubSimpleUserSnapshot>()
        this.homeStack.pushPath(NavPathInfo(name: "userProfilePage", param: ""), options: NavigationOptions(animated: true))
    }

    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
}

@Component
public class HomeUserProfilePage {
    @Consume var homeStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var selectedRepository: String
    @Consume var selectedGitHubUserLogin: String
    @Consume var selectedGitHubUserProfile: GitHubUserProfileSnapshot
    @Consume var selectedGitHubUserRepositories: ArrayList<GitHubRepositoryCardSnapshot>
    @Consume var selectedGitHubUserIssues: ArrayList<GitHubIssueSnapshot>
    @Consume var selectedGitHubUserPullRequests: ArrayList<GitHubPullRequestSnapshot>
    @Consume var selectedGitHubUserGists: ArrayList<GitHubGistSnapshot>
    @Consume var selectedGitHubGistFiles: ArrayList<GitHubGistFileSnapshot>
    @Consume var selectedGitHubGistId: String
    @Consume var selectedGitHubFollowers: ArrayList<GitHubSimpleUserSnapshot>
    @Consume var selectedGitHubFollowing: ArrayList<GitHubSimpleUserSnapshot>
    @Consume var liveRepositoryDetail: GitHubRepositoryDetailSnapshot
    @Consume var liveRepositoryReadme: String
    @Consume var liveIssues: ArrayList<GitHubIssueSnapshot>
    @Consume var livePullRequests: ArrayList<GitHubPullRequestSnapshot>

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @State var loading: Bool = false
    @State var actionMessage: String = ""
    @State var recentEvents: ArrayList<GitHubEventSnapshot> = ArrayList<GitHubEventSnapshot>()

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
        this.loadProfile()
    }

    public func build() {
        NavDestination() {
            Stack(alignContent: Alignment.TopStart) {
                detailBackgroundCommon(this.pageBackgroundColor())
                Scroll {
                    Column(space: 18) {
                        detailHeaderCommon(this.homeStack, this.t("back"), this.selectedGitHubUserLogin, this.primaryTextColor(), this.surfaceColor())
                        this.buildIdentityCard()
                        this.buildStatsCard()
                        if (this.selectedGitHubUserRepositories.size > 0) {
                            this.buildRepoPreviewCard()
                        }
                        this.buildActivityCard()
                        if (this.actionMessage != "") {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("status"), this.actionMessage)
                        }
                    }
                    .width(100.percent)
                    .padding(left: 18, right: 18, top: 18, bottom: 120)
                }
                .width(100.percent)
                .height(100.percent)
                .scrollBar(BarState.Off)
                .align(Alignment.Top)
            }
            .width(100.percent)
            .height(100.percent)
        }
        .hideTitleBar(true)
        .backgroundColor(this.pageBackgroundColor())
    }

    func loadProfile(): Unit {
        if (this.sharedAuthAccessToken == "" || this.selectedGitHubUserLogin == "") {
            this.actionMessage = this.t("sign_in_required")
            return
        }
        this.loading = true
        fetchGitHubUserProfile(
            this.sharedAuthAccessToken,
            this.selectedGitHubUserLogin,
            { snapshot => spawn(UIThread) { this.selectedGitHubUserProfile = snapshot; this.loading = false } },
            { message => spawn(UIThread) { this.actionMessage = message; this.loading = false } }
        )
        fetchGitHubUserRepositories(
            this.sharedAuthAccessToken,
            this.selectedGitHubUserLogin,
            { items => spawn(UIThread) { this.selectedGitHubUserRepositories = items } },
            { _ => }
        )
        fetchGitHubUserIssues(
            this.sharedAuthAccessToken,
            this.selectedGitHubUserLogin,
            { items => spawn(UIThread) { this.selectedGitHubUserIssues = items } },
            { _ => }
        )
        fetchGitHubUserPullRequests(
            this.sharedAuthAccessToken,
            this.selectedGitHubUserLogin,
            { items => spawn(UIThread) { this.selectedGitHubUserPullRequests = items } },
            { _ => }
        )
        fetchGitHubUserGists(
            this.sharedAuthAccessToken,
            this.selectedGitHubUserLogin,
            { items => spawn(UIThread) { this.selectedGitHubUserGists = items } },
            { _ => }
        )
        fetchGitHubUserFollowers(
            this.sharedAuthAccessToken,
            this.selectedGitHubUserLogin,
            { items => spawn(UIThread) { this.selectedGitHubFollowers = items } },
            { _ => }
        )
        fetchGitHubUserFollowing(
            this.sharedAuthAccessToken,
            this.selectedGitHubUserLogin,
            { items => spawn(UIThread) { this.selectedGitHubFollowing = items } },
            { _ => }
        )
        fetchGitHubUserActivity(
            this.sharedAuthAccessToken,
            this.selectedGitHubUserLogin,
            { items => spawn(UIThread) { this.recentEvents = items } },
            { _ => }
        )
    }

    func profileMetaLine(): String {
        if (this.selectedGitHubUserProfile.location != "" && this.selectedGitHubUserProfile.company != "") {
            return "${this.selectedGitHubUserProfile.location} ${this.selectedGitHubUserProfile.company}"
        }
        if (this.selectedGitHubUserProfile.location != "") {
            return this.selectedGitHubUserProfile.location
        }
        this.selectedGitHubUserProfile.company
    }

    @Builder
    func buildIdentityCard() {
        Column(space: 10) {
            Text(if (this.selectedGitHubUserProfile.displayName != "") { this.selectedGitHubUserProfile.displayName } else { this.selectedGitHubUserProfile.login })
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.primaryTextColor())
                .width(100.percent)
            if (this.selectedGitHubUserProfile.bio != "") {
                Text(this.selectedGitHubUserProfile.bio).fontSize(13).lineHeight(20).fontColor(this.secondaryTextColor()).width(100.percent)
            }
            if (this.selectedGitHubUserProfile.location != "" || this.selectedGitHubUserProfile.company != "") {
                Text(this.profileMetaLine())
                    .fontSize(12).fontColor(this.secondaryTextColor()).width(100.percent)
            }
            Button(this.t("open_on_github"))
                .width(100.percent)
                .height(44)
                .backgroundColor(this.surfaceColor())
                .fontColor(this.primaryTextColor())
                .borderRadius(14)
                .onClick({ _ => this.openUrl(this.selectedGitHubUserProfile.profileUrl) })
        }
        .width(100.percent)
        .padding(18)
        .backgroundColor(this.surfaceColor())
        .borderRadius(24)
    }

    @Builder
    func buildStatsCard() {
        Column(space: 0) {
            buildStatRow(this.t("repositories"), this.selectedGitHubUserProfile.repositoryCount, { => this.homeStack.pushPath(NavPathInfo(name: "userRepositoriesPage", param: ""), options: NavigationOptions(animated: true)) }, this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor())
            buildThinDivider(this.mutedSurfaceColor())
            buildStatRow(this.t("issues"), "${this.selectedGitHubUserIssues.size}", { => this.homeStack.pushPath(NavPathInfo(name: "userIssuesPage", param: ""), options: NavigationOptions(animated: true)) }, this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor())
            buildThinDivider(this.mutedSurfaceColor())
            buildStatRow(this.t("pull_requests"), "${this.selectedGitHubUserPullRequests.size}", { => this.homeStack.pushPath(NavPathInfo(name: "userPullRequestsPage", param: ""), options: NavigationOptions(animated: true)) }, this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor())
            buildThinDivider(this.mutedSurfaceColor())
            buildStatRow(this.t("gists"), this.selectedGitHubUserProfile.gistCount, { => this.homeStack.pushPath(NavPathInfo(name: "userGistsPage", param: ""), options: NavigationOptions(animated: true)) }, this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor())
            buildThinDivider(this.mutedSurfaceColor())
            buildStatRow(this.t("followers"), this.selectedGitHubUserProfile.followersCount, { => this.homeStack.pushPath(NavPathInfo(name: "userFollowersPage", param: ""), options: NavigationOptions(animated: true)) }, this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor())
            buildThinDivider(this.mutedSurfaceColor())
            buildStatRow(this.t("following"), this.selectedGitHubUserProfile.followingCount, { => this.homeStack.pushPath(NavPathInfo(name: "userFollowingPage", param: ""), options: NavigationOptions(animated: true)) }, this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor())
        }
        .width(100.percent)
        .backgroundColor(this.surfaceColor())
        .borderRadius(24)
    }

    @Builder
    func buildRepoPreviewCard() {
        Column(space: 12) {
            Text(this.t("repositories")).fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor()).width(100.percent)
            ForEach(this.topRepositories(), itemGeneratorFunc: { item: GitHubRepositoryCardSnapshot, _: Int64 =>
                buildRepositoryCardRow(this.mutedSurfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), item, this.t("public"), this.t("private"), { => this.openRepository(item.name) })
            })
        }
        .width(100.percent)
        .padding(18)
        .backgroundColor(this.surfaceColor())
        .borderRadius(24)
    }

    func topRepositories(): ArrayList<GitHubRepositoryCardSnapshot> {
        let top = ArrayList<GitHubRepositoryCardSnapshot>()
        var index: Int64 = 0
        for (item in this.selectedGitHubUserRepositories) {
            if (index >= 5) { break }
            top.add(item)
            index += 1
        }
        top
    }

    @Builder
    func buildActivityCard() {
        Column(space: 12) {
            Row {
                Text(this.t("activity")).fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
                Blank()
                Text(this.t("view_all")).fontSize(12).fontColor(this.secondaryTextColor())
            }
            .width(100.percent)
            .onClick({ _ => this.homeStack.pushPath(NavPathInfo(name: "userActivityPage", param: ""), options: NavigationOptions(animated: true)) })
            if (this.recentEvents.size > 0) {
                ForEach(this.topEvents(), itemGeneratorFunc: { item: GitHubEventSnapshot, _: Int64 =>
                    this.buildActivityRow(item)
                })
            } else {
                Text(this.t("activity_empty")).fontSize(13).lineHeight(20).fontColor(this.secondaryTextColor()).width(100.percent)
            }
        }
        .width(100.percent)
        .padding(18)
        .backgroundColor(this.surfaceColor())
        .borderRadius(24)
    }

    @Builder
    func buildActivityRow(item: GitHubEventSnapshot) {
        Column(space: 8) {
            Text(if (item.repoName == "") { item.targetTitle } else { item.repoName }).fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor()).width(100.percent)
            Text(this.eventSummary(item)).fontSize(12).lineHeight(18).fontColor(this.secondaryTextColor()).width(100.percent)
        }
        .width(100.percent)
        .onClick({ _ => this.openUrl(item.targetUrl) })
    }

    func topEvents(): ArrayList<GitHubEventSnapshot> {
        let top = ArrayList<GitHubEventSnapshot>()
        var index: Int64 = 0
        for (item in this.recentEvents) {
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

    func openUrl(url: String): Unit {
        if (url == "") { return }
        try { getAppAbilityContext().startAbility(Want(uri: url, action: "ohos.want.action.viewData")) } catch (_: BusinessException) {}
    }
    func openRepository(repositoryId: String): Unit {
        if (repositoryId == "") { return }
        this.selectedRepository = repositoryId
        this.liveRepositoryDetail = GitHubRepositoryDetailSnapshot(repositoryId, "Loading repository details...", "", "", "0", "0", "main")
        this.liveRepositoryReadme = ""
        this.liveIssues = ArrayList<GitHubIssueSnapshot>()
        this.livePullRequests = ArrayList<GitHubPullRequestSnapshot>()
        if (this.sharedAuthAccessToken != "") {
            refreshGitHubRepositoryBundle(
                this.sharedAuthAccessToken,
                repositoryId,
                { snapshot => spawn(UIThread) { this.liveRepositoryDetail = snapshot } },
                { markdown => spawn(UIThread) { this.liveRepositoryReadme = markdown } },
                { items => spawn(UIThread) { this.liveIssues = items } },
                { items => spawn(UIThread) { this.livePullRequests = items } },
                { message => spawn(UIThread) { this.actionMessage = message } }
            )
        }
        this.homeStack.pushPath(NavPathInfo(name: "repositoryDetail", param: ""), options: NavigationOptions(animated: true))
    }

    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func mutedSurfaceColor(): Int64 { appThemeColor("mutedSurface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
}

@Component
public class HomeUserFollowersPage {
    @Consume var homeStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var selectedGitHubFollowers: ArrayList<GitHubSimpleUserSnapshot>
    @Consume var selectedGitHubUserLogin: String
    @Consume var selectedGitHubUserProfile: GitHubUserProfileSnapshot
    @Consume var selectedGitHubUserRepositories: ArrayList<GitHubRepositoryCardSnapshot>
    @Consume var selectedGitHubUserIssues: ArrayList<GitHubIssueSnapshot>
    @Consume var selectedGitHubUserPullRequests: ArrayList<GitHubPullRequestSnapshot>
    @Consume var selectedGitHubUserGists: ArrayList<GitHubGistSnapshot>
    @Consume var selectedGitHubFollowing: ArrayList<GitHubSimpleUserSnapshot>

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light
    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"
    @Consume var sharedAuthAccessToken: String

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
                        detailHeaderCommon(this.homeStack, this.t("back"), this.t("followers"), this.primaryTextColor(), this.surfaceColor())
                        if (this.actionMessage != "") {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("followers"), this.actionMessage)
                        }
                        if (this.selectedGitHubFollowers.size > 0) {
                            ForEach(this.selectedGitHubFollowers, itemGeneratorFunc: { item: GitHubSimpleUserSnapshot, _: Int64 =>
                                buildSimpleUserRow(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), item, { => this.openUser(item.login) })
                            })
                        } else if (!this.loading) {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("followers"), this.t("followers_empty"))
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
        if (this.sharedAuthAccessToken == "" || this.selectedGitHubUserLogin == "") {
            this.actionMessage = this.t("sign_in_required")
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
        fetchGitHubUserFollowers(
            this.sharedAuthAccessToken,
            this.selectedGitHubUserLogin,
            { items => spawn(UIThread) {
                if (reset) {
                    this.selectedGitHubFollowers = items
                } else {
                    let merged = ArrayList<GitHubSimpleUserSnapshot>()
                    for (item in this.selectedGitHubFollowers) { merged.add(item) }
                    for (item in items) { merged.add(item) }
                    this.selectedGitHubFollowers = merged
                }
                this.page = targetPage
                this.hasMore = items.size >= 50
                this.loading = false
                this.loadingMore = false
                this.actionMessage = ""
            } },
            { message => spawn(UIThread) {
                if (reset) {
                    this.selectedGitHubFollowers = ArrayList<GitHubSimpleUserSnapshot>()
                }
                this.loading = false
                this.loadingMore = false
                this.actionMessage = message
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
        this.selectedGitHubUserGists = ArrayList<GitHubGistSnapshot>()
        this.selectedGitHubFollowing = ArrayList<GitHubSimpleUserSnapshot>()
        this.homeStack.pushPath(NavPathInfo(name: "userProfilePage", param: ""), options: NavigationOptions(animated: true))
    }
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
}

@Component
public class HomeUserRepositoriesPage {
    @Consume var homeStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var selectedGitHubUserLogin: String
    @Consume var selectedGitHubUserRepositories: ArrayList<GitHubRepositoryCardSnapshot>
    @Consume var selectedRepository: String
    @Consume var selectedIssue: String
    @Consume var selectedPullRequest: String
    @Consume var selectedTask: String
    @Consume var liveRepositoryDetail: GitHubRepositoryDetailSnapshot
    @Consume var liveIssues: ArrayList<GitHubIssueSnapshot>
    @Consume var livePullRequests: ArrayList<GitHubPullRequestSnapshot>

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

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
                        detailHeaderCommon(this.homeStack, this.t("back"), this.t("repositories"), this.primaryTextColor(), this.surfaceColor())
                        if (this.actionMessage != "") {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("repositories"), this.actionMessage)
                        }
                        if (this.selectedGitHubUserRepositories.size > 0) {
                            ForEach(this.selectedGitHubUserRepositories, itemGeneratorFunc: { item: GitHubRepositoryCardSnapshot, _: Int64 =>
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
        if (this.sharedAuthAccessToken == "" || this.selectedGitHubUserLogin == "") {
            this.actionMessage = this.t("sign_in_required")
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
        fetchGitHubUserRepositories(
            this.sharedAuthAccessToken,
            this.selectedGitHubUserLogin,
            { items => spawn(UIThread) {
                if (reset) {
                    this.selectedGitHubUserRepositories = items
                } else {
                    let merged = ArrayList<GitHubRepositoryCardSnapshot>()
                    for (item in this.selectedGitHubUserRepositories) { merged.add(item) }
                    for (item in items) { merged.add(item) }
                    this.selectedGitHubUserRepositories = merged
                }
                this.page = targetPage
                this.hasMore = items.size >= 50
                this.actionMessage = ""
                this.loading = false
                this.loadingMore = false
            } },
            { message => spawn(UIThread) {
                if (reset) {
                    this.selectedGitHubUserRepositories = ArrayList<GitHubRepositoryCardSnapshot>()
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
        if (this.sharedAuthAccessToken != "") {
            refreshGitHubRepositoryBundle(
                this.sharedAuthAccessToken,
                repositoryId,
                { snapshot => this.liveRepositoryDetail = snapshot },
                { _ => },
                { items =>
                    this.liveIssues = items
                    if (items.size > 0) {
                        this.selectedIssue = items[0].id
                        this.selectedTask = taskIdForIssue(items[0].id)
                    }
                },
                { items =>
                    this.livePullRequests = items
                    if (items.size > 0) {
                        this.selectedPullRequest = items[0].id
                    }
                },
                { _ => }
            )
        }
        this.homeStack.pushPath(NavPathInfo(name: "repositoryDetail", param: ""), options: NavigationOptions(animated: true))
    }

    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
}

@Component
public class HomeUserIssuesPage {
    @Consume var homeStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var selectedGitHubUserIssues: ArrayList<GitHubIssueSnapshot>
    @Consume var selectedRepository: String
    @Consume var selectedIssue: String
    @Consume var selectedTask: String
    @Consume var liveRepositoryDetail: GitHubRepositoryDetailSnapshot
    @Consume var liveIssues: ArrayList<GitHubIssueSnapshot>
    @Consume var livePullRequests: ArrayList<GitHubPullRequestSnapshot>
    @Consume var sharedAuthAccessToken: String

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light
    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @Consume var selectedGitHubUserLogin: String
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
                        detailHeaderCommon(this.homeStack, this.t("back"), this.t("issues"), this.primaryTextColor(), this.surfaceColor())
                        if (this.actionMessage != "") {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("issues"), this.actionMessage)
                        }
                        if (this.selectedGitHubUserIssues.size > 0) {
                            ForEach(this.selectedGitHubUserIssues, itemGeneratorFunc: { item: GitHubIssueSnapshot, _: Int64 =>
                                this.buildIssueRow(item)
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
        if (this.sharedAuthAccessToken == "" || this.selectedGitHubUserLogin == "") {
            this.actionMessage = this.t("sign_in_required")
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
        fetchGitHubUserIssues(
            this.sharedAuthAccessToken,
            this.selectedGitHubUserLogin,
            { items => spawn(UIThread) {
                if (reset) {
                    this.selectedGitHubUserIssues = items
                } else {
                    let merged = ArrayList<GitHubIssueSnapshot>()
                    for (item in this.selectedGitHubUserIssues) { merged.add(item) }
                    for (item in items) { merged.add(item) }
                    this.selectedGitHubUserIssues = merged
                }
                this.page = targetPage
                this.hasMore = items.size >= 20
                this.actionMessage = ""
                this.loading = false
                this.loadingMore = false
            } },
            { message => spawn(UIThread) {
                if (reset) {
                    this.selectedGitHubUserIssues = ArrayList<GitHubIssueSnapshot>()
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
        if (this.sharedAuthAccessToken != "") {
            refreshGitHubRepositoryBundle(
                this.sharedAuthAccessToken,
                repositoryName,
                { snapshot => this.liveRepositoryDetail = snapshot },
                { _ => },
                { items => this.liveIssues = items },
                { items => this.livePullRequests = items },
                { _ => }
            )
        }
        this.homeStack.pushPath(NavPathInfo(name: "issueDetail", param: ""), options: NavigationOptions(animated: true))
    }

    @Builder
    func buildIssueRow(snapshot: GitHubIssueSnapshot) {
        Button() {
            Column(space: 8) {
                Text(snapshot.title).fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
                Text(snapshot.summary).fontSize(12).fontColor(this.secondaryTextColor())
                Text("${snapshot.status} / @${snapshot.authorLogin}").fontSize(12).fontColor(this.secondaryTextColor())
            }
            .width(100.percent)
            .alignItems(HorizontalAlign.Start)
        }
        .width(100.percent)
        .padding(18)
        .backgroundColor(this.surfaceColor())
        .borderRadius(24)
        .onClick({ _ => this.openIssue(snapshot) })
    }

    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
}

@Component
public class HomeUserPullRequestsPage {
    @Consume var homeStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var selectedGitHubUserPullRequests: ArrayList<GitHubPullRequestSnapshot>
    @Consume var selectedRepository: String
    @Consume var selectedPullRequest: String
    @Consume var liveRepositoryDetail: GitHubRepositoryDetailSnapshot
    @Consume var liveIssues: ArrayList<GitHubIssueSnapshot>
    @Consume var livePullRequests: ArrayList<GitHubPullRequestSnapshot>
    @Consume var sharedAuthAccessToken: String

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light
    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @Consume var selectedGitHubUserLogin: String
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
                        detailHeaderCommon(this.homeStack, this.t("back"), this.t("pull_requests"), this.primaryTextColor(), this.surfaceColor())
                        if (this.actionMessage != "") {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("pull_requests"), this.actionMessage)
                        }
                        if (this.selectedGitHubUserPullRequests.size > 0) {
                            ForEach(this.selectedGitHubUserPullRequests, itemGeneratorFunc: { item: GitHubPullRequestSnapshot, _: Int64 =>
                                this.buildPullRequestRow(item)
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
        if (this.sharedAuthAccessToken == "" || this.selectedGitHubUserLogin == "") {
            this.actionMessage = this.t("sign_in_required")
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
        fetchGitHubUserPullRequests(
            this.sharedAuthAccessToken,
            this.selectedGitHubUserLogin,
            { items => spawn(UIThread) {
                if (reset) {
                    this.selectedGitHubUserPullRequests = items
                } else {
                    let merged = ArrayList<GitHubPullRequestSnapshot>()
                    for (item in this.selectedGitHubUserPullRequests) { merged.add(item) }
                    for (item in items) { merged.add(item) }
                    this.selectedGitHubUserPullRequests = merged
                }
                this.page = targetPage
                this.hasMore = items.size >= 20
                this.actionMessage = ""
                this.loading = false
                this.loadingMore = false
            } },
            { message => spawn(UIThread) {
                if (reset) {
                    this.selectedGitHubUserPullRequests = ArrayList<GitHubPullRequestSnapshot>()
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
        if (this.sharedAuthAccessToken != "") {
            refreshGitHubRepositoryBundle(
                this.sharedAuthAccessToken,
                repositoryName,
                { snapshot => this.liveRepositoryDetail = snapshot },
                { _ => },
                { items => this.liveIssues = items },
                { items => this.livePullRequests = items },
                { _ => }
            )
        }
        this.homeStack.pushPath(NavPathInfo(name: "pullRequestDetail", param: ""), options: NavigationOptions(animated: true))
    }

    @Builder
    func buildPullRequestRow(snapshot: GitHubPullRequestSnapshot) {
        Button() {
            Column(space: 8) {
                Text(snapshot.title).fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
                Text(snapshot.summary).fontSize(12).fontColor(this.secondaryTextColor())
                Text("${snapshot.status} / @${snapshot.authorLogin}").fontSize(12).fontColor(this.secondaryTextColor())
            }
            .width(100.percent)
            .alignItems(HorizontalAlign.Start)
        }
        .width(100.percent)
        .padding(18)
        .backgroundColor(this.surfaceColor())
        .borderRadius(24)
        .onClick({ _ => this.openPullRequest(snapshot) })
    }

    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
}

@Component
public class HomeUserActivityPage {
    @Consume var homeStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var selectedGitHubUserLogin: String

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @State var loading: Bool = false
    @State var loadingMore: Bool = false
    @State var page: Int64 = 1
    @State var hasMore: Bool = true
    @State var actionMessage: String = ""
    @State var events: ArrayList<GitHubEventSnapshot> = ArrayList<GitHubEventSnapshot>()

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
                        detailHeaderCommon(this.homeStack, this.t("back"), this.t("activity"), this.primaryTextColor(), this.surfaceColor())
                        if (this.actionMessage != "") {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("activity"), this.actionMessage)
                        }
                        if (this.events.size > 0) {
                            ForEach(this.events, itemGeneratorFunc: { item: GitHubEventSnapshot, _: Int64 =>
                                this.buildActivityRow(item)
                            })
                        } else if (!this.loading) {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("activity"), this.t("activity_empty"))
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
        if (this.sharedAuthAccessToken == "" || this.selectedGitHubUserLogin == "") {
            this.actionMessage = this.t("sign_in_required")
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
        fetchGitHubUserActivity(
            this.sharedAuthAccessToken,
            this.selectedGitHubUserLogin,
            { items => spawn(UIThread) {
                if (reset) {
                    this.events = items
                } else {
                    let merged = ArrayList<GitHubEventSnapshot>()
                    for (item in this.events) { merged.add(item) }
                    for (item in items) { merged.add(item) }
                    this.events = merged
                }
                this.page = targetPage
                this.hasMore = items.size >= 20
                this.actionMessage = ""
                this.loading = false
                this.loadingMore = false
            } },
            { message => spawn(UIThread) {
                if (reset) {
                    this.events = ArrayList<GitHubEventSnapshot>()
                }
                this.actionMessage = message
                this.loading = false
                this.loadingMore = false
            } },
            page: targetPage
        )
    }

    func loadMore(): Unit { this.loadItems(reset: false) }

    @Builder
    func buildActivityRow(item: GitHubEventSnapshot) {
        Column(space: 8) {
            Text(if (item.repoName == "") { item.targetTitle } else { item.repoName }).fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor()).width(100.percent)
            Text(this.eventSummary(item)).fontSize(12).lineHeight(18).fontColor(this.secondaryTextColor()).width(100.percent)
        }
        .width(100.percent)
        .padding(18)
        .backgroundColor(this.surfaceColor())
        .borderRadius(24)
        .onClick({ _ => this.openUrl(item.targetUrl) })
    }

    func eventSummary(item: GitHubEventSnapshot): String {
        if (item.eventType == "IssuesEvent") {
            if (item.action == "opened") { return "${this.t("event_issue_opened")} · ${item.targetTitle}" }
            if (item.action == "closed") { return "${this.t("event_issue_closed")} · ${item.targetTitle}" }
            return "${this.t("event_issue_updated")} · ${item.targetTitle}"
        }
        if (item.eventType == "IssueCommentEvent") { return "${this.t("event_issue_commented")} · ${item.targetTitle}" }
        if (item.eventType == "PullRequestEvent") {
            if (item.action == "opened") { return "${this.t("event_pr_opened")} · ${item.targetTitle}" }
            if (item.action == "closed") { return "${this.t("event_pr_closed")} · ${item.targetTitle}" }
            return "${this.t("event_pr_updated")} · ${item.targetTitle}"
        }
        if (item.eventType == "PullRequestReviewEvent") { return "${this.t("event_pr_reviewed")} · ${item.targetTitle}" }
        if (item.eventType == "PullRequestReviewCommentEvent") { return "${this.t("event_pr_commented")} · ${item.targetTitle}" }
        if (item.eventType == "PushEvent") { return "${this.t("event_push")} · ${item.targetTitle}" }
        if (item.eventType == "WatchEvent") { return "${this.t("event_starred")} · ${item.repoName}" }
        if (item.eventType == "ForkEvent") { return "${this.t("event_forked")} · ${item.repoName}" }
        if (item.eventType == "CreateEvent") { return "${this.t("event_created")} · ${item.targetTitle}" }
        if (item.eventType == "DeleteEvent") { return "${this.t("event_deleted")} · ${item.targetTitle}" }
        if (item.eventType == "ReleaseEvent") { return "${this.t("event_released")} · ${item.targetTitle}" }
        if (item.targetTitle != "") { return item.targetTitle }
        item.eventType
    }

    func openUrl(url: String): Unit {
        if (url == "") { return }
        try { getAppAbilityContext().startAbility(Want(uri: url, action: "ohos.want.action.viewData")) } catch (_: BusinessException) {}
    }

    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
}

@Component
public class HomeUserFollowingPage {
    @Consume var homeStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var selectedGitHubFollowing: ArrayList<GitHubSimpleUserSnapshot>
    @Consume var selectedGitHubUserLogin: String
    @Consume var selectedGitHubUserProfile: GitHubUserProfileSnapshot
    @Consume var selectedGitHubUserRepositories: ArrayList<GitHubRepositoryCardSnapshot>
    @Consume var selectedGitHubUserIssues: ArrayList<GitHubIssueSnapshot>
    @Consume var selectedGitHubUserPullRequests: ArrayList<GitHubPullRequestSnapshot>
    @Consume var selectedGitHubUserGists: ArrayList<GitHubGistSnapshot>
    @Consume var selectedGitHubFollowers: ArrayList<GitHubSimpleUserSnapshot>

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light
    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"
    @Consume var sharedAuthAccessToken: String

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
                        detailHeaderCommon(this.homeStack, this.t("back"), this.t("following"), this.primaryTextColor(), this.surfaceColor())
                        if (this.actionMessage != "") {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("following"), this.actionMessage)
                        }
                        if (this.selectedGitHubFollowing.size > 0) {
                            ForEach(this.selectedGitHubFollowing, itemGeneratorFunc: { item: GitHubSimpleUserSnapshot, _: Int64 =>
                                buildSimpleUserRow(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), item, { => this.openUser(item.login) })
                            })
                        } else if (!this.loading) {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("following"), this.t("following_empty"))
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
        if (this.sharedAuthAccessToken == "" || this.selectedGitHubUserLogin == "") {
            this.actionMessage = this.t("sign_in_required")
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
        fetchGitHubUserFollowing(
            this.sharedAuthAccessToken,
            this.selectedGitHubUserLogin,
            { items => spawn(UIThread) {
                if (reset) {
                    this.selectedGitHubFollowing = items
                } else {
                    let merged = ArrayList<GitHubSimpleUserSnapshot>()
                    for (item in this.selectedGitHubFollowing) { merged.add(item) }
                    for (item in items) { merged.add(item) }
                    this.selectedGitHubFollowing = merged
                }
                this.page = targetPage
                this.hasMore = items.size >= 50
                this.actionMessage = ""
                this.loading = false
                this.loadingMore = false
            } },
            { message => spawn(UIThread) {
                if (reset) {
                    this.selectedGitHubFollowing = ArrayList<GitHubSimpleUserSnapshot>()
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
        this.selectedGitHubUserGists = ArrayList<GitHubGistSnapshot>()
        this.selectedGitHubFollowers = ArrayList<GitHubSimpleUserSnapshot>()
        this.homeStack.pushPath(NavPathInfo(name: "userProfilePage", param: ""), options: NavigationOptions(animated: true))
    }
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
}

@Component
public class HomeUserGistsPage {
    @Consume var homeStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var selectedGitHubUserGists: ArrayList<GitHubGistSnapshot>
    @Consume var selectedGitHubGistFiles: ArrayList<GitHubGistFileSnapshot>
    @Consume var selectedGitHubGistId: String

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"
    @Consume var sharedAuthAccessToken: String
    @Consume var selectedGitHubUserLogin: String

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
                        detailHeaderCommon(this.homeStack, this.t("back"), this.t("gists"), this.primaryTextColor(), this.surfaceColor())
                        if (this.actionMessage != "") {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("gists"), this.actionMessage)
                        }
                        if (this.selectedGitHubUserGists.size > 0) {
                            ForEach(this.selectedGitHubUserGists, itemGeneratorFunc: { item: GitHubGistSnapshot, _: Int64 =>
                                buildGistRow(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), item, this.t("public"), this.t("private"), this.t("files"), { => this.openGist(item) })
                            })
                        } else if (!this.loading) {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("gists"), this.t("gists_empty"))
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
        if (this.sharedAuthAccessToken == "" || this.selectedGitHubUserLogin == "") {
            this.actionMessage = this.t("sign_in_required")
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
        fetchGitHubUserGists(
            this.sharedAuthAccessToken,
            this.selectedGitHubUserLogin,
            { items => spawn(UIThread) {
                if (reset) {
                    this.selectedGitHubUserGists = items
                } else {
                    let merged = ArrayList<GitHubGistSnapshot>()
                    for (item in this.selectedGitHubUserGists) { merged.add(item) }
                    for (item in items) { merged.add(item) }
                    this.selectedGitHubUserGists = merged
                }
                this.page = targetPage
                this.hasMore = items.size >= 50
                this.actionMessage = ""
                this.loading = false
                this.loadingMore = false
            } },
            { message => spawn(UIThread) {
                if (reset) {
                    this.selectedGitHubUserGists = ArrayList<GitHubGistSnapshot>()
                }
                this.actionMessage = message
                this.loading = false
                this.loadingMore = false
            } },
            page: targetPage
        )
    }

    func loadMore(): Unit { this.loadItems(reset: false) }

    func openGist(snapshot: GitHubGistSnapshot): Unit {
        this.selectedGitHubGistId = snapshot.id
        this.selectedGitHubGistFiles = ArrayList<GitHubGistFileSnapshot>()
        this.homeStack.pushPath(NavPathInfo(name: "gistDetailPage", param: ""), options: NavigationOptions(animated: true))
    }

    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
}

@Component
public class HomeGistDetailPage {
    @Consume var homeStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var selectedGitHubGistId: String
    @Consume var selectedGitHubGistFiles: ArrayList<GitHubGistFileSnapshot>

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @State var loading: Bool = false
    @State var actionMessage: String = ""

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
        this.loadFiles()
    }

    public func build() {
        NavDestination() {
            Stack(alignContent: Alignment.TopStart) {
                detailBackgroundCommon(this.pageBackgroundColor())
                Scroll {
                    Column(space: 12) {
                        detailHeaderCommon(this.homeStack, this.t("back"), this.t("gists"), this.primaryTextColor(), this.surfaceColor())
                        if (this.actionMessage != "") {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("gists"), this.actionMessage)
                        }
                        if (this.selectedGitHubGistFiles.size > 0) {
                            ForEach(this.selectedGitHubGistFiles, itemGeneratorFunc: { item: GitHubGistFileSnapshot, _: Int64 =>
                                buildGistFileCard(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), item)
                            })
                        } else if (!this.loading) {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("gists"), this.t("gists_empty"))
                        }
                    }
                    .width(100.percent)
                    .padding(left: 18, right: 18, top: 18, bottom: 120)
                }
                .width(100.percent)
                .height(100.percent)
                .scrollBar(BarState.Off)
                .align(Alignment.Top)
            }
            .width(100.percent)
            .height(100.percent)
        }
        .hideTitleBar(true)
        .backgroundColor(this.pageBackgroundColor())
    }

    func loadFiles(): Unit {
        if (this.sharedAuthAccessToken == "" || this.selectedGitHubGistId == "") {
            this.actionMessage = this.t("sign_in_required")
            return
        }
        this.loading = true
        fetchGitHubGistFiles(
            this.sharedAuthAccessToken,
            this.selectedGitHubGistId,
            { items => spawn(UIThread) { this.selectedGitHubGistFiles = items; this.actionMessage = ""; this.loading = false } },
            { message => spawn(UIThread) { this.selectedGitHubGistFiles = ArrayList<GitHubGistFileSnapshot>(); this.actionMessage = message; this.loading = false } }
        )
    }

    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
}

@Component
public class ExploreRepositoryWatchersPage {
    @Consume var exploreStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var selectedRepository: String
    @Consume var liveRepositoryWatchers: ArrayList<GitHubSimpleUserSnapshot>
    @Consume var selectedGitHubUserLogin: String
    @Consume var selectedGitHubUserProfile: GitHubUserProfileSnapshot
    @Consume var selectedGitHubUserRepositories: ArrayList<GitHubRepositoryCardSnapshot>
    @Consume var selectedGitHubFollowers: ArrayList<GitHubSimpleUserSnapshot>
    @Consume var selectedGitHubFollowing: ArrayList<GitHubSimpleUserSnapshot>

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light
    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"
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
                        detailHeaderCommon(this.exploreStack, this.t("back"), this.t("watchers"), this.primaryTextColor(), this.surfaceColor())
                        if (this.actionMessage != "") {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("watchers"), this.actionMessage)
                        }
                        if (this.liveRepositoryWatchers.size > 0) {
                            ForEach(this.liveRepositoryWatchers, itemGeneratorFunc: { item: GitHubSimpleUserSnapshot, _: Int64 =>
                                buildSimpleUserRow(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), item, { => this.openUser(item.login) })
                            })
                        } else if (!this.loading) {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("watchers"), this.t("watchers_empty"))
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
        if (this.sharedAuthAccessToken == "" || this.selectedRepository == "") { this.actionMessage = this.t("sign_in_required"); return }
        let targetPage = if (reset) { 1 } else { this.page + 1 }
        if (reset) {
            this.loading = true
            this.page = 1
            this.hasMore = true
        } else {
            if (this.loadingMore || !this.hasMore) { return }
            this.loadingMore = true
        }
        fetchGitHubRepositoryWatchers(
            this.sharedAuthAccessToken,
            this.selectedRepository,
            { items => spawn(UIThread) {
                if (reset) {
                    this.liveRepositoryWatchers = items
                } else {
                    let merged = ArrayList<GitHubSimpleUserSnapshot>()
                    for (item in this.liveRepositoryWatchers) { merged.add(item) }
                    for (item in items) { merged.add(item) }
                    this.liveRepositoryWatchers = merged
                }
                this.page = targetPage
                this.hasMore = items.size >= 50
                this.loading = false
                this.loadingMore = false
                this.actionMessage = ""
            } },
            { message => spawn(UIThread) {
                if (reset) {
                    this.liveRepositoryWatchers = ArrayList<GitHubSimpleUserSnapshot>()
                }
                this.loading = false
                this.loadingMore = false
                this.actionMessage = message
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

@Component
public class ExploreRepositoryStargazersPage {
    @Consume var exploreStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var selectedRepository: String
    @Consume var liveRepositoryStargazers: ArrayList<GitHubSimpleUserSnapshot>
    @Consume var selectedGitHubUserLogin: String
    @Consume var selectedGitHubUserProfile: GitHubUserProfileSnapshot
    @Consume var selectedGitHubUserRepositories: ArrayList<GitHubRepositoryCardSnapshot>
    @Consume var selectedGitHubFollowers: ArrayList<GitHubSimpleUserSnapshot>
    @Consume var selectedGitHubFollowing: ArrayList<GitHubSimpleUserSnapshot>

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light
    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"
    @State var loading: Bool = false
    @State var loadingMore: Bool = false
    @State var page: Int64 = 1
    @State var hasMore: Bool = true
    @State var actionMessage: String = ""

    protected override func aboutToAppear(): Unit { applyAppStatusBarStyle(this.isDarkTheme()); this.loadItems() }

    public func build() {
        NavDestination() {
            Stack(alignContent: Alignment.TopStart) {
                detailBackgroundCommon(this.pageBackgroundColor())
                Scroll {
                    Column(space: 12) {
                        detailHeaderCommon(this.exploreStack, this.t("back"), this.t("stargazers"), this.primaryTextColor(), this.surfaceColor())
                        if (this.actionMessage != "") { detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("stargazers"), this.actionMessage) }
                        if (this.liveRepositoryStargazers.size > 0) {
                            ForEach(this.liveRepositoryStargazers, itemGeneratorFunc: { item: GitHubSimpleUserSnapshot, _: Int64 =>
                                buildSimpleUserRow(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), item, { => this.openUser(item.login) })
                            })
                        } else if (!this.loading) {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("stargazers"), this.t("stargazers_empty"))
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
        }.hideTitleBar(true).backgroundColor(this.pageBackgroundColor())
    }

    func loadItems(reset!: Bool = true): Unit {
        if (this.sharedAuthAccessToken == "" || this.selectedRepository == "") { this.actionMessage = this.t("sign_in_required"); return }
        let targetPage = if (reset) { 1 } else { this.page + 1 }
        if (reset) {
            this.loading = true
            this.page = 1
            this.hasMore = true
        } else {
            if (this.loadingMore || !this.hasMore) { return }
            this.loadingMore = true
        }
        fetchGitHubRepositoryStargazers(
            this.sharedAuthAccessToken,
            this.selectedRepository,
            { items => spawn(UIThread) {
                if (reset) {
                    this.liveRepositoryStargazers = items
                } else {
                    let merged = ArrayList<GitHubSimpleUserSnapshot>()
                    for (item in this.liveRepositoryStargazers) { merged.add(item) }
                    for (item in items) { merged.add(item) }
                    this.liveRepositoryStargazers = merged
                }
                this.page = targetPage
                this.hasMore = items.size >= 50
                this.loading = false
                this.loadingMore = false
                this.actionMessage = ""
            } },
            { message => spawn(UIThread) {
                if (reset) {
                    this.liveRepositoryStargazers = ArrayList<GitHubSimpleUserSnapshot>()
                }
                this.loading = false
                this.loadingMore = false
                this.actionMessage = message
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

@Component
public class ExploreRepositoryForksPage {
    @Consume var exploreStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var selectedRepository: String
    @Consume var liveRepositoryForks: ArrayList<GitHubRepositoryCardSnapshot>
    @Consume var liveRepositoryDetail: GitHubRepositoryDetailSnapshot
    @Consume var liveRepositoryReadme: String
    @Consume var liveIssues: ArrayList<GitHubIssueSnapshot>
    @Consume var livePullRequests: ArrayList<GitHubPullRequestSnapshot>

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light
    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"
    @State var loading: Bool = false
    @State var loadingMore: Bool = false
    @State var page: Int64 = 1
    @State var hasMore: Bool = true
    @State var actionMessage: String = ""

    protected override func aboutToAppear(): Unit { applyAppStatusBarStyle(this.isDarkTheme()); this.loadItems() }

    public func build() {
        NavDestination() {
            Stack(alignContent: Alignment.TopStart) {
                detailBackgroundCommon(this.pageBackgroundColor())
                Scroll {
                    Column(space: 12) {
                        detailHeaderCommon(this.exploreStack, this.t("back"), this.t("forks"), this.primaryTextColor(), this.surfaceColor())
                        if (this.actionMessage != "") { detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("forks"), this.actionMessage) }
                        if (this.liveRepositoryForks.size > 0) {
                            ForEach(this.liveRepositoryForks, itemGeneratorFunc: { item: GitHubRepositoryCardSnapshot, _: Int64 =>
                                buildRepositoryCardRow(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), item, this.t("public"), this.t("private"), { => this.openRepository(item.name) })
                            })
                        } else if (!this.loading) {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("forks"), this.t("forks_empty"))
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
        }.hideTitleBar(true).backgroundColor(this.pageBackgroundColor())
    }

    func loadItems(reset!: Bool = true): Unit {
        if (this.sharedAuthAccessToken == "" || this.selectedRepository == "") { this.actionMessage = this.t("sign_in_required"); return }
        let targetPage = if (reset) { 1 } else { this.page + 1 }
        if (reset) {
            this.loading = true
            this.page = 1
            this.hasMore = true
        } else {
            if (this.loadingMore || !this.hasMore) { return }
            this.loadingMore = true
        }
        fetchGitHubRepositoryForks(
            this.sharedAuthAccessToken,
            this.selectedRepository,
            { items => spawn(UIThread) {
                if (reset) {
                    this.liveRepositoryForks = items
                } else {
                    let merged = ArrayList<GitHubRepositoryCardSnapshot>()
                    for (item in this.liveRepositoryForks) { merged.add(item) }
                    for (item in items) { merged.add(item) }
                    this.liveRepositoryForks = merged
                }
                this.page = targetPage
                this.hasMore = items.size >= 50
                this.loading = false
                this.loadingMore = false
                this.actionMessage = ""
            } },
            { message => spawn(UIThread) {
                if (reset) {
                    this.liveRepositoryForks = ArrayList<GitHubRepositoryCardSnapshot>()
                }
                this.loading = false
                this.loadingMore = false
                this.actionMessage = message
            } },
            page: targetPage
        )
    }
    func loadMore(): Unit { this.loadItems(reset: false) }
    func runOnUi(task: () -> Unit): Unit { spawn(UIThread) { => task() } }
    func openRepository(repositoryId: String): Unit {
        if (repositoryId == "") { return }
        this.selectedRepository = repositoryId
        this.liveRepositoryDetail = GitHubRepositoryDetailSnapshot(repositoryId, "Loading repository details...", "", "", "0", "0", "main")
        this.liveRepositoryReadme = ""
        this.liveIssues = ArrayList<GitHubIssueSnapshot>()
        this.livePullRequests = ArrayList<GitHubPullRequestSnapshot>()
        if (this.sharedAuthAccessToken != "") {
            refreshGitHubRepositoryBundle(
                this.sharedAuthAccessToken,
                repositoryId,
                { snapshot => this.runOnUi({ => this.liveRepositoryDetail = snapshot }) },
                { markdown => this.runOnUi({ => this.liveRepositoryReadme = markdown }) },
                { items => this.runOnUi({ => this.liveIssues = items }) },
                { items => this.runOnUi({ => this.livePullRequests = items }) },
                { message => this.runOnUi({ => this.actionMessage = message }) }
            )
        }
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
public class ExploreRepositoryCommitsPage {
    @Consume var exploreStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var selectedRepository: String
    @Consume var liveRepositoryCommits: ArrayList<GitHubCommitSnapshot>
    @Consume var selectedRepositoryCommitSha: String
    @Consume var selectedRepositoryCommitDetail: GitHubCommitDetailSnapshot

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light
    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"
    @State var loading: Bool = false
    @State var loadingMore: Bool = false
    @State var page: Int64 = 1
    @State var hasMore: Bool = true
    @State var actionMessage: String = ""

    protected override func aboutToAppear(): Unit { applyAppStatusBarStyle(this.isDarkTheme()); this.loadItems() }

    public func build() {
        NavDestination() {
            Stack(alignContent: Alignment.TopStart) {
                detailBackgroundCommon(this.pageBackgroundColor())
                Scroll {
                    Column(space: 12) {
                        detailHeaderCommon(this.exploreStack, this.t("back"), this.t("commits"), this.primaryTextColor(), this.surfaceColor())
                        if (this.actionMessage != "") { detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("commits"), this.actionMessage) }
                        if (this.liveRepositoryCommits.size > 0) {
                            ForEach(this.liveRepositoryCommits, itemGeneratorFunc: { item: GitHubCommitSnapshot, _: Int64 =>
                                buildCommitRow(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), item, { => this.openCommit(item) })
                            })
                        } else if (!this.loading) {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("commits"), this.t("commits_empty"))
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
        }.hideTitleBar(true).backgroundColor(this.pageBackgroundColor())
    }

    func loadItems(reset!: Bool = true): Unit {
        if (this.sharedAuthAccessToken == "" || this.selectedRepository == "") { this.actionMessage = this.t("sign_in_required"); return }
        let targetPage = if (reset) { 1 } else { this.page + 1 }
        if (reset) {
            this.loading = true
            this.page = 1
            this.hasMore = true
        } else {
            if (this.loadingMore || !this.hasMore) { return }
            this.loadingMore = true
        }
        fetchGitHubRepositoryCommits(
            this.sharedAuthAccessToken,
            this.selectedRepository,
            { items => spawn(UIThread) {
                if (reset) {
                    this.liveRepositoryCommits = items
                } else {
                    let merged = ArrayList<GitHubCommitSnapshot>()
                    for (item in this.liveRepositoryCommits) { merged.add(item) }
                    for (item in items) { merged.add(item) }
                    this.liveRepositoryCommits = merged
                }
                this.page = targetPage
                this.hasMore = items.size >= 50
                this.loading = false
                this.loadingMore = false
                this.actionMessage = ""
            } },
            { message => spawn(UIThread) {
                if (reset) {
                    this.liveRepositoryCommits = ArrayList<GitHubCommitSnapshot>()
                }
                this.loading = false
                this.loadingMore = false
                this.actionMessage = message
            } },
            page: targetPage
        )
    }
    func loadMore(): Unit { this.loadItems(reset: false) }
    func openCommit(item: GitHubCommitSnapshot): Unit {
        if (item.sha == "") { return }
        this.selectedRepositoryCommitSha = item.sha
        this.selectedRepositoryCommitDetail = GitHubCommitDetailSnapshot(item.sha, item.message, item.authorLogin, "", "", "", 0, 0, item.commitUrl)
        this.exploreStack.pushPath(NavPathInfo(name: "commitDetailPage", param: ""), options: NavigationOptions(animated: true))
    }
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
}

@Component
public class ExploreRepositoryCommitDetailPage {
    @Consume var exploreStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var selectedRepository: String
    @Consume var selectedRepositoryCommitSha: String
    @Consume var selectedRepositoryCommitDetail: GitHubCommitDetailSnapshot
    @Consume var selectedGitHubUserLogin: String
    @Consume var selectedGitHubUserProfile: GitHubUserProfileSnapshot
    @Consume var selectedGitHubUserRepositories: ArrayList<GitHubRepositoryCardSnapshot>
    @Consume var selectedGitHubFollowers: ArrayList<GitHubSimpleUserSnapshot>
    @Consume var selectedGitHubFollowing: ArrayList<GitHubSimpleUserSnapshot>

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light
    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"
    @State var loading: Bool = false
    @State var actionMessage: String = ""

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
        this.loadDetail()
    }

    public func build() {
        NavDestination() {
            Stack(alignContent: Alignment.TopStart) {
                detailBackgroundCommon(this.pageBackgroundColor())
                Scroll {
                    Column(space: 12) {
                        detailHeaderCommon(this.exploreStack, this.t("back"), this.t("commits"), this.primaryTextColor(), this.surfaceColor())
                        if (this.actionMessage != "") {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("commits"), this.actionMessage)
                        }
                        this.buildAuthorCard()
                        this.buildStatsCard()
                        this.buildMessageCard()
                    }
                    .width(100.percent)
                    .padding(left: 18, right: 18, top: 18, bottom: 120)
                }
                .width(100.percent)
                .height(100.percent)
                .scrollBar(BarState.Off)
                .align(Alignment.Top)
            }
            .width(100.percent)
            .height(100.percent)
        }
        .hideTitleBar(true)
        .backgroundColor(this.pageBackgroundColor())
    }

    func loadDetail(): Unit {
        if (this.sharedAuthAccessToken == "" || this.selectedRepository == "" || this.selectedRepositoryCommitSha == "") {
            this.actionMessage = this.t("sign_in_required")
            return
        }
        this.loading = true
        fetchGitHubRepositoryCommitDetail(
            this.sharedAuthAccessToken,
            this.selectedRepository,
            this.selectedRepositoryCommitSha,
            { snapshot => spawn(UIThread) { this.selectedRepositoryCommitDetail = snapshot; this.loading = false; this.actionMessage = "" } },
            { message => spawn(UIThread) { this.loading = false; this.actionMessage = message } }
        )
    }

    @Builder
    func buildAuthorCard() {
        Button() {
            Row(space: 12) {
                Text("◉")
                    .fontSize(22)
                    .fontColor(this.secondaryTextColor())
                Column(space: 6) {
                    Text(if (this.selectedRepositoryCommitDetail.authorLogin == "") { this.selectedRepositoryCommitDetail.authorName } else { this.selectedRepositoryCommitDetail.authorLogin })
                        .fontSize(16)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(this.primaryTextColor())
                    if (this.selectedRepositoryCommitDetail.committedAt != "") {
                        Text("${this.t("commit_date")}: ${this.selectedRepositoryCommitDetail.committedAt}")
                            .fontSize(12)
                            .fontColor(this.secondaryTextColor())
                    }
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
            }
            .width(100.percent)
            .alignItems(VerticalAlign.Center)
        }
        .width(100.percent)
        .padding(18)
        .backgroundColor(this.surfaceColor())
        .borderRadius(24)
        .enabled(this.selectedRepositoryCommitDetail.authorLogin != "")
        .onClick({ _ => this.openAuthor() })
    }

    @Builder
    func buildStatsCard() {
        Column(space: 10) {
            Text("${this.t("commit_sha")}: ${this.selectedRepositoryCommitDetail.sha}")
                .fontSize(13)
                .fontColor(this.secondaryTextColor())
            Row(space: 18) {
                Text("+${this.selectedRepositoryCommitDetail.additions} ${this.t("additions")}")
                    .fontSize(13)
                    .fontColor(0x2F9E44)
                Text("-${this.selectedRepositoryCommitDetail.deletions} ${this.t("deletions")}")
                    .fontSize(13)
                    .fontColor(0xE03131)
            }
        }
        .width(100.percent)
        .padding(18)
        .backgroundColor(this.surfaceColor())
        .borderRadius(24)
    }

    @Builder
    func buildMessageCard() {
        Column(space: 10) {
            Text(this.t("commit_message"))
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.primaryTextColor())
            Text(this.selectedRepositoryCommitDetail.message)
                .fontSize(15)
                .fontColor(this.primaryTextColor())
        }
        .width(100.percent)
        .padding(18)
        .backgroundColor(this.surfaceColor())
        .borderRadius(24)
    }

    func openAuthor(): Unit {
        if (this.selectedRepositoryCommitDetail.authorLogin == "") { return }
        this.selectedGitHubUserLogin = this.selectedRepositoryCommitDetail.authorLogin
        this.selectedGitHubUserProfile = GitHubUserProfileSnapshot("", "", "", "", "", "", "", "", "0", "0", "0", "0")
        this.selectedGitHubUserRepositories = ArrayList<GitHubRepositoryCardSnapshot>()
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

@Component
public class ExploreUserProfilePage {
    @Consume var exploreStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var selectedRepository: String
    @Consume var selectedGitHubUserLogin: String
    @Consume var selectedGitHubUserProfile: GitHubUserProfileSnapshot
    @Consume var selectedGitHubUserRepositories: ArrayList<GitHubRepositoryCardSnapshot>
    @Consume var selectedGitHubUserIssues: ArrayList<GitHubIssueSnapshot>
    @Consume var selectedGitHubUserPullRequests: ArrayList<GitHubPullRequestSnapshot>
    @Consume var selectedGitHubUserGists: ArrayList<GitHubGistSnapshot>
    @Consume var selectedGitHubGistFiles: ArrayList<GitHubGistFileSnapshot>
    @Consume var selectedGitHubGistId: String
    @Consume var selectedGitHubFollowers: ArrayList<GitHubSimpleUserSnapshot>
    @Consume var selectedGitHubFollowing: ArrayList<GitHubSimpleUserSnapshot>
    @Consume var liveRepositoryDetail: GitHubRepositoryDetailSnapshot
    @Consume var liveRepositoryReadme: String
    @Consume var liveIssues: ArrayList<GitHubIssueSnapshot>
    @Consume var livePullRequests: ArrayList<GitHubPullRequestSnapshot>

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light
    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"
    @State var loading: Bool = false
    @State var actionMessage: String = ""
    @State var recentEvents: ArrayList<GitHubEventSnapshot> = ArrayList<GitHubEventSnapshot>()

    protected override func aboutToAppear(): Unit { applyAppStatusBarStyle(this.isDarkTheme()); this.loadProfile() }

    public func build() {
        NavDestination() {
            Stack(alignContent: Alignment.TopStart) {
                detailBackgroundCommon(this.pageBackgroundColor())
                Scroll {
                    Column(space: 18) {
                        detailHeaderCommon(this.exploreStack, this.t("back"), this.selectedGitHubUserLogin, this.primaryTextColor(), this.surfaceColor())
                        this.buildIdentityCard()
                        this.buildStatsCard()
                        if (this.selectedGitHubUserRepositories.size > 0) { this.buildRepoPreviewCard() }
                        this.buildActivityCard()
                        if (this.actionMessage != "") { detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("status"), this.actionMessage) }
                    }
                    .width(100.percent)
                    .padding(left: 18, right: 18, top: 18, bottom: 120)
                }
                .width(100.percent)
                .height(100.percent)
                .scrollBar(BarState.Off)
                .align(Alignment.Top)
            }
            .width(100.percent)
            .height(100.percent)
        }.hideTitleBar(true).backgroundColor(this.pageBackgroundColor())
    }

    func loadProfile(): Unit {
        if (this.sharedAuthAccessToken == "" || this.selectedGitHubUserLogin == "") { this.actionMessage = this.t("sign_in_required"); return }
        this.loading = true
        fetchGitHubUserProfile(this.sharedAuthAccessToken, this.selectedGitHubUserLogin, { snapshot => spawn(UIThread) { this.selectedGitHubUserProfile = snapshot; this.loading = false } }, { message => spawn(UIThread) { this.actionMessage = message; this.loading = false } })
        fetchGitHubUserRepositories(this.sharedAuthAccessToken, this.selectedGitHubUserLogin, { items => spawn(UIThread) { this.selectedGitHubUserRepositories = items } }, { _ => })
        fetchGitHubUserIssues(this.sharedAuthAccessToken, this.selectedGitHubUserLogin, { items => spawn(UIThread) { this.selectedGitHubUserIssues = items } }, { _ => })
        fetchGitHubUserPullRequests(this.sharedAuthAccessToken, this.selectedGitHubUserLogin, { items => spawn(UIThread) { this.selectedGitHubUserPullRequests = items } }, { _ => })
        fetchGitHubUserGists(this.sharedAuthAccessToken, this.selectedGitHubUserLogin, { items => spawn(UIThread) { this.selectedGitHubUserGists = items } }, { _ => })
        fetchGitHubUserFollowers(this.sharedAuthAccessToken, this.selectedGitHubUserLogin, { items => spawn(UIThread) { this.selectedGitHubFollowers = items } }, { _ => })
        fetchGitHubUserFollowing(this.sharedAuthAccessToken, this.selectedGitHubUserLogin, { items => spawn(UIThread) { this.selectedGitHubFollowing = items } }, { _ => })
        fetchGitHubUserActivity(this.sharedAuthAccessToken, this.selectedGitHubUserLogin, { items => spawn(UIThread) { this.recentEvents = items } }, { _ => })
    }

    func profileMetaLine(): String {
        if (this.selectedGitHubUserProfile.location != "" && this.selectedGitHubUserProfile.company != "") {
            return "${this.selectedGitHubUserProfile.location} ${this.selectedGitHubUserProfile.company}"
        }
        if (this.selectedGitHubUserProfile.location != "") {
            return this.selectedGitHubUserProfile.location
        }
        this.selectedGitHubUserProfile.company
    }

    @Builder
    func buildIdentityCard() {
        Column(space: 10) {
            Text(if (this.selectedGitHubUserProfile.displayName != "") { this.selectedGitHubUserProfile.displayName } else { this.selectedGitHubUserProfile.login }).fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor()).width(100.percent)
            if (this.selectedGitHubUserProfile.bio != "") { Text(this.selectedGitHubUserProfile.bio).fontSize(13).lineHeight(20).fontColor(this.secondaryTextColor()).width(100.percent) }
            if (this.selectedGitHubUserProfile.location != "" || this.selectedGitHubUserProfile.company != "") { Text(this.profileMetaLine()).fontSize(12).fontColor(this.secondaryTextColor()).width(100.percent) }
            Button(this.t("open_on_github")).width(100.percent).height(44).backgroundColor(this.surfaceColor()).fontColor(this.primaryTextColor()).borderRadius(14).onClick({ _ => this.openUrl(this.selectedGitHubUserProfile.profileUrl) })
        }.width(100.percent).padding(18).backgroundColor(this.surfaceColor()).borderRadius(24)
    }
    @Builder
    func buildStatsCard() {
        Column(space: 0) {
            buildStatRow(this.t("repositories"), this.selectedGitHubUserProfile.repositoryCount, { => this.exploreStack.pushPath(NavPathInfo(name: "userRepositoriesPage", param: ""), options: NavigationOptions(animated: true)) }, this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor())
            buildThinDivider(this.mutedSurfaceColor())
            buildStatRow(this.t("issues"), "${this.selectedGitHubUserIssues.size}", { => this.exploreStack.pushPath(NavPathInfo(name: "userIssuesPage", param: ""), options: NavigationOptions(animated: true)) }, this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor())
            buildThinDivider(this.mutedSurfaceColor())
            buildStatRow(this.t("pull_requests"), "${this.selectedGitHubUserPullRequests.size}", { => this.exploreStack.pushPath(NavPathInfo(name: "userPullRequestsPage", param: ""), options: NavigationOptions(animated: true)) }, this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor())
            buildThinDivider(this.mutedSurfaceColor())
            buildStatRow(this.t("gists"), this.selectedGitHubUserProfile.gistCount, { => this.exploreStack.pushPath(NavPathInfo(name: "userGistsPage", param: ""), options: NavigationOptions(animated: true)) }, this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor())
            buildThinDivider(this.mutedSurfaceColor())
            buildStatRow(this.t("followers"), this.selectedGitHubUserProfile.followersCount, { => this.exploreStack.pushPath(NavPathInfo(name: "userFollowersPage", param: ""), options: NavigationOptions(animated: true)) }, this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor())
            buildThinDivider(this.mutedSurfaceColor())
            buildStatRow(this.t("following"), this.selectedGitHubUserProfile.followingCount, { => this.exploreStack.pushPath(NavPathInfo(name: "userFollowingPage", param: ""), options: NavigationOptions(animated: true)) }, this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor())
        }.width(100.percent).backgroundColor(this.surfaceColor()).borderRadius(24)
    }
    @Builder
    func buildRepoPreviewCard() {
        Column(space: 12) {
            Text(this.t("repositories")).fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor()).width(100.percent)
            ForEach(this.topRepositories(), itemGeneratorFunc: { item: GitHubRepositoryCardSnapshot, _: Int64 =>
                buildRepositoryCardRow(this.mutedSurfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), item, this.t("public"), this.t("private"), { => this.openRepository(item.name) })
            })
        }.width(100.percent).padding(18).backgroundColor(this.surfaceColor()).borderRadius(24)
    }
    func topRepositories(): ArrayList<GitHubRepositoryCardSnapshot> {
        let top = ArrayList<GitHubRepositoryCardSnapshot>()
        var index: Int64 = 0
        for (item in this.selectedGitHubUserRepositories) { if (index >= 5) { break }; top.add(item); index += 1 }
        top
    }
    @Builder
    func buildActivityCard() {
        Column(space: 12) {
            Row {
                Text(this.t("activity")).fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
                Blank()
                Text(this.t("view_all")).fontSize(12).fontColor(this.secondaryTextColor())
            }
            .width(100.percent)
            .onClick({ _ => this.exploreStack.pushPath(NavPathInfo(name: "userActivityPage", param: ""), options: NavigationOptions(animated: true)) })
            if (this.recentEvents.size > 0) {
                ForEach(this.topEvents(), itemGeneratorFunc: { item: GitHubEventSnapshot, _: Int64 =>
                    this.buildActivityRow(item)
                })
            } else {
                Text(this.t("activity_empty")).fontSize(13).lineHeight(20).fontColor(this.secondaryTextColor()).width(100.percent)
            }
        }.width(100.percent).padding(18).backgroundColor(this.surfaceColor()).borderRadius(24)
    }
    @Builder
    func buildActivityRow(item: GitHubEventSnapshot) {
        Column(space: 8) {
            Text(if (item.repoName == "") { item.targetTitle } else { item.repoName }).fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor()).width(100.percent)
            Text(this.eventSummary(item)).fontSize(12).lineHeight(18).fontColor(this.secondaryTextColor()).width(100.percent)
        }
        .width(100.percent)
        .onClick({ _ => this.openUrl(item.targetUrl) })
    }
    func topEvents(): ArrayList<GitHubEventSnapshot> {
        let top = ArrayList<GitHubEventSnapshot>()
        var index: Int64 = 0
        for (item in this.recentEvents) { if (index >= 5) { break }; top.add(item); index += 1 }
        top
    }
    func eventSummary(item: GitHubEventSnapshot): String {
        if (item.eventType == "IssuesEvent") {
            if (item.action == "opened") { return "${this.t("event_issue_opened")} · ${item.targetTitle}" }
            if (item.action == "closed") { return "${this.t("event_issue_closed")} · ${item.targetTitle}" }
            return "${this.t("event_issue_updated")} · ${item.targetTitle}"
        }
        if (item.eventType == "IssueCommentEvent") { return "${this.t("event_issue_commented")} · ${item.targetTitle}" }
        if (item.eventType == "PullRequestEvent") {
            if (item.action == "opened") { return "${this.t("event_pr_opened")} · ${item.targetTitle}" }
            if (item.action == "closed") { return "${this.t("event_pr_closed")} · ${item.targetTitle}" }
            return "${this.t("event_pr_updated")} · ${item.targetTitle}"
        }
        if (item.eventType == "PullRequestReviewEvent") { return "${this.t("event_pr_reviewed")} · ${item.targetTitle}" }
        if (item.eventType == "PullRequestReviewCommentEvent") { return "${this.t("event_pr_commented")} · ${item.targetTitle}" }
        if (item.eventType == "PushEvent") { return "${this.t("event_push")} · ${item.targetTitle}" }
        if (item.eventType == "WatchEvent") { return "${this.t("event_starred")} · ${item.repoName}" }
        if (item.eventType == "ForkEvent") { return "${this.t("event_forked")} · ${item.repoName}" }
        if (item.eventType == "CreateEvent") { return "${this.t("event_created")} · ${item.targetTitle}" }
        if (item.eventType == "DeleteEvent") { return "${this.t("event_deleted")} · ${item.targetTitle}" }
        if (item.eventType == "ReleaseEvent") { return "${this.t("event_released")} · ${item.targetTitle}" }
        if (item.targetTitle != "") { return item.targetTitle }
        item.eventType
    }
    func openUrl(url: String): Unit {
        if (url == "") { return }
        try { getAppAbilityContext().startAbility(Want(uri: url, action: "ohos.want.action.viewData")) } catch (_: BusinessException) {}
    }
    func openRepository(repositoryId: String): Unit {
        if (repositoryId == "") { return }
        this.selectedRepository = repositoryId
        this.liveRepositoryDetail = GitHubRepositoryDetailSnapshot(repositoryId, "Loading repository details...", "", "", "0", "0", "main")
        this.liveRepositoryReadme = ""
        this.liveIssues = ArrayList<GitHubIssueSnapshot>()
        this.livePullRequests = ArrayList<GitHubPullRequestSnapshot>()
        if (this.sharedAuthAccessToken != "") {
            refreshGitHubRepositoryBundle(
                this.sharedAuthAccessToken,
                repositoryId,
                { snapshot => spawn(UIThread) { this.liveRepositoryDetail = snapshot } },
                { markdown => spawn(UIThread) { this.liveRepositoryReadme = markdown } },
                { items => spawn(UIThread) { this.liveIssues = items } },
                { items => spawn(UIThread) { this.livePullRequests = items } },
                { message => spawn(UIThread) { this.actionMessage = message } }
            )
        }
        this.exploreStack.pushPath(NavPathInfo(name: "repositoryDetail", param: ""), options: NavigationOptions(animated: true))
    }
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func mutedSurfaceColor(): Int64 { appThemeColor("mutedSurface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
}

@Component
public class ExploreUserRepositoriesPage {
    @Consume var exploreStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var selectedGitHubUserLogin: String
    @Consume var selectedGitHubUserRepositories: ArrayList<GitHubRepositoryCardSnapshot>
    @Consume var selectedRepository: String
    @Consume var liveRepositoryDetail: GitHubRepositoryDetailSnapshot
    @Consume var liveRepositoryReadme: String
    @Consume var liveIssues: ArrayList<GitHubIssueSnapshot>
    @Consume var livePullRequests: ArrayList<GitHubPullRequestSnapshot>

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

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
                        if (this.selectedGitHubUserRepositories.size > 0) {
                            ForEach(this.selectedGitHubUserRepositories, itemGeneratorFunc: { item: GitHubRepositoryCardSnapshot, _: Int64 =>
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
        if (this.sharedAuthAccessToken == "" || this.selectedGitHubUserLogin == "") {
            this.actionMessage = this.t("sign_in_required")
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
        fetchGitHubUserRepositories(
            this.sharedAuthAccessToken,
            this.selectedGitHubUserLogin,
            { items => spawn(UIThread) {
                if (reset) {
                    this.selectedGitHubUserRepositories = items
                } else {
                    let merged = ArrayList<GitHubRepositoryCardSnapshot>()
                    for (item in this.selectedGitHubUserRepositories) { merged.add(item) }
                    for (item in items) { merged.add(item) }
                    this.selectedGitHubUserRepositories = merged
                }
                this.page = targetPage
                this.hasMore = items.size >= 50
                this.actionMessage = ""
                this.loading = false
                this.loadingMore = false
            } },
            { message => spawn(UIThread) {
                if (reset) {
                    this.selectedGitHubUserRepositories = ArrayList<GitHubRepositoryCardSnapshot>()
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
        this.liveRepositoryReadme = ""
        this.liveIssues = ArrayList<GitHubIssueSnapshot>()
        this.livePullRequests = ArrayList<GitHubPullRequestSnapshot>()
        if (this.sharedAuthAccessToken != "") {
            refreshGitHubRepositoryBundle(
                this.sharedAuthAccessToken,
                repositoryId,
                { snapshot => spawn(UIThread) { this.liveRepositoryDetail = snapshot } },
                { markdown => spawn(UIThread) { this.liveRepositoryReadme = markdown } },
                { items => spawn(UIThread) { this.liveIssues = items } },
                { items => spawn(UIThread) { this.livePullRequests = items } },
                { message => spawn(UIThread) { this.actionMessage = message } }
            )
        }
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
public class ExploreUserActivityPage {
    @Consume var exploreStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var selectedGitHubUserLogin: String

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @State var loading: Bool = false
    @State var loadingMore: Bool = false
    @State var page: Int64 = 1
    @State var hasMore: Bool = true
    @State var actionMessage: String = ""
    @State var events: ArrayList<GitHubEventSnapshot> = ArrayList<GitHubEventSnapshot>()

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
                        detailHeaderCommon(this.exploreStack, this.t("back"), this.t("activity"), this.primaryTextColor(), this.surfaceColor())
                        if (this.actionMessage != "") {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("activity"), this.actionMessage)
                        }
                        if (this.events.size > 0) {
                            ForEach(this.events, itemGeneratorFunc: { item: GitHubEventSnapshot, _: Int64 =>
                                this.buildActivityRow(item)
                            })
                        } else if (!this.loading) {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("activity"), this.t("activity_empty"))
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
        if (this.sharedAuthAccessToken == "" || this.selectedGitHubUserLogin == "") {
            this.actionMessage = this.t("sign_in_required")
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
        fetchGitHubUserActivity(
            this.sharedAuthAccessToken,
            this.selectedGitHubUserLogin,
            { items => spawn(UIThread) {
                if (reset) {
                    this.events = items
                } else {
                    let merged = ArrayList<GitHubEventSnapshot>()
                    for (item in this.events) { merged.add(item) }
                    for (item in items) { merged.add(item) }
                    this.events = merged
                }
                this.page = targetPage
                this.hasMore = items.size >= 20
                this.actionMessage = ""
                this.loading = false
                this.loadingMore = false
            } },
            { message => spawn(UIThread) {
                if (reset) {
                    this.events = ArrayList<GitHubEventSnapshot>()
                }
                this.actionMessage = message
                this.loading = false
                this.loadingMore = false
            } },
            page: targetPage
        )
    }

    func loadMore(): Unit { this.loadItems(reset: false) }

    @Builder
    func buildActivityRow(item: GitHubEventSnapshot) {
        Column(space: 8) {
            Text(if (item.repoName == "") { item.targetTitle } else { item.repoName }).fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor()).width(100.percent)
            Text(this.eventSummary(item)).fontSize(12).lineHeight(18).fontColor(this.secondaryTextColor()).width(100.percent)
        }
        .width(100.percent)
        .padding(18)
        .backgroundColor(this.surfaceColor())
        .borderRadius(24)
        .onClick({ _ => this.openUrl(item.targetUrl) })
    }

    func eventSummary(item: GitHubEventSnapshot): String {
        if (item.eventType == "IssuesEvent") {
            if (item.action == "opened") { return "${this.t("event_issue_opened")} · ${item.targetTitle}" }
            if (item.action == "closed") { return "${this.t("event_issue_closed")} · ${item.targetTitle}" }
            return "${this.t("event_issue_updated")} · ${item.targetTitle}"
        }
        if (item.eventType == "IssueCommentEvent") { return "${this.t("event_issue_commented")} · ${item.targetTitle}" }
        if (item.eventType == "PullRequestEvent") {
            if (item.action == "opened") { return "${this.t("event_pr_opened")} · ${item.targetTitle}" }
            if (item.action == "closed") { return "${this.t("event_pr_closed")} · ${item.targetTitle}" }
            return "${this.t("event_pr_updated")} · ${item.targetTitle}"
        }
        if (item.eventType == "PullRequestReviewEvent") { return "${this.t("event_pr_reviewed")} · ${item.targetTitle}" }
        if (item.eventType == "PullRequestReviewCommentEvent") { return "${this.t("event_pr_commented")} · ${item.targetTitle}" }
        if (item.eventType == "PushEvent") { return "${this.t("event_push")} · ${item.targetTitle}" }
        if (item.eventType == "WatchEvent") { return "${this.t("event_starred")} · ${item.repoName}" }
        if (item.eventType == "ForkEvent") { return "${this.t("event_forked")} · ${item.repoName}" }
        if (item.eventType == "CreateEvent") { return "${this.t("event_created")} · ${item.targetTitle}" }
        if (item.eventType == "DeleteEvent") { return "${this.t("event_deleted")} · ${item.targetTitle}" }
        if (item.eventType == "ReleaseEvent") { return "${this.t("event_released")} · ${item.targetTitle}" }
        if (item.targetTitle != "") { return item.targetTitle }
        item.eventType
    }

    func openUrl(url: String): Unit {
        if (url == "") { return }
        try { getAppAbilityContext().startAbility(Want(uri: url, action: "ohos.want.action.viewData")) } catch (_: BusinessException) {}
    }

    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
}

@Component
public class ExploreUserFollowersPage {
    @Consume var exploreStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var selectedGitHubFollowers: ArrayList<GitHubSimpleUserSnapshot>
    @Consume var selectedGitHubUserLogin: String
    @Consume var selectedGitHubUserProfile: GitHubUserProfileSnapshot
    @Consume var selectedGitHubUserRepositories: ArrayList<GitHubRepositoryCardSnapshot>
    @Consume var selectedGitHubUserGists: ArrayList<GitHubGistSnapshot>
    @Consume var selectedGitHubFollowing: ArrayList<GitHubSimpleUserSnapshot>

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light
    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"
    @Consume var sharedAuthAccessToken: String

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
                        detailHeaderCommon(this.exploreStack, this.t("back"), this.t("followers"), this.primaryTextColor(), this.surfaceColor())
                        if (this.actionMessage != "") {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("followers"), this.actionMessage)
                        }
                        if (this.selectedGitHubFollowers.size > 0) {
                            ForEach(this.selectedGitHubFollowers, itemGeneratorFunc: { item: GitHubSimpleUserSnapshot, _: Int64 =>
                                buildSimpleUserRow(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), item, { => this.openUser(item.login) })
                            })
                        } else if (!this.loading) {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("followers"), this.t("followers_empty"))
                        }
                    }
                    .width(100.percent)
                    .padding(left: 18, right: 18, top: 18, bottom: 120)
                }
                .width(100.percent).height(100.percent).scrollBar(BarState.Off).onReachEnd({ => this.loadMore() })
            }.width(100.percent).height(100.percent)
        }.hideTitleBar(true).backgroundColor(this.pageBackgroundColor())
    }

    func loadItems(reset!: Bool = true): Unit {
        if (this.sharedAuthAccessToken == "" || this.selectedGitHubUserLogin == "") {
            this.actionMessage = this.t("sign_in_required")
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
        fetchGitHubUserFollowers(
            this.sharedAuthAccessToken,
            this.selectedGitHubUserLogin,
            { items => spawn(UIThread) {
                if (reset) {
                    this.selectedGitHubFollowers = items
                } else {
                    let merged = ArrayList<GitHubSimpleUserSnapshot>()
                    for (item in this.selectedGitHubFollowers) { merged.add(item) }
                    for (item in items) { merged.add(item) }
                    this.selectedGitHubFollowers = merged
                }
                this.page = targetPage
                this.hasMore = items.size >= 50
                this.actionMessage = ""
                this.loading = false
                this.loadingMore = false
            } },
            { message => spawn(UIThread) {
                if (reset) {
                    this.selectedGitHubFollowers = ArrayList<GitHubSimpleUserSnapshot>()
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
        this.selectedGitHubUserGists = ArrayList<GitHubGistSnapshot>()
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

@Component
public class ExploreUserIssuesPage {
    @Consume var exploreStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var selectedGitHubUserIssues: ArrayList<GitHubIssueSnapshot>
    @Consume var selectedRepository: String
    @Consume var selectedIssue: String
    @Consume var selectedTask: String
    @Consume var liveRepositoryDetail: GitHubRepositoryDetailSnapshot
    @Consume var liveIssues: ArrayList<GitHubIssueSnapshot>
    @Consume var livePullRequests: ArrayList<GitHubPullRequestSnapshot>
    @Consume var sharedAuthAccessToken: String

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light
    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @Consume var selectedGitHubUserLogin: String
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
                        if (this.selectedGitHubUserIssues.size > 0) {
                            ForEach(this.selectedGitHubUserIssues, itemGeneratorFunc: { item: GitHubIssueSnapshot, _: Int64 =>
                                this.buildIssueRow(item)
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
        if (this.sharedAuthAccessToken == "" || this.selectedGitHubUserLogin == "") {
            this.actionMessage = this.t("sign_in_required")
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
        fetchGitHubUserIssues(
            this.sharedAuthAccessToken,
            this.selectedGitHubUserLogin,
            { items => spawn(UIThread) {
                if (reset) {
                    this.selectedGitHubUserIssues = items
                } else {
                    let merged = ArrayList<GitHubIssueSnapshot>()
                    for (item in this.selectedGitHubUserIssues) { merged.add(item) }
                    for (item in items) { merged.add(item) }
                    this.selectedGitHubUserIssues = merged
                }
                this.page = targetPage
                this.hasMore = items.size >= 20
                this.actionMessage = ""
                this.loading = false
                this.loadingMore = false
            } },
            { message => spawn(UIThread) {
                if (reset) {
                    this.selectedGitHubUserIssues = ArrayList<GitHubIssueSnapshot>()
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
        if (this.sharedAuthAccessToken != "") {
            refreshGitHubRepositoryBundle(
                this.sharedAuthAccessToken,
                repositoryName,
                { snapshot => this.liveRepositoryDetail = snapshot },
                { _ => },
                { items => this.liveIssues = items },
                { items => this.livePullRequests = items },
                { _ => }
            )
        }
        this.exploreStack.pushPath(NavPathInfo(name: "issueDetail", param: ""), options: NavigationOptions(animated: true))
    }

    @Builder
    func buildIssueRow(snapshot: GitHubIssueSnapshot) {
        Button() {
            Column(space: 8) {
                Text(snapshot.title).fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
                Text(snapshot.summary).fontSize(12).fontColor(this.secondaryTextColor())
                Text("${snapshot.status} / @${snapshot.authorLogin}").fontSize(12).fontColor(this.secondaryTextColor())
            }
            .width(100.percent)
            .alignItems(HorizontalAlign.Start)
        }
        .width(100.percent)
        .padding(18)
        .backgroundColor(this.surfaceColor())
        .borderRadius(24)
        .onClick({ _ => this.openIssue(snapshot) })
    }

    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
}

@Component
public class ExploreUserPullRequestsPage {
    @Consume var exploreStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var selectedGitHubUserPullRequests: ArrayList<GitHubPullRequestSnapshot>
    @Consume var selectedRepository: String
    @Consume var selectedPullRequest: String
    @Consume var liveRepositoryDetail: GitHubRepositoryDetailSnapshot
    @Consume var liveIssues: ArrayList<GitHubIssueSnapshot>
    @Consume var livePullRequests: ArrayList<GitHubPullRequestSnapshot>
    @Consume var sharedAuthAccessToken: String

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light
    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @Consume var selectedGitHubUserLogin: String
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
                        if (this.selectedGitHubUserPullRequests.size > 0) {
                            ForEach(this.selectedGitHubUserPullRequests, itemGeneratorFunc: { item: GitHubPullRequestSnapshot, _: Int64 =>
                                this.buildPullRequestRow(item)
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
        if (this.sharedAuthAccessToken == "" || this.selectedGitHubUserLogin == "") {
            this.actionMessage = this.t("sign_in_required")
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
        fetchGitHubUserPullRequests(
            this.sharedAuthAccessToken,
            this.selectedGitHubUserLogin,
            { items => spawn(UIThread) {
                if (reset) {
                    this.selectedGitHubUserPullRequests = items
                } else {
                    let merged = ArrayList<GitHubPullRequestSnapshot>()
                    for (item in this.selectedGitHubUserPullRequests) { merged.add(item) }
                    for (item in items) { merged.add(item) }
                    this.selectedGitHubUserPullRequests = merged
                }
                this.page = targetPage
                this.hasMore = items.size >= 20
                this.actionMessage = ""
                this.loading = false
                this.loadingMore = false
            } },
            { message => spawn(UIThread) {
                if (reset) {
                    this.selectedGitHubUserPullRequests = ArrayList<GitHubPullRequestSnapshot>()
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
        if (this.sharedAuthAccessToken != "") {
            refreshGitHubRepositoryBundle(
                this.sharedAuthAccessToken,
                repositoryName,
                { snapshot => this.liveRepositoryDetail = snapshot },
                { _ => },
                { items => this.liveIssues = items },
                { items => this.livePullRequests = items },
                { _ => }
            )
        }
        this.exploreStack.pushPath(NavPathInfo(name: "pullRequestDetail", param: ""), options: NavigationOptions(animated: true))
    }

    @Builder
    func buildPullRequestRow(snapshot: GitHubPullRequestSnapshot) {
        Button() {
            Column(space: 8) {
                Text(snapshot.title).fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
                Text(snapshot.summary).fontSize(12).fontColor(this.secondaryTextColor())
                Text("${snapshot.status} / @${snapshot.authorLogin}").fontSize(12).fontColor(this.secondaryTextColor())
            }
            .width(100.percent)
            .alignItems(HorizontalAlign.Start)
        }
        .width(100.percent)
        .padding(18)
        .backgroundColor(this.surfaceColor())
        .borderRadius(24)
        .onClick({ _ => this.openPullRequest(snapshot) })
    }

    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
}

@Component
public class ExploreUserFollowingPage {
    @Consume var exploreStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var selectedGitHubFollowing: ArrayList<GitHubSimpleUserSnapshot>
    @Consume var selectedGitHubUserLogin: String
    @Consume var selectedGitHubUserProfile: GitHubUserProfileSnapshot
    @Consume var selectedGitHubUserRepositories: ArrayList<GitHubRepositoryCardSnapshot>
    @Consume var selectedGitHubUserGists: ArrayList<GitHubGistSnapshot>
    @Consume var selectedGitHubFollowers: ArrayList<GitHubSimpleUserSnapshot>

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light
    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"
    @Consume var sharedAuthAccessToken: String

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
                        detailHeaderCommon(this.exploreStack, this.t("back"), this.t("following"), this.primaryTextColor(), this.surfaceColor())
                        if (this.actionMessage != "") {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("following"), this.actionMessage)
                        }
                        if (this.selectedGitHubFollowing.size > 0) {
                            ForEach(this.selectedGitHubFollowing, itemGeneratorFunc: { item: GitHubSimpleUserSnapshot, _: Int64 =>
                                buildSimpleUserRow(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), item, { => this.openUser(item.login) })
                            })
                        } else if (!this.loading) {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("following"), this.t("following_empty"))
                        }
                    }
                    .width(100.percent)
                    .padding(left: 18, right: 18, top: 18, bottom: 120)
                }
                .width(100.percent).height(100.percent).scrollBar(BarState.Off).onReachEnd({ => this.loadMore() })
            }.width(100.percent).height(100.percent)
        }.hideTitleBar(true).backgroundColor(this.pageBackgroundColor())
    }

    func loadItems(reset!: Bool = true): Unit {
        if (this.sharedAuthAccessToken == "" || this.selectedGitHubUserLogin == "") {
            this.actionMessage = this.t("sign_in_required")
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
        fetchGitHubUserFollowing(
            this.sharedAuthAccessToken,
            this.selectedGitHubUserLogin,
            { items => spawn(UIThread) {
                if (reset) {
                    this.selectedGitHubFollowing = items
                } else {
                    let merged = ArrayList<GitHubSimpleUserSnapshot>()
                    for (item in this.selectedGitHubFollowing) { merged.add(item) }
                    for (item in items) { merged.add(item) }
                    this.selectedGitHubFollowing = merged
                }
                this.page = targetPage
                this.hasMore = items.size >= 50
                this.actionMessage = ""
                this.loading = false
                this.loadingMore = false
            } },
            { message => spawn(UIThread) {
                if (reset) {
                    this.selectedGitHubFollowing = ArrayList<GitHubSimpleUserSnapshot>()
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
        this.selectedGitHubUserGists = ArrayList<GitHubGistSnapshot>()
        this.selectedGitHubFollowers = ArrayList<GitHubSimpleUserSnapshot>()
        this.exploreStack.pushPath(NavPathInfo(name: "userProfilePage", param: ""), options: NavigationOptions(animated: true))
    }
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
}

@Component
public class ExploreUserGistsPage {
    @Consume var exploreStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var selectedGitHubUserGists: ArrayList<GitHubGistSnapshot>
    @Consume var selectedGitHubGistFiles: ArrayList<GitHubGistFileSnapshot>
    @Consume var selectedGitHubGistId: String

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"
    @Consume var sharedAuthAccessToken: String
    @Consume var selectedGitHubUserLogin: String

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
                        detailHeaderCommon(this.exploreStack, this.t("back"), this.t("gists"), this.primaryTextColor(), this.surfaceColor())
                        if (this.actionMessage != "") {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("gists"), this.actionMessage)
                        }
                        if (this.selectedGitHubUserGists.size > 0) {
                            ForEach(this.selectedGitHubUserGists, itemGeneratorFunc: { item: GitHubGistSnapshot, _: Int64 =>
                                buildGistRow(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), item, this.t("public"), this.t("private"), this.t("files"), { => this.openGist(item) })
                            })
                        } else if (!this.loading) {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("gists"), this.t("gists_empty"))
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
        if (this.sharedAuthAccessToken == "" || this.selectedGitHubUserLogin == "") {
            this.actionMessage = this.t("sign_in_required")
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
        fetchGitHubUserGists(
            this.sharedAuthAccessToken,
            this.selectedGitHubUserLogin,
            { items => spawn(UIThread) {
                if (reset) {
                    this.selectedGitHubUserGists = items
                } else {
                    let merged = ArrayList<GitHubGistSnapshot>()
                    for (item in this.selectedGitHubUserGists) { merged.add(item) }
                    for (item in items) { merged.add(item) }
                    this.selectedGitHubUserGists = merged
                }
                this.page = targetPage
                this.hasMore = items.size >= 50
                this.actionMessage = ""
                this.loading = false
                this.loadingMore = false
            } },
            { message => spawn(UIThread) {
                if (reset) {
                    this.selectedGitHubUserGists = ArrayList<GitHubGistSnapshot>()
                }
                this.actionMessage = message
                this.loading = false
                this.loadingMore = false
            } },
            page: targetPage
        )
    }

    func loadMore(): Unit { this.loadItems(reset: false) }

    func openGist(snapshot: GitHubGistSnapshot): Unit {
        this.selectedGitHubGistId = snapshot.id
        this.selectedGitHubGistFiles = ArrayList<GitHubGistFileSnapshot>()
        this.exploreStack.pushPath(NavPathInfo(name: "gistDetailPage", param: ""), options: NavigationOptions(animated: true))
    }

    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
}

@Component
public class ExploreGistDetailPage {
    @Consume var exploreStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var selectedGitHubGistId: String
    @Consume var selectedGitHubGistFiles: ArrayList<GitHubGistFileSnapshot>

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @State var loading: Bool = false
    @State var actionMessage: String = ""

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
        this.loadFiles()
    }

    public func build() {
        NavDestination() {
            Stack(alignContent: Alignment.TopStart) {
                detailBackgroundCommon(this.pageBackgroundColor())
                Scroll {
                    Column(space: 12) {
                        detailHeaderCommon(this.exploreStack, this.t("back"), this.t("gists"), this.primaryTextColor(), this.surfaceColor())
                        if (this.actionMessage != "") {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("gists"), this.actionMessage)
                        }
                        if (this.selectedGitHubGistFiles.size > 0) {
                            ForEach(this.selectedGitHubGistFiles, itemGeneratorFunc: { item: GitHubGistFileSnapshot, _: Int64 =>
                                buildGistFileCard(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), item)
                            })
                        } else if (!this.loading) {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("gists"), this.t("gists_empty"))
                        }
                    }
                    .width(100.percent)
                    .padding(left: 18, right: 18, top: 18, bottom: 120)
                }
                .width(100.percent)
                .height(100.percent)
                .scrollBar(BarState.Off)
                .align(Alignment.Top)
            }
            .width(100.percent)
            .height(100.percent)
        }
        .hideTitleBar(true)
        .backgroundColor(this.pageBackgroundColor())
    }

    func loadFiles(): Unit {
        if (this.sharedAuthAccessToken == "" || this.selectedGitHubGistId == "") {
            this.actionMessage = this.t("sign_in_required")
            return
        }
        this.loading = true
        fetchGitHubGistFiles(
            this.sharedAuthAccessToken,
            this.selectedGitHubGistId,
            { items => spawn(UIThread) { this.selectedGitHubGistFiles = items; this.actionMessage = ""; this.loading = false } },
            { message => spawn(UIThread) { this.selectedGitHubGistFiles = ArrayList<GitHubGistFileSnapshot>(); this.actionMessage = message; this.loading = false } }
        )
    }

    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
}

@Builder
func buildSimpleUserRow(surfaceColor: Int64, primaryTextColor: Int64, secondaryTextColor: Int64, item: GitHubSimpleUserSnapshot, onTap: () -> Unit) {
    Button() {
        Column(space: 6) {
            Text(item.login).fontSize(16).fontWeight(FontWeight.Bold).fontColor(primaryTextColor)
            if (item.subtitle != "") {
                Text(item.subtitle).fontSize(12).fontColor(secondaryTextColor)
            }
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
func buildRepositoryCardRow(surfaceColor: Int64, primaryTextColor: Int64, secondaryTextColor: Int64, item: GitHubRepositoryCardSnapshot, publicLabel: String, privateLabel: String, onTap: () -> Unit) {
    Button() {
        Column(space: 8) {
            Text(item.name).fontSize(16).fontWeight(FontWeight.Bold).fontColor(primaryTextColor)
            Text(if (item.summary == "") { "No description" } else { item.summary }).fontSize(12).fontColor(secondaryTextColor)
            Row(space: 8) {
                Text(if (item.viewerStarred) { "★" } else { "☆" })
                    .fontSize(14)
                    .fontColor(if (item.viewerStarred) { 0xFFD54A } else { secondaryTextColor })
                Text("${item.starCount}").fontSize(12).fontColor(secondaryTextColor)
                Text(if (item.isPrivate) { privateLabel } else { publicLabel }).fontSize(12).fontColor(secondaryTextColor)
            }
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
func buildCommitRow(surfaceColor: Int64, primaryTextColor: Int64, secondaryTextColor: Int64, item: GitHubCommitSnapshot, onTap: () -> Unit) {
    Button() {
        Column(space: 8) {
            Text(item.message).fontSize(15).fontWeight(FontWeight.Bold).fontColor(primaryTextColor)
            Text(if (item.authorLogin == "") { item.sha } else { "@${item.authorLogin} · ${item.sha}" }).fontSize(12).fontColor(secondaryTextColor)
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
func buildGistRow(surfaceColor: Int64, primaryTextColor: Int64, secondaryTextColor: Int64, item: GitHubGistSnapshot, publicLabel: String, privateLabel: String, filesLabel: String, onTap: () -> Unit) {
    Button() {
        Column(space: 8) {
            Text(if (item.primaryFilename != "") { item.primaryFilename } else if (item.description != "") { item.description } else { item.id })
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(primaryTextColor)
            Text(if (item.description != "") { item.description } else { item.ownerLogin })
                .fontSize(12)
                .fontColor(secondaryTextColor)
            Row(space: 8) {
                Text(if (item.isPublic) { publicLabel } else { privateLabel }).fontSize(12).fontColor(secondaryTextColor)
                Text("·").fontSize(12).fontColor(secondaryTextColor)
                Text("${item.fileCount} ${filesLabel}").fontSize(12).fontColor(secondaryTextColor)
            }
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
func buildGistFileCard(surfaceColor: Int64, primaryTextColor: Int64, secondaryTextColor: Int64, item: GitHubGistFileSnapshot) {
    Column(space: 8) {
        Text(item.filename).fontSize(15).fontWeight(FontWeight.Bold).fontColor(primaryTextColor)
        if (item.language != "") {
            Text(item.language).fontSize(12).fontColor(secondaryTextColor)
        }
        if (item.content != "") {
            Text(item.content).fontSize(12).lineHeight(18).fontColor(primaryTextColor)
        } else if (item.rawUrl != "") {
            Text(item.rawUrl).fontSize(12).lineHeight(18).fontColor(secondaryTextColor)
        }
    }
    .width(100.percent)
    .padding(18)
    .backgroundColor(surfaceColor)
    .borderRadius(24)
    .alignItems(HorizontalAlign.Start)
}

@Builder
func buildStatRow(label: String, value: String, onTap: () -> Unit, surfaceColor: Int64, primaryTextColor: Int64, secondaryTextColor: Int64) {
    Button() {
        Row() {
            Text(label).fontSize(15).fontColor(primaryTextColor)
            Blank()
            Text(value).fontSize(14).fontColor(secondaryTextColor)
            Text("›").fontSize(18).fontColor(secondaryTextColor)
        }
        .width(100.percent)
    }
    .width(100.percent)
    .height(54)
    .padding(left: 18, right: 18)
    .backgroundColor(surfaceColor)
    .onClick({ _ => onTap() })
}

@Builder
func buildThinDivider(color: Int64) {
    Column() {}
        .width(100.percent)
        .height(1)
        .margin(left: 18, right: 18)
        .backgroundColor(color)
}
