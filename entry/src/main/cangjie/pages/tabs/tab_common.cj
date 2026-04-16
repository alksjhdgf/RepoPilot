package ohos_app_cangjie_entry.pages.tabs

import kit.ArkUI.ColorMode
import ohos_app_cangjie_entry.ui.i18n.{appLocalizedText, appResolveLanguage}
import ohos_app_cangjie_entry.ui.theme.{appResolveIsDarkTheme, appThemeColor}

public func tabText(languagePreference: String, systemLanguageCode: String, key: String): String {
    appLocalizedText(appResolveLanguage(languagePreference, systemLanguageCode), key)
}

public func tabIsDarkTheme(themePreference: String, systemColorMode: ColorMode): Bool {
    appResolveIsDarkTheme(themePreference, systemColorMode)
}

public func tabColor(colorKey: String, themePreference: String, systemColorMode: ColorMode): Int64 {
    appThemeColor(colorKey, tabIsDarkTheme(themePreference, systemColorMode))
}

public func tabWorkplaceHeaderTitle(workplaceId: String, languagePreference: String, systemLanguageCode: String): String {
    if (workplaceId == "unified") {
        tabText(languagePreference, systemLanguageCode, "all_workplaces")
    } else {
        tabText(languagePreference, systemLanguageCode, "workplace_github")
    }
}
