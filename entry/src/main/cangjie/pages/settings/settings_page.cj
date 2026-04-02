package ohos_app_cangjie_entry.pages.settings

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.*
import ohos_app_cangjie_entry.pages.common.{detailCardCommon, detailHeaderCommon}
import ohos_app_cangjie_entry.ui.theme.{appResolveIsDarkTheme, appThemeColor}
import ohos_app_cangjie_entry.ui.i18n.{appLocalizedText, appResolveLanguage}

@Component
public class SettingsPage {
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var stack: NavPathStack

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    public func build() {
        NavDestination() {
            Scroll {
                Column(space: 16) {
                    detailHeaderCommon(this.stack, this.t("back"), this.t("settings"), this.primaryTextColor(), this.surfaceColor())
                    detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("appearance"), this.preferenceLabel("theme", this.themePreference))
                    detailCardCommon(this.surfaceColor(), this.primaryTextColor(), this.secondaryTextColor(), this.t("language"), this.preferenceLabel("language", this.languagePreference))
                    buildSettingsToggleRow(this, "theme")
                    buildSettingsToggleRow(this, "language")
                }
                .width(100.percent)
                .padding(left: 18, right: 18, top: 18, bottom: 32)
            }
            .width(100.percent)
            .height(100.percent)
            .scrollBar(BarState.Off)
        }
        .hideTitleBar(true)
        .backgroundColor(this.pageBackgroundColor())
    }

    func setPreference(kind: String, value: String): Unit {
        if (kind == "theme") {
            this.themePreference = value
        } else {
            this.languagePreference = value
        }
    }
    func preferenceLabel(kind: String, value: String): String {
        if (value == "system") {
            this.t("system")
        } else if (kind == "theme" && value == "dark") {
            this.t("dark")
        } else if (kind == "theme") {
            this.t("light")
        } else if (value == "zh") {
            this.t("lang_zh")
        } else {
            this.t("lang_en")
        }
    }
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
}

@Builder
func buildSettingsToggleRow(page: SettingsPage, kind: String) {
    Row(space: 10) {
        if (kind == "theme") {
            buildSettingsToggle(page, kind, "system")
            buildSettingsToggle(page, kind, "light")
            buildSettingsToggle(page, kind, "dark")
        } else {
            buildSettingsToggle(page, kind, "system")
            buildSettingsToggle(page, kind, "en")
            buildSettingsToggle(page, kind, "zh")
        }
    }
    .width(100.percent)
}

@Builder
func buildSettingsToggle(page: SettingsPage, kind: String, value: String) {
    Button(page.preferenceLabel(kind, value))
        .height(42)
        .backgroundColor(page.surfaceColor())
        .fontColor(page.primaryTextColor())
        .onClick({ _ => page.setPreference(kind, value) })
}
