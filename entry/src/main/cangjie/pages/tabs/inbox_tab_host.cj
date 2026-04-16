package ohos_app_cangjie_entry.pages.tabs

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.*
import ohos_app_cangjie_entry.pages.maps.inboxPageMap
import ohos_app_cangjie_entry.domain.InboxItemSnapshot
import ohos_app_cangjie_entry.services.platform.inboxItem

@Component
public class InboxTabHost {
    @Consume var inboxStack: NavPathStack = NavPathStack()
    @Consume var themePreference: String = "system"
    @Consume var languagePreference: String = "system"

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    public func build() {
        Navigation(this.inboxStack) {
            Stack(alignContent: Alignment.Top) {
                this.buildTabBackground()
                Column(space: 0) {
                    this.buildTopBar()
                    Scroll {
                        Column(space: 18) {
                            this.buildInboxMessage(inboxItem(1))
                            this.buildInboxMessage(inboxItem(2))
                            this.buildInboxMessage(inboxItem(3))
                        }
                        .width(100.percent)
                        .padding(left: 18, right: 18, top: 18, bottom: 100)
                    }
                    .width(100.percent)
                    .height(100.percent)
                    .scrollBar(BarState.Off)
                    .layoutWeight(1)
                    .expandSafeArea(types: [SafeAreaType.System], edges: [SafeAreaEdge.Bottom])
                }
                .width(100.percent)
                .height(100.percent)
            }
            .width(100.percent)
            .height(100.percent)
        }
        .width(100.percent)
        .height(100.percent)
        .hideTitleBar(true)
        .navDestination(bind(inboxPageMap, this))
    }

    func t(key: String): String { tabText(this.languagePreference, this.systemLanguageCode, key) }
    func isDarkTheme(): Bool { tabIsDarkTheme(this.themePreference, this.systemColorMode) }
    func surfaceColor(): Int64 { tabColor("surface", this.themePreference, this.systemColorMode) }
    func primaryTextColor(): Int64 { tabColor("primaryText", this.themePreference, this.systemColorMode) }
    func secondaryTextColor(): Int64 { tabColor("secondaryText", this.themePreference, this.systemColorMode) }
    func topBarOverlayColor(): Int64 { if (this.isDarkTheme()) { 0xE0090B10 } else { 0xEAF2F3F7 } }

    @Builder
    func buildTopBar() {
        Row() {
            Column(space: 4) {
                Text(this.t("inbox")).fontSize(30).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
                Text(this.t("inbox_subtitle")).fontSize(12).fontColor(this.secondaryTextColor())
            }.alignItems(HorizontalAlign.Start)
            Blank()
        }
        .width(100.percent)
        .padding(left: 18, right: 18, top: 16, bottom: 12)
        .backgroundColor(this.topBarOverlayColor())
    }

    @Builder
    func buildInboxMessage(snapshot: InboxItemSnapshot) {
        Column(space: 8) {
            Text(this.t(snapshot.titleKey)).fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
            Text(this.t(snapshot.bodyKey)).fontSize(13).fontColor(this.secondaryTextColor())
        }
        .width(100.percent)
        .padding(18)
        .backgroundColor(this.surfaceColor())
        .borderRadius(24)
    }

    @Builder
    func buildTabBackground() {
        Column() { Blank() }
            .width(100.percent)
            .height(100.percent)
            .backgroundColor(tabColor("pageBackground", this.themePreference, this.systemColorMode))
            .expandSafeArea(types: [SafeAreaType.System], edges: [SafeAreaEdge.Top, SafeAreaEdge.Bottom])
    }
}
