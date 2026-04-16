package ohos_app_cangjie_entry.pages.repository

import kit.ArkUI.*
import kit.BasicServicesKit.SystemDateTime
import ohos.base.UIThread
import ohos.arkui.state_macro_manage.*
import std.collection.ArrayList
import ohos_app_cangjie_entry.domain.{GitHubCommentSnapshot, GitHubIssueSnapshot, GitHubPullRequestSnapshot, GitHubRepositoryDetailSnapshot}
import ohos_app_cangjie_entry.infra.runtime.applyAppStatusBarStyle
import ohos_app_cangjie_entry.pages.common.{detailBackgroundCommon, detailCardCommon, detailHeaderCommon}
import ohos_app_cangjie_entry.services.agent.taskIdForIssue
import ohos_app_cangjie_entry.services.github.{closeGitHubIssue, createGitHubIssueComment, deleteGitHubRepository, fetchGitHubIssueComments, forkGitHubRepository, submitGitHubPullRequestReview}
import ohos_app_cangjie_entry.ui.theme.{appResolveIsDarkTheme, appThemeColor}
import ohos_app_cangjie_entry.ui.i18n.{appLocalizedText, appResolveLanguage}

@Component
public class ExploreRepositoryDetailPage {
    @Consume var exploreStack: NavPathStack
    @Consume var selectedRepository: String
    @Consume var selectedIssue: String
    @Consume var selectedPullRequest: String
    @Consume var selectedTask: String
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
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
                        detailHeaderCommon(this.exploreStack, this.t("back"), this.t("repository_detail"), this.primaryTextColor(), this.surfaceColor())
                        detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.currentRepository().name, this.currentRepository().summary)
                        detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("issues"), "${this.currentRepository().issueCount} ${this.t("issues")} / ${this.currentRepository().pullRequestCount} ${this.t("pull_requests")}")
                        detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("status"), "${this.currentRepository().visibilityLabel} / ${this.currentRepository().defaultBranch}")
                        if (this.repositoryActionMessage != "") {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("status"), this.repositoryActionMessage)
                        }
                        buildExploreRepositoryActionGrid(this)
                        if (this.currentIssues().size > 0) {
                            ForEach(this.currentIssues(), itemGeneratorFunc: { item: GitHubIssueSnapshot, _: Int64 =>
                                buildExploreIssueStrip(this, item)
                            })
                        } else {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("issues"), "No open issues.")
                        }
                        if (this.currentPullRequests().size > 0) {
                            ForEach(this.currentPullRequests(), itemGeneratorFunc: { item: GitHubPullRequestSnapshot, _: Int64 =>
                                buildExplorePullRequestStrip(this, item)
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
        this.exploreStack.pushPath(NavPathInfo(name: "issueDetail", param: ""), options: NavigationOptions(animated: true))
    }
    func openPullRequest(pullRequestId: String): Unit {
        this.selectedPullRequest = pullRequestId
        this.exploreStack.pushPath(NavPathInfo(name: "pullRequestDetail", param: ""), options: NavigationOptions(animated: true))
    }
    func openCreateTask(): Unit {
        this.selectedTask = taskIdForIssue(this.selectedIssue)
        this.exploreStack.pushPath(NavPathInfo(name: "createTask", param: ""), options: NavigationOptions(animated: true))
    }
    func runOnUi(task: () -> Unit): Unit { spawn(UIThread) { => task() } }
    func forkRepository(): Unit {
        if (this.sharedAuthAccessToken == "") {
            this.repositoryActionMessage = "Connect GitHub first."
            return
        }
        forkGitHubRepository(
            this.sharedAuthAccessToken,
            this.selectedRepository,
            { => this.runOnUi({ => this.repositoryActionMessage = "Fork requested on GitHub." }) },
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
            { => this.runOnUi({ => this.repositoryActionMessage = "Repository deleted on GitHub." }) },
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
func buildExploreRepositoryActionGrid(page: ExploreRepositoryDetailPage) {
    Column(space: 12) {
        Button(page.t("open_issue"))
            .width(100.percent)
            .height(48)
            .backgroundColor(page.surfaceColor())
            .fontColor(page.primaryTextColor())
            .onClick({ _ =>
                if (page.currentIssues().size > 0) {
                    page.openIssue(page.currentIssues()[0].id)
                }
            })
        Button(page.t("review_pr"))
            .width(100.percent)
            .height(48)
            .backgroundColor(page.surfaceColor())
            .fontColor(page.primaryTextColor())
            .onClick({ _ =>
                if (page.currentPullRequests().size > 0) {
                    page.openPullRequest(page.currentPullRequests()[0].id)
                }
            })
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
func buildExploreIssueStrip(page: ExploreRepositoryDetailPage, item: GitHubIssueSnapshot) {
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
func buildExplorePullRequestStrip(page: ExploreRepositoryDetailPage, item: GitHubPullRequestSnapshot) {
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
public class ExploreIssueDetailPage {
    @Consume var exploreStack: NavPathStack
    @Consume var selectedRepository: String
    @Consume var selectedIssue: String
    @Consume var selectedTask: String
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var liveIssues: ArrayList<GitHubIssueSnapshot>

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
                        detailHeaderCommon(this.exploreStack, this.t("back"), this.t("issue_detail"), this.primaryTextColor(), this.surfaceColor())
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
                        Button(this.t("ask_agent"))
                            .width(100.percent)
                            .height(48)
                            .backgroundColor(this.primaryTextColor())
                            .fontColor(this.surfaceColor())
                            .onClick({ _ =>
                                this.selectedTask = taskIdForIssue(this.currentIssue().id)
                                this.exploreStack.pushPath(NavPathInfo(name: "createTask", param: ""), options: NavigationOptions(animated: true))
                            })
                        if (this.issueComments.size > 0) {
                            ForEach(this.issueComments, itemGeneratorFunc: { item: GitHubCommentSnapshot, _: Int64 =>
                                buildExploreCommentStrip(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), item)
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
        let commentBody = "RepoPilot mobile note @ ${SystemDateTime.getTime()}"
        createGitHubIssueComment(
            this.sharedAuthAccessToken,
            this.selectedRepository,
            this.selectedIssue,
            commentBody,
            {
                comment =>
                this.runOnUi({
                    =>
                    this.issueComments.add(comment)
                    this.actionMessage = "Posted a live GitHub issue comment."
                })
            },
            { message => this.runOnUi({ => this.actionMessage = message }) }
        )
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
public class ExplorePullRequestDetailPage {
    @Consume var exploreStack: NavPathStack
    @Consume var selectedRepository: String
    @Consume var selectedPullRequest: String
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var livePullRequests: ArrayList<GitHubPullRequestSnapshot>

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
                        detailHeaderCommon(this.exploreStack, this.t("back"), this.t("pull_request_detail"), this.primaryTextColor(), this.surfaceColor())
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
                            .onClick({ _ => this.submitReview("APPROVE", "Approved from RepoPilot mobile.") })
                        Button(this.t("request_changes"))
                            .width(100.percent)
                            .height(48)
                            .backgroundColor(this.surfaceColor())
                            .fontColor(this.primaryTextColor())
                            .onClick({ _ => this.submitReview("REQUEST_CHANGES", "Please address the mobile review notes from RepoPilot.") })
                        Button(this.t("comment_pr"))
                            .width(100.percent)
                            .height(48)
                            .backgroundColor(this.surfaceColor())
                            .fontColor(this.primaryTextColor())
                            .onClick({ _ => this.submitReview("COMMENT", "RepoPilot mobile review comment @ ${SystemDateTime.getTime()}") })
                        if (this.reviewComments.size > 0) {
                            ForEach(this.reviewComments, itemGeneratorFunc: { item: GitHubCommentSnapshot, _: Int64 =>
                                buildExploreCommentStrip(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), item)
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
    func submitReview(event: String, body: String): Unit {
        if (this.sharedAuthAccessToken == "") {
            this.actionMessage = "Connect GitHub first."
            return
        }
        submitGitHubPullRequestReview(
            this.sharedAuthAccessToken,
            this.selectedRepository,
            this.selectedPullRequest,
            event,
            body,
            {
                =>
                this.runOnUi({
                    =>
                    this.actionMessage = "Submitted live pull request review."
                    this.refreshPullRequestComments()
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

@Builder
func buildExploreCommentStrip(surfaceColor: Int64, primaryTextColor: Int64, secondaryTextColor: Int64, item: GitHubCommentSnapshot) {
    Column(space: 6) {
        Text("@${item.authorLogin}").fontSize(12).fontWeight(FontWeight.Bold).fontColor(primaryTextColor)
        Text(if (item.body == "") { "Empty comment." } else { item.body }).fontSize(12).fontColor(secondaryTextColor)
    }
    .width(100.percent)
    .padding(16)
    .backgroundColor(surfaceColor)
    .borderRadius(20)
}
