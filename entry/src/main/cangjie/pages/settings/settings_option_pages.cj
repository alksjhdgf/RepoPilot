package ohos_app_cangjie_entry.pages.settings

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.*
import ohos_app_cangjie_entry.infra.runtime.{applyAppStatusBarStyle, notifyAppPreferenceChange}
import ohos_app_cangjie_entry.ui.theme.{appResolveIsDarkTheme, appThemeColor}
import ohos_app_cangjie_entry.ui.i18n.{appLocalizedText, appResolveLanguage}

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
                this.buildBackground()

                Column(space: 20) {
                    this.buildHeader()
                    this.buildOptionList()
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
        notifyAppPreferenceChange("theme", value)
    }

    func goBack(): Unit { this.stack.pop(animated: true) }
    func isSelected(value: String): Bool { this.themePreference == value }
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func mutedSurfaceColor(): Int64 { appThemeColor("mutedSurface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func accentStrongColor(): Int64 { appThemeColor("accentStrong", this.isDarkTheme()) }

    @Builder
    func buildBackground() {
        Column() {}
            .width(100.percent)
            .height(100.percent)
            .backgroundColor(this.pageBackgroundColor())
            .expandSafeArea(types: [SafeAreaType.System], edges: [SafeAreaEdge.Top, SafeAreaEdge.Bottom])
    }

    @Builder
    func buildHeader() {
        Row(space: 10) {
            Button("<")
                .width(44)
                .height(44)
                .backgroundColor(this.surfaceColor())
                .fontColor(this.primaryTextColor())
                .borderRadius(22)
                .onClick({ _ => this.goBack() })
            Text(this.t("appearance")).fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
        }
        .width(100.percent)
        .alignItems(VerticalAlign.Center)
    }

    @Builder
    func buildOptionList() {
        Column() {
            this.buildOptionRow("system")
            this.buildDivider()
            this.buildOptionRow("light")
            this.buildDivider()
            this.buildOptionRow("dark")
        }
        .width(100.percent)
        .backgroundColor(this.surfaceColor())
        .borderRadius(26)
        .padding(top: 2, bottom: 2)
    }

    @Builder
    func buildOptionRow(value: String) {
        Row() {
            Text(
                if (value == "system") {
                    this.t("system")
                } else if (value == "light") {
                    this.t("light")
                } else {
                    this.t("dark")
                }
            ).fontSize(18).fontColor(this.primaryTextColor())
            Blank()
            Text(if (this.isSelected(value)) { "ON" } else { "" }).fontSize(14).fontColor(this.accentStrongColor())
        }
        .width(100.percent)
        .height(68)
        .padding(left: 18, right: 18)
        .onClick({ _ => this.selectTheme(value) })
    }

    @Builder
    func buildDivider() {
        Blank().width(100.percent).height(1).backgroundColor(this.mutedSurfaceColor())
    }
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
                this.buildBackground()

                Column(space: 20) {
                    this.buildHeader()
                    this.buildOptionList()
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
        notifyAppPreferenceChange("language", value)
    }

    func goBack(): Unit { this.stack.pop(animated: true) }
    func isSelected(value: String): Bool { this.languagePreference == value }
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func mutedSurfaceColor(): Int64 { appThemeColor("mutedSurface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func accentStrongColor(): Int64 { appThemeColor("accentStrong", this.isDarkTheme()) }

    @Builder
    func buildBackground() {
        Column() {}
            .width(100.percent)
            .height(100.percent)
            .backgroundColor(this.pageBackgroundColor())
            .expandSafeArea(types: [SafeAreaType.System], edges: [SafeAreaEdge.Top, SafeAreaEdge.Bottom])
    }

    @Builder
    func buildHeader() {
        Row(space: 10) {
            Button("<")
                .width(44)
                .height(44)
                .backgroundColor(this.surfaceColor())
                .fontColor(this.primaryTextColor())
                .borderRadius(22)
                .onClick({ _ => this.goBack() })
            Text(this.t("app_language")).fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
        }
        .width(100.percent)
        .alignItems(VerticalAlign.Center)
    }

    @Builder
    func buildOptionList() {
        Column() {
            this.buildOptionRow("system")
            this.buildDivider()
            this.buildOptionRow("en")
            this.buildDivider()
            this.buildOptionRow("zh")
        }
        .width(100.percent)
        .backgroundColor(this.surfaceColor())
        .borderRadius(26)
        .padding(top: 2, bottom: 2)
    }

    @Builder
    func buildOptionRow(value: String) {
        Row() {
            Text(
                if (value == "system") {
                    this.t("system")
                } else if (value == "zh") {
                    this.t("lang_zh")
                } else {
                    this.t("lang_en")
                }
            ).fontSize(18).fontColor(this.primaryTextColor())
            Blank()
            Text(if (this.isSelected(value)) { "ON" } else { "" }).fontSize(14).fontColor(this.accentStrongColor())
        }
        .width(100.percent)
        .height(68)
        .padding(left: 18, right: 18)
        .onClick({ _ => this.selectLanguage(value) })
    }

    @Builder
    func buildDivider() {
        Blank().width(100.percent).height(1).backgroundColor(this.mutedSurfaceColor())
    }
}
