package ohos_app_cangjie_entry.pages.repository

import kit.ArkUI.*
import ohos.base.UIThread
import ohos.arkui.state_macro_manage.*
import std.collection.ArrayList
import std.convert.*
import ohos_app_cangjie_entry.domain.{GitHubIssueSnapshot, GitHubPullRequestSnapshot, GitHubRepositoryDetailSnapshot}
import ohos_app_cangjie_entry.infra.runtime.applyAppStatusBarStyle
import ohos_app_cangjie_entry.pages.common.{detailBackgroundCommon, detailHeaderCommon}
import ohos_app_cangjie_entry.services.agent.taskIdForIssue
import ohos_app_cangjie_entry.services.github.{createGitHubIssue, createGitHubIssueComment, createGitHubPullRequest, fetchGitHubRepositoryBranches, submitGitHubPullRequestReview}
import ohos_app_cangjie_entry.ui.i18n.{appLocalizedText, appResolveLanguage}
import ohos_app_cangjie_entry.ui.theme.{appResolveIsDarkTheme, appThemeColor}

@Builder
func markdownActionButton(label: String, onTap: () -> Unit, surfaceColor: Int64, primaryTextColor: Int64) {
    Button(label)
        .height(34)
        .padding(left: 12, right: 12)
        .backgroundColor(surfaceColor)
        .fontColor(primaryTextColor)
        .fontSize(12)
        .borderRadius(16)
        .onClick({ _ => onTap() })
}

@Builder
func markdownPreviewBlock(
    lines: ArrayList<String>,
    cardSurfaceColor: Int64,
    surfaceColor: Int64,
    primaryTextColor: Int64,
    secondaryTextColor: Int64,
    accentStrongColor: Int64
) {
    Column(space: 8) {
        ForEach(lines, itemGeneratorFunc: { line: String, _: Int64 =>
            if (line.startsWith("```")) {
                Text(line.replace("```", ""))
                    .fontSize(12)
                    .fontColor(primaryTextColor)
                    .fontFamily("monospace")
                    .width(100.percent)
                    .padding(left: 12, right: 12, top: 8, bottom: 8)
                    .backgroundColor(surfaceColor)
                    .borderRadius(12)
            } else if (line.startsWith("    ")) {
                Text(line)
                    .width(100.percent)
                    .fontSize(12)
                    .fontColor(primaryTextColor)
                    .fontFamily("monospace")
                    .padding(left: 12, right: 12, top: 8, bottom: 8)
                    .backgroundColor(surfaceColor)
                    .borderRadius(12)
            } else if (line.startsWith("# ")) {
                Text(line.replace("# ", ""))
                    .fontSize(20)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(primaryTextColor)
                    .width(100.percent)
            } else if (line.startsWith("## ")) {
                Text(line.replace("## ", ""))
                    .fontSize(17)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(primaryTextColor)
                    .width(100.percent)
            } else if (line.startsWith("- [x] ") || line.startsWith("- [ ] ")) {
                Row(space: 8) {
                    Text(if (line.startsWith("- [x] ")) { "☑" } else { "☐" })
                        .fontSize(14)
                        .fontColor(accentStrongColor)
                    Text(if (line.startsWith("- [x] ")) { line.replace("- [x] ", "") } else { line.replace("- [ ] ", "") })
                        .fontSize(14)
                        .fontColor(primaryTextColor)
                        .layoutWeight(1)
                }
                .width(100.percent)
            } else if (line.startsWith("- ") || line.startsWith("* ")) {
                Row(space: 8) {
                    Text("•").fontSize(14).fontColor(accentStrongColor)
                    Text(if (line.startsWith("- ")) { line.replace("- ", "") } else { line.replace("* ", "") }).fontSize(14).fontColor(primaryTextColor).layoutWeight(1)
                }
                .width(100.percent)
            } else if (line.startsWith("> ")) {
                Row(space: 10) {
                    Blank().width(4).height(100.percent).backgroundColor(accentStrongColor).borderRadius(2)
                    Text(line.replace("> ", ""))
                        .fontSize(14)
                        .fontColor(secondaryTextColor)
                        .layoutWeight(1)
                }
                .width(100.percent)
                .padding(top: 4, bottom: 4)
            } else if (line == "") {
                Blank().height(6)
            } else {
                Text(line)
                    .fontSize(14)
                    .fontColor(primaryTextColor)
                    .width(100.percent)
            }
        })
    }
    .width(100.percent)
    .alignItems(HorizontalAlign.Start)
    .padding(18)
    .backgroundColor(cardSurfaceColor)
    .borderRadius(24)
}

@Builder
func composerTitleInput(
    value: String,
    placeholder: String,
    surfaceColor: Int64,
    primaryTextColor: Int64,
    secondaryTextColor: Int64,
    onChange: (String) -> Unit
) {
    TextInput(placeholder: placeholder, text: value)
        .width(100.percent)
        .height(52)
        .backgroundColor(surfaceColor)
        .fontColor(primaryTextColor)
        .placeholderColor(secondaryTextColor)
        .fontSize(16)
        .borderRadius(18)
        .padding(left: 16, right: 16)
        .onChange(onChange)
}

@Builder
func composerBodyEditor(
    value: String,
    placeholder: String,
    surfaceColor: Int64,
    primaryTextColor: Int64,
    secondaryTextColor: Int64,
    onChange: (String) -> Unit
) {
    TextArea(placeholder: placeholder, text: value)
        .width(100.percent)
        .constraintSize(minHeight: 180, maxHeight: 360)
        .backgroundColor(surfaceColor)
        .fontColor(primaryTextColor)
        .placeholderColor(secondaryTextColor)
        .fontSize(15)
        .borderRadius(20)
        .padding(left: 16, right: 16, top: 16, bottom: 16)
        .onChange(onChange)
}

func markdownLines(markdown: String): ArrayList<String> {
    let lines = ArrayList<String>()
    for (line in markdown.split("\n")) {
        lines.add(line)
    }
    if (lines.size == 0) {
        lines.add("")
    }
    lines
}

func compactInputValue(value: String): String {
    value.replace(" ", "").replace("\n", "").replace("\t", "").replace("\r", "")
}

@Component
public class HomeIssueComposerPage {
    @Consume var homeStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var selectedRepository: String
    @Consume var selectedIssue: String
    @Consume var selectedTask: String
    @Consume var liveIssues: ArrayList<GitHubIssueSnapshot>
    @Consume var liveRepositoryDetail: GitHubRepositoryDetailSnapshot

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @State var titleDraft: String = ""
    @State var bodyDraft: String = ""
    @State var previewMode: Bool = false
    @State var actionMessage: String = ""

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
    }

    public func build() {
        NavDestination() {
            Stack() {
                detailBackgroundCommon(this.pageBackgroundColor())
                Scroll {
                    Column(space: 14) {
                        detailHeaderCommon(this.homeStack, this.t("back"), this.t("issue_editor"), this.primaryTextColor(), this.surfaceColor())
                        composerTitleInput(this.titleDraft, this.t("composer_title_placeholder"), this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), { value => this.titleDraft = value })
                        this.buildModeSwitcher()
                        this.buildMarkdownToolbar()
                        if (this.previewMode) {
                            markdownPreviewBlock(
                                markdownLines(this.bodyDraft),
                                this.surfaceColor(),
                                this.mutedSurfaceColor(),
                                this.primaryTextColor(),
                                this.secondaryTextColor(),
                                this.accentStrongColor()
                            )
                        } else {
                            composerBodyEditor(this.bodyDraft, this.t("composer_body_placeholder"), this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), { value => this.bodyDraft = value })
                        }
                        if (this.actionMessage != "") {
                            Text(this.actionMessage)
                                .width(100.percent)
                                .fontSize(13)
                                .fontColor(this.secondaryTextColor())
                        }
                        Button(this.t("publish_issue"))
                            .width(100.percent)
                            .height(50)
                            .backgroundColor(this.primaryTextColor())
                            .fontColor(this.surfaceColor())
                            .borderRadius(18)
                            .onClick({ _ => this.publishIssue() })
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

    @Builder
    func buildModeSwitcher() {
        Row(space: 12) {
            Button(this.t("composer_write"))
                .layoutWeight(1)
                .height(40)
                .backgroundColor(if (!this.previewMode) { this.primaryTextColor() } else { this.surfaceColor() })
                .fontColor(if (!this.previewMode) { this.surfaceColor() } else { this.primaryTextColor() })
                .borderRadius(16)
                .onClick({ _ => this.previewMode = false })
            Button(this.t("composer_preview"))
                .layoutWeight(1)
                .height(40)
                .backgroundColor(if (this.previewMode) { this.primaryTextColor() } else { this.surfaceColor() })
                .fontColor(if (this.previewMode) { this.surfaceColor() } else { this.primaryTextColor() })
                .borderRadius(16)
                .onClick({ _ => this.previewMode = true })
        }
        .width(100.percent)
    }

    @Builder
    func buildMarkdownToolbar() {
        Scroll() {
            Row(space: 10) {
                markdownActionButton(this.t("composer_h1"), { => this.appendMarkdown("# ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_h2"), { => this.appendMarkdown("## ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_bullets"), { => this.appendMarkdown("- ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_checklist"), { => this.appendMarkdown("- [ ] ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_quote"), { => this.appendMarkdown("> ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_code"), { => this.appendMarkdown("```text\n\n```") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_link"), { => this.appendMarkdown("[title](https://)") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_bold"), { => this.appendMarkdown("**bold**") }, this.surfaceColor(), this.primaryTextColor())
            }
        }
        .width(100.percent)
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
    }

    func appendMarkdown(snippet: String): Unit {
        if (this.bodyDraft == "") {
            this.bodyDraft = snippet
        } else {
            this.bodyDraft = "${this.bodyDraft}\n${snippet}"
        }
    }

    func runOnUi(task: () -> Unit): Unit { spawn(UIThread) { => task() } }
    func publishIssue(): Unit {
        if (this.sharedAuthAccessToken == "" || this.selectedRepository == "") {
            this.actionMessage = this.t("sign_in_required")
            return
        }
        if (compactInputValue(this.titleDraft) == "") {
            this.actionMessage = this.t("composer_title_required")
            return
        }
        createGitHubIssue(
            this.sharedAuthAccessToken,
            this.selectedRepository,
            this.titleDraft,
            this.bodyDraft,
            { issue =>
                this.runOnUi({
                    =>
                    let nextItems = ArrayList<GitHubIssueSnapshot>()
                    nextItems.add(issue)
                    for (item in this.liveIssues) {
                        nextItems.add(item)
                    }
                    this.liveIssues = nextItems
                    this.selectedIssue = issue.id
                    this.selectedTask = taskIdForIssue(issue.id)
                    let nextDetail = this.liveRepositoryDetail
                    let issueCount = Int64.parse(nextDetail.issueCount)
                    this.liveRepositoryDetail = GitHubRepositoryDetailSnapshot(
                        nextDetail.name,
                        nextDetail.summary,
                        nextDetail.repoUrl,
                        nextDetail.visibilityLabel,
                        "${issueCount + 1}",
                        nextDetail.pullRequestCount,
                        nextDetail.defaultBranch
                    )
                    this.homeStack.pop(animated: true)
                })
            },
            { message => this.runOnUi({ => this.actionMessage = message }) }
        )
    }

    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func mutedSurfaceColor(): Int64 { appThemeColor("mutedSurface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
    func accentStrongColor(): Int64 { appThemeColor("accentStrong", this.isDarkTheme()) }
}

@Component
public class HomePullRequestComposerPage {
    @Consume var homeStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var selectedRepository: String
    @Consume var selectedIssue: String
    @Consume var selectedPullRequest: String
    @Consume var livePullRequests: ArrayList<GitHubPullRequestSnapshot>
    @Consume var liveRepositoryDetail: GitHubRepositoryDetailSnapshot
    @Consume var liveIssues: ArrayList<GitHubIssueSnapshot>

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @State var titleDraft: String = ""
    @State var bodyDraft: String = ""
    @State var headDraft: String = ""
    @State var baseDraft: String = ""
    @State var previewMode: Bool = false
    @State var actionMessage: String = ""
    @State var branchNames: ArrayList<String> = ArrayList<String>()

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
        this.baseDraft = this.liveRepositoryDetail.defaultBranch
        if (this.selectedIssue != "") {
            let issueNumber = this.selectedIssue
            this.bodyDraft = "Closes #${issueNumber}\n\n"
            for (item in this.liveIssues) {
                if (item.id == issueNumber && this.titleDraft == "") {
                    this.titleDraft = "Resolve ${item.title}"
                    break
                }
            }
        }
        this.loadBranches()
    }

    public func build() {
        NavDestination() {
            Stack() {
                detailBackgroundCommon(this.pageBackgroundColor())
                Scroll {
                    Column(space: 14) {
                        detailHeaderCommon(this.homeStack, this.t("back"), this.t("pull_request_editor"), this.primaryTextColor(), this.surfaceColor())
                        composerTitleInput(this.titleDraft, this.t("composer_pr_title_placeholder"), this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), { value => this.titleDraft = value })
                        composerTitleInput(this.headDraft, this.t("composer_head_branch_placeholder"), this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), { value => this.headDraft = value })
                        composerTitleInput(this.baseDraft, this.t("composer_base_branch_placeholder"), this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), { value => this.baseDraft = value })
                        this.buildBranchSuggestions()
                        this.buildModeSwitcher()
                        this.buildMarkdownToolbar()
                        if (this.previewMode) {
                            markdownPreviewBlock(
                                markdownLines(this.bodyDraft),
                                this.surfaceColor(),
                                this.mutedSurfaceColor(),
                                this.primaryTextColor(),
                                this.secondaryTextColor(),
                                this.accentStrongColor()
                            )
                        } else {
                            composerBodyEditor(this.bodyDraft, this.t("composer_pr_body_placeholder"), this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), { value => this.bodyDraft = value })
                        }
                        if (this.actionMessage != "") {
                            Text(this.actionMessage)
                                .width(100.percent)
                                .fontSize(13)
                                .fontColor(this.secondaryTextColor())
                        }
                        Button(this.t("publish_pull_request"))
                            .width(100.percent)
                            .height(50)
                            .backgroundColor(this.primaryTextColor())
                            .fontColor(this.surfaceColor())
                            .borderRadius(18)
                            .onClick({ _ => this.publishPullRequest() })
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

    @Builder
    func buildModeSwitcher() {
        Row(space: 12) {
            Button(this.t("composer_write"))
                .layoutWeight(1)
                .height(40)
                .backgroundColor(if (!this.previewMode) { this.primaryTextColor() } else { this.surfaceColor() })
                .fontColor(if (!this.previewMode) { this.surfaceColor() } else { this.primaryTextColor() })
                .borderRadius(16)
                .onClick({ _ => this.previewMode = false })
            Button(this.t("composer_preview"))
                .layoutWeight(1)
                .height(40)
                .backgroundColor(if (this.previewMode) { this.primaryTextColor() } else { this.surfaceColor() })
                .fontColor(if (this.previewMode) { this.surfaceColor() } else { this.primaryTextColor() })
                .borderRadius(16)
                .onClick({ _ => this.previewMode = true })
        }
        .width(100.percent)
    }

    @Builder
    func buildMarkdownToolbar() {
        Scroll() {
            Row(space: 10) {
                markdownActionButton(this.t("composer_h1"), { => this.appendMarkdown("# ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_h2"), { => this.appendMarkdown("## ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_bullets"), { => this.appendMarkdown("- ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_checklist"), { => this.appendMarkdown("- [ ] ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_quote"), { => this.appendMarkdown("> ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_code"), { => this.appendMarkdown("```text\n\n```") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_link"), { => this.appendMarkdown("[title](https://)") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_bold"), { => this.appendMarkdown("**bold**") }, this.surfaceColor(), this.primaryTextColor())
            }
        }
        .width(100.percent)
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
    }

    @Builder
    func buildBranchSuggestions() {
        if (this.branchNames.size > 0) {
            Scroll() {
                Row(space: 10) {
                    ForEach(this.branchNames, itemGeneratorFunc: { branch: String, _: Int64 =>
                        Button(branch)
                            .height(34)
                            .padding(left: 12, right: 12)
                            .backgroundColor(this.surfaceColor())
                            .fontColor(this.primaryTextColor())
                            .fontSize(12)
                            .borderRadius(16)
                            .onClick({ _ =>
                                this.baseDraft = branch
                                if (this.headDraft == "") {
                                    this.headDraft = branch
                                }
                            })
                    })
                }
            }
            .width(100.percent)
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Off)
        }
    }

    func appendMarkdown(snippet: String): Unit {
        if (this.bodyDraft == "") {
            this.bodyDraft = snippet
        } else {
            this.bodyDraft = "${this.bodyDraft}\n${snippet}"
        }
    }

    func loadBranches(): Unit {
        if (this.sharedAuthAccessToken == "" || this.selectedRepository == "") {
            return
        }
        fetchGitHubRepositoryBranches(
            this.sharedAuthAccessToken,
            this.selectedRepository,
            { branches => this.runOnUi({ => this.branchNames = branches }) },
            { message => this.runOnUi({ => this.actionMessage = message }) }
        )
    }

    func runOnUi(task: () -> Unit): Unit { spawn(UIThread) { => task() } }
    func publishPullRequest(): Unit {
        if (this.sharedAuthAccessToken == "" || this.selectedRepository == "") {
            this.actionMessage = this.t("sign_in_required")
            return
        }
        if (compactInputValue(this.titleDraft) == "") {
            this.actionMessage = this.t("composer_title_required")
            return
        }
        if (compactInputValue(this.headDraft) == "" || compactInputValue(this.baseDraft) == "") {
            this.actionMessage = this.t("composer_branch_required")
            return
        }
        createGitHubPullRequest(
            this.sharedAuthAccessToken,
            this.selectedRepository,
            this.titleDraft,
            this.bodyDraft,
            this.headDraft,
            this.baseDraft,
            { pullRequest =>
                this.runOnUi({
                    =>
                    let nextItems = ArrayList<GitHubPullRequestSnapshot>()
                    nextItems.add(pullRequest)
                    for (item in this.livePullRequests) {
                        nextItems.add(item)
                    }
                    this.livePullRequests = nextItems
                    this.selectedPullRequest = pullRequest.id
                    let nextDetail = this.liveRepositoryDetail
                    let pullCount = Int64.parse(nextDetail.pullRequestCount)
                    this.liveRepositoryDetail = GitHubRepositoryDetailSnapshot(
                        nextDetail.name,
                        nextDetail.summary,
                        nextDetail.repoUrl,
                        nextDetail.visibilityLabel,
                        nextDetail.issueCount,
                        if (pullCount >= 0) { "${pullCount + 1}" } else { nextDetail.pullRequestCount },
                        nextDetail.defaultBranch
                    )
                    this.homeStack.pop(animated: true)
                })
            },
            { message => this.runOnUi({ => this.actionMessage = message }) }
        )
    }

    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func mutedSurfaceColor(): Int64 { appThemeColor("mutedSurface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
    func accentStrongColor(): Int64 { appThemeColor("accentStrong", this.isDarkTheme()) }
}

@Component
public class ExploreIssueComposerPage {
    @Consume var exploreStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var selectedRepository: String
    @Consume var selectedIssue: String
    @Consume var selectedTask: String
    @Consume var liveIssues: ArrayList<GitHubIssueSnapshot>
    @Consume var liveRepositoryDetail: GitHubRepositoryDetailSnapshot

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @State var titleDraft: String = ""
    @State var bodyDraft: String = ""
    @State var previewMode: Bool = false
    @State var actionMessage: String = ""

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
    }

    public func build() {
        NavDestination() {
            Stack() {
                detailBackgroundCommon(this.pageBackgroundColor())
                Scroll {
                    Column(space: 14) {
                        detailHeaderCommon(this.exploreStack, this.t("back"), this.t("issue_editor"), this.primaryTextColor(), this.surfaceColor())
                        composerTitleInput(this.titleDraft, this.t("composer_title_placeholder"), this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), { value => this.titleDraft = value })
                        this.buildModeSwitcher()
                        this.buildMarkdownToolbar()
                        if (this.previewMode) {
                            markdownPreviewBlock(
                                markdownLines(this.bodyDraft),
                                this.surfaceColor(),
                                this.mutedSurfaceColor(),
                                this.primaryTextColor(),
                                this.secondaryTextColor(),
                                this.accentStrongColor()
                            )
                        } else {
                            composerBodyEditor(this.bodyDraft, this.t("composer_body_placeholder"), this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), { value => this.bodyDraft = value })
                        }
                        if (this.actionMessage != "") {
                            Text(this.actionMessage)
                                .width(100.percent)
                                .fontSize(13)
                                .fontColor(this.secondaryTextColor())
                        }
                        Button(this.t("publish_issue"))
                            .width(100.percent)
                            .height(50)
                            .backgroundColor(this.primaryTextColor())
                            .fontColor(this.surfaceColor())
                            .borderRadius(18)
                            .onClick({ _ => this.publishIssue() })
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

    @Builder
    func buildModeSwitcher() {
        Row(space: 12) {
            Button(this.t("composer_write"))
                .layoutWeight(1)
                .height(40)
                .backgroundColor(if (!this.previewMode) { this.primaryTextColor() } else { this.surfaceColor() })
                .fontColor(if (!this.previewMode) { this.surfaceColor() } else { this.primaryTextColor() })
                .borderRadius(16)
                .onClick({ _ => this.previewMode = false })
            Button(this.t("composer_preview"))
                .layoutWeight(1)
                .height(40)
                .backgroundColor(if (this.previewMode) { this.primaryTextColor() } else { this.surfaceColor() })
                .fontColor(if (this.previewMode) { this.surfaceColor() } else { this.primaryTextColor() })
                .borderRadius(16)
                .onClick({ _ => this.previewMode = true })
        }
        .width(100.percent)
    }

    @Builder
    func buildMarkdownToolbar() {
        Scroll() {
            Row(space: 10) {
                markdownActionButton(this.t("composer_h1"), { => this.appendMarkdown("# ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_h2"), { => this.appendMarkdown("## ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_bullets"), { => this.appendMarkdown("- ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_checklist"), { => this.appendMarkdown("- [ ] ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_quote"), { => this.appendMarkdown("> ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_code"), { => this.appendMarkdown("```text\n\n```") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_link"), { => this.appendMarkdown("[title](https://)") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_bold"), { => this.appendMarkdown("**bold**") }, this.surfaceColor(), this.primaryTextColor())
            }
        }
        .width(100.percent)
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
    }

    func appendMarkdown(snippet: String): Unit {
        if (this.bodyDraft == "") {
            this.bodyDraft = snippet
        } else {
            this.bodyDraft = "${this.bodyDraft}\n${snippet}"
        }
    }

    func runOnUi(task: () -> Unit): Unit { spawn(UIThread) { => task() } }
    func publishIssue(): Unit {
        if (this.sharedAuthAccessToken == "" || this.selectedRepository == "") {
            this.actionMessage = this.t("sign_in_required")
            return
        }
        if (compactInputValue(this.titleDraft) == "") {
            this.actionMessage = this.t("composer_title_required")
            return
        }
        createGitHubIssue(
            this.sharedAuthAccessToken,
            this.selectedRepository,
            this.titleDraft,
            this.bodyDraft,
            { issue =>
                this.runOnUi({
                    =>
                    let nextItems = ArrayList<GitHubIssueSnapshot>()
                    nextItems.add(issue)
                    for (item in this.liveIssues) {
                        nextItems.add(item)
                    }
                    this.liveIssues = nextItems
                    this.selectedIssue = issue.id
                    this.selectedTask = taskIdForIssue(issue.id)
                    let nextDetail = this.liveRepositoryDetail
                    let issueCount = Int64.parse(nextDetail.issueCount)
                    this.liveRepositoryDetail = GitHubRepositoryDetailSnapshot(
                        nextDetail.name,
                        nextDetail.summary,
                        nextDetail.repoUrl,
                        nextDetail.visibilityLabel,
                        "${issueCount + 1}",
                        nextDetail.pullRequestCount,
                        nextDetail.defaultBranch
                    )
                    this.exploreStack.pop(animated: true)
                })
            },
            { message => this.runOnUi({ => this.actionMessage = message }) }
        )
    }

    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func mutedSurfaceColor(): Int64 { appThemeColor("mutedSurface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
    func accentStrongColor(): Int64 { appThemeColor("accentStrong", this.isDarkTheme()) }
}

@Component
public class ExplorePullRequestComposerPage {
    @Consume var exploreStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var selectedRepository: String
    @Consume var selectedIssue: String
    @Consume var selectedPullRequest: String
    @Consume var livePullRequests: ArrayList<GitHubPullRequestSnapshot>
    @Consume var liveRepositoryDetail: GitHubRepositoryDetailSnapshot
    @Consume var liveIssues: ArrayList<GitHubIssueSnapshot>

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @State var titleDraft: String = ""
    @State var bodyDraft: String = ""
    @State var headDraft: String = ""
    @State var baseDraft: String = ""
    @State var previewMode: Bool = false
    @State var actionMessage: String = ""
    @State var branchNames: ArrayList<String> = ArrayList<String>()

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
        this.baseDraft = this.liveRepositoryDetail.defaultBranch
        if (this.selectedIssue != "") {
            let issueNumber = this.selectedIssue
            this.bodyDraft = "Closes #${issueNumber}\n\n"
            for (item in this.liveIssues) {
                if (item.id == issueNumber && this.titleDraft == "") {
                    this.titleDraft = "Resolve ${item.title}"
                    break
                }
            }
        }
        this.loadBranches()
    }

    public func build() {
        NavDestination() {
            Stack() {
                detailBackgroundCommon(this.pageBackgroundColor())
                Scroll {
                    Column(space: 14) {
                        detailHeaderCommon(this.exploreStack, this.t("back"), this.t("pull_request_editor"), this.primaryTextColor(), this.surfaceColor())
                        composerTitleInput(this.titleDraft, this.t("composer_pr_title_placeholder"), this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), { value => this.titleDraft = value })
                        composerTitleInput(this.headDraft, this.t("composer_head_branch_placeholder"), this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), { value => this.headDraft = value })
                        composerTitleInput(this.baseDraft, this.t("composer_base_branch_placeholder"), this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), { value => this.baseDraft = value })
                        this.buildBranchSuggestions()
                        this.buildModeSwitcher()
                        this.buildMarkdownToolbar()
                        if (this.previewMode) {
                            markdownPreviewBlock(
                                markdownLines(this.bodyDraft),
                                this.surfaceColor(),
                                this.mutedSurfaceColor(),
                                this.primaryTextColor(),
                                this.secondaryTextColor(),
                                this.accentStrongColor()
                            )
                        } else {
                            composerBodyEditor(this.bodyDraft, this.t("composer_pr_body_placeholder"), this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), { value => this.bodyDraft = value })
                        }
                        if (this.actionMessage != "") {
                            Text(this.actionMessage)
                                .width(100.percent)
                                .fontSize(13)
                                .fontColor(this.secondaryTextColor())
                        }
                        Button(this.t("publish_pull_request"))
                            .width(100.percent)
                            .height(50)
                            .backgroundColor(this.primaryTextColor())
                            .fontColor(this.surfaceColor())
                            .borderRadius(18)
                            .onClick({ _ => this.publishPullRequest() })
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

    @Builder
    func buildModeSwitcher() {
        Row(space: 12) {
            Button(this.t("composer_write"))
                .layoutWeight(1)
                .height(40)
                .backgroundColor(if (!this.previewMode) { this.primaryTextColor() } else { this.surfaceColor() })
                .fontColor(if (!this.previewMode) { this.surfaceColor() } else { this.primaryTextColor() })
                .borderRadius(16)
                .onClick({ _ => this.previewMode = false })
            Button(this.t("composer_preview"))
                .layoutWeight(1)
                .height(40)
                .backgroundColor(if (this.previewMode) { this.primaryTextColor() } else { this.surfaceColor() })
                .fontColor(if (this.previewMode) { this.surfaceColor() } else { this.primaryTextColor() })
                .borderRadius(16)
                .onClick({ _ => this.previewMode = true })
        }
        .width(100.percent)
    }

    @Builder
    func buildMarkdownToolbar() {
        Scroll() {
            Row(space: 10) {
                markdownActionButton(this.t("composer_h1"), { => this.appendMarkdown("# ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_h2"), { => this.appendMarkdown("## ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_bullets"), { => this.appendMarkdown("- ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_checklist"), { => this.appendMarkdown("- [ ] ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_quote"), { => this.appendMarkdown("> ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_code"), { => this.appendMarkdown("```text\n\n```") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_link"), { => this.appendMarkdown("[title](https://)") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_bold"), { => this.appendMarkdown("**bold**") }, this.surfaceColor(), this.primaryTextColor())
            }
        }
        .width(100.percent)
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
    }

    @Builder
    func buildBranchSuggestions() {
        if (this.branchNames.size > 0) {
            Scroll() {
                Row(space: 10) {
                    ForEach(this.branchNames, itemGeneratorFunc: { branch: String, _: Int64 =>
                        Button(branch)
                            .height(34)
                            .padding(left: 12, right: 12)
                            .backgroundColor(this.surfaceColor())
                            .fontColor(this.primaryTextColor())
                            .fontSize(12)
                            .borderRadius(16)
                            .onClick({ _ =>
                                this.baseDraft = branch
                                if (this.headDraft == "") {
                                    this.headDraft = branch
                                }
                            })
                    })
                }
            }
            .width(100.percent)
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Off)
        }
    }

    func appendMarkdown(snippet: String): Unit {
        if (this.bodyDraft == "") {
            this.bodyDraft = snippet
        } else {
            this.bodyDraft = "${this.bodyDraft}\n${snippet}"
        }
    }

    func loadBranches(): Unit {
        if (this.sharedAuthAccessToken == "" || this.selectedRepository == "") {
            return
        }
        fetchGitHubRepositoryBranches(
            this.sharedAuthAccessToken,
            this.selectedRepository,
            { branches => this.runOnUi({ => this.branchNames = branches }) },
            { message => this.runOnUi({ => this.actionMessage = message }) }
        )
    }

    func runOnUi(task: () -> Unit): Unit { spawn(UIThread) { => task() } }
    func publishPullRequest(): Unit {
        if (this.sharedAuthAccessToken == "" || this.selectedRepository == "") {
            this.actionMessage = this.t("sign_in_required")
            return
        }
        if (compactInputValue(this.titleDraft) == "") {
            this.actionMessage = this.t("composer_title_required")
            return
        }
        if (compactInputValue(this.headDraft) == "" || compactInputValue(this.baseDraft) == "") {
            this.actionMessage = this.t("composer_branch_required")
            return
        }
        createGitHubPullRequest(
            this.sharedAuthAccessToken,
            this.selectedRepository,
            this.titleDraft,
            this.bodyDraft,
            this.headDraft,
            this.baseDraft,
            { pullRequest =>
                this.runOnUi({
                    =>
                    let nextItems = ArrayList<GitHubPullRequestSnapshot>()
                    nextItems.add(pullRequest)
                    for (item in this.livePullRequests) {
                        nextItems.add(item)
                    }
                    this.livePullRequests = nextItems
                    this.selectedPullRequest = pullRequest.id
                    let nextDetail = this.liveRepositoryDetail
                    let pullCount = Int64.parse(nextDetail.pullRequestCount)
                    this.liveRepositoryDetail = GitHubRepositoryDetailSnapshot(
                        nextDetail.name,
                        nextDetail.summary,
                        nextDetail.repoUrl,
                        nextDetail.visibilityLabel,
                        nextDetail.issueCount,
                        if (pullCount >= 0) { "${pullCount + 1}" } else { nextDetail.pullRequestCount },
                        nextDetail.defaultBranch
                    )
                    this.exploreStack.pop(animated: true)
                })
            },
            { message => this.runOnUi({ => this.actionMessage = message }) }
        )
    }

    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func mutedSurfaceColor(): Int64 { appThemeColor("mutedSurface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
    func accentStrongColor(): Int64 { appThemeColor("accentStrong", this.isDarkTheme()) }
}

@Component
public class HomeIssueCommentComposerPage {
    @Consume var homeStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var selectedRepository: String
    @Consume var selectedIssue: String

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @State var bodyDraft: String = ""
    @State var previewMode: Bool = false
    @State var actionMessage: String = ""

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
    }

    public func build() {
        NavDestination() {
            Stack() {
                detailBackgroundCommon(this.pageBackgroundColor())
                Scroll {
                    Column(space: 14) {
                        detailHeaderCommon(this.homeStack, this.t("back"), this.t("issue_comment_editor"), this.primaryTextColor(), this.surfaceColor())
                        this.buildModeSwitcher()
                        this.buildMarkdownToolbar()
                        if (this.previewMode) {
                            markdownPreviewBlock(
                                markdownLines(this.bodyDraft),
                                this.surfaceColor(),
                                this.mutedSurfaceColor(),
                                this.primaryTextColor(),
                                this.secondaryTextColor(),
                                this.accentStrongColor()
                            )
                        } else {
                            composerBodyEditor(this.bodyDraft, this.t("composer_comment_placeholder"), this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), { value => this.bodyDraft = value })
                        }
                        if (this.actionMessage != "") {
                            Text(this.actionMessage)
                                .width(100.percent)
                                .fontSize(13)
                                .fontColor(this.secondaryTextColor())
                        }
                        Button(this.t("publish_comment"))
                            .width(100.percent)
                            .height(50)
                            .backgroundColor(this.primaryTextColor())
                            .fontColor(this.surfaceColor())
                            .borderRadius(18)
                            .onClick({ _ => this.publishComment() })
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

    @Builder
    func buildModeSwitcher() {
        Row(space: 12) {
            Button(this.t("composer_write"))
                .layoutWeight(1)
                .height(40)
                .backgroundColor(if (!this.previewMode) { this.primaryTextColor() } else { this.surfaceColor() })
                .fontColor(if (!this.previewMode) { this.surfaceColor() } else { this.primaryTextColor() })
                .borderRadius(16)
                .onClick({ _ => this.previewMode = false })
            Button(this.t("composer_preview"))
                .layoutWeight(1)
                .height(40)
                .backgroundColor(if (this.previewMode) { this.primaryTextColor() } else { this.surfaceColor() })
                .fontColor(if (this.previewMode) { this.surfaceColor() } else { this.primaryTextColor() })
                .borderRadius(16)
                .onClick({ _ => this.previewMode = true })
        }
        .width(100.percent)
    }

    @Builder
    func buildMarkdownToolbar() {
        Scroll() {
            Row(space: 10) {
                markdownActionButton(this.t("composer_h1"), { => this.appendMarkdown("# ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_h2"), { => this.appendMarkdown("## ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_bullets"), { => this.appendMarkdown("- ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_checklist"), { => this.appendMarkdown("- [ ] ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_quote"), { => this.appendMarkdown("> ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_code"), { => this.appendMarkdown("```text\n\n```") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_link"), { => this.appendMarkdown("[title](https://)") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_bold"), { => this.appendMarkdown("**bold**") }, this.surfaceColor(), this.primaryTextColor())
            }
        }
        .width(100.percent)
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
    }

    func appendMarkdown(snippet: String): Unit {
        if (this.bodyDraft == "") {
            this.bodyDraft = snippet
        } else {
            this.bodyDraft = "${this.bodyDraft}\n${snippet}"
        }
    }

    func runOnUi(task: () -> Unit): Unit { spawn(UIThread) { => task() } }
    func publishComment(): Unit {
        if (this.sharedAuthAccessToken == "" || this.selectedRepository == "" || this.selectedIssue == "") {
            this.actionMessage = this.t("sign_in_required")
            return
        }
        if (compactInputValue(this.bodyDraft) == "") {
            this.actionMessage = this.t("composer_body_required")
            return
        }
        createGitHubIssueComment(
            this.sharedAuthAccessToken,
            this.selectedRepository,
            this.selectedIssue,
            this.bodyDraft,
            { _ => this.runOnUi({ => this.homeStack.pop(animated: true) }) },
            { message => this.runOnUi({ => this.actionMessage = message }) }
        )
    }

    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func mutedSurfaceColor(): Int64 { appThemeColor("mutedSurface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
    func accentStrongColor(): Int64 { appThemeColor("accentStrong", this.isDarkTheme()) }
}

@Component
public class HomePullRequestReviewComposerPage {
    @Consume var homeStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var selectedRepository: String
    @Consume var selectedPullRequest: String
    @Consume var pendingPullRequestReviewEvent: String

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @State var bodyDraft: String = ""
    @State var previewMode: Bool = false
    @State var actionMessage: String = ""

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
    }

    public func build() {
        NavDestination() {
            Stack() {
                detailBackgroundCommon(this.pageBackgroundColor())
                Scroll {
                    Column(space: 14) {
                        detailHeaderCommon(this.homeStack, this.t("back"), this.t("pull_request_review_editor"), this.primaryTextColor(), this.surfaceColor())
                        this.buildReviewTypeSwitcher()
                        this.buildModeSwitcher()
                        this.buildMarkdownToolbar()
                        if (this.previewMode) {
                            markdownPreviewBlock(
                                markdownLines(this.bodyDraft),
                                this.surfaceColor(),
                                this.mutedSurfaceColor(),
                                this.primaryTextColor(),
                                this.secondaryTextColor(),
                                this.accentStrongColor()
                            )
                        } else {
                            composerBodyEditor(this.bodyDraft, this.t("composer_review_placeholder"), this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), { value => this.bodyDraft = value })
                        }
                        if (this.actionMessage != "") {
                            Text(this.actionMessage)
                                .width(100.percent)
                                .fontSize(13)
                                .fontColor(this.secondaryTextColor())
                        }
                        Button(this.t("publish_review"))
                            .width(100.percent)
                            .height(50)
                            .backgroundColor(this.primaryTextColor())
                            .fontColor(this.surfaceColor())
                            .borderRadius(18)
                            .onClick({ _ => this.publishReview() })
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

    @Builder
    func buildReviewTypeSwitcher() {
        Column(space: 8) {
            Text(this.t("review_type"))
                .fontSize(13)
                .fontColor(this.secondaryTextColor())
            Row(space: 10) {
                this.buildReviewTypeButton("COMMENT", this.t("review_comment"))
                this.buildReviewTypeButton("APPROVE", this.t("review_approve"))
                this.buildReviewTypeButton("REQUEST_CHANGES", this.t("review_request_changes"))
            }
            .width(100.percent)
        }
        .width(100.percent)
    }

    @Builder
    func buildReviewTypeButton(event: String, label: String) {
        Button(label)
            .height(36)
            .padding(left: 12, right: 12)
            .backgroundColor(if (this.pendingPullRequestReviewEvent == event) { this.primaryTextColor() } else { this.surfaceColor() })
            .fontColor(if (this.pendingPullRequestReviewEvent == event) { this.surfaceColor() } else { this.primaryTextColor() })
            .borderRadius(16)
            .onClick({ _ => this.pendingPullRequestReviewEvent = event })
    }

    @Builder
    func buildModeSwitcher() {
        Row(space: 12) {
            Button(this.t("composer_write"))
                .layoutWeight(1)
                .height(40)
                .backgroundColor(if (!this.previewMode) { this.primaryTextColor() } else { this.surfaceColor() })
                .fontColor(if (!this.previewMode) { this.surfaceColor() } else { this.primaryTextColor() })
                .borderRadius(16)
                .onClick({ _ => this.previewMode = false })
            Button(this.t("composer_preview"))
                .layoutWeight(1)
                .height(40)
                .backgroundColor(if (this.previewMode) { this.primaryTextColor() } else { this.surfaceColor() })
                .fontColor(if (this.previewMode) { this.surfaceColor() } else { this.primaryTextColor() })
                .borderRadius(16)
                .onClick({ _ => this.previewMode = true })
        }
        .width(100.percent)
    }

    @Builder
    func buildMarkdownToolbar() {
        Scroll() {
            Row(space: 10) {
                markdownActionButton(this.t("composer_h1"), { => this.appendMarkdown("# ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_h2"), { => this.appendMarkdown("## ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_bullets"), { => this.appendMarkdown("- ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_checklist"), { => this.appendMarkdown("- [ ] ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_quote"), { => this.appendMarkdown("> ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_code"), { => this.appendMarkdown("```text\n\n```") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_link"), { => this.appendMarkdown("[title](https://)") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_bold"), { => this.appendMarkdown("**bold**") }, this.surfaceColor(), this.primaryTextColor())
            }
        }
        .width(100.percent)
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
    }

    func appendMarkdown(snippet: String): Unit {
        if (this.bodyDraft == "") {
            this.bodyDraft = snippet
        } else {
            this.bodyDraft = "${this.bodyDraft}\n${snippet}"
        }
    }

    func runOnUi(task: () -> Unit): Unit { spawn(UIThread) { => task() } }
    func publishReview(): Unit {
        if (this.sharedAuthAccessToken == "" || this.selectedRepository == "" || this.selectedPullRequest == "") {
            this.actionMessage = this.t("sign_in_required")
            return
        }
        if (compactInputValue(this.bodyDraft) == "") {
            this.actionMessage = this.t("composer_body_required")
            return
        }
        submitGitHubPullRequestReview(
            this.sharedAuthAccessToken,
            this.selectedRepository,
            this.selectedPullRequest,
            this.pendingPullRequestReviewEvent,
            this.bodyDraft,
            { => this.runOnUi({ => this.homeStack.pop(animated: true) }) },
            { message => this.runOnUi({ => this.actionMessage = message }) }
        )
    }

    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func mutedSurfaceColor(): Int64 { appThemeColor("mutedSurface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
    func accentStrongColor(): Int64 { appThemeColor("accentStrong", this.isDarkTheme()) }
}

@Component
public class ExploreIssueCommentComposerPage {
    @Consume var exploreStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var selectedRepository: String
    @Consume var selectedIssue: String

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @State var bodyDraft: String = ""
    @State var previewMode: Bool = false
    @State var actionMessage: String = ""

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
    }

    public func build() {
        NavDestination() {
            Stack() {
                detailBackgroundCommon(this.pageBackgroundColor())
                Scroll {
                    Column(space: 14) {
                        detailHeaderCommon(this.exploreStack, this.t("back"), this.t("issue_comment_editor"), this.primaryTextColor(), this.surfaceColor())
                        this.buildModeSwitcher()
                        this.buildMarkdownToolbar()
                        if (this.previewMode) {
                            markdownPreviewBlock(
                                markdownLines(this.bodyDraft),
                                this.surfaceColor(),
                                this.mutedSurfaceColor(),
                                this.primaryTextColor(),
                                this.secondaryTextColor(),
                                this.accentStrongColor()
                            )
                        } else {
                            composerBodyEditor(this.bodyDraft, this.t("composer_comment_placeholder"), this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), { value => this.bodyDraft = value })
                        }
                        if (this.actionMessage != "") {
                            Text(this.actionMessage)
                                .width(100.percent)
                                .fontSize(13)
                                .fontColor(this.secondaryTextColor())
                        }
                        Button(this.t("publish_comment"))
                            .width(100.percent)
                            .height(50)
                            .backgroundColor(this.primaryTextColor())
                            .fontColor(this.surfaceColor())
                            .borderRadius(18)
                            .onClick({ _ => this.publishComment() })
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

    @Builder
    func buildModeSwitcher() {
        Row(space: 12) {
            Button(this.t("composer_write"))
                .layoutWeight(1)
                .height(40)
                .backgroundColor(if (!this.previewMode) { this.primaryTextColor() } else { this.surfaceColor() })
                .fontColor(if (!this.previewMode) { this.surfaceColor() } else { this.primaryTextColor() })
                .borderRadius(16)
                .onClick({ _ => this.previewMode = false })
            Button(this.t("composer_preview"))
                .layoutWeight(1)
                .height(40)
                .backgroundColor(if (this.previewMode) { this.primaryTextColor() } else { this.surfaceColor() })
                .fontColor(if (this.previewMode) { this.surfaceColor() } else { this.primaryTextColor() })
                .borderRadius(16)
                .onClick({ _ => this.previewMode = true })
        }
        .width(100.percent)
    }

    @Builder
    func buildMarkdownToolbar() {
        Scroll() {
            Row(space: 10) {
                markdownActionButton(this.t("composer_h1"), { => this.appendMarkdown("# ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_h2"), { => this.appendMarkdown("## ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_bullets"), { => this.appendMarkdown("- ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_checklist"), { => this.appendMarkdown("- [ ] ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_quote"), { => this.appendMarkdown("> ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_code"), { => this.appendMarkdown("```text\n\n```") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_link"), { => this.appendMarkdown("[title](https://)") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_bold"), { => this.appendMarkdown("**bold**") }, this.surfaceColor(), this.primaryTextColor())
            }
        }
        .width(100.percent)
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
    }

    func appendMarkdown(snippet: String): Unit {
        if (this.bodyDraft == "") {
            this.bodyDraft = snippet
        } else {
            this.bodyDraft = "${this.bodyDraft}\n${snippet}"
        }
    }

    func runOnUi(task: () -> Unit): Unit { spawn(UIThread) { => task() } }
    func publishComment(): Unit {
        if (this.sharedAuthAccessToken == "" || this.selectedRepository == "" || this.selectedIssue == "") {
            this.actionMessage = this.t("sign_in_required")
            return
        }
        if (compactInputValue(this.bodyDraft) == "") {
            this.actionMessage = this.t("composer_body_required")
            return
        }
        createGitHubIssueComment(
            this.sharedAuthAccessToken,
            this.selectedRepository,
            this.selectedIssue,
            this.bodyDraft,
            { _ => this.runOnUi({ => this.exploreStack.pop(animated: true) }) },
            { message => this.runOnUi({ => this.actionMessage = message }) }
        )
    }

    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func mutedSurfaceColor(): Int64 { appThemeColor("mutedSurface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
    func accentStrongColor(): Int64 { appThemeColor("accentStrong", this.isDarkTheme()) }
}

@Component
public class ExplorePullRequestReviewComposerPage {
    @Consume var exploreStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var sharedAuthAccessToken: String
    @Consume var selectedRepository: String
    @Consume var selectedPullRequest: String
    @Consume var pendingPullRequestReviewEvent: String

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @State var bodyDraft: String = ""
    @State var previewMode: Bool = false
    @State var actionMessage: String = ""

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
    }

    public func build() {
        NavDestination() {
            Stack() {
                detailBackgroundCommon(this.pageBackgroundColor())
                Scroll {
                    Column(space: 14) {
                        detailHeaderCommon(this.exploreStack, this.t("back"), this.t("pull_request_review_editor"), this.primaryTextColor(), this.surfaceColor())
                        this.buildReviewTypeSwitcher()
                        this.buildModeSwitcher()
                        this.buildMarkdownToolbar()
                        if (this.previewMode) {
                            markdownPreviewBlock(
                                markdownLines(this.bodyDraft),
                                this.surfaceColor(),
                                this.mutedSurfaceColor(),
                                this.primaryTextColor(),
                                this.secondaryTextColor(),
                                this.accentStrongColor()
                            )
                        } else {
                            composerBodyEditor(this.bodyDraft, this.t("composer_review_placeholder"), this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), { value => this.bodyDraft = value })
                        }
                        if (this.actionMessage != "") {
                            Text(this.actionMessage)
                                .width(100.percent)
                                .fontSize(13)
                                .fontColor(this.secondaryTextColor())
                        }
                        Button(this.t("publish_review"))
                            .width(100.percent)
                            .height(50)
                            .backgroundColor(this.primaryTextColor())
                            .fontColor(this.surfaceColor())
                            .borderRadius(18)
                            .onClick({ _ => this.publishReview() })
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

    @Builder
    func buildReviewTypeSwitcher() {
        Column(space: 8) {
            Text(this.t("review_type"))
                .fontSize(13)
                .fontColor(this.secondaryTextColor())
            Row(space: 10) {
                this.buildReviewTypeButton("COMMENT", this.t("review_comment"))
                this.buildReviewTypeButton("APPROVE", this.t("review_approve"))
                this.buildReviewTypeButton("REQUEST_CHANGES", this.t("review_request_changes"))
            }
            .width(100.percent)
        }
        .width(100.percent)
    }

    @Builder
    func buildReviewTypeButton(event: String, label: String) {
        Button(label)
            .height(36)
            .padding(left: 12, right: 12)
            .backgroundColor(if (this.pendingPullRequestReviewEvent == event) { this.primaryTextColor() } else { this.surfaceColor() })
            .fontColor(if (this.pendingPullRequestReviewEvent == event) { this.surfaceColor() } else { this.primaryTextColor() })
            .borderRadius(16)
            .onClick({ _ => this.pendingPullRequestReviewEvent = event })
    }

    @Builder
    func buildModeSwitcher() {
        Row(space: 12) {
            Button(this.t("composer_write"))
                .layoutWeight(1)
                .height(40)
                .backgroundColor(if (!this.previewMode) { this.primaryTextColor() } else { this.surfaceColor() })
                .fontColor(if (!this.previewMode) { this.surfaceColor() } else { this.primaryTextColor() })
                .borderRadius(16)
                .onClick({ _ => this.previewMode = false })
            Button(this.t("composer_preview"))
                .layoutWeight(1)
                .height(40)
                .backgroundColor(if (this.previewMode) { this.primaryTextColor() } else { this.surfaceColor() })
                .fontColor(if (this.previewMode) { this.surfaceColor() } else { this.primaryTextColor() })
                .borderRadius(16)
                .onClick({ _ => this.previewMode = true })
        }
        .width(100.percent)
    }

    @Builder
    func buildMarkdownToolbar() {
        Scroll() {
            Row(space: 10) {
                markdownActionButton(this.t("composer_h1"), { => this.appendMarkdown("# ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_h2"), { => this.appendMarkdown("## ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_bullets"), { => this.appendMarkdown("- ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_checklist"), { => this.appendMarkdown("- [ ] ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_quote"), { => this.appendMarkdown("> ") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_code"), { => this.appendMarkdown("```text\n\n```") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_link"), { => this.appendMarkdown("[title](https://)") }, this.surfaceColor(), this.primaryTextColor())
                markdownActionButton(this.t("composer_bold"), { => this.appendMarkdown("**bold**") }, this.surfaceColor(), this.primaryTextColor())
            }
        }
        .width(100.percent)
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
    }

    func appendMarkdown(snippet: String): Unit {
        if (this.bodyDraft == "") {
            this.bodyDraft = snippet
        } else {
            this.bodyDraft = "${this.bodyDraft}\n${snippet}"
        }
    }

    func runOnUi(task: () -> Unit): Unit { spawn(UIThread) { => task() } }
    func publishReview(): Unit {
        if (this.sharedAuthAccessToken == "" || this.selectedRepository == "" || this.selectedPullRequest == "") {
            this.actionMessage = this.t("sign_in_required")
            return
        }
        if (compactInputValue(this.bodyDraft) == "") {
            this.actionMessage = this.t("composer_body_required")
            return
        }
        submitGitHubPullRequestReview(
            this.sharedAuthAccessToken,
            this.selectedRepository,
            this.selectedPullRequest,
            this.pendingPullRequestReviewEvent,
            this.bodyDraft,
            { => this.runOnUi({ => this.exploreStack.pop(animated: true) }) },
            { message => this.runOnUi({ => this.actionMessage = message }) }
        )
    }

    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func mutedSurfaceColor(): Int64 { appThemeColor("mutedSurface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
    func accentStrongColor(): Int64 { appThemeColor("accentStrong", this.isDarkTheme()) }
}
