 package ohos_app_cangjie_entry.pages.cursor

import kit.AbilityKit.Want
import kit.ArkUI.*
import ohos.arkui.state_macro_manage.*
import ohos.base.UIThread
import ohos.business_exception.BusinessException
import std.collection.ArrayList
import kit.BasicServicesKit.SystemDateTime
import ohos_app_cangjie_entry.domain.{CursorConversationSnapshot, CursorMessageSnapshot, CursorModelSnapshot, CursorPromptSuggestionSnapshot, GitHubRepositoryDetailSnapshot}
import ohos_app_cangjie_entry.infra.databoard.dataBoardSet
import ohos_app_cangjie_entry.infra.runtime.{applyAppStatusBarStyle, getAppAbilityContext}
import ohos_app_cangjie_entry.services.cursor.{fetchCursorAgentConversation, fetchCursorAgents, findCursorConversationTitle, findCursorModelTitle, launchCursorAgent, messagesForCursorConversation, modelForCursorConversation, sendCursorAgentFollowup}
import ohos_app_cangjie_entry.ui.i18n.{appLocalizedText, appResolveLanguage}
import ohos_app_cangjie_entry.ui.theme.{appResolveIsDarkTheme, appThemeColor}
import ohos_app_cangjie_entry.infra.logging.logWarn
import ohos.app.ability.ui_ability.UIAbilityContext

let CURSOR_API_KEY_STORE_KEY = "cursor_api_key"
let CURSOR_DASHBOARD_URL = "https://cursor.com/dashboard"

@Component
public class CursorConversationPage {
    @Consume var stack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var cursorConversations: ArrayList<CursorConversationSnapshot>
    @Consume var cursorMessages: ArrayList<CursorMessageSnapshot>
    @Consume var cursorSuggestions: ArrayList<CursorPromptSuggestionSnapshot>
    @Consume var cursorModels: ArrayList<CursorModelSnapshot>
    @Consume var cursorConversationId: String
    @Consume var cursorConversationTitle: String
    @Consume var cursorSelectedModelId: String
    @Consume var cursorConnectionReady: Bool
    @Consume var cursorComposerDraft: String
    @Consume var cursorMenuActionMessage: String
    @Consume var cursorApiKey: String
    @Consume var selectedRepository: String
    @Consume var liveRepositoryDetail: GitHubRepositoryDetailSnapshot
    @Consume var pendingPageTitle: String
    @Consume var pendingPageMessage: String

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @State
    var showMenu: Bool = false

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
    }

    public func build() {
        NavDestination() {
            Stack(alignContent: Alignment.Bottom) {
                cursorBackgroundCommon(this.pageBackgroundColor())

                Scroll {
                    Column(space: 18) {
                        buildCursorConversationHeader(this)
                        buildCursorConversationNotice(this)
                        if (this.cursorMenuActionMessage != "") {
                            buildCursorBanner(this, this.cursorMenuActionMessage)
                        }
                        buildCursorConversationMessages(this)
                    }
                    .width(100.percent)
                    .padding(left: 18, right: 18, top: 18, bottom: 220)
                }
                .width(100.percent)
                .height(100.percent)
                .scrollBar(BarState.Off)

                Column(space: 14) {
                    buildCursorSuggestionRail(this)
                    buildCursorComposer(this)
                }
                .width(100.percent)
                .padding(left: 18, right: 18, bottom: 18)

                if (this.showMenu) {
                    Column() {}
                        .width(100.percent)
                        .height(100.percent)
                        .backgroundColor(0x33000000)
                        .onClick({ _ => this.toggleMenu(false) })

                    buildCursorConversationMenu(this)
                }
            }
            .width(100.percent)
            .height(100.percent)
        }
        .hideTitleBar(true)
        .backgroundColor(this.pageBackgroundColor())
    }

    func goBack(): Unit { this.stack.pop(animated: true) }
    func toggleMenu(show: Bool): Unit { this.showMenu = show }
    func openAllConversations(): Unit {
        this.showMenu = false
        this.stack.pushPath(NavPathInfo(name: "cursorConversationList", param: ""), options: NavigationOptions(animated: true))
    }
    func openModelPicker(): Unit {
        this.stack.pushPath(NavPathInfo(name: "cursorModelPicker", param: ""), options: NavigationOptions(animated: true))
    }
    func openPending(title: String, message: String): Unit {
        this.pendingPageTitle = title
        this.pendingPageMessage = message
        this.showMenu = false
        this.stack.pushPath(NavPathInfo(name: "placeholder", param: ""), options: NavigationOptions(animated: true))
    }
    func appendLocalPrompt(prompt: String): Unit {
        let text = prompt
        if (text == "") {
            return
        }
        if (this.cursorConversationId == "") {
            let conversationId = "conv_local_${SystemDateTime.getTime()}"
            this.cursorConversationId = conversationId
            this.cursorConversationTitle = this.t("cursor_new_conversation")
            this.cursorConversations.add(
                CursorConversationSnapshot(
                    conversationId,
                    this.cursorConversationTitle,
                    this.cursorSelectedModelId,
                    text,
                    this.t("cursor_now")
                )
            )
        }
        this.cursorMessages.add(CursorMessageSnapshot("user_${SystemDateTime.getTime()}", "user", text))
        this.cursorMessages.add(CursorMessageSnapshot("assistant_${SystemDateTime.getTime()}", "assistant", this.t("cursor_local_agent_reply")))
    }
    func submitPrompt(): Unit {
        if (this.cursorComposerDraft == "") {
            return
        }
        if (this.cursorApiKey == "") {
            this.openPending(this.t("cursor_account"), this.t("cursor_api_key_missing"))
            return
        }
        let prompt = this.cursorComposerDraft
        this.cursorComposerDraft = ""
        if (this.cursorConversationId == "") {
            let repositoryUrl = this.currentRepositoryUrl()
            if (repositoryUrl == "") {
                this.openPending(this.t("cursor_new_chat"), this.t("cursor_repository_required"))
                return
            }
            launchCursorAgent(
                this.cursorApiKey,
                prompt,
                repositoryUrl,
                this.currentRepositoryBranch(),
                this.cursorSelectedModelId,
                { snapshot =>
                    spawn(UIThread) {
                        this.cursorConversationId = snapshot.id
                        this.cursorConversationTitle = snapshot.title
                        this.cursorConversations.add(snapshot)
                        this.cursorMessages = ArrayList<CursorMessageSnapshot>()
                        this.cursorMessages.add(CursorMessageSnapshot("user_${SystemDateTime.getTime()}", "user", prompt))
                        this.cursorMenuActionMessage = this.t("cursor_agent_started")
                    }
                },
                { message =>
                    spawn(UIThread) {
                        this.cursorMenuActionMessage = message
                    }
                }
            )
            return
        }
        sendCursorAgentFollowup(
            this.cursorApiKey,
            this.cursorConversationId,
            prompt,
            {
                =>
                spawn(UIThread) {
                    this.cursorMessages.add(CursorMessageSnapshot("user_${SystemDateTime.getTime()}", "user", prompt))
                    this.cursorMenuActionMessage = this.t("cursor_followup_sent")
                }
            },
            { message =>
                spawn(UIThread) {
                    this.cursorMenuActionMessage = message
                }
            }
        )
    }
    func titleText(): String {
        if (this.cursorConversationTitle == "") { this.t("cursor_new_conversation") } else { this.cursorConversationTitle }
    }
    func composerDraftValue(): String { this.cursorComposerDraft }
    func updateComposerDraft(value: String): Unit { this.cursorComposerDraft = value }
    func currentRepositoryUrl(): String {
        if (this.selectedRepository == "") {
            return ""
        }
        "https://github.com/${this.selectedRepository}"
    }
    func currentRepositoryBranch(): String {
        if (this.liveRepositoryDetail.defaultBranch == "") { "main" } else { this.liveRepositoryDetail.defaultBranch }
    }
    func modelTitle(): String {
        let title = findCursorModelTitle(this.cursorModels, this.cursorSelectedModelId)
        if (title == "") { this.t("cursor_default_model") } else { title }
    }
    func visibleMessages(): ArrayList<CursorMessageSnapshot> { this.cursorMessages }
    func visibleSuggestions(): ArrayList<CursorPromptSuggestionSnapshot> { this.cursorSuggestions }
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func mutedSurfaceColor(): Int64 { appThemeColor("mutedSurface", this.isDarkTheme()) }
    func navBarColor(): Int64 { appThemeColor("navBar", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
    func accentStrongColor(): Int64 { appThemeColor("accentStrong", this.isDarkTheme()) }
    func shadowColor(): Int64 { appThemeColor("shadow", this.isDarkTheme()) }
}

@Component
public class CursorConversationListPage {
    @Consume var stack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var cursorConversations: ArrayList<CursorConversationSnapshot>
    @Consume var cursorMessages: ArrayList<CursorMessageSnapshot>
    @Consume var cursorConversationId: String
    @Consume var cursorConversationTitle: String
    @Consume var cursorSelectedModelId: String

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
    }

    public func build() {
        NavDestination() {
            Stack(alignContent: Alignment.Bottom) {
                Column() {}
                    .width(100.percent)
                    .height(100.percent)
                    .backgroundColor(0x55000000)
                    .onClick({ _ => this.goBack() })

                Column(space: 18) {
                    Row() {
                        Text(this.t("cursor_all_conversations"))
                            .fontSize(30)
                            .fontWeight(FontWeight.Bold)
                            .fontColor(this.primaryTextColor())
                        Blank()
                        Button("×")
                            .width(48)
                            .height(48)
                            .backgroundColor(this.surfaceColor())
                            .fontColor(this.primaryTextColor())
                            .borderRadius(24)
                            .onClick({ _ => this.goBack() })
                    }
                    .width(100.percent)

                    Scroll {
                        Column(space: 12) {
                            ForEach(
                                this.cursorConversations,
                                itemGeneratorFunc: { item: CursorConversationSnapshot, _: Int64 =>
                                    buildCursorConversationListRow(this, item)
                                }
                            )
                        }
                        .width(100.percent)
                    }
                    .width(100.percent)
                    .height(62.percent)
                    .scrollBar(BarState.Off)
                }
                .width(100.percent)
                .padding(left: 18, right: 18, top: 20, bottom: 28)
                .backgroundColor(this.pageBackgroundColor())
                .borderRadius(28)
            }
            .width(100.percent)
            .height(100.percent)
        }
        .hideTitleBar(true)
        .backgroundColor(0x00000000)
    }

    func goBack(): Unit { this.stack.pop(animated: true) }
    func selectConversation(conversationId: String): Unit {
        this.cursorConversationId = conversationId
        this.cursorConversationTitle = findCursorConversationTitle(this.cursorConversations, conversationId)
        this.cursorSelectedModelId = modelForCursorConversation(conversationId)
        this.cursorMessages = messagesForCursorConversation(conversationId)
        this.goBack()
    }
    func isCurrentConversation(conversationId: String): Bool { this.cursorConversationId == conversationId }
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
    func accentStrongColor(): Int64 { appThemeColor("accentStrong", this.isDarkTheme()) }
}

@Component
public class CursorModelPickerPage {
    @Consume var stack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var cursorModels: ArrayList<CursorModelSnapshot>
    @Consume var cursorSelectedModelId: String

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
                Column() {}
                    .width(100.percent)
                    .height(100.percent)
                    .backgroundColor(0x66000000)
                    .onClick({ _ => this.goBack() })

                Scroll {
                    Column(space: 18) {
                        Row() {
                            Text(this.t("cursor_models"))
                                .fontSize(28)
                                .fontWeight(FontWeight.Bold)
                                .fontColor(this.primaryTextColor())
                            Blank()
                            Button("×")
                                .width(52)
                                .height(52)
                                .backgroundColor(this.surfaceColor())
                                .fontColor(this.primaryTextColor())
                                .borderRadius(26)
                                .onClick({ _ => this.goBack() })
                        }
                        .width(100.percent)

                        Text(this.t("cursor_models_fast_group"))
                            .fontSize(16)
                            .fontWeight(FontWeight.Bold)
                            .fontColor(this.primaryTextColor())
                            .width(100.percent)

                        buildCursorModelGroup(this, "fast")

                        Text(this.t("cursor_models_versatile_group"))
                            .fontSize(16)
                            .fontWeight(FontWeight.Bold)
                            .fontColor(this.primaryTextColor())
                            .width(100.percent)

                        buildCursorModelGroup(this, "versatile")
                    }
                    .width(100.percent)
                    .padding(left: 18, right: 18, top: 24, bottom: 24)
                }
                .width(100.percent)
                .height(100.percent)
                .scrollBar(BarState.Off)
            }
            .width(100.percent)
            .height(100.percent)
        }
        .hideTitleBar(true)
        .backgroundColor(0x00000000)
    }

    func goBack(): Unit { this.stack.pop(animated: true) }
    func selectModel(modelId: String): Unit {
        this.cursorSelectedModelId = modelId
        this.goBack()
    }
    func isSelected(modelId: String): Bool { this.cursorSelectedModelId == modelId }
    func visibleModels(): ArrayList<CursorModelSnapshot> { this.cursorModels }
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func mutedSurfaceColor(): Int64 { appThemeColor("mutedSurface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
    func accentStrongColor(): Int64 { appThemeColor("accentStrong", this.isDarkTheme()) }
}

@Component
public class CursorAccountSettingsPage {
    @Consume var stack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var cursorApiKey: String
    @Consume var cursorConversations: ArrayList<CursorConversationSnapshot>
    @Consume var cursorMessages: ArrayList<CursorMessageSnapshot>
    @Consume var cursorConversationId: String
    @Consume var cursorConversationTitle: String
    @Consume var cursorSelectedModelId: String

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @State
    var cursorApiKeyDraft: String = ""

    @State
    var validationMessage: String = ""

    @State
    var connectionValidated: Bool = false

    @State
    var showFailureDialogVisible: Bool = false

    @State
    var failureDialogTitle: String = ""

    @State
    var failureDialogBody: String = ""

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
        this.cursorApiKeyDraft = this.cursorApiKey
    }

    public func build() {
        NavDestination() {
            Stack(alignContent: Alignment.TopStart) {
                cursorBackgroundCommon(this.pageBackgroundColor())

                Column(space: 18) {
                    Row(space: 10) {
                        Button("<")
                            .width(44)
                            .height(44)
                            .backgroundColor(this.surfaceColor())
                            .fontColor(this.primaryTextColor())
                            .borderRadius(22)
                            .onClick({ _ => this.goBack() })
                        Text(this.t("cursor_account"))
                            .fontSize(22)
                            .fontWeight(FontWeight.Bold)
                            .fontColor(this.primaryTextColor())
                    }
                    .width(100.percent)

                    Column(space: 12) {
                        Text(this.t("cursor_api_key_title"))
                            .fontSize(18)
                            .fontWeight(FontWeight.Bold)
                            .fontColor(this.primaryTextColor())

                        Text(this.t("cursor_api_key_desc"))
                            .fontSize(14)
                            .lineHeight(22)
                            .fontColor(this.secondaryTextColor())

                        TextInput(placeholder: this.t("cursor_api_key_placeholder"), text: this.cursorApiKeyDraft)
                            .width(100.percent)
                            .height(54)
                            .backgroundColor(this.surfaceColor())
                            .fontColor(this.primaryTextColor())
                            .borderRadius(18)
                            .padding(left: 16, right: 16)
                            .onChange({ value => this.cursorApiKeyDraft = value })

                        if (this.validationMessage != "") {
                            Text(this.validationMessage)
                                .fontSize(13)
                                .fontColor(if (this.connectionValidated) { this.accentStrongColor() } else { this.secondaryTextColor() })
                                .width(100.percent)
                        }
                    }
                    .width(100.percent)
                    .padding(left: 18, right: 18, top: 18, bottom: 18)
                    .backgroundColor(this.surfaceColor())
                    .borderRadius(24)

                    Column(space: 8) {
                        Button(this.t("cursor_open_dashboard"))
                            .width(100.percent)
                            .height(50)
                            .backgroundColor(this.mutedSurfaceColor())
                            .fontColor(this.primaryTextColor())
                            .fontSize(16)
                            .borderRadius(16)
                            .onClick({ _ => this.openCursorDashboard() })

                        Text(this.t("cursor_api_key_path_hint"))
                            .width(100.percent)
                            .fontSize(12)
                            .lineHeight(18)
                            .fontColor(this.secondaryTextColor())
                    }

                    Button(this.t("save"))
                        .width(100.percent)
                        .height(50)
                        .backgroundColor(this.navBarColor())
                        .fontColor(this.primaryTextColor())
                        .fontSize(16)
                        .borderRadius(16)
                        .onClick({ _ => this.saveCursorApiKey() })
                }
                .width(100.percent)
                .padding(left: 18, right: 18, top: 18, bottom: 32)

                if (this.showFailureDialogVisible) {
                    Column() {}
                        .width(100.percent)
                        .height(100.percent)
                        .backgroundColor(0x55000000)
                        .onClick({ _ => this.closeFailureDialog() })

                    Column() {
                        this.failureDialogBuilder()
                    }
                    .width(100.percent)
                    .height(100.percent)
                    .justifyContent(FlexAlign.Center)
                }

            }
            .width(100.percent)
            .height(100.percent)
        }
        .hideTitleBar(true)
        .backgroundColor(this.pageBackgroundColor())
    }

    @Builder
    func failureDialogBuilder() {
        Column(space: 18) {
            Text(this.failureDialogTitle)
                .width(100.percent)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.primaryTextColor())

            Text(this.failureDialogBody)
                .width(100.percent)
                .fontSize(14)
                .lineHeight(22)
                .fontColor(this.secondaryTextColor())

            Button(this.t("close"))
                .width(100.percent)
                .height(46)
                .backgroundColor(this.navBarColor())
                .fontColor(this.primaryTextColor())
                .fontSize(15)
                .borderRadius(16)
                .onClick({ _ => this.closeFailureDialog() })
        }
        .width(100.percent)
        .padding(left: 18, right: 18, top: 18, bottom: 18)
        .backgroundColor(this.surfaceColor())
        .borderRadius(24)
        .margin(left: 20, right: 20)
    }

    func goBack(): Unit { this.stack.pop(animated: true) }
    func openExternalUrl(url: String, successMessage: String): Unit {
        try {
            getAppAbilityContext().startAbility(Want(uri: url, action: "ohos.want.action.viewData"))
            this.validationMessage = successMessage
        } catch (_: BusinessException) {
            this.validationMessage = this.t("cursor_browser_open_failed")
        }
    }
    func openCursorDashboard(): Unit {
        this.openExternalUrl(CURSOR_DASHBOARD_URL, this.t("cursor_dashboard_opened"))
    }
    func saveCursorApiKey(): Unit {
        this.cursorApiKey = this.cursorApiKeyDraft
        spawn { => dataBoardSet(CURSOR_API_KEY_STORE_KEY, this.cursorApiKeyDraft) }
        if (this.cursorApiKeyDraft == "") {
            this.connectionValidated = false
            this.cursorConversations = ArrayList<CursorConversationSnapshot>()
            this.cursorMessages = ArrayList<CursorMessageSnapshot>()
            this.validationMessage = this.t("cursor_api_key_saved")
            this.showFailureDialog(this.t("cursor_connect_failed_title"), this.t("cursor_api_key_missing_reason"))
            return
        }
        this.validationMessage = this.t("cursor_api_key_testing")
        this.loadCursorAgents()
    }
    func showFailureDialog(title: String, body: String): Unit {
        this.failureDialogTitle = title
        this.failureDialogBody = body
        this.showFailureDialogVisible = true
    }
    func closeFailureDialog(): Unit {
        this.showFailureDialogVisible = false
    }
    func describeCursorFailure(message: String): String {
        if (message.contains("Cursor API 400")) {
            this.t("cursor_error_400")
        } else if (message.contains("Cursor API 401")) {
            this.t("cursor_error_401")
        } else if (message.contains("Cursor API 403")) {
            this.t("cursor_error_403")
        } else if (message.contains("Cursor API 404")) {
            this.t("cursor_error_404")
        } else if (message.contains("Cursor API 409")) {
            this.t("cursor_error_409")
        } else if (message.contains("Cursor API 429")) {
            this.t("cursor_error_429")
        } else if (message.contains("Cursor API 500")) {
            this.t("cursor_error_500")
        } else if (message.contains("network error")) {
            this.t("cursor_error_network")
        } else if (message.contains("returned no response")) {
            this.t("cursor_error_no_response")
        } else {
            "${this.t("cursor_error_unknown")}\n\n${message}"
        }
    }
    func loadCursorAgents(): Unit {
        fetchCursorAgents(
            this.cursorApiKeyDraft,
            { items =>
                spawn(UIThread) {
                    this.connectionValidated = true
                    this.cursorConversations = items
                    if (items.size > 0) {
                        let first = items[0]
                        this.cursorConversationId = first.id
                        this.cursorConversationTitle = first.title
                        this.cursorSelectedModelId = "claude-haiku-4.5"
                        fetchCursorAgentConversation(
                            this.cursorApiKeyDraft,
                            first.id,
                            { messages =>
                                spawn(UIThread) {
                                    this.cursorMessages = messages
                                }
                            },
                            { _ => () }
                        )
                    }
                    this.validationMessage = "${this.t("cursor_api_key_valid")} (${items.size})"
                }
            },
            { message =>
                spawn(UIThread) {
                    this.connectionValidated = false
                    this.validationMessage = message
                    this.showFailureDialog(this.t("cursor_connect_failed_title"), this.describeCursorFailure(message))
                }
            }
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
    func navBarColor(): Int64 { appThemeColor("navBar", this.isDarkTheme()) }
}

@Builder
func cursorBackgroundCommon(pageBackgroundColor: Int64) {
    Column() {}
        .width(100.percent)
        .height(100.percent)
        .backgroundColor(pageBackgroundColor)
        .expandSafeArea(types: [SafeAreaType.System], edges: [SafeAreaEdge.Top, SafeAreaEdge.Bottom])
}

@Builder
func buildCursorConversationHeader(page: CursorConversationPage) {
    Row(space: 12) {
        Button("<")
            .width(48)
            .height(48)
            .backgroundColor(page.surfaceColor())
            .fontColor(page.primaryTextColor())
            .borderRadius(24)
            .onClick({ _ => page.goBack() })

        Column(space: 4) {
            Text(page.titleText())
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor(page.primaryTextColor())
            Button(page.modelTitle())
                .height(28)
                .backgroundColor(0x00000000)
                .fontColor(page.secondaryTextColor())
                .fontSize(14)
                .onClick({ _ => page.openModelPicker() })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Button("...")
            .width(48)
            .height(48)
            .backgroundColor(page.surfaceColor())
            .fontColor(page.primaryTextColor())
            .borderRadius(24)
            .onClick({ _ => page.toggleMenu(true) })
    }
    .width(100.percent)
    .alignItems(VerticalAlign.Top)
}

@Builder
func buildCursorConversationNotice(page: CursorConversationPage) {
    Row(space: 0) {
        Text("Cursor")
            .fontSize(14)
            .fontColor(page.accentStrongColor())
        Text(" ${page.t("cursor_notice")}")
            .fontSize(14)
            .fontColor(page.secondaryTextColor())
    }
    .width(100.percent)
}

@Builder
func buildCursorBanner(page: CursorConversationPage, message: String) {
    Text(message)
        .width(100.percent)
        .padding(left: 16, right: 16, top: 14, bottom: 14)
        .backgroundColor(page.surfaceColor())
        .borderRadius(18)
        .fontSize(14)
        .fontColor(page.secondaryTextColor())
}

@Builder
func buildCursorConversationMessages(page: CursorConversationPage) {
    Column(space: 14) {
        if (page.visibleMessages().size == 0) {
            Text(page.t("cursor_empty_conversation"))
                .fontSize(16)
                .fontColor(page.secondaryTextColor())
                .width(100.percent)
        } else {
            ForEach(
                page.visibleMessages(),
                itemGeneratorFunc: { item: CursorMessageSnapshot, _: Int64 =>
                    buildCursorMessageBubble(page, item)
                }
            )
        }
    }
    .width(100.percent)
}

@Builder
func buildCursorMessageBubble(page: CursorConversationPage, item: CursorMessageSnapshot) {
    Column(space: 8) {
        Text(if (item.role == "user") { page.t("cursor_you") } else { "Cursor" })
            .fontSize(12)
            .fontColor(page.secondaryTextColor())
        Text(item.body)
            .fontSize(15)
            .lineHeight(24)
            .fontColor(page.primaryTextColor())
    }
    .width(100.percent)
    .padding(left: 16, right: 16, top: 16, bottom: 16)
    .backgroundColor(if (item.role == "user") { page.mutedSurfaceColor() } else { page.surfaceColor() })
    .borderRadius(20)
}

@Builder
func buildCursorSuggestionRail(page: CursorConversationPage) {
    if (page.visibleSuggestions().size > 0) {
        Column(space: 12) {
            ForEach(
                page.visibleSuggestions(),
                itemGeneratorFunc: { item: CursorPromptSuggestionSnapshot, _: Int64 =>
                    buildCursorSuggestionCard(page, item)
                }
            )
        }
        .width(100.percent)
    }
}

@Builder
func buildCursorSuggestionCard(page: CursorConversationPage, item: CursorPromptSuggestionSnapshot) {
    Column(space: 6) {
        Text(item.title)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(page.primaryTextColor())
        Text(item.subtitle)
            .fontSize(13)
            .fontColor(page.secondaryTextColor())
            .maxLines(2)
    }
    .width(260)
    .padding(left: 16, right: 16, top: 16, bottom: 16)
    .backgroundColor(page.surfaceColor())
    .borderRadius(18)
    .onClick({ _ => page.appendLocalPrompt(item.subtitle) })
}

@Builder
func buildCursorComposer(page: CursorConversationPage) {
    Row(space: 12) {
        TextInput(placeholder: page.t("cursor_ask"), text: page.composerDraftValue())
            .height(54)
            .layoutWeight(1)
            .backgroundColor(page.surfaceColor())
            .fontColor(page.secondaryTextColor())
            .fontSize(16)
            .borderRadius(18)
            .padding(left: 16, right: 16)
            .onChange({ value => page.updateComposerDraft(value) })

        Button("➜")
            .width(54)
            .height(54)
            .backgroundColor(page.navBarColor())
            .fontColor(page.primaryTextColor())
            .borderRadius(27)
            .onClick({ _ => page.submitPrompt() })
    }
    .width(100.percent)
}

@Builder
func buildCursorConversationMenu(page: CursorConversationPage) {
    Column() {
        Button(page.t("cursor_new_agent_session"))
            .width(100.percent)
            .height(72)
            .backgroundColor(0x00000000)
            .fontColor(page.primaryTextColor())
            .fontSize(18)
            .onClick({ _ => page.openPending(page.t("cursor_new_agent_session"), page.t("cursor_new_agent_session_pending")) })
        Blank().width(100.percent).height(1).backgroundColor(page.mutedSurfaceColor())
        Button(page.t("cursor_view_all_conversations"))
            .width(100.percent)
            .height(72)
            .backgroundColor(0x00000000)
            .fontColor(page.primaryTextColor())
            .fontSize(18)
            .onClick({ _ => page.openAllConversations() })
    }
    .width(72.percent)
    .backgroundColor(page.surfaceColor())
    .borderRadius(24)
    .shadow(radius: 24.0, color: page.shadowColor(), offsetX: 0.0, offsetY: 16.0)
    .align(Alignment.TopEnd)
    .margin(top: 84, right: 18)
}

@Builder
func buildCursorConversationListRow(page: CursorConversationListPage, item: CursorConversationSnapshot) {
    Column(space: 8) {
        Row() {
            Text(item.title)
                .fontSize(17)
                .fontWeight(FontWeight.Medium)
                .fontColor(page.primaryTextColor())
            Blank()
            if (page.isCurrentConversation(item.id)) {
                Text("ON").fontSize(12).fontColor(page.accentStrongColor())
            }
        }
        .width(100.percent)

        Text(item.preview)
            .fontSize(14)
            .fontColor(page.secondaryTextColor())
            .maxLines(2)

        Text(item.updatedAtLabel)
            .fontSize(12)
            .fontColor(page.secondaryTextColor())
    }
    .width(100.percent)
    .padding(left: 16, right: 16, top: 16, bottom: 16)
    .backgroundColor(page.surfaceColor())
    .borderRadius(18)
    .onClick({ _ => page.selectConversation(item.id) })
}

@Builder
func buildCursorModelGroup(page: CursorModelPickerPage, groupKey: String) {
    Column() {
        ForEach(
            page.visibleModels(),
            itemGeneratorFunc: { item: CursorModelSnapshot, _: Int64 =>
                if (item.groupKey == groupKey) {
                    buildCursorModelRow(page, item)
                }
            }
        )
    }
    .width(100.percent)
    .backgroundColor(page.surfaceColor())
    .borderRadius(24)
    .padding(top: 2, bottom: 2)
}

@Builder
func buildCursorModelRow(page: CursorModelPickerPage, item: CursorModelSnapshot) {
    Row(space: 14) {
        Row() {
            Text(item.providerLabel).fontSize(14).fontWeight(FontWeight.Bold).fontColor(page.primaryTextColor())
        }
        .width(44)
        .height(44)
        .backgroundColor(page.mutedSurfaceColor())
        .borderRadius(14)
        .justifyContent(FlexAlign.Center)

        Text(item.title).fontSize(18).fontColor(page.primaryTextColor())
        Blank()
        if (page.isSelected(item.id)) {
            Text("ON").fontSize(13).fontColor(page.accentStrongColor())
        }
    }
    .width(100.percent)
    .height(72)
    .padding(left: 16, right: 16)
    .onClick({ _ => page.selectModel(item.id) })
}
