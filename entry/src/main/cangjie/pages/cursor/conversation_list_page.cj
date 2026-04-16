package ohos_app_cangjie_entry.pages.cursor

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.*
import std.collection.ArrayList
import ohos_app_cangjie_entry.domain.CursorConversationSnapshot
import ohos_app_cangjie_entry.infra.runtime.applyAppStatusBarStyle
import ohos_app_cangjie_entry.services.cursor.findCursorConversationTitle
import ohos_app_cangjie_entry.ui.i18n.{appLocalizedText, appResolveLanguage}
import ohos_app_cangjie_entry.ui.theme.{appResolveIsDarkTheme, appThemeColor}

@Component
public class CursorConversationListPage {
    @Consume var stack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var cursorConversations: ArrayList<CursorConversationSnapshot>
    @Consume var cursorConversationId: String
    @Consume var cursorConversationTitle: String
    @Consume var cursorSelectedModelId: String
    @Consume var cursorAtRoot: Bool
    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
        this.cursorAtRoot = false
    }

    protected override func aboutToDisappear(): Unit {
        this.cursorAtRoot = true
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
