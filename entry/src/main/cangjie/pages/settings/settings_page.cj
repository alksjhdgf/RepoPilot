package ohos_app_cangjie_entry.pages.settings

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.*
import ohos_app_cangjie_entry.infra.runtime.applyAppStatusBarStyle
import ohos_app_cangjie_entry.ui.theme.{appResolveIsDarkTheme, appThemeColor}
import ohos_app_cangjie_entry.ui.i18n.{appLocalizedText, appResolveLanguage}

@Component
public class SettingsPage {
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var homeStack: NavPathStack
    @Consume var pendingPageTitle: String
    @Consume var pendingPageMessage: String

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
                this.buildSettingsBackground()

                Scroll {
                    Column(space: 22) {
                        this.buildSettingsHeader()
                        this.buildPrimarySettingsGroup()
                        this.buildCopilotSettingsGroup()
                        this.buildShareFeedbackSettingsGroup()
                        this.buildLegalSettingsGroup()
                        this.buildFeaturePreviewSettingsGroup()
                        this.buildAccountSettingsGroup()
                        this.buildCacheRow()
                    }
                    .width(100.percent)
                    .padding(left: 18, right: 18, top: 8, bottom: 32)
                }
                .width(100.percent)
                .height(100.percent)
                .scrollBar(BarState.Off)
            }
            .width(100.percent)
            .height(100.percent)
        }
        .hideTitleBar(true)
        .backgroundColor(this.pageBackgroundColor())
    }

    func openSettingDestination(kind: String, title: String): Unit {
        if (kind == "appearance") {
            this.homeStack.pushPath(NavPathInfo(name: "appearanceSettings", param: ""), options: NavigationOptions(animated: true))
        } else if (kind == "language") {
            this.homeStack.pushPath(NavPathInfo(name: "languageSettings", param: ""), options: NavigationOptions(animated: true))
        } else {
            this.pendingPageTitle = title
            this.pendingPageMessage = "该页面待开发"
            this.homeStack.pushPath(NavPathInfo(name: "placeholder", param: ""), options: NavigationOptions(animated: true))
        }
    }

    func goBack(): Unit { this.homeStack.pop(animated: true) }

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
    func mutedSurfaceColor(): Int64 { appThemeColor("mutedSurface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
    func accentStrongColor(): Int64 { appThemeColor("accentStrong", this.isDarkTheme()) }

    @Builder
    func buildSettingsBackground() {
        Column() {}
            .width(100.percent)
            .height(100.percent)
            .backgroundColor(this.pageBackgroundColor())
            .expandSafeArea(types: [SafeAreaType.System], edges: [SafeAreaEdge.Top, SafeAreaEdge.Bottom])
    }

    @Builder
    func buildSettingsHeader() {
        Row(space: 10) {
            Button("<")
                .width(44)
                .height(44)
                .backgroundColor(this.surfaceColor())
                .fontColor(this.primaryTextColor())
                .borderRadius(22)
                .onClick({ _ => this.goBack() })
            Text(this.t("settings")).fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
        }
        .width(100.percent)
        .alignItems(VerticalAlign.Center)
    }

    @Builder
    func buildPrimarySettingsGroup() {
        Column() {
            this.buildSettingsRow("appearance", "theme", this.themePreference, "appearance")
            this.buildDivider()
            this.buildSettingsRow("app_icon", "default_option", "", "pending")
            this.buildDivider()
            this.buildSettingsRow("app_language", "language", this.languagePreference, "language")
            this.buildDivider()
            this.buildSettingsRow("notifications", "setup_needed", "", "pending")
            this.buildDivider()
            this.buildSettingsRow("code_options", "", "", "pending")
            this.buildDivider()
            this.buildSettingsRow("external_links", "", "", "pending")
        }
        .width(100.percent)
        .backgroundColor(this.surfaceColor())
        .borderRadius(26)
        .padding(top: 2, bottom: 2)
    }

    @Builder
    func buildCopilotSettingsGroup() {
        Column() {
            this.buildSettingsRowRaw("Copilot", "Copilot Free", "pending")
            this.buildDivider()
            this.buildSettingsRowRaw("GitHub Pro", "", "pending")
        }
        .width(100.percent)
        .backgroundColor(this.surfaceColor())
        .borderRadius(26)
        .padding(top: 2, bottom: 2)
    }

    @Builder
    func buildLegalSettingsGroup() {
        Column() {
            this.buildSettingsRow("terms_of_service", "", "", "pending")
            this.buildDivider()
            this.buildSettingsRow("privacy_policy", "", "", "pending")
        }
        .width(100.percent)
        .backgroundColor(this.surfaceColor())
        .borderRadius(26)
        .padding(top: 2, bottom: 2)
    }

    @Builder
    func buildAccountSettingsGroup() {
        Column() {
            this.buildSettingsRow("manage_accounts", "", "", "pending")
            this.buildDivider()
            this.buildSettingsRow("app_lock", "", "", "pending")
        }
        .width(100.percent)
        .backgroundColor(this.surfaceColor())
        .borderRadius(26)
        .padding(top: 2, bottom: 2)
    }

    @Builder
    func buildShareFeedbackSettingsGroup() {
        Column() {
            this.buildSettingsRow("share_feedback", "", "", "pending")
        }
        .width(100.percent)
        .backgroundColor(this.surfaceColor())
        .borderRadius(26)
        .padding(top: 2, bottom: 2)
    }

    @Builder
    func buildFeaturePreviewSettingsGroup() {
        Column() {
            this.buildSettingsRow("feature_preview", "", "", "pending")
        }
        .width(100.percent)
        .backgroundColor(this.surfaceColor())
        .borderRadius(26)
        .padding(top: 2, bottom: 2)
    }

    @Builder
    func buildSettingsRow(titleKey: String, valueMode: String, rawValue: String, kind: String) {
        Row(space: 14) {
            Text(this.t(titleKey)).fontSize(18).fontColor(this.primaryTextColor())
            Blank()
            if (valueMode != "") {
                Text(
                    if (valueMode == "theme" || valueMode == "language") {
                        this.preferenceLabel(valueMode, rawValue)
                    } else {
                        this.t(valueMode)
                    }
                ).fontSize(17).fontColor(this.secondaryTextColor())
            }
            Text("›").fontSize(24).fontColor(this.secondaryTextColor())
        }
        .width(100.percent)
        .height(72)
        .padding(left: 18, right: 18)
        .onClick({ _ => this.openSettingDestination(kind, this.t(titleKey)) })
    }

    @Builder
    func buildSettingsRowRaw(title: String, value: String, kind: String) {
        Row(space: 14) {
            Text(title).fontSize(18).fontColor(this.primaryTextColor())
            Blank()
            if (value != "") {
                Text(value).fontSize(17).fontColor(this.secondaryTextColor())
            }
            Text("›").fontSize(24).fontColor(this.secondaryTextColor())
        }
        .width(100.percent)
        .height(72)
        .padding(left: 18, right: 18)
        .onClick({ _ => this.openSettingDestination(kind, title) })
    }

    @Builder
    func buildDivider() {
        Blank().width(100.percent).height(1).backgroundColor(this.mutedSurfaceColor())
    }

    @Builder
    func buildCacheRow() {
        Row() {
            Text(this.t("clear_cache")).fontSize(18).fontColor(this.accentStrongColor())
            Blank()
            Text("107 KB").fontSize(18).fontColor(this.secondaryTextColor())
        }
        .width(100.percent)
        .height(72)
        .padding(left: 18, right: 18)
        .backgroundColor(this.surfaceColor())
        .borderRadius(26)
    }
}
