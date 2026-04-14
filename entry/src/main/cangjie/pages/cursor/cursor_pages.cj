 package ohos_app_cangjie_entry.pages.cursor

import kit.AbilityKit.Want
import kit.ArkUI.*
import ohos.arkui.state_macro_manage.*
import ohos.base.UIThread
import ohos.business_exception.BusinessException
import std.collection.ArrayList
import kit.BasicServicesKit.SystemDateTime
import ohos_app_cangjie_entry.domain.{CursorConversationSnapshot, CursorMessageSnapshot, CursorModelSnapshot, GitHubRepositoryDetailSnapshot}
import ohos_app_cangjie_entry.infra.databoard.dataBoardSet
import ohos_app_cangjie_entry.infra.runtime.{applyAppStatusBarStyle, getAppAbilityContext}
import ohos_app_cangjie_entry.services.cursor.{fetchCursorAgentConversation, fetchCursorAgents, fetchCursorModels, findCursorConversationTitle, findCursorModelTitle, launchCursorAgent, sendCursorAgentFollowup}
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
    @State var cursorMessages: ObservedArrayList<CursorMessageSnapshot> = ObservedArrayList<CursorMessageSnapshot>()
    @Consume var cursorModels: ArrayList<CursorModelSnapshot>
    @Consume var cursorConversationId: String
    @Consume var cursorConversationTitle: String
    @Consume var cursorSelectedModelId: String
    @Consume var cursorConnectionReady: Bool
    @State var cursorComposerDraft: String = ""
    @State var cursorMenuActionMessage: String = ""
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

    let messageScroller: Scroller = Scroller()
    let composerController: TextInputController = TextInputController()

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
        this.refreshModelsIfPossible()
        if (this.cursorConversationId == "") {
            this.cursorMessages = ObservedArrayList<CursorMessageSnapshot>()
            this.cursorMenuActionMessage = ""
        }
        this.refreshConversationIfPossible()
        this.scrollMessagesToBottom()
    }

    public func build() {
        NavDestination() {
            Stack() {
                cursorBackgroundCommon(this.pageBackgroundColor())

                Column(space: 0) {
                    Column(space: 18) {
                        this.buildConversationHeader()
                        this.buildConversationNotice()
                        if (this.cursorMenuActionMessage != "") {
                            this.buildConversationBanner(this.cursorMenuActionMessage)
                        }
                    }
                    .width(100.percent)
                    .padding(left: 18, right: 18, top: 18, bottom: 18)

                    Scroll(this.messageScroller) {
                        Column(space: 14) {
                            this.buildConversationMessages()
                        }
                        .width(100.percent)
                        .justifyContent(FlexAlign.Start)
                        .alignItems(HorizontalAlign.Start)
                        .padding(left: 18, right: 18, top: 0, bottom: 18)
                    }
                    .width(100.percent)
                    .align(Alignment.Top)
                    .layoutWeight(1)
                    .scrollBar(BarState.Off)

                    this.buildConversationComposer()
                }
                .width(100.percent)
                .height(100.percent)
                .padding(bottom: 18)

                if (this.showMenu) {
                    Column() {}
                        .width(100.percent)
                        .height(100.percent)
                        .backgroundColor(0x33000000)
                        .onClick({ _ => this.toggleMenu(false) })

                    this.buildConversationMenu()
                }
            }
            .width(100.percent)
            .height(100.percent)
        }
        .hideTitleBar(true)
        .backgroundColor(this.pageBackgroundColor())
    }

    @Builder
    func buildConversationHeader() {
        Row(space: 12) {
            Button("<")
                .width(48)
                .height(48)
                .backgroundColor(this.surfaceColor())
                .fontColor(this.primaryTextColor())
                .borderRadius(24)
                .onClick({ _ => this.goBack() })

            Column(space: 4) {
                Text(if (this.cursorConversationTitle == "") { this.t("cursor_new_conversation") } else { this.cursorConversationTitle })
                    .fontSize(24)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.primaryTextColor())
                Button(if (findCursorModelTitle(this.cursorModels, this.cursorSelectedModelId) == "") {
                    this.t("cursor_default_model")
                } else {
                    findCursorModelTitle(this.cursorModels, this.cursorSelectedModelId)
                })
                    .height(28)
                    .backgroundColor(this.mutedSurfaceColor())
                    .fontColor(this.primaryTextColor())
                    .fontSize(14)
                    .borderRadius(14)
                    .padding(left: 12, right: 12)
                    .onClick({ _ => this.openModelPicker() })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Button("...")
                .width(48)
                .height(48)
                .backgroundColor(this.surfaceColor())
                .fontColor(this.primaryTextColor())
                .borderRadius(24)
                .onClick({ _ => this.toggleMenu(true) })
        }
        .width(100.percent)
        .alignItems(VerticalAlign.Top)
    }

    @Builder
    func buildConversationNotice() {
        Row(space: 0) {
            Text("Cursor")
                .fontSize(14)
                .fontColor(this.accentStrongColor())
            Text(" ${this.t("cursor_notice")}")
                .fontSize(14)
                .fontColor(this.secondaryTextColor())
        }
        .width(100.percent)
    }

    @Builder
    func buildConversationBanner(message: String) {
        Text(message)
            .width(100.percent)
            .padding(left: 16, right: 16, top: 14, bottom: 14)
            .backgroundColor(this.surfaceColor())
            .borderRadius(18)
            .fontSize(14)
            .fontColor(this.secondaryTextColor())
    }

    @Builder
    func buildConversationMessages() {
        Column(space: 14) {
            if (this.cursorMessages.size > 0) {
                ForEach(
                    this.cursorMessages,
                    itemGeneratorFunc: { item: CursorMessageSnapshot, idx: Int64 =>
                        this.buildConversationMessageBubble(idx)
                    }
                )
            }
        }
        .width(100.percent)
    }

    @Builder
    func buildConversationMessageBubble(idx: Int64) {
        Column() {
            if (this.cursorMessages[idx].role == "user") {
                Row(space: 0) {
                    Blank().layoutWeight(1)
                    Column(space: 10) {
                        Text(this.cursorMessages[idx].body)
                            .fontSize(15)
                            .lineHeight(24)
                            .fontColor(this.primaryTextColor())
                            .padding(left: 16, right: 16, top: 16, bottom: 16)
                            .backgroundColor(this.userBubbleColor())
                            .borderRadius(20)

                        if (this.cursorMessages[idx].failed) {
                            Row(space: 10) {
                                Text("!")
                                    .width(20)
                                    .height(20)
                                    .textAlign(TextAlign.Center)
                                    .fontSize(12)
                                    .fontWeight(FontWeight.Bold)
                                    .fontColor(0xFFFFFF)
                                    .backgroundColor(0xD14343)
                                    .borderRadius(10)
                                Column(space: 2) {
                                    Text(this.t("cursor_message_failed"))
                                        .fontSize(12)
                                        .fontWeight(FontWeight.Medium)
                                        .fontColor(this.errorColor())
                                    Text(this.cursorMessages[idx].failureReason)
                                        .fontSize(12)
                                        .fontColor(this.secondaryTextColor())
                                }
                                .layoutWeight(1)
                                .alignItems(HorizontalAlign.Start)
                            }
                            .width(100.percent)
                        }
                    }
                    .width(74.percent)
                    .alignItems(HorizontalAlign.End)
                }
            } else {
                Row(space: 0) {
                    Column(space: 8) {
                        Text("Cursor")
                            .fontSize(12)
                            .fontColor(this.secondaryTextColor())
                        Text(this.cursorMessages[idx].body)
                            .fontSize(15)
                            .lineHeight(24)
                            .fontColor(this.primaryTextColor())
                    }
                    .width(82.percent)
                    .padding(left: 16, right: 16, top: 16, bottom: 16)
                    .backgroundColor(this.surfaceColor())
                    .borderRadius(20)
                    Blank().layoutWeight(1)
                }
            }
        }
        .width(100.percent)
    }

    @Builder
    func buildConversationComposer() {
        Row(space: 12) {
            TextInput(placeholder: this.t("cursor_ask"), text: this.cursorComposerDraft, controller: this.composerController)
                .height(54)
                .layoutWeight(1)
                .backgroundColor(this.surfaceColor())
                .fontColor(this.secondaryTextColor())
                .fontSize(16)
                .borderRadius(18)
                .padding(left: 16, right: 16)
                .onChange({ value => this.updateComposerDraft(value) })

            Button("➜")
                .width(54)
                .height(54)
                .backgroundColor(this.navBarColor())
                .fontColor(this.primaryTextColor())
                .borderRadius(27)
                .onClick({ _ => this.submitPrompt() })
        }
        .width(100.percent)
    }

    @Builder
    func buildConversationMenu() {
        Column() {
            Button(this.t("cursor_new_agent_session"))
                .width(100.percent)
                .height(72)
                .backgroundColor(0x00000000)
                .fontColor(this.primaryTextColor())
                .fontSize(18)
                .onClick({ _ => this.openPending(this.t("cursor_new_agent_session"), this.t("cursor_new_agent_session_pending")) })
            Blank().width(100.percent).height(1).backgroundColor(this.mutedSurfaceColor())
            Button(this.t("cursor_view_all_conversations"))
                .width(100.percent)
                .height(72)
                .backgroundColor(0x00000000)
                .fontColor(this.primaryTextColor())
                .fontSize(18)
                .onClick({ _ => this.openAllConversations() })
        }
        .width(72.percent)
        .backgroundColor(this.surfaceColor())
        .borderRadius(24)
        .shadow(radius: 24.0, color: this.shadowColor(), offsetX: 0.0, offsetY: 16.0)
        .align(Alignment.TopEnd)
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
    func refreshModelsIfPossible(): Unit {
        if (this.cursorApiKey == "") {
            return
        }
        fetchCursorModels(
            this.cursorApiKey,
            { items =>
                spawn(UIThread) {
                    if (items.size > 0) {
                        this.cursorModels = items
                        if (findCursorModelTitle(items, this.cursorSelectedModelId) == "") {
                            this.cursorSelectedModelId = items[0].id
                        }
                    }
                }
            },
            { _ => () }
        )
    }
    func refreshConversationIfPossible(): Unit {
        if (this.cursorApiKey == "" || this.cursorConversationId == "") {
            return
        }
        fetchCursorAgentConversation(
            this.cursorApiKey,
            this.cursorConversationId,
            { items =>
                spawn(UIThread) {
                    this.cursorMessages = ObservedArrayList<CursorMessageSnapshot>(items)
                    this.scrollMessagesToBottom()
                }
            },
            { message =>
                spawn(UIThread) {
                    this.cursorMenuActionMessage = message
                }
            }
        )
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
        this.cursorMessages.append(CursorMessageSnapshot("user_${SystemDateTime.getTime()}", "user", text))
        this.cursorMessages.append(CursorMessageSnapshot("assistant_${SystemDateTime.getTime()}", "assistant", this.t("cursor_local_agent_reply")))
        this.scrollMessagesToBottom()
    }
    func appendUserPrompt(prompt: String): String {
        let messageId = "user_${SystemDateTime.getTime()}"
        this.cursorMessages.append(CursorMessageSnapshot(messageId, "user", prompt))
        this.scrollMessagesToBottom()
        messageId
    }
    func markMessageFailed(messageId: String, reason: String): Unit {
        logWarn("zxc", "id=${messageId} reason=${reason}")
        for (i in 0..this.cursorMessages.size) {
            logWarn("zxc", "lastId=${this.cursorMessages[i].id}")
            if (this.cursorMessages[i].id == messageId) {
                logWarn("zxc", "aaa")
                let message = CursorMessageSnapshot(this.cursorMessages[i])
//                this.cursorMessages.remove(i)
                message.failed = true
                message.failureReason = reason
                this.cursorMessages[i] = message
                break
            }
        }
        this.scrollMessagesToBottom()
    }
    func submitPrompt(): Unit {
        if (this.cursorComposerDraft == "") {
            return
        }
        if (this.cursorApiKey == "") {
            this.openPending(this.t("cursor_account"), this.t("cursor_api_key_missing"))
            return
        }
        this.composerController.stopEditing()
        let prompt = this.cursorComposerDraft
        this.cursorComposerDraft = ""
        let messageId = this.appendUserPrompt(prompt)
        this.cursorMenuActionMessage = ""
        if (this.cursorConversationId == "") {
            let repositoryUrl = this.currentRepositoryUrl()
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
                        this.scrollMessagesToBottom()
                    }
                },
                { message =>
                    spawn(UIThread) {
                        this.markMessageFailed(messageId, message)
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
                    this.scrollMessagesToBottom()
                }
            },
            { message =>
                spawn(UIThread) {
                    this.markMessageFailed(messageId, message)
                }
            }
        )
    }
    func updateComposerDraft(value: String): Unit { this.cursorComposerDraft = value }
    func currentRepositoryUrl(): String {
        if (this.selectedRepository == "") {
            return ""
        }
        "https://github.com/${this.selectedRepository}"
    }
    func currentRepositoryBranch(): String {
        if (this.selectedRepository == "") {
            return ""
        }
        if (this.liveRepositoryDetail.defaultBranch == "") { "main" } else { this.liveRepositoryDetail.defaultBranch }
    }
    func scrollMessagesToBottom(): Unit {
        spawn(UIThread) {
            this.messageScroller.scrollEdge(Edge.Bottom)
        }
    }
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
    func userBubbleColor(): Int64 { if (this.isDarkTheme()) { 0x243146 } else { 0xDCEBFF } }
    func errorColor(): Int64 { if (this.isDarkTheme()) { 0xFF8F8F } else { 0xC62828 } }
}

@Component
public class CursorConversationListPage {
    @Consume var stack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var cursorConversations: ArrayList<CursorConversationSnapshot>
    @Consume var cursorConversationId: String
    @Consume var cursorConversationTitle: String
    @Consume var cursorSelectedModelId: String
    @Consume var cursorApiKey: String

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
                                    this.buildConversationListRow(item)
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
        for (item in this.cursorConversations) {
            if (item.id == conversationId && item.modelId != "") {
                this.cursorSelectedModelId = item.modelId
            }
        }
        this.goBack()
    }
    func isCurrentConversation(conversationId: String): Bool { this.cursorConversationId == conversationId }
    @Builder
    func buildConversationListRow(item: CursorConversationSnapshot) {
        Column(space: 8) {
            Row() {
                Text(item.title)
                    .fontSize(17)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.primaryTextColor())
                Blank()
                if (this.isCurrentConversation(item.id)) {
                    Text("ON").fontSize(12).fontColor(this.accentStrongColor())
                }
            }
            .width(100.percent)

            Text(item.preview)
                .fontSize(14)
                .fontColor(this.secondaryTextColor())
                .maxLines(2)

            Text(item.updatedAtLabel)
                .fontSize(12)
                .fontColor(this.secondaryTextColor())
        }
        .width(100.percent)
        .padding(left: 16, right: 16, top: 16, bottom: 16)
        .backgroundColor(this.surfaceColor())
        .borderRadius(18)
        .onClick({ _ => this.selectConversation(item.id) })
    }
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

                        this.buildModelGroup("fast")

                        Text(this.t("cursor_models_versatile_group"))
                            .fontSize(16)
                            .fontWeight(FontWeight.Bold)
                            .fontColor(this.primaryTextColor())
                            .width(100.percent)

                        this.buildModelGroup("versatile")
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
    @Builder
    func buildModelGroup(groupKey: String) {
        Column() {
            ForEach(
                this.cursorModels,
                itemGeneratorFunc: { item: CursorModelSnapshot, _: Int64 =>
                    if (item.groupKey == groupKey) {
                        this.buildModelRow(item)
                    }
                }
            )
        }
        .width(100.percent)
        .backgroundColor(this.surfaceColor())
        .borderRadius(24)
        .padding(top: 2, bottom: 2)
    }
    @Builder
    func buildModelRow(item: CursorModelSnapshot) {
        Row(space: 14) {
            Row() {
                Text(item.providerLabel).fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
            }
            .width(44)
            .height(44)
            .backgroundColor(this.mutedSurfaceColor())
            .borderRadius(14)
            .justifyContent(FlexAlign.Center)

            Text(item.title).fontSize(18).fontColor(this.primaryTextColor())
            Blank()
            if (this.isSelected(item.id)) {
                Text("ON").fontSize(13).fontColor(this.accentStrongColor())
            }
        }
        .width(100.percent)
        .height(72)
        .padding(left: 16, right: 16)
        .onClick({ _ => this.selectModel(item.id) })
    }
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
    @Consume var cursorConnectionReady: Bool
    @Consume var cursorConversations: ArrayList<CursorConversationSnapshot>
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

                    if (this.cursorApiKey != "") {
                        Button(this.t("cursor_clear_api_key"))
                            .width(100.percent)
                            .height(50)
                            .backgroundColor(this.mutedSurfaceColor())
                            .fontColor(this.secondaryTextColor())
                            .fontSize(16)
                            .borderRadius(16)
                            .onClick({ _ => this.clearCursorApiKey() })
                    }
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
            this.cursorConnectionReady = false
            this.cursorConversations = ArrayList<CursorConversationSnapshot>()
            this.cursorConversationId = ""
            this.cursorConversationTitle = this.t("cursor_new_conversation")
            this.validationMessage = this.t("cursor_api_key_cleared")
            return
        }
        this.validationMessage = this.t("cursor_api_key_testing")
        this.loadCursorAgents()
    }
    func clearCursorApiKey(): Unit {
        this.cursorApiKeyDraft = ""
        this.cursorApiKey = ""
        spawn { => dataBoardSet(CURSOR_API_KEY_STORE_KEY, "") }
        this.connectionValidated = false
        this.cursorConnectionReady = false
        this.cursorConversations = ArrayList<CursorConversationSnapshot>()
        this.cursorConversationId = ""
        this.cursorConversationTitle = this.t("cursor_new_conversation")
        this.validationMessage = this.t("cursor_api_key_cleared")
        this.closeFailureDialog()
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
                    this.cursorConnectionReady = true
                    this.cursorConversations = items
                    if (items.size > 0) {
                        let first = items[0]
                        this.cursorConversationId = first.id
                        this.cursorConversationTitle = first.title
                        this.cursorSelectedModelId = "claude-haiku-4.5"
                    } else {
                        this.cursorConversationId = ""
                        this.cursorConversationTitle = this.t("cursor_new_conversation")
                    }
                    this.validationMessage = "${this.t("cursor_api_key_valid")} (${items.size})"
                    this.goBack()
                }
            },
            { message =>
                spawn(UIThread) {
                    this.connectionValidated = false
                    this.cursorConnectionReady = false
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
    func userBubbleColor(): Int64 { if (this.isDarkTheme()) { 0x243146 } else { 0xDCEBFF } }
    func errorColor(): Int64 { if (this.isDarkTheme()) { 0xFF8F8F } else { 0xC62828 } }
}

@Builder
func cursorBackgroundCommon(pageBackgroundColor: Int64) {
    Column() {}
        .width(100.percent)
        .height(100.percent)
        .backgroundColor(pageBackgroundColor)
        .expandSafeArea(types: [SafeAreaType.System], edges: [SafeAreaEdge.Top, SafeAreaEdge.Bottom])
}
