package ohos_app_cangjie_entry.app

import kit.ArkUI.*
import std.collection.ArrayList
import ohos.arkui.state_macro_manage.*
import ohos_app_cangjie_entry.domain.{ExploreLaneSnapshot, InboxItemSnapshot, RepositorySnapshot, TaskSnapshot}
import ohos_app_cangjie_entry.services.platform.{activeAccountSnapshot, defaultWorkplace, exploreLane, inboxItem, primaryRepositoryId, repositorySnapshot, workplaceSnapshot}
import ohos_app_cangjie_entry.services.agent.{taskIdForIssue, taskSnapshot}
import ohos_app_cangjie_entry.ui.theme.{appResolveIsDarkTheme, appThemeColor}
import ohos_app_cangjie_entry.ui.i18n.{appLocalizedText, appResolveLanguage}

@Component
public class AppShell {
    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @State
    var isAuthenticated: Bool = false

    @State
    var authStage: String = "welcome"

    @State
    var activeTab: String = "home"

    @State
    var showWorkplacePicker: Bool = false

    @Provide
    var themePreference: String = "system"

    @Provide
    var languagePreference: String = "system"

    @Provide
    var currentWorkplace: String = "github"

    @Provide
    var selectedRepository: String = ""

    @Provide
    var selectedIssue: String = ""

    @Provide
    var selectedTask: String = ""

    @Provide
    var draftPrStatusKey: String = "draft_pr_pending"

    @State
    var authMessage: String = ""

    protected override func aboutToAppear(): Unit {
        this.ensureInitialSelection()
    }

    public func build() {
        if (this.isAuthenticated) {
            this.buildMainScene()
        } else {
            this.buildAuthScene()
        }
    }

    @Builder
    func buildAuthScene() {
        Stack() {
            Column() {}
                .width(100.percent)
                .height(100.percent)
                .backgroundColor(0x05070A)

            if (this.authStage == "welcome") {
                buildAuthWelcome(this)
            } else if (this.authStage == "credentials") {
                buildAuthCredentials(this)
            } else {
                buildAuthConnected(this)
            }
        }
        .width(100.percent)
        .height(100.percent)
    }

    @Builder
    func buildMainScene() {
        Stack() {
            this.buildRootBackground()

            Scroll {
                Column(space: 18) {
                    buildTopBar(this)
                    buildActiveTabContent(this)
                }
                .width(100.percent)
                .padding(left: 18, right: 18, top: 16, bottom: 132)
            }
            .width(100.percent)
            .height(100.percent)
            .scrollBar(BarState.Off)

            if (this.showWorkplacePicker) {
                Column() {}
                    .width(100.percent)
                    .height(100.percent)
                    .backgroundColor(0x33000000)
                    .onClick({ _ => this.toggleWorkplacePicker(false) })

                buildWorkplacePicker(this)
            }

            Column() {
                Blank()
                buildFloatingNavigation(this)
            }
            .width(100.percent)
            .height(100.percent)
        }
        .width(100.percent)
        .height(100.percent)
    }

    @Builder
    func buildRootBackground() {
        Column() {
            Column() {}
                .width(100.percent)
                .height(260)
                .backgroundColor(this.heroStartColor())
                .opacity(0.96)

            Blank()
        }
        .width(100.percent)
        .height(100.percent)
        .backgroundColor(this.pageBackgroundColor())
    }

    func beginAuth(): Unit {
        getUIContext().animateTo(AnimateParam(duration: 220, curve: Curve.Ease), { =>
            this.authStage = "credentials"
            this.authMessage = this.t("auth_subtitle")
        })
    }

    func returnToAuthWelcome(): Unit {
        getUIContext().animateTo(AnimateParam(duration: 220, curve: Curve.Ease), { =>
            this.authStage = "welcome"
            this.authMessage = ""
        })
    }

    func confirmAuth(): Unit {
        getUIContext().animateTo(AnimateParam(duration: 220, curve: Curve.Ease), { =>
            this.authStage = "connected"
            this.authMessage = this.t("auth_connected_body")
        })
    }

    func enterWorkspace(): Unit {
        getUIContext().animateTo(AnimateParam(duration: 240, curve: Curve.Ease), { =>
            this.isAuthenticated = true
            this.activeTab = "home"
            this.showWorkplacePicker = false
            this.selectedRepository = primaryRepositoryId(this.currentWorkplace)
            this.selectedIssue = repositorySnapshot(this.selectedRepository).primaryIssueId
            this.selectedTask = taskIdForIssue(this.selectedIssue)
            this.draftPrStatusKey = "draft_pr_pending"
        })
    }

    func signOut(): Unit {
        getUIContext().animateTo(AnimateParam(duration: 220, curve: Curve.Ease), { =>
            this.isAuthenticated = false
            this.authStage = "welcome"
            this.authMessage = ""
        })
    }

    func handleTabTap(tab: String): Unit {
        if (tab == "home" && this.activeTab == "home") {
            this.toggleWorkplacePicker(!this.showWorkplacePicker)
            return
        }
        getUIContext().animateTo(AnimateParam(duration: 200, curve: Curve.Ease), { =>
            this.activeTab = tab
            this.showWorkplacePicker = false
        })
    }

    func toggleWorkplacePicker(show: Bool): Unit {
        getUIContext().animateTo(AnimateParam(duration: 180, curve: Curve.Ease), { =>
            this.showWorkplacePicker = show
        })
    }

    func switchWorkplace(workplaceId: String): Unit {
        let repositoryId = primaryRepositoryId(workplaceId)
        let repository = repositorySnapshot(repositoryId)
        getUIContext().animateTo(AnimateParam(duration: 200, curve: Curve.Ease), { =>
            this.currentWorkplace = workplaceId
            this.selectedRepository = repositoryId
            this.selectedIssue = repository.primaryIssueId
            this.selectedTask = taskIdForIssue(repository.primaryIssueId)
            this.showWorkplacePicker = false
        })
    }

    func createScratchRepository(): Unit {
        this.authMessage = this.t("draft_pr_pending")
    }

    func ensureInitialSelection(): Unit {
        if (this.currentWorkplace == "") {
            this.currentWorkplace = defaultWorkplace()
        }
        if (this.selectedRepository == "") {
            this.selectedRepository = primaryRepositoryId(this.currentWorkplace)
        }
        if (this.selectedIssue == "") {
            this.selectedIssue = repositorySnapshot(this.selectedRepository).primaryIssueId
        }
        if (this.selectedTask == "") {
            this.selectedTask = taskIdForIssue(this.selectedIssue)
        }
    }

    func currentWorkplaceTitle(): String { this.t(workplaceSnapshot(this.currentWorkplace).titleKey) }
    func currentWorkplaceSummary(): String { this.t(workplaceSnapshot(this.currentWorkplace).summaryKey) }
    func currentWorkplaceHeroTitle(): String { this.t(workplaceSnapshot(this.currentWorkplace).heroTitleKey) }
    func primaryHomeRepository(): RepositorySnapshot { repositorySnapshot(primaryRepositoryId(this.currentWorkplace)) }
    func secondaryHomeRepository(): RepositorySnapshot { repositorySnapshot("bff") }
    func tertiaryHomeRepository(): RepositorySnapshot { repositorySnapshot("orchestrator") }
    func visibleRepositories(): ArrayList<RepositorySnapshot> {
        let items = ArrayList<RepositorySnapshot>()
        items.add(this.primaryHomeRepository())
        items.add(this.secondaryHomeRepository())
        items.add(this.tertiaryHomeRepository())
        items
    }
    func focusedTask(): TaskSnapshot { taskSnapshot(this.selectedTask) }
    func reviewTask(): TaskSnapshot { taskSnapshot("repoPolish") }
    func inboxPrimary(): InboxItemSnapshot { inboxItem(1) }
    func inboxSecondary(): InboxItemSnapshot { inboxItem(2) }
    func inboxTertiary(): InboxItemSnapshot { inboxItem(3) }
    func firstExploreLane(): ExploreLaneSnapshot { exploreLane(1) }
    func secondExploreLane(): ExploreLaneSnapshot { exploreLane(2) }
    func isActiveTab(tab: String): Bool { this.activeTab == tab }
    func isCurrentWorkplace(workplaceId: String): Bool { this.currentWorkplace == workplaceId }
    func themePreferenceValue(): String { this.themePreference }
    func languagePreferenceValue(): String { this.languagePreference }
    func mainTitle(): String {
        if (this.activeTab == "home") {
            this.currentWorkplaceTitle()
        } else if (this.activeTab == "inbox") {
            this.t("inbox")
        } else if (this.activeTab == "explore") {
            this.t("explore")
        } else {
            this.t("profile")
        }
    }
    func mainSubtitle(): String {
        if (this.activeTab == "home") {
            this.currentWorkplaceSummary()
        } else if (this.activeTab == "inbox") {
            this.t("inbox_subtitle")
        } else if (this.activeTab == "explore") {
            this.t("explore_subtitle")
        } else {
            this.t("profile_subtitle")
        }
    }
    func accountCaption(): String {
        let account = activeAccountSnapshot()
        "${this.t("profile_account_prefix")}: ${this.t(account.providerKey)} / ${account.accountLabel}"
    }
    func applyRootPreference(kind: String, value: String): Unit {
        getUIContext().animateTo(AnimateParam(duration: 180, curve: Curve.Ease), { =>
            if (kind == "theme") {
                this.themePreference = value
            } else {
                this.languagePreference = value
            }
        })
    }
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
    func authMessageText(): String { if (this.authMessage == "") { this.t("auth_subtitle") } else { this.authMessage } }
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func surfaceStrongColor(): Int64 { appThemeColor("surfaceStrong", this.isDarkTheme()) }
    func mutedSurfaceColor(): Int64 { appThemeColor("mutedSurface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
    func accentStrongColor(): Int64 { appThemeColor("accentStrong", this.isDarkTheme()) }
    func heroStartColor(): Int64 { appThemeColor("heroStart", this.isDarkTheme()) }
    func heroCardColor(): Int64 { appThemeColor("heroCard", this.isDarkTheme()) }
    func heroTextColor(): Int64 { appThemeColor("heroText", this.isDarkTheme()) }
    func heroSubTextColor(): Int64 { appThemeColor("heroSubText", this.isDarkTheme()) }
    func navBarColor(): Int64 { appThemeColor("navBar", this.isDarkTheme()) }
    func navSelectionColor(): Int64 { appThemeColor("navSelection", this.isDarkTheme()) }
    func shadowColor(): Int64 { appThemeColor("shadow", this.isDarkTheme()) }
}
