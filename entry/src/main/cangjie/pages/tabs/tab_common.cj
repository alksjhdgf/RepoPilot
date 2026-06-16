package ohos_app_cangjie_entry.pages.tabs

import kit.ArkUI.ColorMode
import ohos_app_cangjie_entry.ui.i18n.{appLocalizedText, appResolveLanguage}
import ohos_app_cangjie_entry.ui.theme.{appResolveIsDarkTheme, appThemeColor}

public func tabResolvedLanguage(languagePreference: String, systemLanguageCode: String): String {
    appResolveLanguage(languagePreference, systemLanguageCode)
}

public func tabTextForResolvedLanguage(language: String, key: String): String {
    appLocalizedText(language, key)
}

public func tabText(languagePreference: String, systemLanguageCode: String, key: String): String {
    appLocalizedText(appResolveLanguage(languagePreference, systemLanguageCode), key)
}

public func tabIsDarkTheme(themePreference: String, systemColorMode: ColorMode): Bool {
    appResolveIsDarkTheme(themePreference, systemColorMode)
}

public func tabColor(colorKey: String, themePreference: String, systemColorMode: ColorMode): Int64 {
    appThemeColor(colorKey, tabIsDarkTheme(themePreference, systemColorMode))
}

public func tabColorForResolvedTheme(colorKey: String, isDarkTheme: Bool): Int64 {
    appThemeColor(colorKey, isDarkTheme)
}

public func tabWorkplaceHeaderTitle(workplaceId: String, languagePreference: String, systemLanguageCode: String): String {
    if (workplaceId == "unified") {
        tabText(languagePreference, systemLanguageCode, "all_workplaces")
    } else {
        tabText(languagePreference, systemLanguageCode, "workplace_github")
    }
}

public func tabWorkplaceHeaderTitleForResolvedLanguage(workplaceId: String, language: String): String {
    if (workplaceId == "unified") {
        tabTextForResolvedLanguage(language, "all_workplaces")
    } else {
        tabTextForResolvedLanguage(language, "workplace_github")
    }
}
