package ohos_app_cangjie_entry.pages.repository

import kit.ArkUI.*
import ohos.base.UIThread
import kit.BasicServicesKit.SystemDateTime
import ohos.arkui.state_macro_manage.*
import std.collection.ArrayList
import std.convert.*
import ohos_app_cangjie_entry.domain.{GitHubCommentSnapshot, GitHubIssueSnapshot, GitHubPullRequestSnapshot, GitHubRepositoryCardSnapshot, GitHubRepositoryDetailSnapshot}
import ohos_app_cangjie_entry.infra.runtime.applyAppStatusBarStyle
import ohos_app_cangjie_entry.pages.common.{detailBackgroundCommon, detailCardCommon, detailHeaderCommon}
import ohos_app_cangjie_entry.services.agent.taskIdForIssue
import ohos_app_cangjie_entry.services.github.{closeGitHubIssue, deleteGitHubRepository, fetchGitHubIssueComments, forkGitHubRepository}
import ohos_app_cangjie_entry.services.github.fetchGitHubRepositories
import ohos_app_cangjie_entry.ui.theme.{appResolveIsDarkTheme, appThemeColor}
import ohos_app_cangjie_entry.ui.i18n.{appLocalizedText, appResolveLanguage}

@Component
public class RepositoryDetailPage {
    @Consume var homeStack: NavPathStack
    @Consume var selectedRepository: String
    @Consume var selectedIssue: String
    @Consume var selectedPullRequest: String
    @Consume var selectedTask: String
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var liveRepositories: ArrayList<GitHubRepositoryCardSnapshot>
    @Consume var liveRepositoryCount: String
    @Consume var liveRepositoryDetail: GitHubRepositoryDetailSnapshot
    @Consume var liveIssues: ArrayList<GitHubIssueSnapshot>
    @Consume var livePullRequests: ArrayList<GitHubPullRequestSnapshot>

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @State var repositoryActionMessage: String = ""

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
    }

    public func build() {
        NavDestination() {
            Stack() {
                detailBackgroundCommon(this.pageBackgroundColor())

                Scroll {
                    Column(space: 16) {
                        detailHeaderCommon(this.homeStack, this.t("back"), this.t("repository_detail"), this.primaryTextColor(), this.surfaceColor())
                        detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.currentRepository().name, this.currentRepository().summary)
                        detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("issues"), "${this.currentRepository().issueCount} ${this.t("issues")} / ${this.currentRepository().pullRequestCount} ${this.t("pull_requests")}")
                        detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("status"), "${this.currentRepository().visibilityLabel} / ${this.currentRepository().defaultBranch}")
                        if (this.repositoryActionMessage != "") {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("status"), this.repositoryActionMessage)
                        }
                        buildRepositoryActionGrid(this)
                        if (this.currentIssues().size > 0) {
                            ForEach(this.currentIssues(), itemGeneratorFunc: { item: GitHubIssueSnapshot, _: Int64 =>
                                buildIssueStrip(this, item)
                            })
                        } else {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("issues"), "No open issues.")
                        }
                        if (this.currentPullRequests().size > 0) {
                            ForEach(this.currentPullRequests(), itemGeneratorFunc: { item: GitHubPullRequestSnapshot, _: Int64 =>
                                buildPullRequestStrip(this, item)
                            })
                        } else {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("pull_requests"), "No open pull requests.")
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

    func currentRepository(): GitHubRepositoryDetailSnapshot { this.liveRepositoryDetail }
    func currentIssues(): ArrayList<GitHubIssueSnapshot> { this.liveIssues }
    func currentPullRequests(): ArrayList<GitHubPullRequestSnapshot> { this.livePullRequests }
    func openIssue(issueId: String): Unit {
        this.selectedIssue = issueId
        this.selectedTask = taskIdForIssue(issueId)
        this.homeStack.pushPath(NavPathInfo(name: "issueDetail", param: ""), options: NavigationOptions(animated: true))
    }
    func openPullRequest(pullRequestId: String): Unit {
        this.selectedPullRequest = pullRequestId
        this.homeStack.pushPath(NavPathInfo(name: "pullRequestDetail", param: ""), options: NavigationOptions(animated: true))
    }
    func openIssuesPage(): Unit {
        this.homeStack.pushPath(NavPathInfo(name: "issuesPage", param: ""), options: NavigationOptions(animated: true))
    }
    func openPullRequestsPage(): Unit {
        this.homeStack.pushPath(NavPathInfo(name: "pullRequestsPage", param: ""), options: NavigationOptions(animated: true))
    }
    func openCreateTask(): Unit {
        this.selectedTask = taskIdForIssue(this.selectedIssue)
        this.homeStack.pushPath(NavPathInfo(name: "createTask", param: ""), options: NavigationOptions(animated: true))
    }
    func runOnUi(task: () -> Unit): Unit { spawn(UIThread) { => task() } }
    func openIssueComposer(): Unit {
        this.homeStack.pushPath(NavPathInfo(name: "issueComposer", param: ""), options: NavigationOptions(animated: true))
    }
    func openPullRequestComposer(): Unit {
        this.homeStack.pushPath(NavPathInfo(name: "pullRequestComposer", param: ""), options: NavigationOptions(animated: true))
    }
    func forkRepository(): Unit {
        if (this.sharedAuthAccessToken == "") {
            this.repositoryActionMessage = "Connect GitHub first."
            return
        }
        forkGitHubRepository(
            this.sharedAuthAccessToken,
            this.selectedRepository,
            {
                =>
                fetchGitHubRepositories(
                    this.sharedAuthAccessToken,
                    { repositories =>
                        this.runOnUi({
                            =>
                            this.liveRepositories = repositories
                            this.liveRepositoryCount = "${repositories.size}"
                            this.repositoryActionMessage = "Fork requested on GitHub."
                        })
                    },
                    { message => this.runOnUi({ => this.repositoryActionMessage = message }) }
                )
            },
            { message => this.runOnUi({ => this.repositoryActionMessage = message }) }
        )
    }
    func deleteRepository(): Unit {
        if (this.sharedAuthAccessToken == "") {
            this.repositoryActionMessage = "Connect GitHub first."
            return
        }
        deleteGitHubRepository(
            this.sharedAuthAccessToken,
            this.selectedRepository,
            {
                =>
                this.runOnUi({
                    =>
                    let nextRepositories = ArrayList<GitHubRepositoryCardSnapshot>()
                    for (item in this.liveRepositories) {
                        if (item.name != this.selectedRepository) {
                            nextRepositories.add(item)
                        }
                    }
                    this.liveRepositories = nextRepositories
                    this.liveRepositoryCount = "${nextRepositories.size}"
                    this.repositoryActionMessage = "Repository deleted on GitHub."
                    this.homeStack.pop()
                })
            },
            { message => this.runOnUi({ => this.repositoryActionMessage = message }) }
        )
    }
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
    func accentStrongColor(): Int64 { appThemeColor("accentStrong", this.isDarkTheme()) }
}

@Builder
func buildRepositoryActionGrid(page: RepositoryDetailPage) {
    Column(space: 12) {
        Button(page.t("open_issue"))
            .width(100.percent)
            .height(48)
            .backgroundColor(page.surfaceColor())
            .fontColor(page.primaryTextColor())
            .onClick({ _ => page.openIssuesPage() })
        Button(page.t("review_pr"))
            .width(100.percent)
            .height(48)
            .backgroundColor(page.surfaceColor())
            .fontColor(page.primaryTextColor())
            .onClick({ _ => page.openPullRequestsPage() })
        Button(page.t("create_issue"))
            .width(100.percent)
            .height(48)
            .backgroundColor(page.surfaceColor())
            .fontColor(page.primaryTextColor())
            .onClick({ _ => page.openIssueComposer() })
        Button(page.t("create_pull_request"))
            .width(100.percent)
            .height(48)
            .backgroundColor(page.surfaceColor())
            .fontColor(page.primaryTextColor())
            .onClick({ _ => page.openPullRequestComposer() })
        Button(page.t("create_task"))
            .width(100.percent)
            .height(48)
            .backgroundColor(page.primaryTextColor())
            .fontColor(page.surfaceColor())
            .onClick({ _ => page.openCreateTask() })
        Button(page.t("fork_repository"))
            .width(100.percent)
            .height(48)
            .backgroundColor(page.surfaceColor())
            .fontColor(page.primaryTextColor())
            .onClick({ _ => page.forkRepository() })
        Button(page.t("delete_repository"))
            .width(100.percent)
            .height(48)
            .backgroundColor(page.surfaceColor())
            .fontColor(page.primaryTextColor())
            .onClick({ _ => page.deleteRepository() })
    }
}

@Builder
func buildIssueStrip(page: RepositoryDetailPage, item: GitHubIssueSnapshot) {
    Button() {
        Column(space: 6) {
            Text(item.title).fontSize(16).fontWeight(FontWeight.Bold).fontColor(page.primaryTextColor())
            Text(item.summary).fontSize(12).fontColor(page.secondaryTextColor())
            Text("${item.status} / @${item.authorLogin}").fontSize(12).fontColor(page.accentStrongColor())
        }
        .alignItems(HorizontalAlign.Start)
        .width(100.percent)
    }
    .width(100.percent)
    .padding(18)
    .backgroundColor(page.surfaceColor())
    .borderRadius(24)
    .onClick({ _ => page.openIssue(item.id) })
}

@Builder
func buildPullRequestStrip(page: RepositoryDetailPage, item: GitHubPullRequestSnapshot) {
    Button() {
        Column(space: 6) {
            Text(item.title).fontSize(16).fontWeight(FontWeight.Bold).fontColor(page.primaryTextColor())
            Text(item.summary).fontSize(12).fontColor(page.secondaryTextColor())
            Text("${item.status} / @${item.authorLogin}").fontSize(12).fontColor(page.accentStrongColor())
        }
        .alignItems(HorizontalAlign.Start)
        .width(100.percent)
    }
    .width(100.percent)
    .padding(18)
    .backgroundColor(page.surfaceColor())
    .borderRadius(24)
    .onClick({ _ => page.openPullRequest(item.id) })
}

@Component
public class IssueDetailPage {
    @Consume var homeStack: NavPathStack
    @Consume var selectedRepository: String
    @Consume var selectedIssue: String
    @Consume var selectedTask: String
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var liveIssues: ArrayList<GitHubIssueSnapshot>
    @Consume var pendingPullRequestReviewEvent: String

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @State var actionMessage: String = ""
    @State var issueComments: ArrayList<GitHubCommentSnapshot> = ArrayList<GitHubCommentSnapshot>()
    @State var issueStatusOverride: String = ""

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
        this.refreshIssueComments()
    }

    public func build() {
        NavDestination() {
            Stack() {
                detailBackgroundCommon(this.pageBackgroundColor())

                Scroll {
                    Column(space: 16) {
                        detailHeaderCommon(this.homeStack, this.t("back"), this.t("issue_detail"), this.primaryTextColor(), this.surfaceColor())
                        detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.currentIssue().title, this.currentIssue().summary)
                        detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("status"), "${this.currentIssueStatus()} / @${this.currentIssue().authorLogin}")
                        if (this.actionMessage != "") {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("status"), this.actionMessage)
                        }
                        Button(this.t("close_issue"))
                            .width(100.percent)
                            .height(48)
                            .backgroundColor(this.surfaceColor())
                            .fontColor(this.primaryTextColor())
                            .onClick({ _ => this.closeIssueOnGitHub() })
                        Button(this.t("comment_issue"))
                            .width(100.percent)
                            .height(48)
                            .backgroundColor(this.surfaceColor())
                            .fontColor(this.primaryTextColor())
                            .onClick({ _ => this.commentOnIssue() })
                        Button(this.t("create_pull_request"))
                            .width(100.percent)
                            .height(48)
                            .backgroundColor(this.surfaceColor())
                            .fontColor(this.primaryTextColor())
                            .onClick({ _ => this.homeStack.pushPath(NavPathInfo(name: "pullRequestComposer", param: ""), options: NavigationOptions(animated: true)) })
                        Button(this.t("ask_agent"))
                            .width(100.percent)
                            .height(48)
                            .backgroundColor(this.primaryTextColor())
                            .fontColor(this.surfaceColor())
                            .onClick({ _ =>
                                this.selectedTask = taskIdForIssue(this.currentIssue().id)
                                this.homeStack.pushPath(NavPathInfo(name: "createTask", param: ""), options: NavigationOptions(animated: true))
                            })
                        if (this.issueComments.size > 0) {
                            ForEach(this.issueComments, itemGeneratorFunc: { item: GitHubCommentSnapshot, _: Int64 =>
                                buildCommentStrip(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), item)
                            })
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

    func currentIssue(): GitHubIssueSnapshot {
        for (item in this.liveIssues) {
            if (item.id == this.selectedIssue) {
                return item
            }
        }
        GitHubIssueSnapshot("", "", "Issue not loaded", "Open a repository issue first.", "", "", "")
    }
    func currentIssueStatus(): String {
        if (this.issueStatusOverride != "") { this.issueStatusOverride } else { this.currentIssue().status }
    }
    func runOnUi(task: () -> Unit): Unit { spawn(UIThread) { => task() } }
    func refreshIssueComments(): Unit {
        if (this.sharedAuthAccessToken == "" || this.selectedRepository == "" || this.selectedIssue == "") {
            return
        }
        fetchGitHubIssueComments(
            this.sharedAuthAccessToken,
            this.selectedRepository,
            this.selectedIssue,
            { comments => this.runOnUi({ => this.issueComments = comments }) },
            { message => this.runOnUi({ => this.actionMessage = message }) }
        )
    }
    func commentOnIssue(): Unit {
        if (this.sharedAuthAccessToken == "") {
            this.actionMessage = "Connect GitHub first."
            return
        }
        this.homeStack.pushPath(NavPathInfo(name: "issueCommentComposer", param: ""), options: NavigationOptions(animated: true))
    }
    func closeIssueOnGitHub(): Unit {
        if (this.sharedAuthAccessToken == "") {
            this.actionMessage = "Connect GitHub first."
            return
        }
        if (this.currentIssue().nodeId == "") {
            this.actionMessage = "This issue is missing a GitHub node id."
            return
        }
        closeGitHubIssue(
            this.sharedAuthAccessToken,
            this.currentIssue().nodeId,
            {
                =>
                this.runOnUi({
                    =>
                    this.issueStatusOverride = "closed"
                    let nextItems = ArrayList<GitHubIssueSnapshot>()
                    for (item in this.liveIssues) {
                        if (item.id == this.currentIssue().id) {
                            nextItems.add(
                                GitHubIssueSnapshot(
                                    item.id,
                                    item.nodeId,
                                    item.title,
                                    item.summary,
                                    "closed",
                                    item.authorLogin,
                                    item.issueUrl
                                )
                            )
                        } else {
                            nextItems.add(item)
                        }
                    }
                    this.liveIssues = nextItems
                    this.actionMessage = "Closed the issue on GitHub."
                })
            },
            { message => this.runOnUi({ => this.actionMessage = message }) }
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
public class PullRequestDetailPage {
    @Consume var homeStack: NavPathStack
    @Consume var selectedRepository: String
    @Consume var selectedPullRequest: String
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var livePullRequests: ArrayList<GitHubPullRequestSnapshot>
    @Consume var pendingPullRequestReviewEvent: String

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @State var actionMessage: String = ""
    @State var reviewComments: ArrayList<GitHubCommentSnapshot> = ArrayList<GitHubCommentSnapshot>()

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
        this.refreshPullRequestComments()
    }

    public func build() {
        NavDestination() {
            Stack() {
                detailBackgroundCommon(this.pageBackgroundColor())

                Scroll {
                    Column(space: 16) {
                        detailHeaderCommon(this.homeStack, this.t("back"), this.t("pull_request_detail"), this.primaryTextColor(), this.surfaceColor())
                        detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.currentPullRequest().title, this.currentPullRequest().summary)
                        detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("status"), "${this.currentPullRequest().status} / @${this.currentPullRequest().authorLogin}")
                        if (this.actionMessage != "") {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("review_summary"), this.actionMessage)
                        }
                        Button(this.t("approve_pr"))
                            .width(100.percent)
                            .height(48)
                            .backgroundColor(this.primaryTextColor())
                            .fontColor(this.surfaceColor())
                            .onClick({ _ => this.openReviewComposer("APPROVE") })
                        Button(this.t("request_changes"))
                            .width(100.percent)
                            .height(48)
                            .backgroundColor(this.surfaceColor())
                            .fontColor(this.primaryTextColor())
                            .onClick({ _ => this.openReviewComposer("REQUEST_CHANGES") })
                        Button(this.t("comment_pr"))
                            .width(100.percent)
                            .height(48)
                            .backgroundColor(this.surfaceColor())
                            .fontColor(this.primaryTextColor())
                            .onClick({ _ => this.openReviewComposer("COMMENT") })
                        if (this.reviewComments.size > 0) {
                            ForEach(this.reviewComments, itemGeneratorFunc: { item: GitHubCommentSnapshot, _: Int64 =>
                                buildCommentStrip(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), item)
                            })
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

    func currentPullRequest(): GitHubPullRequestSnapshot {
        for (item in this.livePullRequests) {
            if (item.id == this.selectedPullRequest) {
                return item
            }
        }
        GitHubPullRequestSnapshot("", "Pull request not loaded", "Open a repository pull request first.", "", "", "")
    }
    func openReviewComposer(event: String): Unit {
        this.pendingPullRequestReviewEvent = event
        this.homeStack.pushPath(NavPathInfo(name: "pullRequestReviewComposer", param: ""), options: NavigationOptions(animated: true))
    }
    func runOnUi(task: () -> Unit): Unit { spawn(UIThread) { => task() } }
    func refreshPullRequestComments(): Unit {
        if (this.sharedAuthAccessToken == "" || this.selectedRepository == "" || this.selectedPullRequest == "") {
            return
        }
        fetchGitHubIssueComments(
            this.sharedAuthAccessToken,
            this.selectedRepository,
            this.selectedPullRequest,
            { comments => this.runOnUi({ => this.reviewComments = comments }) },
            { message => this.runOnUi({ => this.actionMessage = message }) }
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
func buildCommentStrip(surfaceColor: Int64, primaryTextColor: Int64, secondaryTextColor: Int64, item: GitHubCommentSnapshot) {
    Column(space: 6) {
        Text("@${item.authorLogin}").fontSize(12).fontWeight(FontWeight.Bold).fontColor(primaryTextColor)
        Text(if (item.body == "") { "Empty comment." } else { item.body }).fontSize(12).fontColor(secondaryTextColor)
    }
    .width(100.percent)
    .padding(16)
    .backgroundColor(surfaceColor)
    .borderRadius(20)
}
