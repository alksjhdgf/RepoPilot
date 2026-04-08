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
    @Consume var stack: NavPathStack
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
                buildSettingsBackground(this)

                Scroll {
                    Column(space: 22) {
                        buildSettingsHeader(this)
                        buildPrimarySettingsGroup(this)
                        buildCopilotSettingsGroup(this)
                        buildShareFeedbackSettingsGroup(this)
                        buildLegalSettingsGroup(this)
                        buildFeaturePreviewSettingsGroup(this)
                        buildAccountSettingsGroup(this)
                        buildCacheRow(this)
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
            this.stack.pushPath(NavPathInfo(name: "appearanceSettings", param: ""), options: NavigationOptions(animated: true))
        } else if (kind == "language") {
            this.stack.pushPath(NavPathInfo(name: "languageSettings", param: ""), options: NavigationOptions(animated: true))
        } else {
            this.pendingPageTitle = title
            this.pendingPageMessage = "该页面待开发"
            this.stack.pushPath(NavPathInfo(name: "placeholder", param: ""), options: NavigationOptions(animated: true))
        }
    }
    func goBack(): Unit { this.stack.pop(animated: true) }
    func themePreferenceValue(): String { this.themePreference }
    func languagePreferenceValue(): String { this.languagePreference }

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
}

@Builder
func buildSettingsHeader(page: SettingsPage) {
    Row(space: 10) {
        Button("<")
            .width(44)
            .height(44)
            .backgroundColor(page.surfaceColor())
            .fontColor(page.primaryTextColor())
            .borderRadius(22)
            .onClick({ _ => page.goBack() })
        Text(page.t("settings")).fontSize(22).fontWeight(FontWeight.Bold).fontColor(page.primaryTextColor())
    }
    .width(100.percent)
    .alignItems(VerticalAlign.Center)
}

@Builder
func buildPrimarySettingsGroup(page: SettingsPage) {
    Column() {
        buildAppearanceSettingsRow(page)
        Blank().width(100.percent).height(1).backgroundColor(page.mutedSurfaceColor())
        buildAppIconSettingsRow(page)
        Blank().width(100.percent).height(1).backgroundColor(page.mutedSurfaceColor())
        buildAppLanguageSettingsRow(page)
        Blank().width(100.percent).height(1).backgroundColor(page.mutedSurfaceColor())
        buildNotificationsSettingsRow(page)
        Blank().width(100.percent).height(1).backgroundColor(page.mutedSurfaceColor())
        buildCodeOptionsSettingsRow(page)
        Blank().width(100.percent).height(1).backgroundColor(page.mutedSurfaceColor())
        buildExternalLinksSettingsRow(page)
    }
    .width(100.percent)
    .backgroundColor(page.surfaceColor())
    .borderRadius(26)
    .padding(top: 2, bottom: 2)
}

@Builder
func buildCopilotSettingsGroup(page: SettingsPage) {
    Column() {
        buildCopilotPlanSettingsRow(page)
        Blank().width(100.percent).height(1).backgroundColor(page.mutedSurfaceColor())
        buildGitHubProSettingsRow(page)
    }
    .width(100.percent)
    .backgroundColor(page.surfaceColor())
    .borderRadius(26)
    .padding(top: 2, bottom: 2)
}

@Builder
func buildLegalSettingsGroup(page: SettingsPage) {
    Column() {
        buildTermsSettingsRow(page)
        Blank().width(100.percent).height(1).backgroundColor(page.mutedSurfaceColor())
        buildPrivacySettingsRow(page)
    }
    .width(100.percent)
    .backgroundColor(page.surfaceColor())
    .borderRadius(26)
    .padding(top: 2, bottom: 2)
}

@Builder
func buildAccountSettingsGroup(page: SettingsPage) {
    Column() {
        buildManageAccountsSettingsRow(page)
        Blank().width(100.percent).height(1).backgroundColor(page.mutedSurfaceColor())
        buildAppLockSettingsRow(page)
    }
    .width(100.percent)
    .backgroundColor(page.surfaceColor())
    .borderRadius(26)
    .padding(top: 2, bottom: 2)
}

@Builder
func buildSettingsBackground(page: SettingsPage) {
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
func buildSettingsRow(page: SettingsPage, title: () -> String, value: () -> String, kind: String) {
    Row(space: 14) {
        Text(title()).fontSize(18).fontColor(page.primaryTextColor())
        Blank()
        if (value() != "") {
            Text(value()).fontSize(17).fontColor(page.secondaryTextColor())
        }
        Text("›").fontSize(24).fontColor(page.secondaryTextColor())
    }
    .width(100.percent)
    .height(72)
    .padding(left: 18, right: 18)
    .onClick({ _ => page.openSettingDestination(kind, title()) })
}

@Builder
func buildAppearanceSettingsRow(page: SettingsPage) {
    buildSettingsRow(page, { => page.t("appearance") }, { => page.preferenceLabel("theme", page.themePreferenceValue()) }, "appearance")
}

@Builder
func buildAppIconSettingsRow(page: SettingsPage) {
    buildSettingsRow(page, { => page.t("app_icon") }, { => page.t("default_option") }, "pending")
}

@Builder
func buildAppLanguageSettingsRow(page: SettingsPage) {
    buildSettingsRow(page, { => page.t("app_language") }, { => page.preferenceLabel("language", page.languagePreferenceValue()) }, "language")
}

@Builder
func buildNotificationsSettingsRow(page: SettingsPage) {
    buildSettingsRow(page, { => page.t("notifications") }, { => page.t("setup_needed") }, "pending")
}

@Builder
func buildCodeOptionsSettingsRow(page: SettingsPage) {
    buildSettingsRow(page, { => page.t("code_options") }, { => "" }, "pending")
}

@Builder
func buildExternalLinksSettingsRow(page: SettingsPage) {
    buildSettingsRow(page, { => page.t("external_links") }, { => "" }, "pending")
}

@Builder
func buildCopilotPlanSettingsRow(page: SettingsPage) {
    buildSettingsRow(page, { => "Copilot" }, { => "Copilot Free" }, "pending")
}

@Builder
func buildGitHubProSettingsRow(page: SettingsPage) {
    buildSettingsRow(page, { => "GitHub Pro" }, { => "" }, "pending")
}

@Builder
func buildTermsSettingsRow(page: SettingsPage) {
    buildSettingsRow(page, { => page.t("terms_of_service") }, { => "" }, "pending")
}

@Builder
func buildPrivacySettingsRow(page: SettingsPage) {
    buildSettingsRow(page, { => page.t("privacy_policy") }, { => "" }, "pending")
}

@Builder
func buildManageAccountsSettingsRow(page: SettingsPage) {
    buildSettingsRow(page, { => page.t("manage_accounts") }, { => "" }, "pending")
}

@Builder
func buildAppLockSettingsRow(page: SettingsPage) {
    buildSettingsRow(page, { => page.t("app_lock") }, { => "" }, "pending")
}

@Builder
func buildShareFeedbackSettingsRow(page: SettingsPage) {
    buildSettingsRow(page, { => page.t("share_feedback") }, { => "" }, "pending")
}

@Builder
func buildFeaturePreviewSettingsRow(page: SettingsPage) {
    buildSettingsRow(page, { => page.t("feature_preview") }, { => "" }, "pending")
}

@Builder
func buildShareFeedbackSettingsGroup(page: SettingsPage) {
    Column() {
        buildShareFeedbackSettingsRow(page)
    }
    .width(100.percent)
    .backgroundColor(page.surfaceColor())
    .borderRadius(26)
    .padding(top: 2, bottom: 2)
}

@Builder
func buildFeaturePreviewSettingsGroup(page: SettingsPage) {
    Column() {
        buildFeaturePreviewSettingsRow(page)
    }
    .width(100.percent)
    .backgroundColor(page.surfaceColor())
    .borderRadius(26)
    .padding(top: 2, bottom: 2)
}

@Builder
func buildCacheRow(page: SettingsPage) {
    Row() {
        Text(page.t("clear_cache")).fontSize(18).fontColor(page.accentStrongColor())
        Blank()
        Text("107 KB").fontSize(18).fontColor(page.secondaryTextColor())
    }
    .width(100.percent)
    .height(72)
    .padding(left: 18, right: 18)
    .backgroundColor(page.surfaceColor())
    .borderRadius(26)
}
