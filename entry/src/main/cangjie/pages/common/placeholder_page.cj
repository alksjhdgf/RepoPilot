package ohos_app_cangjie_entry.pages.common

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.*
import ohos_app_cangjie_entry.infra.runtime.applyAppStatusBarStyle
import ohos_app_cangjie_entry.ui.theme.{appResolveIsDarkTheme, appThemeColor}
import ohos_app_cangjie_entry.ui.i18n.{appLocalizedText, appResolveLanguage}

let PLACEHOLDER_FIELD_DELIMITER = "::|::"

func parsePlaceholderParam(payload: String): (String, String) {
    let parts = payload.split(PLACEHOLDER_FIELD_DELIMITER)
    if (parts.size >= 2) {
        return (parts[0], parts[1])
    }
    (payload, "")
}

func buildPlaceholderParam(title: String, message: String): String {
    "${title}${PLACEHOLDER_FIELD_DELIMITER}${message}"
}

func placeholderPayloadFromContext(context: NavDestinationContext): String {
    match (context.pathInfo.param) {
        case Some(value) =>
            match (value as String) {
                case Some(text) => text
                case None => ""
            }
        case None => ""
    }
}

@Component
public class HomePlaceholderPage {
    @Consume var homeStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String

    @StorageProp["colorMode"] let systemColorMode: ColorMode = ColorMode.Light
    @StorageProp["languageCode"] let systemLanguageCode: String = "en"

    @State var pageTitle: String = "Pending"
    @State var pageMessage: String = "该页面待开发"

    protected override func aboutToAppear(): Unit { applyAppStatusBarStyle(this.isDarkTheme()) }

    public func build() {
        NavDestination() {
            Stack() {
                detailBackgroundCommon(this.pageBackgroundColor())
                Column(space: 16) {
                    detailHeaderCommon(this.homeStack, this.t("back"), this.pageTitle, this.primaryTextColor(), this.surfaceColor())
                    detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.pageTitle, this.pageMessage)
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
        .onReady({ context =>
            let values = parsePlaceholderParam(placeholderPayloadFromContext(context))
            this.pageTitle = values[0]
            this.pageMessage = values[1]
        })
    }

    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
}

@Component
public class CursorPlaceholderPage {
    @Consume var cursorStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String

    @StorageProp["colorMode"] let systemColorMode: ColorMode = ColorMode.Light
    @StorageProp["languageCode"] let systemLanguageCode: String = "en"

    @State var pageTitle: String = "Pending"
    @State var pageMessage: String = "该页面待开发"

    protected override func aboutToAppear(): Unit { applyAppStatusBarStyle(this.isDarkTheme()) }

    public func build() {
        NavDestination() {
            Stack() {
                detailBackgroundCommon(this.pageBackgroundColor())
                Column(space: 16) {
                    detailHeaderCommon(this.cursorStack, this.t("back"), this.pageTitle, this.primaryTextColor(), this.surfaceColor())
                    detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.pageTitle, this.pageMessage)
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
        .onReady({ context =>
            let values = parsePlaceholderParam(placeholderPayloadFromContext(context))
            this.pageTitle = values[0]
            this.pageMessage = values[1]
        })
    }

    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
}

@Component
public class ExplorePlaceholderPage {
    @Consume var exploreStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String

    @StorageProp["colorMode"] let systemColorMode: ColorMode = ColorMode.Light
    @StorageProp["languageCode"] let systemLanguageCode: String = "en"

    @State var pageTitle: String = "Pending"
    @State var pageMessage: String = "该页面待开发"

    protected override func aboutToAppear(): Unit { applyAppStatusBarStyle(this.isDarkTheme()) }

    public func build() {
        NavDestination() {
            Stack() {
                detailBackgroundCommon(this.pageBackgroundColor())
                Column(space: 16) {
                    detailHeaderCommon(this.exploreStack, this.t("back"), this.pageTitle, this.primaryTextColor(), this.surfaceColor())
                    detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.pageTitle, this.pageMessage)
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
        .onReady({ context =>
            let values = parsePlaceholderParam(placeholderPayloadFromContext(context))
            this.pageTitle = values[0]
            this.pageMessage = values[1]
        })
    }

    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
}
