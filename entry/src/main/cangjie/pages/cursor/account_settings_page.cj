package ohos_app_cangjie_entry.pages.cursor

import kit.AbilityKit.Want
import kit.ArkUI.*
import ohos.arkui.state_macro_manage.*
import ohos.base.UIThread
import ohos.business_exception.BusinessException
import std.collection.ArrayList
import ohos_app_cangjie_entry.domain.CursorConversationSnapshot
import ohos_app_cangjie_entry.infra.runtime.{applyAppStatusBarStyle, getAppAbilityContext}
import ohos_app_cangjie_entry.services.cursor.{clearStoredCursorApiKey, loadStoredCursorApiKey, loadStoredCursorConversations, validateCursorSession, persistStoredCursorApiKey}
import ohos_app_cangjie_entry.ui.i18n.{appLocalizedText, appResolveLanguage}
import ohos_app_cangjie_entry.ui.theme.{appResolveIsDarkTheme, appThemeColor}

@Component
public class CursorAccountSettingsPage {
    @Consume var cursorStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var cursorConnectionReady: Bool
    @Consume var cursorConversations: ArrayList<CursorConversationSnapshot>
    @Consume var cursorConversationId: String
    @Consume var cursorConversationTitle: String
    @Consume var cursorSelectedModelId: String

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @State var cursorApiKeyDraft: String = ""
    @State var hasStoredApiKey: Bool = false
    @State var validationMessage: String = ""
    @State var connectionValidated: Bool = false
    @State var showFailureDialogVisible: Bool = false
    @State var failureDialogTitle: String = ""
    @State var failureDialogBody: String = ""

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
        let storedApiKey = loadStoredCursorApiKey()
        this.cursorApiKeyDraft = storedApiKey
        this.hasStoredApiKey = storedApiKey != ""
    }

    public func build() {
        NavDestination() {
            Stack(alignContent: Alignment.TopStart) {
                cursorBackgroundCommon(this.pageBackgroundColor())

                Column(space: 18) {
                    Row(space: 10) {
                        Button("<")
                            .width(44)
                            .height(44)
                            .backgroundColor(this.surfaceColor())
                            .fontColor(this.primaryTextColor())
                            .borderRadius(22)
                            .onClick({ _ => this.goBack() })
                        Text(this.t("cursor_account"))
                            .fontSize(22)
                            .fontWeight(FontWeight.Bold)
                            .fontColor(this.primaryTextColor())
                    }
                    .width(100.percent)

                    Column(space: 12) {
                        Text(this.t("cursor_api_key_title"))
                            .fontSize(18)
                            .fontWeight(FontWeight.Bold)
                            .fontColor(this.primaryTextColor())

                        Text(this.t("cursor_api_key_desc"))
                            .fontSize(14)
                            .lineHeight(22)
                            .fontColor(this.secondaryTextColor())

                        TextInput(placeholder: this.t("cursor_api_key_placeholder"), text: this.cursorApiKeyDraft)
                            .width(100.percent)
                            .height(54)
                            .backgroundColor(this.surfaceColor())
                            .fontColor(this.primaryTextColor())
                            .borderRadius(18)
                            .padding(left: 16, right: 16)
                            .onChange({ value => this.cursorApiKeyDraft = value })

                        if (this.validationMessage != "") {
                            Text(this.validationMessage)
                                .fontSize(13)
                                .fontColor(if (this.connectionValidated) { this.accentStrongColor() } else { this.secondaryTextColor() })
                                .width(100.percent)
                        }
                    }
                    .width(100.percent)
                    .padding(left: 18, right: 18, top: 18, bottom: 18)
                    .backgroundColor(this.surfaceColor())
                    .borderRadius(24)

                    Column(space: 8) {
                        Button(this.t("cursor_open_dashboard"))
                            .width(100.percent)
                            .height(50)
                            .backgroundColor(this.mutedSurfaceColor())
                            .fontColor(this.primaryTextColor())
                            .fontSize(16)
                            .borderRadius(16)
                            .onClick({ _ => this.openCursorDashboard() })

                        Text(this.t("cursor_api_key_path_hint"))
                            .width(100.percent)
                            .fontSize(12)
                            .lineHeight(18)
                            .fontColor(this.secondaryTextColor())
                    }

                    Button(this.t("save"))
                        .width(100.percent)
                        .height(50)
                        .backgroundColor(this.navBarColor())
                        .fontColor(this.primaryTextColor())
                        .fontSize(16)
                        .borderRadius(16)
                        .onClick({ _ => this.saveCursorApiKey() })

                    if (this.hasStoredApiKey) {
                        Button(this.t("cursor_clear_api_key"))
                            .width(100.percent)
                            .height(50)
                            .backgroundColor(this.mutedSurfaceColor())
                            .fontColor(this.secondaryTextColor())
                            .fontSize(16)
                            .borderRadius(16)
                            .onClick({ _ => this.clearCursorApiKey() })
                    }
                }
                .width(100.percent)
                .padding(left: 18, right: 18, top: 18, bottom: 32)

                if (this.showFailureDialogVisible) {
                    Column() {}
                        .width(100.percent)
                        .height(100.percent)
                        .backgroundColor(0x55000000)
                        .onClick({ _ => this.closeFailureDialog() })

                    Column() {
                        this.failureDialogBuilder()
                    }
                    .width(100.percent)
                    .height(100.percent)
                    .justifyContent(FlexAlign.Center)
                }
            }
            .width(100.percent)
            .height(100.percent)
        }
        .hideTitleBar(true)
        .backgroundColor(this.pageBackgroundColor())
    }

    @Builder
    func failureDialogBuilder() {
        Column(space: 18) {
            Text(this.failureDialogTitle)
                .width(100.percent)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.primaryTextColor())

            Text(this.failureDialogBody)
                .width(100.percent)
                .fontSize(14)
                .lineHeight(22)
                .fontColor(this.secondaryTextColor())

            Button(this.t("close"))
                .width(100.percent)
                .height(46)
                .backgroundColor(this.navBarColor())
                .fontColor(this.primaryTextColor())
                .fontSize(15)
                .borderRadius(16)
                .onClick({ _ => this.closeFailureDialog() })
        }
        .width(100.percent)
        .padding(left: 18, right: 18, top: 18, bottom: 18)
        .backgroundColor(this.surfaceColor())
        .borderRadius(24)
        .margin(left: 20, right: 20)
    }

    func goBack(): Unit { this.cursorStack.pop(animated: true) }
    func openExternalUrl(url: String, successMessage: String): Unit {
        try {
            getAppAbilityContext().startAbility(Want(uri: url, action: "ohos.want.action.viewData"))
            this.validationMessage = successMessage
        } catch (_: BusinessException) {
            this.validationMessage = this.t("cursor_browser_open_failed")
        }
    }
    func openCursorDashboard(): Unit {
        this.openExternalUrl(CURSOR_DASHBOARD_URL, this.t("cursor_dashboard_opened"))
    }
    func saveCursorApiKey(): Unit {
        spawn { => persistStoredCursorApiKey(this.cursorApiKeyDraft) }
        this.hasStoredApiKey = this.cursorApiKeyDraft != ""
        if (this.cursorApiKeyDraft == "") {
            this.connectionValidated = false
            this.cursorConnectionReady = false
            this.cursorConversations = loadStoredCursorConversations()
            this.cursorConversationId = ""
            this.cursorConversationTitle = this.t("cursor_new_conversation")
            this.validationMessage = this.t("cursor_api_key_cleared")
            return
        }
        this.validationMessage = this.t("cursor_api_key_testing")
        this.loadCursorAgents()
    }
    func clearCursorApiKey(): Unit {
        this.cursorApiKeyDraft = ""
        this.hasStoredApiKey = false
        spawn { => clearStoredCursorApiKey() }
        this.connectionValidated = false
        this.cursorConnectionReady = false
        this.cursorConversations = loadStoredCursorConversations()
        this.cursorConversationId = ""
        this.cursorConversationTitle = this.t("cursor_new_conversation")
        this.validationMessage = this.t("cursor_api_key_cleared")
        this.closeFailureDialog()
    }
    func showFailureDialog(title: String, body: String): Unit {
        this.failureDialogTitle = title
        this.failureDialogBody = body
        this.showFailureDialogVisible = true
    }
    func closeFailureDialog(): Unit {
        this.showFailureDialogVisible = false
    }
    func describeCursorFailure(message: String): String {
        if (message.contains("Cursor API 400")) {
            this.t("cursor_error_400")
        } else if (message.contains("Cursor API 401")) {
            this.t("cursor_error_401")
        } else if (message.contains("Cursor API 403")) {
            this.t("cursor_error_403")
        } else if (message.contains("Cursor API 404")) {
            this.t("cursor_error_404")
        } else if (message.contains("Cursor API 409")) {
            this.t("cursor_error_409")
        } else if (message.contains("Cursor API 429")) {
            this.t("cursor_error_429")
        } else if (message.contains("Cursor API 500")) {
            this.t("cursor_error_500")
        } else if (message.contains("network error")) {
            this.t("cursor_error_network")
        } else if (message.contains("returned no response")) {
            this.t("cursor_error_no_response")
        } else {
            "${this.t("cursor_error_unknown")}\n\n${message}"
        }
    }
    func loadCursorAgents(): Unit {
        validateCursorSession(
            this.cursorApiKeyDraft,
            { items =>
                spawn(UIThread) {
                    this.connectionValidated = true
                    this.cursorConnectionReady = true
                    this.cursorConversations = items
                    this.hasStoredApiKey = true
                    if (items.size > 0) {
                        let first = items[0]
                        this.cursorConversationId = first.id
                        this.cursorConversationTitle = first.title
                        this.cursorSelectedModelId = "claude-haiku-4.5"
                    } else {
                        this.cursorConversationId = ""
                        this.cursorConversationTitle = this.t("cursor_new_conversation")
                    }
                    this.validationMessage = "${this.t("cursor_api_key_valid")} (${items.size})"
                    this.goBack()
                }
            },
            { message =>
                spawn(UIThread) {
                    this.connectionValidated = false
                    this.cursorConnectionReady = false
                    this.validationMessage = message
                    this.showFailureDialog(this.t("cursor_connect_failed_title"), this.describeCursorFailure(message))
                }
            }
        )
    }
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func mutedSurfaceColor(): Int64 { appThemeColor("mutedSurface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
    func accentStrongColor(): Int64 { appThemeColor("accentStrong", this.isDarkTheme()) }
    func navBarColor(): Int64 { appThemeColor("navBar", this.isDarkTheme()) }
}
