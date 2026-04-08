package ohos_app_cangjie_entry.pages.settings

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.*
import ohos_app_cangjie_entry.infra.databoard.dataBoardSet
import ohos_app_cangjie_entry.infra.runtime.applyAppStatusBarStyle
import ohos_app_cangjie_entry.ui.theme.{appResolveIsDarkTheme, appThemeColor}
import ohos_app_cangjie_entry.ui.i18n.{appLocalizedText, appResolveLanguage}

let THEME_PREFERENCE_STORE_KEY = "theme_preference"
let LANGUAGE_PREFERENCE_STORE_KEY = "language_preference"

@Component
public class AppearanceSettingsPage {
    @Consume var stack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String

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
                buildSettingsOptionBackground(this)

                Column(space: 20) {
                    buildSettingsOptionHeader(this)
                    buildAppearanceOptionList(this)
                }
                .width(100.percent)
                .height(100.percent)
                .padding(left: 18, right: 18, top: 8, bottom: 32)
            }
            .width(100.percent)
            .height(100.percent)
        }
        .hideTitleBar(true)
        .backgroundColor(this.pageBackgroundColor())
    }

    func selectTheme(value: String): Unit {
        this.themePreference = value
        applyAppStatusBarStyle(this.isDarkTheme())
        spawn { => dataBoardSet(THEME_PREFERENCE_STORE_KEY, value) }
    }

    func goBack(): Unit { this.stack.pop(animated: true) }
    func isSelected(value: String): Bool { this.themePreference == value }
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
public class LanguageSettingsPage {
    @Consume var stack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String

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
                buildSettingsOptionBackground(this)

                Column(space: 20) {
                    buildSettingsOptionHeader(this)
                    buildLanguageOptionList(this)
                }
                .width(100.percent)
                .height(100.percent)
                .padding(left: 18, right: 18, top: 8, bottom: 32)
            }
            .width(100.percent)
            .height(100.percent)
        }
        .hideTitleBar(true)
        .backgroundColor(this.pageBackgroundColor())
    }

    func selectLanguage(value: String): Unit {
        this.languagePreference = value
        spawn { => dataBoardSet(LANGUAGE_PREFERENCE_STORE_KEY, value) }
    }

    func goBack(): Unit { this.stack.pop(animated: true) }
    func isSelected(value: String): Bool { this.languagePreference == value }
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func mutedSurfaceColor(): Int64 { appThemeColor("mutedSurface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
    func accentStrongColor(): Int64 { appThemeColor("accentStrong", this.isDarkTheme()) }
}

@Builder
func buildSettingsOptionHeader(page: AppearanceSettingsPage) {
    Row(space: 10) {
        Button("<")
            .width(44)
            .height(44)
            .backgroundColor(page.surfaceColor())
            .fontColor(page.primaryTextColor())
            .borderRadius(22)
            .onClick({ _ => page.goBack() })
        Text(page.t("appearance")).fontSize(22).fontWeight(FontWeight.Bold).fontColor(page.primaryTextColor())
    }
    .width(100.percent)
    .alignItems(VerticalAlign.Center)
}

@Builder
func buildSettingsOptionHeader(page: LanguageSettingsPage) {
    Row(space: 10) {
        Button("<")
            .width(44)
            .height(44)
            .backgroundColor(page.surfaceColor())
            .fontColor(page.primaryTextColor())
            .borderRadius(22)
            .onClick({ _ => page.goBack() })
        Text(page.t("app_language")).fontSize(22).fontWeight(FontWeight.Bold).fontColor(page.primaryTextColor())
    }
    .width(100.percent)
    .alignItems(VerticalAlign.Center)
}

@Builder
func buildAppearanceOptionList(page: AppearanceSettingsPage) {
    Column() {
        buildSettingsOptionRow(page, { => page.t("system") }, "system")
        Blank().width(100.percent).height(1).backgroundColor(page.mutedSurfaceColor())
        buildSettingsOptionRow(page, { => page.t("light") }, "light")
        Blank().width(100.percent).height(1).backgroundColor(page.mutedSurfaceColor())
        buildSettingsOptionRow(page, { => page.t("dark") }, "dark")
    }
    .width(100.percent)
    .backgroundColor(page.surfaceColor())
    .borderRadius(26)
    .padding(top: 2, bottom: 2)
}

@Builder
func buildLanguageOptionList(page: LanguageSettingsPage) {
    Column() {
        buildSettingsOptionRow(page, { => page.t("system") }, "system")
        Blank().width(100.percent).height(1).backgroundColor(page.mutedSurfaceColor())
        buildSettingsOptionRow(page, { => page.t("lang_en") }, "en")
        Blank().width(100.percent).height(1).backgroundColor(page.mutedSurfaceColor())
        buildSettingsOptionRow(page, { => page.t("lang_zh") }, "zh")
    }
    .width(100.percent)
    .backgroundColor(page.surfaceColor())
    .borderRadius(26)
    .padding(top: 2, bottom: 2)
}

@Builder
func buildSettingsOptionBackground(page: AppearanceSettingsPage) {
    if (page.isDarkTheme()) {
        Column() {}
            .width(100.percent)
            .height(100.percent)
            .backgroundColor(page.pageBackgroundColor())
            .expandSafeArea(types: [SafeAreaType.System], edges: [SafeAreaEdge.Top, SafeAreaEdge.Bottom])
    } else {
        Column() {}
            .width(100.percent)
            .height(100.percent)
            .backgroundColor(page.pageBackgroundColor())
            .expandSafeArea(types: [SafeAreaType.System], edges: [SafeAreaEdge.Top, SafeAreaEdge.Bottom])
    }
}

@Builder
func buildSettingsOptionBackground(page: LanguageSettingsPage) {
    if (page.isDarkTheme()) {
        Column() {}
            .width(100.percent)
            .height(100.percent)
            .backgroundColor(page.pageBackgroundColor())
            .expandSafeArea(types: [SafeAreaType.System], edges: [SafeAreaEdge.Top, SafeAreaEdge.Bottom])
    } else {
        Column() {}
            .width(100.percent)
            .height(100.percent)
            .backgroundColor(page.pageBackgroundColor())
            .expandSafeArea(types: [SafeAreaType.System], edges: [SafeAreaEdge.Top, SafeAreaEdge.Bottom])
    }
}

@Builder
func buildSettingsOptionRow(page: AppearanceSettingsPage, title: () -> String, value: String) {
    Row() {
        Text(title()).fontSize(18).fontColor(page.primaryTextColor())
        Blank()
        Text(if (page.isSelected(value)) { "ON" } else { "" }).fontSize(14).fontColor(page.accentStrongColor())
    }
    .width(100.percent)
    .height(68)
    .padding(left: 18, right: 18)
    .onClick({ _ => page.selectTheme(value) })
}

@Builder
func buildSettingsOptionRow(page: LanguageSettingsPage, title: () -> String, value: String) {
    Row() {
        Text(title()).fontSize(18).fontColor(page.primaryTextColor())
        Blank()
        Text(if (page.isSelected(value)) { "ON" } else { "" }).fontSize(14).fontColor(page.accentStrongColor())
    }
    .width(100.percent)
    .height(68)
    .padding(left: 18, right: 18)
    .onClick({ _ => page.selectLanguage(value) })
}
