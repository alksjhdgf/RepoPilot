package ohos_app_cangjie_entry.pages.repository

import kit.ArkUI.*
import kit.AbilityKit.Want
import ohos.base.UIThread
import kit.BasicServicesKit.SystemDateTime
import ohos.arkui.state_macro_manage.*
import ohos.business_exception.BusinessException
import std.collection.ArrayList
import std.convert.*
import ohos_app_cangjie_entry.domain.{GitHubCommentSnapshot, GitHubCommitSnapshot, GitHubGistSnapshot, GitHubIssueSnapshot, GitHubPullRequestSnapshot, GitHubRepositoryCardSnapshot, GitHubRepositoryDetailSnapshot, GitHubSimpleUserSnapshot, GitHubUserProfileSnapshot}
import ohos_app_cangjie_entry.infra.runtime.{applyAppStatusBarStyle, getAppAbilityContext}
import ohos_app_cangjie_entry.pages.common.{detailBackgroundCommon, detailCardCommon, detailHeaderCommon}
import ohos_app_cangjie_entry.services.agent.taskIdForIssue
import ohos_app_cangjie_entry.services.github.{closeGitHubIssue, deleteGitHubRepository, fetchGitHubIssueComments, forkGitHubRepository}
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
    @Consume var liveRepositoryReadme: String
    @Consume var liveIssues: ArrayList<GitHubIssueSnapshot>
    @Consume var livePullRequests: ArrayList<GitHubPullRequestSnapshot>
    @Consume var selectedGitHubUserLogin: String
    @Consume var selectedGitHubUserProfile: GitHubUserProfileSnapshot
    @Consume var selectedGitHubUserRepositories: ArrayList<GitHubRepositoryCardSnapshot>
    @Consume var selectedGitHubUserGists: ArrayList<GitHubGistSnapshot>
    @Consume var selectedGitHubFollowers: ArrayList<GitHubSimpleUserSnapshot>
    @Consume var selectedGitHubFollowing: ArrayList<GitHubSimpleUserSnapshot>
    @Consume var liveRepositoryWatchers: ArrayList<GitHubSimpleUserSnapshot>
    @Consume var liveRepositoryStargazers: ArrayList<GitHubSimpleUserSnapshot>
    @Consume var liveRepositoryForks: ArrayList<GitHubRepositoryCardSnapshot>
    @Consume var liveRepositoryCommits: ArrayList<GitHubCommitSnapshot>

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
            Stack(alignContent: Alignment.TopStart) {
                detailBackgroundCommon(this.pageBackgroundColor())
                Column(space: 16) {
                    detailHeaderCommon(this.exploreStack, this.t("back"), this.t("repository_detail"), this.primaryTextColor(), this.surfaceColor())
                    Scroll {
                        Column(space: 16) {
                            buildExploreRepositoryOverviewCard(this)
                            if (this.repositoryActionMessage != "") {
                                detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("status"), this.repositoryActionMessage)
                            }
                            buildExploreRepositoryInfoListCard(this)
                            buildExploreRepositoryActionGrid(this)
                            if (this.liveRepositoryReadme != "") {
                                markdownPreviewBlock(
                                    markdownLines(this.liveRepositoryReadme),
                                    this.surfaceColor(),
                                    this.mutedSurfaceColor(),
                                    this.primaryTextColor(),
                                    this.secondaryTextColor(),
                                    this.accentStrongColor()
                                )
                            } else {
                                detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("readme"), this.t("readme_empty"))
                            }
                            Text(this.t("issues"))
                                .fontSize(18)
                                .fontWeight(FontWeight.Bold)
                                .fontColor(this.primaryTextColor())
                                .width(100.percent)
                            if (this.currentIssues().size > 0) {
                                ForEach(this.currentIssues(), itemGeneratorFunc: { item: GitHubIssueSnapshot, _: Int64 =>
                                    buildExploreIssueStrip(this, item)
                                })
                            } else {
                                detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("issues"), this.t("no_open_issues"))
                            }
                            Text(this.t("pull_requests"))
                                .fontSize(18)
                                .fontWeight(FontWeight.Bold)
                                .fontColor(this.primaryTextColor())
                                .width(100.percent)
                            if (this.currentPullRequests().size > 0) {
                                ForEach(this.currentPullRequests(), itemGeneratorFunc: { item: GitHubPullRequestSnapshot, _: Int64 =>
                                    buildExplorePullRequestStrip(this, item)
                                })
                            } else {
                                detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("pull_requests"), this.t("no_open_pull_requests"))
                            }
                        }
                        .width(100.percent)
                        .padding(bottom: 120)
                    }
                    .width(100.percent)
                    .layoutWeight(1)
                    .scrollBar(BarState.Off)
                    .align(Alignment.Top)
                }
                .width(100.percent)
                .height(100.percent)
                .padding(left: 18, right: 18, top: 18)
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
    func repositoryDisplayName(): String {
        let parts = this.currentRepository().name.split("/")
        if (parts.size > 0) {
            return parts[parts.size - 1]
        }
        this.currentRepository().name
    }
    func openIssue(issueId: String): Unit {
        this.selectedIssue = issueId
        this.selectedTask = taskIdForIssue(issueId)
        this.exploreStack.pushPath(NavPathInfo(name: "issueDetail", param: ""), options: NavigationOptions(animated: true))
    }
    func openPullRequest(pullRequestId: String): Unit {
        this.selectedPullRequest = pullRequestId
        this.exploreStack.pushPath(NavPathInfo(name: "pullRequestDetail", param: ""), options: NavigationOptions(animated: true))
    }
    func openIssuesPage(): Unit {
        this.exploreStack.pushPath(NavPathInfo(name: "issuesPage", param: ""), options: NavigationOptions(animated: true))
    }
    func openPullRequestsPage(): Unit {
        this.exploreStack.pushPath(NavPathInfo(name: "pullRequestsPage", param: ""), options: NavigationOptions(animated: true))
    }
    func openCreateTask(): Unit {
        this.selectedTask = taskIdForIssue(this.selectedIssue)
        this.exploreStack.pushPath(NavPathInfo(name: "createTask", param: ""), options: NavigationOptions(animated: true))
    }
    func runOnUi(task: () -> Unit): Unit { spawn(UIThread) { => task() } }
    func openIssueComposer(): Unit {
        this.exploreStack.pushPath(NavPathInfo(name: "issueComposer", param: ""), options: NavigationOptions(animated: true))
    }
    func openPullRequestComposer(): Unit {
        this.exploreStack.pushPath(NavPathInfo(name: "pullRequestComposer", param: ""), options: NavigationOptions(animated: true))
    }
    func openOwnerProfile(): Unit {
        if (this.currentRepository().ownerLogin == "") {
            this.repositoryActionMessage = this.t("not_available")
            return
        }
        this.selectedGitHubUserLogin = this.currentRepository().ownerLogin
        this.selectedGitHubUserProfile = GitHubUserProfileSnapshot("", "", "", "", "", "", "", "", "0", "0", "0", "0")
        this.selectedGitHubUserRepositories = ArrayList<GitHubRepositoryCardSnapshot>()
        this.selectedGitHubUserGists = ArrayList<GitHubGistSnapshot>()
        this.selectedGitHubFollowers = ArrayList<GitHubSimpleUserSnapshot>()
        this.selectedGitHubFollowing = ArrayList<GitHubSimpleUserSnapshot>()
        this.exploreStack.pushPath(NavPathInfo(name: "userProfilePage", param: ""), options: NavigationOptions(animated: true))
    }
    func openStargazersPage(): Unit {
        this.liveRepositoryStargazers = ArrayList<GitHubSimpleUserSnapshot>()
        this.exploreStack.pushPath(NavPathInfo(name: "stargazersPage", param: ""), options: NavigationOptions(animated: true))
    }
    func openWatchersPage(): Unit {
        this.liveRepositoryWatchers = ArrayList<GitHubSimpleUserSnapshot>()
        this.exploreStack.pushPath(NavPathInfo(name: "watchersPage", param: ""), options: NavigationOptions(animated: true))
    }
    func openForksPage(): Unit {
        this.liveRepositoryForks = ArrayList<GitHubRepositoryCardSnapshot>()
        this.exploreStack.pushPath(NavPathInfo(name: "forksPage", param: ""), options: NavigationOptions(animated: true))
    }
    func openCommitsPage(): Unit {
        this.liveRepositoryCommits = ArrayList<GitHubCommitSnapshot>()
        this.exploreStack.pushPath(NavPathInfo(name: "commitsPage", param: ""), options: NavigationOptions(animated: true))
    }
    func forkRepository(): Unit {
        if (this.sharedAuthAccessToken == "") {
            this.repositoryActionMessage = this.t("connect_github_first")
            return
        }
        forkGitHubRepository(
            this.sharedAuthAccessToken,
            this.selectedRepository,
            { => this.runOnUi({ => this.repositoryActionMessage = this.t("repository_fork_requested") }) },
            { message => this.runOnUi({ => this.repositoryActionMessage = message }) }
        )
    }
    func deleteRepository(): Unit {
        if (this.sharedAuthAccessToken == "") {
            this.repositoryActionMessage = this.t("connect_github_first")
            return
        }
        deleteGitHubRepository(
            this.sharedAuthAccessToken,
            this.selectedRepository,
            {
                =>
                this.runOnUi({
                    =>
                    this.repositoryActionMessage = this.t("repository_deleted")
                    this.exploreStack.pop(animated: true)
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
    func mutedSurfaceColor(): Int64 { appThemeColor("mutedSurface", this.isDarkTheme()) }
    func openRepositoryInBrowser(): Unit {
        if (this.currentRepository().repoUrl == "") {
            this.repositoryActionMessage = this.t("not_available")
            return
        }
        try {
            getAppAbilityContext().startAbility(Want(uri: this.currentRepository().repoUrl, action: "ohos.want.action.viewData"))
        } catch (_: BusinessException) {
            this.repositoryActionMessage = this.t("not_available")
        }
    }
}

@Builder
func buildExploreRepositoryOverviewCard(page: ExploreRepositoryDetailPage) {
    Column(space: 12) {
        Row(space: 10) {
            if (page.currentRepository().ownerAvatarUrl != "") {
                Image(page.currentRepository().ownerAvatarUrl)
                    .width(28)
                    .height(28)
                    .borderRadius(14)
            } else {
                Row() { Text("GH").fontSize(11).fontWeight(FontWeight.Bold).fontColor(page.primaryTextColor()) }
                    .width(28)
                    .height(28)
                    .borderRadius(14)
                    .backgroundColor(page.mutedSurfaceColor())
                    .justifyContent(FlexAlign.Center)
            }
            Text(page.currentRepository().ownerLogin)
                .fontSize(13)
                .fontColor(page.secondaryTextColor())
        }
        .width(100.percent)
        Text(page.repositoryDisplayName())
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(page.primaryTextColor())
            .width(100.percent)
        if (page.currentRepository().summary != "") {
            Text(page.currentRepository().summary)
                .fontSize(13)
                .lineHeight(20)
                .fontColor(page.secondaryTextColor())
                .width(100.percent)
        }
        Row(space: 20) {
            Row(space: 8) {
                Text("★").fontSize(14).fontColor(0xFFD54A)
                Text("${page.currentRepository().starCount}").fontSize(13).fontColor(page.secondaryTextColor())
            }
            Row(space: 8) {
                Text("⑂").fontSize(14).fontColor(page.secondaryTextColor())
                Text("${page.currentRepository().forkCount}").fontSize(13).fontColor(page.secondaryTextColor())
            }
        }
        .width(100.percent)
    }
    .width(100.percent)
    .padding(18)
    .backgroundColor(page.surfaceColor())
    .borderRadius(24)
}

@Builder
func buildExploreRepositoryInfoListCard(page: ExploreRepositoryDetailPage) {
    Column() {
        buildExploreRepositoryInfoActionRow(page, page.t("issues"), "${page.currentRepository().issueCount}", { => page.openIssuesPage() })
        buildExploreRepositoryDivider(page)
        buildExploreRepositoryInfoActionRow(page, page.t("watchers"), "${page.currentRepository().watcherCount}", { => page.openWatchersPage() })
        buildExploreRepositoryDivider(page)
        buildExploreRepositoryInfoActionRow(page, page.t("pull_requests"), "${page.currentRepository().pullRequestCount}", { => page.openPullRequestsPage() })
        buildExploreRepositoryDivider(page)
        buildExploreRepositoryInfoValueRow(page, page.t("language"), if (page.currentRepository().primaryLanguage == "") { page.t("not_available") } else { page.currentRepository().primaryLanguage })
        buildExploreRepositoryDivider(page)
        buildExploreRepositoryInfoValueRow(page, page.t("default_branch"), page.currentRepository().defaultBranch)
        buildExploreRepositoryDivider(page)
        buildExploreRepositoryInfoActionRow(page, page.t("commits"), page.t("view_more"), { => page.openCommitsPage() })
        buildExploreRepositoryDivider(page)
        buildExploreRepositoryInfoActionRow(page, page.t("browse_code"), page.t("open"), { => page.openRepositoryInBrowser() })
    }
    .width(100.percent)
    .padding(left: 18, right: 18)
    .backgroundColor(page.surfaceColor())
    .borderRadius(24)
}

@Builder
func buildExploreRepositoryInfoValueRow(page: ExploreRepositoryDetailPage, label: String, value: String) {
    Button() {
        Row() {
            Text(label).fontSize(16).fontColor(page.primaryTextColor())
            Blank()
            Text(value).fontSize(14).fontColor(page.secondaryTextColor())
        }
        .width(100.percent)
        .height(52)
    }
    .width(100.percent)
    .backgroundColor(page.surfaceColor())
    .fontColor(page.primaryTextColor())
}

@Builder
func buildExploreRepositoryInfoActionRow(page: ExploreRepositoryDetailPage, label: String, value: String, onClick: () -> Unit) {
    Button() {
        Row() {
            Text(label).fontSize(16).fontColor(page.primaryTextColor())
            Blank()
            Text(value).fontSize(14).fontColor(page.secondaryTextColor())
            Text("›").fontSize(18).fontColor(page.secondaryTextColor())
        }
        .width(100.percent)
        .height(52)
    }
    .width(100.percent)
    .backgroundColor(page.surfaceColor())
    .fontColor(page.primaryTextColor())
    .onClick({ _ => onClick() })
}

@Builder
func buildExploreRepositoryDivider(page: ExploreRepositoryDetailPage) {
    Divider()
        .strokeWidth(1)
        .color(page.mutedSurfaceColor())
}

@Builder
func buildExploreRepositoryActionGrid(page: ExploreRepositoryDetailPage) {
    Column(space: 12) {
        Row(space: 12) {
            buildExploreRepositoryActionButton(page, "${page.t("repository_owner")}: ${page.currentRepository().ownerLogin}", { => page.openOwnerProfile() })
            buildExploreRepositoryActionButton(page, "${page.t("stargazers")}: ${page.currentRepository().starCount}", { => page.openStargazersPage() })
        }
        Row(space: 12) {
            buildExploreRepositoryActionButton(page, "${page.t("watchers")}: ${page.currentRepository().watcherCount}", { => page.openWatchersPage() })
            buildExploreRepositoryActionButton(page, "${page.t("forks")}: ${page.currentRepository().forkCount}", { => page.openForksPage() })
        }
        Row(space: 12) {
            buildExploreRepositoryActionButton(page, page.t("commits"), { => page.openCommitsPage() })
            buildExploreRepositoryActionButton(page, page.t("browse_code"), { => page.openRepositoryInBrowser() })
        }
        Row(space: 12) {
            buildExploreRepositoryActionButton(page, page.t("open_issue"), { => page.openIssuesPage() })
            buildExploreRepositoryActionButton(page, page.t("review_pr"), { => page.openPullRequestsPage() })
        }
        Row(space: 12) {
            buildExploreRepositoryActionButton(page, page.t("create_issue"), { => page.openIssueComposer() })
            buildExploreRepositoryActionButton(page, page.t("create_pull_request"), { => page.openPullRequestComposer() })
        }
        Row(space: 12) {
            buildExploreRepositoryEmphasizedActionButton(page, page.t("create_task"), { => page.openCreateTask() })
            buildExploreRepositoryActionButton(page, page.t("fork_repository"), { => page.forkRepository() })
        }
        Row(space: 12) {
            buildExploreRepositoryActionButton(page, page.t("delete_repository"), { => page.deleteRepository() })
            Blank()
        }
    }
}

@Builder
func buildExploreRepositoryActionButton(page: ExploreRepositoryDetailPage, label: String, action: () -> Unit) {
    Button(label)
        .width(49.percent)
        .height(48)
        .backgroundColor(page.surfaceColor())
        .fontColor(page.primaryTextColor())
        .borderRadius(18)
        .onClick({ _ => action() })
}

@Builder
func buildExploreRepositoryEmphasizedActionButton(page: ExploreRepositoryDetailPage, label: String, action: () -> Unit) {
    Button(label)
        .width(49.percent)
        .height(48)
        .backgroundColor(page.primaryTextColor())
        .fontColor(page.surfaceColor())
        .borderRadius(18)
        .onClick({ _ => action() })
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
            Stack(alignContent: Alignment.TopStart) {
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
                        Button(this.t("create_pull_request"))
                            .width(100.percent)
                            .height(48)
                            .backgroundColor(this.surfaceColor())
                            .fontColor(this.primaryTextColor())
                            .onClick({ _ => this.exploreStack.pushPath(NavPathInfo(name: "pullRequestComposer", param: ""), options: NavigationOptions(animated: true)) })
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
            this.actionMessage = this.t("connect_github_first")
            return
        }
        this.exploreStack.pushPath(NavPathInfo(name: "issueCommentComposer", param: ""), options: NavigationOptions(animated: true))
    }
    func closeIssueOnGitHub(): Unit {
        if (this.sharedAuthAccessToken == "") {
            this.actionMessage = this.t("connect_github_first")
            return
        }
        if (this.currentIssue().nodeId == "") {
            this.actionMessage = this.t("issue_node_id_missing")
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
                    this.actionMessage = this.t("issue_closed")
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
            Stack(alignContent: Alignment.TopStart) {
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
                                buildExploreCommentStrip(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), item)
                            })
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

    func currentPullRequest(): GitHubPullRequestSnapshot {
        for (item in this.livePullRequests) {
            if (item.id == this.selectedPullRequest) {
                return item
            }
        }
        GitHubPullRequestSnapshot("", "Pull request not loaded", "Open a repository pull request first.", "", "", "")
    }
    func openReviewComposer(event: String): Unit {
        this.exploreStack.pushPath(NavPathInfo(name: "pullRequestReviewComposer", param: event), options: NavigationOptions(animated: true))
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
