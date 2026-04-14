package ohos_app_cangjie_entry.pages.cursor

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.Builder

let CURSOR_API_KEY_STORE_KEY = "cursor_api_key"
let CURSOR_DASHBOARD_URL = "https://cursor.com/dashboard"

@Builder
func cursorBackgroundCommon(pageBackgroundColor: Int64) {
    Column() {}
        .width(100.percent)
        .height(100.percent)
        .backgroundColor(pageBackgroundColor)
        .expandSafeArea(types: [SafeAreaType.System], edges: [SafeAreaEdge.Top, SafeAreaEdge.Bottom])
}
