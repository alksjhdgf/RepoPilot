package ohos_app_cangjie_entry.pages.repository

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.*
import ohos_app_cangjie_entry.domain.{IssueSnapshot, PullRequestSnapshot, RepositorySnapshot}
import ohos_app_cangjie_entry.pages.common.{detailCardCommon, detailHeaderCommon}
import ohos_app_cangjie_entry.services.platform.{issueSnapshot, pullRequestSnapshot, repositorySnapshot}
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

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    public func build() {
        NavDestination() {
            Scroll {
                Column(space: 16) {
                    detailHeaderCommon(this.stack, this.t("back"), this.t("repository_detail"), this.primaryTextColor(), this.surfaceColor())
                    detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t(this.currentRepository().titleKey), this.t(this.currentRepository().summaryKey))
                    detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("issues"), "${this.currentRepository().issueCount} ${this.t("issues")} / ${this.currentRepository().reviewCount} ${this.t("pull_requests")}")
                    buildRepositoryActionGrid(this)
                    buildIssueStrip(this, this.currentIssuePreview())
                    buildPullRequestStrip(this, this.currentPullRequestPreview())
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

    func currentRepository(): RepositorySnapshot { repositorySnapshot(this.selectedRepository) }
    func currentIssuePreview(): IssueSnapshot { issueSnapshot(this.currentRepository().primaryIssueId) }
    func currentPullRequestPreview(): PullRequestSnapshot { pullRequestSnapshot(this.currentRepository().primaryPullRequestId) }
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
            .onClick({ _ => page.openIssue(page.currentRepository().primaryIssueId) })
        Button(page.t("review_pr"))
            .width(100.percent)
            .height(48)
            .backgroundColor(page.surfaceColor())
            .fontColor(page.primaryTextColor())
            .onClick({ _ => page.openPullRequest(page.currentRepository().primaryPullRequestId) })
        Button(page.t("create_task"))
            .width(100.percent)
            .height(48)
            .backgroundColor(page.primaryTextColor())
            .fontColor(page.surfaceColor())
            .onClick({ _ => page.openCreateTask() })
    }
}

@Builder
func buildIssueStrip(page: RepositoryDetailPage, item: IssueSnapshot) {
    Button() {
        Column(space: 6) {
            Text(page.t(item.titleKey)).fontSize(16).fontWeight(FontWeight.Bold).fontColor(page.primaryTextColor())
            Text(page.t(item.summaryKey)).fontSize(12).fontColor(page.secondaryTextColor())
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
func buildPullRequestStrip(page: RepositoryDetailPage, item: PullRequestSnapshot) {
    Button() {
        Column(space: 6) {
            Text(page.t(item.titleKey)).fontSize(16).fontWeight(FontWeight.Bold).fontColor(page.primaryTextColor())
            Text(page.t(item.summaryKey)).fontSize(12).fontColor(page.secondaryTextColor())
            Text(page.t(item.statusKey)).fontSize(12).fontColor(page.accentStrongColor())
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
                    detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t(this.currentIssue().titleKey), this.t(this.currentIssue().summaryKey))
                    detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("context"), this.t(this.currentIssue().contextKey))
                    if (this.actionMessage != "") {
                        detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("status"), this.actionMessage)
                    }
                    Button(this.t("close_issue"))
                        .width(100.percent)
                        .height(48)
                        .backgroundColor(this.surfaceColor())
                        .fontColor(this.primaryTextColor())
                        .onClick({ _ => this.actionMessage = this.t("close_issue_mock") })
                    Button(this.t("comment_issue"))
                        .width(100.percent)
                        .height(48)
                        .backgroundColor(this.surfaceColor())
                        .fontColor(this.primaryTextColor())
                        .onClick({ _ => this.actionMessage = this.t("comment_issue_mock") })
                    Button(this.t("ask_agent"))
                        .width(100.percent)
                        .height(48)
                        .backgroundColor(this.primaryTextColor())
                        .fontColor(this.surfaceColor())
                        .onClick({ _ =>
                            this.selectedTask = this.currentIssue().suggestedTaskId
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

    func currentIssue(): IssueSnapshot { issueSnapshot(this.selectedIssue) }
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
                    detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t(this.currentPullRequest().titleKey), this.t(this.currentPullRequest().summaryKey))
                    detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("status"), this.t(this.currentPullRequest().statusKey))
                    if (this.actionMessage != "") {
                        detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("review_summary"), this.actionMessage)
                    }
                    Button(this.t("approve_pr"))
                        .width(100.percent)
                        .height(48)
                        .backgroundColor(this.primaryTextColor())
                        .fontColor(this.surfaceColor())
                        .onClick({ _ => this.actionMessage = this.t("approve_pr_mock") })
                    Button(this.t("request_changes"))
                        .width(100.percent)
                        .height(48)
                        .backgroundColor(this.surfaceColor())
                        .fontColor(this.primaryTextColor())
                        .onClick({ _ => this.actionMessage = this.t("request_changes_mock") })
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

    func currentPullRequest(): PullRequestSnapshot { pullRequestSnapshot(this.selectedPullRequest) }
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
}
