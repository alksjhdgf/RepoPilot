package ohos_app_cangjie_entry.pages.maps

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.Builder
import ohos_app_cangjie_entry.pages.common.CursorPlaceholderPage
import ohos_app_cangjie_entry.pages.cursor.{CursorAccountSettingsPage, CursorConversationListPage, CursorConversationPage, CursorModelPickerPage}

@Builder
public func cursorPageMap(name: String, detailParam: Any) {
    if (name == "cursorConversation") {
        CursorConversationPage()
    } else if (name == "cursorConversationList") {
        CursorConversationListPage()
    } else if (name == "cursorModelPicker") {
        CursorModelPickerPage()
    } else if (name == "cursorAccountSettings") {
        CursorAccountSettingsPage()
    } else {
        CursorPlaceholderPage()
    }
}
