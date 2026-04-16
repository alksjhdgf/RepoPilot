package ohos_app_cangjie_entry.pages.tabs

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.*
import ohos.base.UIThread
import std.collection.ArrayList
import ohos_app_cangjie_entry.pages.maps.cursorPageMap
import ohos_app_cangjie_entry.domain.{CursorConversationSnapshot, CursorModelSnapshot}
import ohos_app_cangjie_entry.services.cursor.{defaultCursorModels, findCursorConversationTitle, refreshStoredCursorSession}

@Component
public class CursorTabHost {
    @Provide var cursorConversations: ArrayList<CursorConversationSnapshot> = ArrayList<CursorConversationSnapshot>()
    @Provide var cursorModels: ArrayList<CursorModelSnapshot> = ArrayList<CursorModelSnapshot>()
    @Provide var cursorConversationId: String = ""
    @Provide var cursorConversationTitle: String = ""
    @Provide var cursorSelectedModelId: String = "claude-haiku-4.5"
    @Provide var cursorConnectionReady: Bool = false
    @Provide var cursorAtRoot: Bool = true
    @Provide var pendingPageTitle: String = "Pending"
    @Provide var pendingPageMessage: String = "该页面待开发"

    @Consume var cursorStack: NavPathStack = NavPathStack()
    @Consume var themePreference: String = "system"
    @Consume var languagePreference: String = "system"

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @State var cursorRefreshing: Bool = false

    protected override func aboutToAppear(): Unit {
        this.cursorAtRoot = true
        this.ensureCursorState()
        this.refreshCursorContent()
    }

    public func build() {
        Navigation(this.cursorStack) {
            Stack(alignContent: Alignment.Top) {
                this.buildTabBackground()

                Column(space: 0) {
                    this.buildTopBar()

                    Refresh(RefreshOptions(refreshing: @Binder(cursorRefreshing))) {
                        Scroll {
                            Column(space: 18) {
                                this.buildCursorContent()
                            }
                            .width(100.percent)
                            .padding(left: 18, right: 18, top: 18, bottom: 100)
                        }
                        .width(100.percent)
                        .height(100.percent)
                        .scrollBar(BarState.Off)
                        .align(Alignment.Top)
                        .expandSafeArea(types: [SafeAreaType.System], edges: [SafeAreaEdge.Bottom])
                    }
                    .layoutWeight(1)
                    .width(100.percent)
                    .onRefreshing({ => this.refreshCursorContent(showRefreshIndicator: true) })
                }
                .width(100.percent)
                .height(100.percent)

                if (this.cursorAtRoot) {
                    Column() {
                        Blank()
                        Row() {
                            Blank()
                            this.buildFloatingNewChatButton()
                        }
                        .width(100.percent)
                        .padding(left: 18, right: 18, bottom: 90)
                    }
                    .width(100.percent)
                    .height(100.percent)
                }
            }
            .width(100.percent)
            .height(100.percent)
        }
        .width(100.percent)
        .height(100.percent)
        .hideTitleBar(true)
        .navDestination(bind(cursorPageMap, this))
    }

    func ensureCursorState(): Unit {
        if (this.cursorModels.size == 0) {
            this.cursorModels = defaultCursorModels()
        }
    }

    func refreshCursorContent(showRefreshIndicator!: Bool = false): Unit {
        if (showRefreshIndicator) {
            this.cursorRefreshing = true
        }
        refreshStoredCursorSession(
            { items => this.applyCursorConversations(items) },
            { => this.runOnUi({ => this.clearCursorSessionState() }) },
            { _ => this.runOnUi({ => this.clearCursorSessionState() }) }
        )
    }

    func runOnUi(task: () -> Unit): Unit {
        spawn(UIThread) { => task() }
    }

    func clearCursorSessionState(): Unit {
        this.cursorConnectionReady = false
        this.cursorConversations = ArrayList<CursorConversationSnapshot>()
        this.cursorRefreshing = false
    }

    func applyCursorConversations(items: ArrayList<CursorConversationSnapshot>): Unit {
        this.runOnUi({
            =>
            this.cursorConnectionReady = true
            this.cursorRefreshing = false
            this.cursorConversations = items
            if (items.size > 0 && this.cursorConversationId == "") {
                this.cursorConversationId = items[0].id
                this.cursorConversationTitle = items[0].title
                this.cursorSelectedModelId = items[0].modelId
            }
        })
    }

    func selectCursorConversation(conversationId: String): Unit {
        this.cursorConversationId = conversationId
        this.cursorConversationTitle = findCursorConversationTitle(this.cursorConversations, conversationId)
        for (item in this.cursorConversations) {
            if (item.id == conversationId) {
                this.cursorSelectedModelId = item.modelId
            }
        }
    }

    func startCursorConversation(): Unit {
        this.cursorConversationId = ""
        this.cursorConversationTitle = this.t("cursor_new_conversation")
        if (this.cursorSelectedModelId == "") {
            this.cursorSelectedModelId = "claude-haiku-4.5"
        }
    }

    func openCursorConversation(conversationId: String): Unit {
        this.selectCursorConversation(conversationId)
        this.cursorAtRoot = false
        this.cursorStack.pushPath(NavPathInfo(name: "cursorConversation", param: ""), options: NavigationOptions(animated: true))
    }

    func openCursorAccountSettings(): Unit {
        this.cursorAtRoot = false
        this.cursorStack.pushPath(NavPathInfo(name: "cursorAccountSettings", param: ""), options: NavigationOptions(animated: true))
    }

    func startCursorConversationEntry(): Unit {
        if (!this.cursorConnectionReady) {
            this.openCursorAccountSettings()
            return
        }
        this.startCursorConversation()
        this.cursorAtRoot = false
        this.cursorStack.pushPath(NavPathInfo(name: "cursorConversation", param: ""), options: NavigationOptions(animated: true))
    }

    func t(key: String): String { tabText(this.languagePreference, this.systemLanguageCode, key) }
    func isDarkTheme(): Bool { tabIsDarkTheme(this.themePreference, this.systemColorMode) }
    func surfaceColor(): Int64 { tabColor("surface", this.themePreference, this.systemColorMode) }
    func mutedSurfaceColor(): Int64 { tabColor("mutedSurface", this.themePreference, this.systemColorMode) }
    func primaryTextColor(): Int64 { tabColor("primaryText", this.themePreference, this.systemColorMode) }
    func secondaryTextColor(): Int64 { tabColor("secondaryText", this.themePreference, this.systemColorMode) }
    func accentStrongColor(): Int64 { tabColor("accentStrong", this.themePreference, this.systemColorMode) }
    func topBarOverlayColor(): Int64 { if (this.isDarkTheme()) { 0xE0090B10 } else { 0xEAF2F3F7 } }
    func navSelectionColor(): Int64 { tabColor("navSelection", this.themePreference, this.systemColorMode) }
    func navBarColor(): Int64 { tabColor("navBar", this.themePreference, this.systemColorMode) }
    func shadowColor(): Int64 { tabColor("shadow", this.themePreference, this.systemColorMode) }

    @Builder
    func buildTopBar() {
        Row() {
            Column(space: 4) {
                Text(this.t("cursor")).fontSize(30).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
            }.alignItems(HorizontalAlign.Start)
            Blank()
        }
        .width(100.percent)
        .padding(left: 18, right: 18, top: 16, bottom: 12)
        .backgroundColor(this.topBarOverlayColor())
    }

    @Builder
    func buildCursorContent() {
        Column(space: 18) {
            this.buildCursorAgentSessionsCard()
            this.buildSectionHeader(this.t("chats"))
            if (this.cursorConversations.size > 0) {
                this.buildCursorConversationList()
            } else {
                this.buildCursorChatsCard()
            }
        }
        .width(100.percent)
    }

    @Builder
    func buildCursorAgentSessionsCard() {
        Column(space: 14) {
            Text(if (this.cursorConnectionReady) { this.t("cursor_connected_title") } else { this.t("cursor_agent_title") })
                .fontSize(18).fontWeight(FontWeight.Bold).textAlign(TextAlign.Start).fontColor(this.primaryTextColor()).width(100.percent)
            Text(if (this.cursorConnectionReady) { this.t("cursor_connected_desc") } else { this.t("cursor_agent_desc") })
                .fontSize(13).lineHeight(22).textAlign(TextAlign.Start).fontColor(this.secondaryTextColor()).width(100.percent)
            Button(if (this.cursorConnectionReady) { this.t("cursor_manage_account") } else { this.t("cursor_upgrade") })
                .width(100.percent).height(48).backgroundColor(this.navSelectionColor()).fontColor(this.accentStrongColor()).fontSize(16).borderRadius(14)
                .onClick({ _ => this.openCursorAccountSettings() })
        }
        .width(100.percent)
        .padding(left: 20, right: 20, top: 22, bottom: 22)
        .backgroundColor(this.surfaceColor())
        .borderRadius(26)
    }

    @Builder
    func buildCursorChatsCard() {
        Column(space: 18) {
            Row() { Text("⌘").fontSize(20).fontColor(this.secondaryTextColor()) }
                .width(64).height(64).backgroundColor(this.navBarColor()).borderRadius(32).justifyContent(FlexAlign.Center)
            Text(this.t("cursor_no_chats")).fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
            Text(this.t("cursor_no_chats_desc")).fontSize(13).lineHeight(22).textAlign(TextAlign.Center).fontColor(this.secondaryTextColor())
            Button(this.t("cursor_new_chat"))
                .width(100.percent).height(46).backgroundColor(this.mutedSurfaceColor()).fontColor(this.accentStrongColor()).fontSize(16).borderRadius(14)
                .onClick({ _ => this.startCursorConversationEntry() })
        }
        .width(100.percent)
        .alignItems(HorizontalAlign.Center)
        .padding(left: 20, right: 20, top: 22, bottom: 22)
        .backgroundColor(this.surfaceColor())
        .borderRadius(26)
    }

    @Builder
    func buildCursorConversationList() {
        Column() {
            ForEach(
                this.cursorConversations,
                itemGeneratorFunc: { item: CursorConversationSnapshot, index: Int64 =>
                    this.buildCursorConversationRow(item)
                    if (index < this.cursorConversations.size - 1) {
                        this.buildDivider()
                    }
                }
            )
        }
        .width(100.percent)
        .backgroundColor(this.surfaceColor())
        .borderRadius(20)
        .padding(top: 2, bottom: 2)
    }

    @Builder
    func buildCursorConversationRow(item: CursorConversationSnapshot) {
        Row(space: 14) {
            Row() { Text("⌘").fontSize(15).fontWeight(FontWeight.Bold).fontColor(0xF8FAFC) }
                .width(36).height(36).backgroundColor(this.navBarColor()).borderRadius(9).justifyContent(FlexAlign.Center)
            Column(space: 4) {
                Row() { Text(item.title).fontSize(15).fontWeight(FontWeight.Medium).fontColor(this.primaryTextColor()) }.width(100.percent)
                Text(item.preview).fontSize(12).fontColor(this.secondaryTextColor()).maxLines(1)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
            Row(space: 10) {
                if (item.updatedAtLabel != "") {
                    Text(item.updatedAtLabel).fontSize(11).fontColor(this.secondaryTextColor())
                }
                Text("›").fontSize(20).fontColor(this.secondaryTextColor())
            }
        }
        .width(100.percent)
        .height(58)
        .borderRadius(20)
        .padding(left: 13, right: 13)
        .backgroundColor(this.surfaceColor())
        .onClick({ _ => this.openCursorConversation(item.id) })
    }

    @Builder
    func buildFloatingNewChatButton() {
        Button("✎")
            .width(58)
            .height(58)
            .backgroundColor(this.navBarColor())
            .fontColor(this.primaryTextColor())
            .fontSize(20)
            .borderRadius(29)
            .opacity(0.7)
            .shadow(radius: 22.0, color: this.shadowColor(), offsetX: 0.0, offsetY: 12.0)
            .onClick({ _ => this.startCursorConversationEntry() })
    }

    @Builder
    func buildTabBackground() {
        Column() { Blank() }
            .width(100.percent)
            .height(100.percent)
            .backgroundColor(tabColor("pageBackground", this.themePreference, this.systemColorMode))
            .expandSafeArea(types: [SafeAreaType.System], edges: [SafeAreaEdge.Top, SafeAreaEdge.Bottom])
    }

    @Builder
    func buildSectionHeader(title: String) {
        Row() {
            Text(title).fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
            Blank()
            Text("...").fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.secondaryTextColor())
        }
        .width(100.percent)
    }

    @Builder
    func buildDivider() {
        Column() {}
            .width(100.percent)
            .height(1)
            .margin(left: 12, right: 12)
            .backgroundColor(this.mutedSurfaceColor())
    }
}
