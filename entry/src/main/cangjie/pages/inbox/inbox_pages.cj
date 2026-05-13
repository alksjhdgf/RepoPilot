package ohos_app_cangjie_entry.pages.inbox

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.*
import kit.AbilityKit.Want
import ohos.business_exception.BusinessException
import ohos.base.UIThread
import ohos_app_cangjie_entry.infra.runtime.{applyAppStatusBarStyle, getAppAbilityContext}
import ohos_app_cangjie_entry.pages.common.{detailBackgroundCommon, detailCardCommon, detailHeaderCommon}
import ohos_app_cangjie_entry.domain.{GitHubIssueSnapshot, GitHubPullRequestSnapshot, GitHubRepositoryDetailSnapshot}
import ohos_app_cangjie_entry.services.agent.taskIdForIssue
import ohos_app_cangjie_entry.services.app.refreshGitHubRepositoryBundle
import ohos_app_cangjie_entry.services.github.resourceNumberFromApiUrl
import ohos_app_cangjie_entry.ui.i18n.{appLocalizedText, appResolveLanguage}
import ohos_app_cangjie_entry.ui.theme.{appResolveIsDarkTheme, appThemeColor}
import std.collection.ArrayList

@Component
public class InboxNotificationDetailPage {
    @Consume var inboxStack: NavPathStack
    @Consume var selectedNotificationTitle: String
    @Consume var selectedNotificationRepository: String
    @Consume var selectedNotificationReason: String
    @Consume var selectedNotificationType: String
    @Consume var selectedNotificationApiUrl: String
    @Consume var selectedNotificationRepositoryUrl: String
    @Consume var selectedNotificationUpdatedAt: String
    @Consume var sharedAuthAccessToken: String
    @Consume var selectedRepository: String
    @Consume var selectedIssue: String
    @Consume var selectedPullRequest: String
    @Consume var selectedTask: String
    @Consume var liveRepositoryDetail: GitHubRepositoryDetailSnapshot
    @Consume var liveRepositoryReadme: String
    @Consume var liveIssues: ArrayList<GitHubIssueSnapshot>
    @Consume var livePullRequests: ArrayList<GitHubPullRequestSnapshot>
    @Consume var themePreference: String
    @Consume var languagePreference: String

    @StorageProp["colorMode"] let systemColorMode: ColorMode = ColorMode.Light
    @StorageProp["languageCode"] let systemLanguageCode: String = "en"

    @State var actionMessage: String = ""

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
    }

    public func build() {
        NavDestination() {
            Stack(alignContent: Alignment.TopStart) {
                detailBackgroundCommon(this.pageBackgroundColor())
                Scroll {
                    Column(space: 12) {
                        detailHeaderCommon(this.inboxStack, this.t("back"), this.t("notifications"), this.primaryTextColor(), this.surfaceColor())
                        detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.selectedNotificationTitle, this.selectedNotificationRepository)
                        detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("status"), "${this.selectedNotificationType} · ${this.selectedNotificationReason}")
                        if (this.selectedNotificationUpdatedAt != "") {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("updated"), this.selectedNotificationUpdatedAt)
                        }
                        if (this.actionMessage != "") {
                            detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("status"), this.actionMessage)
                        }
                        Column(space: 10) {
                            Button(this.t("open_in_app"))
                                .width(100.percent)
                                .height(48)
                                .backgroundColor(this.surfaceColor())
                                .fontColor(this.primaryTextColor())
                                .onClick({ _ => this.openNotificationTargetInApp() })
                            Button(this.t("open_on_github"))
                                .width(100.percent)
                                .height(48)
                                .backgroundColor(this.surfaceColor())
                                .fontColor(this.primaryTextColor())
                                .onClick({ _ => this.openNotificationTarget() })
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

    func openNotificationTarget(): Unit {
        let target = if (this.selectedNotificationRepositoryUrl != "") { this.selectedNotificationRepositoryUrl } else { this.selectedNotificationApiUrl }
        if (target == "") {
            this.actionMessage = this.t("not_available")
            return
        }
        try {
            getAppAbilityContext().startAbility(Want(uri: target, action: "ohos.want.action.viewData"))
        } catch (_: BusinessException) {
            this.actionMessage = this.t("not_available")
        }
    }

    func runOnUi(task: () -> Unit): Unit {
        spawn(UIThread) { => task() }
    }

    func openNotificationTargetInApp(): Unit {
        let route = this.resolveNotificationRoute()
        if (route == "external") {
            this.openNotificationTarget()
            if (this.actionMessage == "") {
                this.actionMessage = this.t("notification_opened_on_github")
            }
            return
        }
        if (route == "unavailable" || this.selectedNotificationRepository == "") {
            this.actionMessage = this.t("not_available")
            return
        }
        this.selectedRepository = this.selectedNotificationRepository
        this.liveRepositoryDetail = GitHubRepositoryDetailSnapshot(this.selectedRepository, "Loading repository details...", "", "", "0", "0", "main")
        this.liveRepositoryReadme = ""
        this.liveIssues = ArrayList<GitHubIssueSnapshot>()
        this.livePullRequests = ArrayList<GitHubPullRequestSnapshot>()
        if (this.sharedAuthAccessToken != "") {
            refreshGitHubRepositoryBundle(
                this.sharedAuthAccessToken,
                this.selectedRepository,
                { snapshot => this.runOnUi({ => this.liveRepositoryDetail = snapshot }) },
                { markdown => this.runOnUi({ => this.liveRepositoryReadme = markdown }) },
                { items => this.runOnUi({ => this.liveIssues = items }) },
                { items => this.runOnUi({ => this.livePullRequests = items }) },
                { _ => }
            )
        }
        if (route == "issue") {
            this.selectedIssue = resourceNumberFromApiUrl(this.selectedNotificationApiUrl)
            this.selectedTask = taskIdForIssue(this.selectedIssue)
            this.inboxStack.pushPath(NavPathInfo(name: "issueDetail", param: ""), options: NavigationOptions(animated: true))
        } else if (route == "pullRequest") {
            this.selectedPullRequest = resourceNumberFromApiUrl(this.selectedNotificationApiUrl)
            this.inboxStack.pushPath(NavPathInfo(name: "pullRequestDetail", param: ""), options: NavigationOptions(animated: true))
        } else {
            this.inboxStack.pushPath(NavPathInfo(name: "repositoryDetail", param: ""), options: NavigationOptions(animated: true))
        }
    }

    func resolveNotificationRoute(): String {
        if (this.selectedNotificationType == "PullRequest" || this.selectedNotificationApiUrl.contains("/pulls/")) {
            return "pullRequest"
        }
        if (this.selectedNotificationType == "Issue" || this.selectedNotificationApiUrl.contains("/issues/")) {
            return "issue"
        }
        if (this.selectedNotificationType == "Repository" || this.selectedNotificationApiUrl == "") {
            return "repository"
        }
        "external"
    }

    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
}
