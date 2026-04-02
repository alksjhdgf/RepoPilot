package ohos_app_cangjie_entry.ui.theme

import kit.ArkUI.ColorMode

public func appResolveIsDarkTheme(preference: String, systemColorMode: ColorMode): Bool {
    if (preference == "dark") { true }
    else if (preference == "light") { false }
    else { systemColorMode == ColorMode.Dark }
}

public func appThemeColor(token: String, isDark: Bool): Int64 {
    if (token == "pageBackground") { if (isDark) { 0x090B10 } else { 0xF2F3F7 } }
    else if (token == "surface") { if (isDark) { 0x161A22 } else { 0xFFFFFF } }
    else if (token == "surfaceStrong") { if (isDark) { 0xE6EDF7 } else { 0x111827 } }
    else if (token == "mutedSurface") { if (isDark) { 0x202632 } else { 0xE8EBF2 } }
    else if (token == "primaryText") { if (isDark) { 0xF4F7FB } else { 0x111827 } }
    else if (token == "secondaryText") { if (isDark) { 0x98A2B3 } else { 0x5B6472 } }
    else if (token == "accentStrong") { if (isDark) { 0x79B8FF } else { 0x1565C0 } }
    else if (token == "heroStart") { if (isDark) { 0x0C1320 } else { 0xD8E8FF } }
    else if (token == "heroCard") { if (isDark) { 0x121B2C } else { 0x0F172A } }
    else if (token == "heroText") { 0xF8FAFC }
    else if (token == "heroSubText") { 0xB7C1D0 }
    else if (token == "navBar") { if (isDark) { 0x11151C } else { 0xF7F8FB } }
    else if (token == "navSelection") { if (isDark) { 0x283041 } else { 0xDDE6F7 } }
    else if (token == "shadow") { if (isDark) { 0x55000000 } else { 0x220B1320 } }
    else { 0xFFFFFF }
}
