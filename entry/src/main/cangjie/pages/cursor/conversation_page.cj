package ohos_app_cangjie_entry.pages.cursor

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.*
import ohos.base.UIThread
import kit.BasicServicesKit.SystemDateTime
import std.collection.ArrayList
import ohos_app_cangjie_entry.domain.{CursorConversationSnapshot, CursorMessageSnapshot, CursorModelSnapshot, GitHubRepositoryDetailSnapshot}
import ohos_app_cangjie_entry.infra.runtime.applyAppStatusBarStyle
import ohos_app_cangjie_entry.services.cursor.{fetchCursorAgentConversation, fetchCursorModels, findCursorModelTitle, launchCursorAgent, loadStoredCursorApiKey, sendCursorAgentFollowup}
import ohos_app_cangjie_entry.ui.i18n.{appLocalizedText, appResolveLanguage}
import ohos_app_cangjie_entry.ui.theme.{appResolveIsDarkTheme, appThemeColor}
import ohos_app_cangjie_entry.infra.logging.logWarn

@Component
public class CursorConversationPage {
    @Consume var cursorStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var cursorConversations: ArrayList<CursorConversationSnapshot>
    @State var cursorMessages: ObservedArrayList<CursorMessageSnapshot> = ObservedArrayList<CursorMessageSnapshot>()
    @Consume var cursorModels: ArrayList<CursorModelSnapshot>
    @Consume var cursorConversationId: String
    @Consume var cursorConversationTitle: String
    @Consume var cursorSelectedModelId: String
    @Consume var cursorConnectionReady: Bool
    @Consume var cursorAtRoot: Bool
    @Consume var hideFloatingNavigation: Bool
    @State var cursorComposerDraft: String = ""
    @State var cursorMenuActionMessage: String = ""
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
    let composerController: TextAreaController = TextAreaController()

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
        this.cursorAtRoot = false
        this.refreshModelsIfPossible()
        if (this.cursorConversationId == "") {
            this.cursorMessages = ObservedArrayList<CursorMessageSnapshot>()
            this.cursorMenuActionMessage = ""
        }
        this.refreshConversationIfPossible()
        this.scrollMessagesToBottom()
    }

    protected override func aboutToDisappear(): Unit {
        this.cursorAtRoot = true
        this.hideFloatingNavigation = false
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
                .padding(bottom: if (this.hideFloatingNavigation) { 18 } else { 104 })

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
                    itemGeneratorFunc: { _: CursorMessageSnapshot, idx: Int64 =>
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
            TextArea(placeholder: this.t("cursor_ask"), text: this.cursorComposerDraft, controller: this.composerController)
                .layoutWeight(1)
                .constraintSize(minHeight: 54, maxHeight: 40.percent)
                .backgroundColor(this.surfaceColor())
                .fontColor(this.secondaryTextColor())
                .fontSize(16)
                .borderRadius(18)
                .padding(left: 16, right: 16, top: 14, bottom: 14)
                .textAlign(TextAlign.Start)
                .onEditChange({ editing => this.hideFloatingNavigation = editing })
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
        .alignItems(VerticalAlign.Bottom)
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

    func goBack(): Unit { this.cursorStack.pop(animated: true) }
    func toggleMenu(show: Bool): Unit { this.showMenu = show }
    func openAllConversations(): Unit {
        this.showMenu = false
        this.cursorStack.pushPath(NavPathInfo(name: "cursorConversationList", param: ""), options: NavigationOptions(animated: true))
    }
    func openModelPicker(): Unit {
        this.cursorStack.pushPath(NavPathInfo(name: "cursorModelPicker", param: ""), options: NavigationOptions(animated: true))
    }
    func openPending(title: String, message: String): Unit {
        this.pendingPageTitle = title
        this.pendingPageMessage = message
        this.showMenu = false
        this.cursorStack.pushPath(NavPathInfo(name: "placeholder", param: ""), options: NavigationOptions(animated: true))
    }
    func refreshModelsIfPossible(): Unit {
        let apiKey = this.currentCursorApiKey()
        if (apiKey == "") {
            return
        }
        fetchCursorModels(
            apiKey,
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
        let apiKey = this.currentCursorApiKey()
        if (apiKey == "" || this.cursorConversationId == "") {
            return
        }
        fetchCursorAgentConversation(
            apiKey,
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
        for (i in 0..this.cursorMessages.size) {
            if (this.cursorMessages[i].id == messageId) {
                let message = CursorMessageSnapshot(this.cursorMessages[i])
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
        let apiKey = this.currentCursorApiKey()
        if (apiKey == "") {
            this.openPending(this.t("cursor_account"), this.t("cursor_api_key_missing"))
            return
        }
        this.hideFloatingNavigation = false
        let prompt = this.cursorComposerDraft
        this.cursorComposerDraft = ""
        let messageId = this.appendUserPrompt(prompt)
        this.cursorMenuActionMessage = ""
        if (this.cursorConversationId == "") {
            let repositoryUrl = this.currentRepositoryUrl()
            launchCursorAgent(
                apiKey,
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
            apiKey,
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
    func currentCursorApiKey(): String { loadStoredCursorApiKey() }
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
