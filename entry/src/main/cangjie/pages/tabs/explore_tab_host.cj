package ohos_app_cangjie_entry.pages.tabs

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.*
import ohos_app_cangjie_entry.pages.maps.explorePageMap
import ohos_app_cangjie_entry.domain.ExploreLaneSnapshot
import ohos_app_cangjie_entry.services.platform.exploreLane

@Component
public class ExploreTabHost {
    @Consume var exploreStack: NavPathStack = NavPathStack()
    @Consume var themePreference: String = "system"
    @Consume var languagePreference: String = "system"
    @Consume var selectedRepository: String = ""

    @Provide var pendingPageTitle: String = "Pending"
    @Provide var pendingPageMessage: String = "该页面待开发"
    @Provide var pendingPullRequestReviewEvent: String = "COMMENT"

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    public func build() {
        Navigation(this.exploreStack) {
            Stack(alignContent: Alignment.Top) {
                this.buildTabBackground()
                Column(space: 0) {
                    this.buildTopBar()
                    Scroll {
                        Column(space: 18) {
                            this.buildExploreLane(exploreLane(1))
                            this.buildExploreLane(exploreLane(2))
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
        .navDestination(bind(explorePageMap, this))
    }

    func t(key: String): String { tabText(this.languagePreference, this.systemLanguageCode, key) }
    func isDarkTheme(): Bool { tabIsDarkTheme(this.themePreference, this.systemColorMode) }
    func surfaceColor(): Int64 { tabColor("surface", this.themePreference, this.systemColorMode) }
    func primaryTextColor(): Int64 { tabColor("primaryText", this.themePreference, this.systemColorMode) }
    func secondaryTextColor(): Int64 { tabColor("secondaryText", this.themePreference, this.systemColorMode) }
    func topBarOverlayColor(): Int64 { if (this.isDarkTheme()) { 0xE0090B10 } else { 0xEAF2F3F7 } }

    func openRepository(repositoryId: String): Unit {
        this.selectedRepository = repositoryId
        this.exploreStack.pushPath(NavPathInfo(name: "repositoryDetail", param: ""), options: NavigationOptions(animated: true))
    }

    @Builder
    func buildTopBar() {
        Row() {
            Column(space: 4) {
                Text(this.t("explore")).fontSize(30).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
                Text(this.t("explore_subtitle")).fontSize(12).fontColor(this.secondaryTextColor())
            }.alignItems(HorizontalAlign.Start)
            Blank()
        }
        .width(100.percent)
        .padding(left: 18, right: 18, top: 16, bottom: 12)
        .backgroundColor(this.topBarOverlayColor())
    }

    @Builder
    func buildExploreLane(snapshot: ExploreLaneSnapshot) {
        Button() {
            Column(space: 8) {
                Text(this.t(snapshot.titleKey)).fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
                Text(this.t(snapshot.summaryKey)).fontSize(13).fontColor(this.secondaryTextColor())
            }
            .width(100.percent)
        }
        .width(100.percent)
        .padding(18)
        .backgroundColor(this.surfaceColor())
        .borderRadius(24)
        .onClick({ _ => this.openRepository(snapshot.repositoryId) })
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
