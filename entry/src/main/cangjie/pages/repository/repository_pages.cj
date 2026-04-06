package ohos_app_cangjie_entry.pages.repository

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.*
import std.collection.ArrayList
import ohos_app_cangjie_entry.domain.{GitHubIssueSnapshot, GitHubPullRequestSnapshot, GitHubRepositoryDetailSnapshot}
import ohos_app_cangjie_entry.pages.common.{detailCardCommon, detailHeaderCommon}
import ohos_app_cangjie_entry.services.agent.taskIdForIssue
import ohos_app_cangjie_entry.ui.theme.{appResolveIsDarkTheme, appThemeColor}
import ohos_app_cangjie_entry.ui.i18n.{appLocalizedText, appResolveLanguage}

@Component
public class RepositoryDetailPage {
    @Consume var stack: NavPathStack
    @Consume var selectedRepository: String
    @Consume var selectedIssue: String
    @Consume var selectedPullRequest: String
    @Consume var selectedTask: String
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var liveRepositoryDetail: GitHubRepositoryDetailSnapshot
    @Consume var liveIssues: ArrayList<GitHubIssueSnapshot>
    @Consume var livePullRequests: ArrayList<GitHubPullRequestSnapshot>

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    public func build() {
        NavDestination() {
            Scroll {
                Column(space: 16) {
                    detailHeaderCommon(this.stack, this.t("back"), this.t("repository_detail"), this.primaryTextColor(), this.surfaceColor())
                    detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.currentRepository().name, this.currentRepository().summary)
                    detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("issues"), "${this.currentRepository().issueCount} ${this.t("issues")} / ${this.currentRepository().pullRequestCount} ${this.t("pull_requests")}")
                    detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("status"), "${this.currentRepository().visibilityLabel} / ${this.currentRepository().defaultBranch}")
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
        .hideTitleBar(true)
        .backgroundColor(this.pageBackgroundColor())
    }

    func currentRepository(): GitHubRepositoryDetailSnapshot { this.liveRepositoryDetail }
    func currentIssues(): ArrayList<GitHubIssueSnapshot> { this.liveIssues }
    func currentPullRequests(): ArrayList<GitHubPullRequestSnapshot> { this.livePullRequests }
    func openIssue(issueId: String): Unit {
        this.selectedIssue = issueId
        this.selectedTask = taskIdForIssue(issueId)
        this.stack.pushPath(NavPathInfo(name: "issueDetail", param: ""), options: NavigationOptions(animated: true))
    }
    func openPullRequest(pullRequestId: String): Unit {
        this.selectedPullRequest = pullRequestId
        this.stack.pushPath(NavPathInfo(name: "pullRequestDetail", param: ""), options: NavigationOptions(animated: true))
    }
    func openCreateTask(): Unit {
        this.selectedTask = taskIdForIssue(this.selectedIssue)
        this.stack.pushPath(NavPathInfo(name: "createTask", param: ""), options: NavigationOptions(animated: true))
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
    @Consume var stack: NavPathStack
    @Consume var selectedIssue: String
    @Consume var selectedTask: String
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var liveIssues: ArrayList<GitHubIssueSnapshot>

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @State var actionMessage: String = ""

    public func build() {
        NavDestination() {
            Scroll {
                Column(space: 16) {
                    detailHeaderCommon(this.stack, this.t("back"), this.t("issue_detail"), this.primaryTextColor(), this.surfaceColor())
                    detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.currentIssue().title, this.currentIssue().summary)
                    detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("status"), "${this.currentIssue().status} / @${this.currentIssue().authorLogin}")
                    if (this.actionMessage != "") {
                        detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("status"), this.actionMessage)
                    }
                    Button(this.t("close_issue"))
                        .width(100.percent)
                        .height(48)
                        .backgroundColor(this.surfaceColor())
                        .fontColor(this.primaryTextColor())
                        .onClick({ _ => this.actionMessage = "Close action still uses mock mutation." })
                    Button(this.t("comment_issue"))
                        .width(100.percent)
                        .height(48)
                        .backgroundColor(this.surfaceColor())
                        .fontColor(this.primaryTextColor())
                        .onClick({ _ => this.actionMessage = "Comment action still uses mock mutation." })
                    Button(this.t("ask_agent"))
                        .width(100.percent)
                        .height(48)
                        .backgroundColor(this.primaryTextColor())
                        .fontColor(this.surfaceColor())
                        .onClick({ _ =>
                            this.selectedTask = taskIdForIssue(this.currentIssue().id)
                            this.stack.pushPath(NavPathInfo(name: "createTask", param: ""), options: NavigationOptions(animated: true))
                        })
                }
                .width(100.percent)
                .padding(left: 18, right: 18, top: 18, bottom: 32)
            }
            .width(100.percent)
            .height(100.percent)
            .scrollBar(BarState.Off)
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
        GitHubIssueSnapshot("", "Issue not loaded", "Open a repository issue first.", "", "", "")
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
    @Consume var stack: NavPathStack
    @Consume var selectedPullRequest: String
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var livePullRequests: ArrayList<GitHubPullRequestSnapshot>

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @State var actionMessage: String = ""

    public func build() {
        NavDestination() {
            Scroll {
                Column(space: 16) {
                    detailHeaderCommon(this.stack, this.t("back"), this.t("pull_request_detail"), this.primaryTextColor(), this.surfaceColor())
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
                        .onClick({ _ => this.actionMessage = "Approve action still uses mock mutation." })
                    Button(this.t("request_changes"))
                        .width(100.percent)
                        .height(48)
                        .backgroundColor(this.surfaceColor())
                        .fontColor(this.primaryTextColor())
                        .onClick({ _ => this.actionMessage = "Request changes action still uses mock mutation." })
                }
                .width(100.percent)
                .padding(left: 18, right: 18, top: 18, bottom: 32)
            }
            .width(100.percent)
            .height(100.percent)
            .scrollBar(BarState.Off)
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
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
}
