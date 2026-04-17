package ohos_app_cangjie_entry.pages.repository

import kit.ArkUI.*
import kit.BasicServicesKit.SystemDateTime
import ohos.arkui.state_macro_manage.*
import ohos.base.UIThread
import std.collection.ArrayList
import std.convert.*
import ohos_app_cangjie_entry.domain.{GitHubIssueSnapshot, GitHubOrganizationSnapshot, GitHubPullRequestSnapshot, GitHubRepositoryCardSnapshot, GitHubRepositoryDetailSnapshot}
import ohos_app_cangjie_entry.infra.runtime.applyAppStatusBarStyle
import ohos_app_cangjie_entry.pages.common.{detailBackgroundCommon, detailCardCommon, detailHeaderCommon}
import ohos_app_cangjie_entry.services.app.refreshGitHubRepositoryBundle
import ohos_app_cangjie_entry.services.agent.taskIdForIssue
import ohos_app_cangjie_entry.services.github.{createGitHubIssue, fetchGitHubOrganizations}
import ohos_app_cangjie_entry.ui.i18n.{appLocalizedText, appResolveLanguage}
import ohos_app_cangjie_entry.ui.theme.{appResolveIsDarkTheme, appThemeColor}

@Component
public class HomeRepositoriesPage {
    @Consume var homeStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var liveRepositories: ArrayList<GitHubRepositoryCardSnapshot>
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

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
    }

    public func build() {
        NavDestination() {
            Stack() {
                detailBackgroundCommon(this.pageBackgroundColor())
                Scroll {
                    Column(space: 12) {
                        detailHeaderCommon(this.homeStack, this.t("back"), this.t("repositories"), this.primaryTextColor(), this.surfaceColor())
                        if (this.liveRepositories.size > 0) {
                            ForEach(this.liveRepositories, itemGeneratorFunc: { item: GitHubRepositoryCardSnapshot, _: Int64 =>
                                this.buildRepositoryRow(item)
                            })
                        } else {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("repositories"), this.t("repositories_empty"))
                        }
                    }
                    .width(100.percent)
                    .padding(left: 18, right: 18, top: 18, bottom: 32)
                }
                .width(100.percent)
                .height(100.percent)
                .scrollBar(BarState.Off)
            }
            .width(100.percent)
            .height(100.percent)
        }
        .hideTitleBar(true)
        .backgroundColor(this.pageBackgroundColor())
    }

    func openRepository(repositoryId: String): Unit {
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

    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
    func accentStrongColor(): Int64 { appThemeColor("accentStrong", this.isDarkTheme()) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }

    @Builder
    func buildRepositoryRow(snapshot: GitHubRepositoryCardSnapshot) {
        Button() {
            Column(space: 8) {
                Text(snapshot.name).fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
                Text(snapshot.summary).fontSize(12).fontColor(this.secondaryTextColor())
                Row(space: 8) {
                    Text(if (snapshot.viewerStarred) { "★" } else { "☆" })
                        .fontSize(14)
                        .fontColor(if (snapshot.viewerStarred) { 0xFFD54A } else { this.secondaryTextColor() })
                    Text("${snapshot.starCount}").fontSize(12).fontColor(this.secondaryTextColor())
                    Text(if (snapshot.isPrivate) { "Private" } else { "Public" }).fontSize(12).fontColor(this.accentStrongColor())
                }
            }
            .width(100.percent)
            .alignItems(HorizontalAlign.Start)
        }
        .width(100.percent)
        .padding(18)
        .backgroundColor(this.surfaceColor())
        .borderRadius(24)
        .onClick({ _ => this.openRepository(snapshot.name) })
    }
}

@Component
public class HomeTopRepositoriesPage {
    @Consume var homeStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var liveRepositories: ArrayList<GitHubRepositoryCardSnapshot>
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

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
    }

    public func build() {
        NavDestination() {
            Stack() {
                detailBackgroundCommon(this.pageBackgroundColor())
                Scroll {
                    Column(space: 12) {
                        detailHeaderCommon(this.homeStack, this.t("back"), this.t("top_repositories"), this.primaryTextColor(), this.surfaceColor())
                        if (this.sortedRepositories().size > 0) {
                            ForEach(this.sortedRepositories(), itemGeneratorFunc: { item: GitHubRepositoryCardSnapshot, _: Int64 =>
                                this.buildRepositoryRow(item)
                            })
                        } else {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("top_repositories"), this.t("repositories_empty"))
                        }
                    }
                    .width(100.percent)
                    .padding(left: 18, right: 18, top: 18, bottom: 32)
                }
                .width(100.percent)
                .height(100.percent)
                .scrollBar(BarState.Off)
            }
            .width(100.percent)
            .height(100.percent)
        }
        .hideTitleBar(true)
        .backgroundColor(this.pageBackgroundColor())
    }

    func sortedRepositories(): ArrayList<GitHubRepositoryCardSnapshot> {
        let sorted = ArrayList<GitHubRepositoryCardSnapshot>()
        let used = ArrayList<String>()
        for (_ in this.liveRepositories) {
            var found = false
            var best = GitHubRepositoryCardSnapshot("", "", "", false, false, -1, false)
            var bestStars = Int64(-1)
            for (item in this.liveRepositories) {
                var alreadyUsed = false
                for (name in used) {
                    if (name == item.name) {
                        alreadyUsed = true
                        break
                    }
                }
                if (alreadyUsed) {
                    continue
                }
                if (!found || item.starCount > bestStars) {
                    found = true
                    best = item
                    bestStars = item.starCount
                }
            }
            if (!found) {
                break
            }
            sorted.add(best)
            used.add(best.name)
        }
        sorted
    }

    func openRepository(repositoryId: String): Unit {
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

    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
    func accentStrongColor(): Int64 { appThemeColor("accentStrong", this.isDarkTheme()) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }

    @Builder
    func buildRepositoryRow(snapshot: GitHubRepositoryCardSnapshot) {
        Button() {
            Column(space: 8) {
                Text(snapshot.name).fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
                Text(snapshot.summary).fontSize(12).fontColor(this.secondaryTextColor())
                Row(space: 8) {
                    Text(if (snapshot.viewerStarred) { "★" } else { "☆" })
                        .fontSize(14)
                        .fontColor(if (snapshot.viewerStarred) { 0xFFD54A } else { this.secondaryTextColor() })
                    Text("${snapshot.starCount}").fontSize(12).fontColor(this.secondaryTextColor())
                    Text(if (snapshot.isPrivate) { "Private" } else { "Public" }).fontSize(12).fontColor(this.accentStrongColor())
                }
            }
            .width(100.percent)
            .alignItems(HorizontalAlign.Start)
        }
        .width(100.percent)
        .padding(18)
        .backgroundColor(this.surfaceColor())
        .borderRadius(24)
        .onClick({ _ => this.openRepository(snapshot.name) })
    }
}

@Component
public class HomeStarredRepositoriesPage {
    @Consume var homeStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var liveRepositories: ArrayList<GitHubRepositoryCardSnapshot>
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

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
    }

    public func build() {
        NavDestination() {
            Stack() {
                detailBackgroundCommon(this.pageBackgroundColor())
                Scroll {
                    Column(space: 12) {
                        detailHeaderCommon(this.homeStack, this.t("back"), this.t("starred"), this.primaryTextColor(), this.surfaceColor())
                        if (this.starredRepositories().size > 0) {
                            ForEach(this.starredRepositories(), itemGeneratorFunc: { item: GitHubRepositoryCardSnapshot, _: Int64 =>
                                this.buildRepositoryRow(item)
                            })
                        } else {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("starred"), this.t("starred_empty"))
                        }
                    }
                    .width(100.percent)
                    .padding(left: 18, right: 18, top: 18, bottom: 32)
                }
                .width(100.percent)
                .height(100.percent)
                .scrollBar(BarState.Off)
            }
            .width(100.percent)
            .height(100.percent)
        }
        .hideTitleBar(true)
        .backgroundColor(this.pageBackgroundColor())
    }

    func starredRepositories(): ArrayList<GitHubRepositoryCardSnapshot> {
        let filtered = ArrayList<GitHubRepositoryCardSnapshot>()
        for (item in this.liveRepositories) {
            if (item.viewerStarred) {
                filtered.add(item)
            }
        }
        filtered
    }

    func openRepository(repositoryId: String): Unit {
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

    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
    func accentStrongColor(): Int64 { appThemeColor("accentStrong", this.isDarkTheme()) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }

    @Builder
    func buildRepositoryRow(snapshot: GitHubRepositoryCardSnapshot) {
        Button() {
            Column(space: 8) {
                Text(snapshot.name).fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
                Text(snapshot.summary).fontSize(12).fontColor(this.secondaryTextColor())
                Row(space: 8) {
                    Text(if (snapshot.viewerStarred) { "★" } else { "☆" })
                        .fontSize(14)
                        .fontColor(if (snapshot.viewerStarred) { 0xFFD54A } else { this.secondaryTextColor() })
                    Text("${snapshot.starCount}").fontSize(12).fontColor(this.secondaryTextColor())
                    Text(if (snapshot.isPrivate) { "Private" } else { "Public" }).fontSize(12).fontColor(this.accentStrongColor())
                }
            }
            .width(100.percent)
            .alignItems(HorizontalAlign.Start)
        }
        .width(100.percent)
        .padding(18)
        .backgroundColor(this.surfaceColor())
        .borderRadius(24)
        .onClick({ _ => this.openRepository(snapshot.name) })
    }
}

@Component
public class HomeIssuesPage {
    @Consume var homeStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var selectedRepository: String
    @Consume var liveIssues: ArrayList<GitHubIssueSnapshot>
    @Consume var selectedIssue: String
    @Consume var selectedTask: String
    @Consume var liveRepositoryDetail: GitHubRepositoryDetailSnapshot

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
    }

    public func build() {
        NavDestination() {
            Stack() {
                detailBackgroundCommon(this.pageBackgroundColor())
                Scroll {
                    Column(space: 12) {
                        detailHeaderCommon(this.homeStack, this.t("back"), this.t("issues"), this.primaryTextColor(), this.surfaceColor())
                        Button(this.t("create_issue"))
                            .width(100.percent)
                            .height(48)
                            .backgroundColor(this.surfaceColor())
                            .fontColor(this.primaryTextColor())
                            .onClick({ _ => this.openIssueComposer() })
                        if (this.liveIssues.size > 0) {
                            ForEach(this.liveIssues, itemGeneratorFunc: { item: GitHubIssueSnapshot, _: Int64 =>
                                this.buildIssueRow(item)
                            })
                        } else {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("issues"), this.t("issues_empty"))
                        }
                    }
                    .width(100.percent)
                    .padding(left: 18, right: 18, top: 18, bottom: 32)
                }
                .width(100.percent)
                .height(100.percent)
                .scrollBar(BarState.Off)
            }
            .width(100.percent)
            .height(100.percent)
        }
        .hideTitleBar(true)
        .backgroundColor(this.pageBackgroundColor())
    }

    func openIssueComposer(): Unit {
        this.homeStack.pushPath(NavPathInfo(name: "issueComposer", param: ""), options: NavigationOptions(animated: true))
    }
    func openIssue(issueId: String): Unit {
        this.selectedIssue = issueId
        this.homeStack.pushPath(NavPathInfo(name: "issueDetail", param: ""), options: NavigationOptions(animated: true))
    }

    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }

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
        .onClick({ _ => this.openIssue(snapshot.id) })
    }
}

@Component
public class HomePullRequestsPage {
    @Consume var homeStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var selectedIssue: String
    @Consume var livePullRequests: ArrayList<GitHubPullRequestSnapshot>
    @Consume var selectedPullRequest: String

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
    }

    public func build() {
        NavDestination() {
            Stack() {
                detailBackgroundCommon(this.pageBackgroundColor())
                Scroll {
                    Column(space: 12) {
                        detailHeaderCommon(this.homeStack, this.t("back"), this.t("pull_requests"), this.primaryTextColor(), this.surfaceColor())
                        Button(this.t("create_pull_request"))
                            .width(100.percent)
                            .height(48)
                            .backgroundColor(this.surfaceColor())
                            .fontColor(this.primaryTextColor())
                            .onClick({ _ => this.openPullRequestComposer() })
                        if (this.livePullRequests.size > 0) {
                            ForEach(this.livePullRequests, itemGeneratorFunc: { item: GitHubPullRequestSnapshot, _: Int64 =>
                                this.buildPullRequestRow(item)
                            })
                        } else {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("pull_requests"), this.t("pull_requests_empty"))
                        }
                    }
                    .width(100.percent)
                    .padding(left: 18, right: 18, top: 18, bottom: 32)
                }
                .width(100.percent)
                .height(100.percent)
                .scrollBar(BarState.Off)
            }
            .width(100.percent)
            .height(100.percent)
        }
        .hideTitleBar(true)
        .backgroundColor(this.pageBackgroundColor())
    }

    func openPullRequest(pullRequestId: String): Unit {
        this.selectedPullRequest = pullRequestId
        this.homeStack.pushPath(NavPathInfo(name: "pullRequestDetail", param: ""), options: NavigationOptions(animated: true))
    }
    func openPullRequestComposer(): Unit {
        this.homeStack.pushPath(NavPathInfo(name: "pullRequestComposer", param: ""), options: NavigationOptions(animated: true))
    }

    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }

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
        .onClick({ _ => this.openPullRequest(snapshot.id) })
    }
}

@Component
public class HomeOrganizationsPage {
    @Consume var homeStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String

    @State var organizations: ArrayList<GitHubOrganizationSnapshot> = ArrayList<GitHubOrganizationSnapshot>()
    @State var actionMessage: String = ""

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
        this.loadOrganizations()
    }

    public func build() {
        NavDestination() {
            Stack() {
                detailBackgroundCommon(this.pageBackgroundColor())
                Scroll {
                    Column(space: 12) {
                        detailHeaderCommon(this.homeStack, this.t("back"), this.t("organizations"), this.primaryTextColor(), this.surfaceColor())
                        if (this.actionMessage != "") {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("organizations"), this.actionMessage)
                        }
                        if (this.organizations.size > 0) {
                            ForEach(this.organizations, itemGeneratorFunc: { item: GitHubOrganizationSnapshot, _: Int64 =>
                                this.buildOrganizationRow(item)
                            })
                        } else if (this.sharedAuthAccessToken != "") {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("organizations"), this.t("organizations_empty"))
                        } else {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("organizations"), this.t("sign_in_required"))
                        }
                    }
                    .width(100.percent)
                    .padding(left: 18, right: 18, top: 18, bottom: 32)
                }
                .width(100.percent)
                .height(100.percent)
                .scrollBar(BarState.Off)
            }
            .width(100.percent)
            .height(100.percent)
        }
        .hideTitleBar(true)
        .backgroundColor(this.pageBackgroundColor())
    }

    func loadOrganizations(): Unit {
        if (this.sharedAuthAccessToken == "") {
            this.organizations = ArrayList<GitHubOrganizationSnapshot>()
            return
        }
        fetchGitHubOrganizations(
            this.sharedAuthAccessToken,
            { items =>
                spawn(UIThread) {
                    this.organizations = items
                    this.actionMessage = ""
                }
            },
            { reason =>
                spawn(UIThread) {
                    this.organizations = ArrayList<GitHubOrganizationSnapshot>()
                    this.actionMessage = reason
                }
            }
        )
    }

    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
    func accentStrongColor(): Int64 { appThemeColor("accentStrong", this.isDarkTheme()) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }

    @Builder
    func buildOrganizationRow(snapshot: GitHubOrganizationSnapshot) {
        Column(space: 8) {
            Text(snapshot.login).fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
            Text(snapshot.description).fontSize(12).fontColor(this.secondaryTextColor())
            Text(snapshot.profileUrl).fontSize(12).fontColor(this.accentStrongColor()).maxLines(1)
        }
        .width(100.percent)
        .padding(18)
        .backgroundColor(this.surfaceColor())
        .borderRadius(24)
    }
}

@Component
public class ExploreIssuesPage {
    @Consume var exploreStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var selectedRepository: String
    @Consume var liveIssues: ArrayList<GitHubIssueSnapshot>
    @Consume var selectedIssue: String
    @Consume var selectedTask: String
    @Consume var liveRepositoryDetail: GitHubRepositoryDetailSnapshot

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
    }

    public func build() {
        NavDestination() {
            Stack() {
                detailBackgroundCommon(this.pageBackgroundColor())
                Scroll {
                    Column(space: 12) {
                        detailHeaderCommon(this.exploreStack, this.t("back"), this.t("issues"), this.primaryTextColor(), this.surfaceColor())
                        Button(this.t("create_issue"))
                            .width(100.percent)
                            .height(48)
                            .backgroundColor(this.surfaceColor())
                            .fontColor(this.primaryTextColor())
                            .onClick({ _ => this.openIssueComposer() })
                        if (this.liveIssues.size > 0) {
                            ForEach(this.liveIssues, itemGeneratorFunc: { item: GitHubIssueSnapshot, _: Int64 =>
                                this.buildIssueRow(item)
                            })
                        } else {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("issues"), this.t("issues_empty"))
                        }
                    }
                    .width(100.percent)
                    .padding(left: 18, right: 18, top: 18, bottom: 32)
                }
                .width(100.percent)
                .height(100.percent)
                .scrollBar(BarState.Off)
            }
            .width(100.percent)
            .height(100.percent)
        }
        .hideTitleBar(true)
        .backgroundColor(this.pageBackgroundColor())
    }

    func openIssueComposer(): Unit {
        this.exploreStack.pushPath(NavPathInfo(name: "issueComposer", param: ""), options: NavigationOptions(animated: true))
    }
    func openIssue(issueId: String): Unit {
        this.selectedIssue = issueId
        this.exploreStack.pushPath(NavPathInfo(name: "issueDetail", param: ""), options: NavigationOptions(animated: true))
    }

    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }

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
        .onClick({ _ => this.openIssue(snapshot.id) })
    }
}

@Component
public class ExplorePullRequestsPage {
    @Consume var exploreStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var selectedIssue: String
    @Consume var livePullRequests: ArrayList<GitHubPullRequestSnapshot>
    @Consume var selectedPullRequest: String

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
    }

    public func build() {
        NavDestination() {
            Stack() {
                detailBackgroundCommon(this.pageBackgroundColor())
                Scroll {
                    Column(space: 12) {
                        detailHeaderCommon(this.exploreStack, this.t("back"), this.t("pull_requests"), this.primaryTextColor(), this.surfaceColor())
                        Button(this.t("create_pull_request"))
                            .width(100.percent)
                            .height(48)
                            .backgroundColor(this.surfaceColor())
                            .fontColor(this.primaryTextColor())
                            .onClick({ _ => this.openPullRequestComposer() })
                        if (this.livePullRequests.size > 0) {
                            ForEach(this.livePullRequests, itemGeneratorFunc: { item: GitHubPullRequestSnapshot, _: Int64 =>
                                this.buildPullRequestRow(item)
                            })
                        } else {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("pull_requests"), this.t("pull_requests_empty"))
                        }
                    }
                    .width(100.percent)
                    .padding(left: 18, right: 18, top: 18, bottom: 32)
                }
                .width(100.percent)
                .height(100.percent)
                .scrollBar(BarState.Off)
            }
            .width(100.percent)
            .height(100.percent)
        }
        .hideTitleBar(true)
        .backgroundColor(this.pageBackgroundColor())
    }

    func openPullRequest(pullRequestId: String): Unit {
        this.selectedPullRequest = pullRequestId
        this.exploreStack.pushPath(NavPathInfo(name: "pullRequestDetail", param: ""), options: NavigationOptions(animated: true))
    }
    func openPullRequestComposer(): Unit {
        this.exploreStack.pushPath(NavPathInfo(name: "pullRequestComposer", param: ""), options: NavigationOptions(animated: true))
    }

    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }

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
        .onClick({ _ => this.openPullRequest(snapshot.id) })
    }
}
