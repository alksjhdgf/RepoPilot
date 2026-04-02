package ohos_app_cangjie_entry.pages.agent

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.*
import ohos_app_cangjie_entry.domain.{DraftPullRequestSnapshot, TaskDraftSnapshot, TaskSnapshot, ValidationSnapshot}
import ohos_app_cangjie_entry.pages.common.{detailCardCommon, detailHeaderCommon}
import ohos_app_cangjie_entry.services.agent.{draftPullRequest, taskDraftForIssue, taskSnapshot, validationSnapshot}
import ohos_app_cangjie_entry.ui.theme.{appResolveIsDarkTheme, appThemeColor}
import ohos_app_cangjie_entry.ui.i18n.{appLocalizedText, appResolveLanguage}

@Component
public class CreateTaskPage {
    @Consume var stack: NavPathStack
    @Consume var selectedIssue: String
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
                    detailHeaderCommon(this.stack, this.t("back"), this.t("create_task"), this.primaryTextColor(), this.surfaceColor())
                    detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("prompt_draft"), this.t(this.currentDraft().promptKey))
                    detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("execution_mode"), this.t(this.currentDraft().executionModeKey))
                    detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("validation_scope"), this.t(this.currentDraft().validationKey))
                    detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("output_target"), this.t(this.currentDraft().outputKey))
                    Button(this.t("create_task_action"))
                        .width(100.percent)
                        .height(48)
                        .backgroundColor(this.primaryTextColor())
                        .fontColor(this.surfaceColor())
                        .onClick({ _ => this.stack.pushPath(NavPathInfo(name: "taskDetail", param: ""), options: NavigationOptions(animated: true)) })
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

    func currentDraft(): TaskDraftSnapshot { taskDraftForIssue(this.selectedIssue) }
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
}

@Component
public class TaskDetailPage {
    @Consume var stack: NavPathStack
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
                    detailHeaderCommon(this.stack, this.t("back"), this.t("task_detail"), this.primaryTextColor(), this.surfaceColor())
                    detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t(this.currentTask().titleKey), this.t(this.currentTask().summaryKey))
                    detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("context"), this.t(this.currentTask().contextKey))
                    detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("validation_result"), this.t(this.currentValidation().summaryKey))
                    Button(this.t("open_diff_review"))
                        .width(100.percent)
                        .height(48)
                        .backgroundColor(this.primaryTextColor())
                        .fontColor(this.surfaceColor())
                        .onClick({ _ => this.stack.pushPath(NavPathInfo(name: "diffReview", param: ""), options: NavigationOptions(animated: true)) })
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

    func currentTask(): TaskSnapshot { taskSnapshot(this.selectedTask) }
    func currentValidation(): ValidationSnapshot { validationSnapshot(this.selectedTask) }
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
}

@Component
public class DiffReviewPage {
    @Consume var stack: NavPathStack
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
                    detailHeaderCommon(this.stack, this.t("back"), this.t("diff_review"), this.primaryTextColor(), this.surfaceColor())
                    detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("review_summary"), this.t(this.currentValidation().summaryKey))
                    detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("draft_pr_title"), this.t(this.currentDraftPr().titleKey))
                    detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("draft_pr_body"), this.t(this.currentDraftPr().bodyKey))
                    detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("status"), this.t(this.currentDraftPr().statusKey))
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

    func currentValidation(): ValidationSnapshot { validationSnapshot(this.selectedTask) }
    func currentDraftPr(): DraftPullRequestSnapshot { draftPullRequest(this.selectedTask) }
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
}
