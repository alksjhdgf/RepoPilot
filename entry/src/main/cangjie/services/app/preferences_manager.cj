package ohos_app_cangjie_entry.services.app

import ohos_app_cangjie_entry.infra.databoard.{dataBoardGet, dataBoardSet}

let THEME_PREFERENCE_STORE_KEY = "theme_preference"
let LANGUAGE_PREFERENCE_STORE_KEY = "language_preference"

public func loadStoredThemePreference(): String {
    let storedTheme = dataBoardGet(THEME_PREFERENCE_STORE_KEY)
    if (storedTheme == "system" || storedTheme == "light" || storedTheme == "dark") {
        storedTheme
    } else {
        "system"
    }
}

public func persistThemePreference(value: String): Unit {
    dataBoardSet(THEME_PREFERENCE_STORE_KEY, value)
}

public func loadStoredLanguagePreference(): String {
    let storedLanguage = dataBoardGet(LANGUAGE_PREFERENCE_STORE_KEY)
    if (storedLanguage == "system" || storedLanguage == "en" || storedLanguage == "zh") {
        storedLanguage
    } else {
        "system"
    }
}

public func persistLanguagePreference(value: String): Unit {
    dataBoardSet(LANGUAGE_PREFERENCE_STORE_KEY, value)
}
