package ohos_app_cangjie_entry.pages.agent

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.*
import std.collection.ArrayList
import ohos_app_cangjie_entry.domain.{DraftPullRequestSnapshot, GitHubIssueSnapshot, GitHubPullRequestSnapshot, GitHubRepositoryDetailSnapshot, TaskDraftSnapshot, TaskSnapshot, ValidationSnapshot}
import ohos_app_cangjie_entry.infra.runtime.applyAppStatusBarStyle
import ohos_app_cangjie_entry.pages.common.{detailBackgroundCommon, detailCardCommon, detailHeaderCommon}
import ohos_app_cangjie_entry.services.agent.{draftPullRequest, taskDraftForIssue, taskSnapshot, validationSnapshot}
import ohos_app_cangjie_entry.ui.theme.{appResolveIsDarkTheme, appThemeColor}
import ohos_app_cangjie_entry.ui.i18n.{appLocalizedText, appResolveLanguage}

@Component
public class CreateTaskPage {
    @Consume var homeStack: NavPathStack
    @Consume var selectedRepository: String
    @Consume var selectedIssue: String
    @Consume var selectedTask: String
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var liveRepositoryDetail: GitHubRepositoryDetailSnapshot
    @Consume var liveIssues: ArrayList<GitHubIssueSnapshot>

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
    }

    public func build() {
        NavDestination() {
            Stack(alignContent: Alignment.TopStart) {
                detailBackgroundCommon(this.pageBackgroundColor())

                Scroll {
                    Column(space: 16) {
                        detailHeaderCommon(this.homeStack, this.t("back"), this.t("create_task"), this.primaryTextColor(), this.surfaceColor())
                        detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("prompt_draft"), this.currentPromptDraft())
                        detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("execution_mode"), this.currentExecutionMode())
                        detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("validation_scope"), this.currentValidationScope())
                        detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("output_target"), this.currentOutputTarget())
                        Button(this.t("create_task_action"))
                            .width(100.percent)
                            .height(48)
                            .backgroundColor(this.primaryTextColor())
                            .fontColor(this.surfaceColor())
                            .onClick({ _ => this.homeStack.pushPath(NavPathInfo(name: "taskDetail", param: ""), options: NavigationOptions(animated: true)) })
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

    func currentDraft(): TaskDraftSnapshot { taskDraftForIssue(this.selectedIssue) }
    func currentIssue(): GitHubIssueSnapshot {
        for (item in this.liveIssues) {
            if (item.id == this.selectedIssue) {
                return item
            }
        }
        GitHubIssueSnapshot("", "", "Issue not loaded", "Open a repository issue first.", "", "", "")
    }
    /**
     * 基于当前真实仓库和 issue 生成任务草稿说明，避免 Agent 页面完全脱离实时上下文。
     * Generates a task prompt from the selected live repository and issue so the agent flow stays contextual.
     */
    func currentPromptDraft(): String {
        let issue = this.currentIssue()
        if (issue.id == "") {
            return this.t(this.currentDraft().promptKey)
        }
        "Review ${this.liveRepositoryDetail.name} issue #${issue.id}: ${issue.title}. Produce a fix plan, note user-visible risks, and outline a draft pull request."
    }
    func currentExecutionMode(): String {
        let issue = this.currentIssue()
        if (issue.id == "") {
            return this.t(this.currentDraft().executionModeKey)
        }
        "Agent execution with live GitHub context for @${issue.authorLogin}."
    }
    func currentValidationScope(): String {
        if (this.currentIssue().id == "") {
            return this.t(this.currentDraft().validationKey)
        }
        "Validate issue scope, repository impact, and pull request follow-up for ${this.liveRepositoryDetail.defaultBranch}."
    }
    func currentOutputTarget(): String {
        if (this.currentIssue().id == "") {
            return this.t(this.currentDraft().outputKey)
        }
        "Task brief, review checklist, and draft PR copy for ${this.liveRepositoryDetail.name}."
    }
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
}

@Component
public class TaskDetailPage {
    @Consume var homeStack: NavPathStack
    @Consume var selectedIssue: String
    @Consume var selectedTask: String
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var liveRepositoryDetail: GitHubRepositoryDetailSnapshot
    @Consume var liveIssues: ArrayList<GitHubIssueSnapshot>

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
    }

    public func build() {
        NavDestination() {
            Stack(alignContent: Alignment.TopStart) {
                detailBackgroundCommon(this.pageBackgroundColor())

                Scroll {
                    Column(space: 16) {
                        detailHeaderCommon(this.homeStack, this.t("back"), this.t("task_detail"), this.primaryTextColor(), this.surfaceColor())
                        detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.currentTaskTitle(), this.currentTaskSummary())
                        detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("context"), this.currentTaskContext())
                        detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("validation_result"), this.currentValidationSummary())
                        Button(this.t("open_diff_review"))
                            .width(100.percent)
                            .height(48)
                            .backgroundColor(this.primaryTextColor())
                            .fontColor(this.surfaceColor())
                            .onClick({ _ => this.homeStack.pushPath(NavPathInfo(name: "diffReview", param: ""), options: NavigationOptions(animated: true)) })
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

    func currentTask(): TaskSnapshot { taskSnapshot(this.selectedTask) }
    func currentValidation(): ValidationSnapshot { validationSnapshot(this.selectedTask) }
    func currentIssue(): GitHubIssueSnapshot {
        for (item in this.liveIssues) {
            if (item.id == this.selectedIssue) {
                return item
            }
        }
        GitHubIssueSnapshot("", "", "Issue not loaded", "Open a repository issue first.", "", "", "")
    }
    func currentTaskTitle(): String {
        if (this.currentIssue().id == "") {
            return this.t(this.currentTask().titleKey)
        }
        "Task for issue #${this.currentIssue().id} in ${this.liveRepositoryDetail.name}"
    }
    func currentTaskSummary(): String {
        if (this.currentIssue().id == "") {
            return this.t(this.currentTask().summaryKey)
        }
        "Investigate '${this.currentIssue().title}' and prepare the change path for a GitHub review."
    }
    func currentTaskContext(): String {
        if (this.currentIssue().id == "") {
            return this.t(this.currentTask().contextKey)
        }
        "Current repository: ${this.liveRepositoryDetail.name}. Issue author: @${this.currentIssue().authorLogin}. Default branch: ${this.liveRepositoryDetail.defaultBranch}."
    }
    func currentValidationSummary(): String {
        if (this.currentIssue().id == "") {
            return this.t(this.currentValidation().summaryKey)
        }
        "Check reproduction notes, scope of impact, and whether follow-up comments or PR review are still required."
    }
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
}

@Component
public class DiffReviewPage {
    @Consume var homeStack: NavPathStack
    @Consume var selectedIssue: String
    @Consume var selectedRepository: String
    @Consume var selectedPullRequest: String
    @Consume var selectedTask: String
    @Consume var themePreference: String
    @Consume var languagePreference: String
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
            Stack(alignContent: Alignment.TopStart) {
                detailBackgroundCommon(this.pageBackgroundColor())

                Scroll {
                    Column(space: 16) {
                        detailHeaderCommon(this.homeStack, this.t("back"), this.t("diff_review"), this.primaryTextColor(), this.surfaceColor())
                        detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("review_summary"), this.currentReviewSummary())
                        detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("draft_pr_title"), this.currentDraftPrTitle())
                        detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("draft_pr_body"), this.currentDraftPrBody())
                        detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("status"), this.currentDraftPrStatus())
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

    func currentValidation(): ValidationSnapshot { validationSnapshot(this.selectedTask) }
    func currentDraftPr(): DraftPullRequestSnapshot { draftPullRequest(this.selectedTask) }
    func currentIssue(): GitHubIssueSnapshot {
        for (item in this.liveIssues) {
            if (item.id == this.selectedIssue) {
                return item
            }
        }
        GitHubIssueSnapshot("", "", "Issue not loaded", "Open a repository issue first.", "", "", "")
    }
    func currentPullRequest(): GitHubPullRequestSnapshot {
        for (item in this.livePullRequests) {
            if (item.id == this.selectedPullRequest) {
                return item
            }
        }
        GitHubPullRequestSnapshot("", "Pull request not loaded", "Open a repository pull request first.", "", "", "")
    }
    func currentReviewSummary(): String {
        if (this.currentIssue().id == "") {
            return this.t(this.currentValidation().summaryKey)
        }
        "Review ${this.selectedRepository} issue #${this.currentIssue().id}, confirm mutation results, and make sure discussion history is reflected in the next PR."
    }
    func currentDraftPrTitle(): String {
        if (this.currentIssue().id == "") {
            return this.t(this.currentDraftPr().titleKey)
        }
        "Draft PR: address #${this.currentIssue().id} ${this.currentIssue().title}"
    }
    func currentDraftPrBody(): String {
        if (this.currentIssue().id == "") {
            return this.t(this.currentDraftPr().bodyKey)
        }
        let pullContext = if (this.currentPullRequest().id == "") {
            "No existing live PR is selected."
        } else {
            "Current live PR context: #${this.currentPullRequest().id} ${this.currentPullRequest().title}."
        }
        "Summarize the fix for ${this.selectedRepository}, reference the issue context, note validation coverage, and include reviewer guidance. ${pullContext}"
    }
    func currentDraftPrStatus(): String {
        if (this.currentPullRequest().id == "") {
            return this.t(this.currentDraftPr().statusKey)
        }
        "Live PR selected: ${this.currentPullRequest().status}"
    }
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
}
