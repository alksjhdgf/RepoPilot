package ohos_app_cangjie_entry.pages.common

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.Builder

@Builder
public func detailHeaderCommon(stack: NavPathStack, backLabel: String, title: String, textColor: Int64, surfaceColor: Int64) {
    Row(space: 14) {
        Button(backLabel)
            .width(72)
            .height(40)
            .fontSize(13)
            .backgroundColor(surfaceColor)
            .fontColor(textColor)
            .onClick({ _ => stack.pop(animated: true) })
        Text(title).fontSize(22).fontWeight(FontWeight.Bold).fontColor(textColor)
    }
    .width(100.percent)
}

@Builder
public func detailCardCommon(surfaceColor: Int64, primaryColor: Int64, secondaryColor: Int64, title: String, body: String) {
    Column(space: 8) {
        Text(title).fontSize(17).fontWeight(FontWeight.Bold).fontColor(primaryColor)
        Text(body).fontSize(13).fontColor(secondaryColor)
    }
    .width(100.percent)
    .padding(18)
    .backgroundColor(surfaceColor)
    .borderRadius(24)
}
