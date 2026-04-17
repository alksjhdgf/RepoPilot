package ohos_app_cangjie_entry.pages.cursor

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.*
import std.collection.ArrayList
import ohos_app_cangjie_entry.domain.CursorModelSnapshot
import ohos_app_cangjie_entry.infra.runtime.applyAppStatusBarStyle
import ohos_app_cangjie_entry.ui.i18n.{appLocalizedText, appResolveLanguage}
import ohos_app_cangjie_entry.ui.theme.{appResolveIsDarkTheme, appThemeColor}

@Component
public class CursorModelPickerPage {
    @Consume var cursorStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var cursorModels: ArrayList<CursorModelSnapshot>
    @Consume var cursorSelectedModelId: String

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
                Column() {}
                    .width(100.percent)
                    .height(100.percent)
                    .backgroundColor(0x66000000)
                    .onClick({ _ => this.goBack() })

                Scroll {
                    Column(space: 18) {
                        Row() {
                            Text(this.t("cursor_models"))
                                .fontSize(28)
                                .fontWeight(FontWeight.Bold)
                                .fontColor(this.primaryTextColor())
                            Blank()
                            Button("×")
                                .width(52)
                                .height(52)
                                .backgroundColor(this.surfaceColor())
                                .fontColor(this.primaryTextColor())
                                .borderRadius(26)
                                .onClick({ _ => this.goBack() })
                        }
                        .width(100.percent)

                        Text(this.t("cursor_models_fast_group"))
                            .fontSize(16)
                            .fontWeight(FontWeight.Bold)
                            .fontColor(this.primaryTextColor())
                            .width(100.percent)

                        this.buildModelGroup("fast")

                        Text(this.t("cursor_models_versatile_group"))
                            .fontSize(16)
                            .fontWeight(FontWeight.Bold)
                            .fontColor(this.primaryTextColor())
                            .width(100.percent)

                        this.buildModelGroup("versatile")
                    }
                    .width(100.percent)
                    .padding(left: 18, right: 18, top: 24, bottom: 24)
                }
                .width(100.percent)
                .height(100.percent)
                .scrollBar(BarState.Off)
            }
            .width(100.percent)
            .height(100.percent)
        }
        .hideTitleBar(true)
        .backgroundColor(0x00000000)
    }

    func goBack(): Unit { this.cursorStack.pop(animated: true) }
    func selectModel(modelId: String): Unit {
        this.cursorSelectedModelId = modelId
        this.goBack()
    }
    func isSelected(modelId: String): Bool { this.cursorSelectedModelId == modelId }

    @Builder
    func buildModelGroup(groupKey: String) {
        Column() {
            ForEach(
                this.cursorModels,
                itemGeneratorFunc: { item: CursorModelSnapshot, _: Int64 =>
                    if (item.groupKey == groupKey) {
                        this.buildModelRow(item)
                    }
                }
            )
        }
        .width(100.percent)
        .backgroundColor(this.surfaceColor())
        .borderRadius(24)
        .padding(top: 2, bottom: 2)
    }

    @Builder
    func buildModelRow(item: CursorModelSnapshot) {
        Row(space: 14) {
            Row() {
                Text(item.providerLabel).fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
            }
            .width(44)
            .height(44)
            .backgroundColor(this.mutedSurfaceColor())
            .borderRadius(14)
            .justifyContent(FlexAlign.Center)

            Text(item.title).fontSize(18).fontColor(this.primaryTextColor())
            Blank()
            if (this.isSelected(item.id)) {
                Text("ON").fontSize(13).fontColor(this.accentStrongColor())
            }
        }
        .width(100.percent)
        .height(72)
        .padding(left: 16, right: 16)
        .onClick({ _ => this.selectModel(item.id) })
    }

    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func mutedSurfaceColor(): Int64 { appThemeColor("mutedSurface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func accentStrongColor(): Int64 { appThemeColor("accentStrong", this.isDarkTheme()) }
}
