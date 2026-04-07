package ohos_app_cangjie_entry.pages.common

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.*
import ohos_app_cangjie_entry.ui.theme.{appResolveIsDarkTheme, appThemeColor}
import ohos_app_cangjie_entry.ui.i18n.{appLocalizedText, appResolveLanguage}

@Component
public class PlaceholderPage {
    @Consume var stack: NavPathStack
    @Consume var pendingPageTitle: String
    @Consume var pendingPageMessage: String
    @Consume var themePreference: String
    @Consume var languagePreference: String

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    public func build() {
        NavDestination() {
            Stack() {
                detailBackgroundCommon(this.pageBackgroundColor())

                Column(space: 16) {
                    detailHeaderCommon(this.stack, this.t("back"), this.pendingPageTitle, this.primaryTextColor(), this.surfaceColor())
                    detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.pendingPageTitle, this.pendingPageMessage)
                    detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), "Status", "该页面待开发")
                }
                .width(100.percent)
                .height(100.percent)
                .padding(left: 18, right: 18, top: 18, bottom: 32)
            }
            .width(100.percent)
            .height(100.percent)
        }
        .hideTitleBar(true)
        .backgroundColor(this.pageBackgroundColor())
    }

    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
}
