package ohos_app_cangjie_entry.pages.profile

import kit.AbilityKit.Want
import kit.ArkUI.*
import ohos.arkui.state_macro_manage.*
import ohos.business_exception.BusinessException
import std.collection.ArrayList
import ohos_app_cangjie_entry.domain.GitHubRepositoryCardSnapshot
import ohos_app_cangjie_entry.infra.runtime.{applyAppStatusBarStyle, getAppAbilityContext, notifyAppDataRefresh}
import ohos_app_cangjie_entry.ui.i18n.{appLocalizedText, appResolveLanguage}
import ohos_app_cangjie_entry.ui.theme.{appResolveIsDarkTheme, appThemeColor}

@Component
public class ProfilePage {
    @Consume var stack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var viewerLogin: String
    @Consume var viewerAvatarUrl: String
    @Consume var viewerProfileUrl: String
    @Consume var liveRepositoryCount: String
    @Consume var liveStarredCount: String
    @Consume var liveOrganizationCount: String
    @Consume var liveRepositories: ArrayList<GitHubRepositoryCardSnapshot>
    @Consume var pendingPageTitle: String
    @Consume var pendingPageMessage: String

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @State
    var profileRefreshing: Bool = false

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
    }

    public func build() {
        NavDestination() {
            Stack(alignContent: Alignment.TopStart) {
                this.buildProfileBackground()

                Column() {
                    this.buildProfileTopBar()

                    Refresh(RefreshOptions(refreshing: @Binder(profileRefreshing))) {
                        Scroll {
                            Column(space: 24) {
                                this.buildProfileIdentity()
                                this.buildProfileStats()
                                this.buildProfilePopular()
                            }
                            .width(100.percent)
                            .padding(left: 18, right: 18, top: 18, bottom: 32)
                        }
                        .width(100.percent)
                        .scrollBar(BarState.Off)
                    }
                    .layoutWeight(1)
                    .width(100.percent)
                    .onRefreshing({ =>
                        notifyAppDataRefresh("profile", {
                            =>
                            this.profileRefreshing = false
                        })
                    })
                    .align(Alignment.Top)
                }
                .width(100.percent)
                .height(100.percent)
                .padding(left: 18, right: 18, top: 18)
            }
            .width(100.percent)
            .height(100.percent)
        }
        .hideTitleBar(true)
        .backgroundColor(this.pageBackgroundColor())
    }

    func openSettings(): Unit {
        this.stack.pushPath(NavPathInfo(name: "settings", param: ""), options: NavigationOptions(animated: true))
    }

    func goBack(): Unit {
        this.stack.pop(animated: true)
    }

    func shareProfile(): Unit {
        if (this.viewerProfileUrl == "") {
            return
        }
        try {
            getAppAbilityContext().startAbility(Want(uri: this.viewerProfileUrl, action: "ohos.want.action.viewData"))
        } catch (_: BusinessException) {}
    }

    func displayName(): String {
        if (this.viewerLogin != "") {
            return this.viewerLogin
        }
        "GitHub"
    }

    func openPlaceholder(title: String, message: String): Unit {
        this.pendingPageTitle = title
        this.pendingPageMessage = message
        this.stack.pushPath(NavPathInfo(name: "placeholder", param: ""), options: NavigationOptions(animated: true))
    }

    func openRepositories(): Unit { this.openPlaceholder(this.t("repositories"), "Repository list is not fully implemented yet.") }
    func openStarred(): Unit { this.openPlaceholder(this.t("starred"), "Starred repositories page is not implemented yet.") }
    func openOrganizations(): Unit { this.openPlaceholder(this.t("organizations"), "Organizations page is not implemented yet.") }
    func openRepositoryCard(snapshot: GitHubRepositoryCardSnapshot): Unit {
        this.openPlaceholder(snapshot.name, "Repository actions from profile are not implemented yet.")
    }

    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func mutedSurfaceColor(): Int64 { appThemeColor("mutedSurface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }

    @Builder
    func buildProfileBackground() {
        Column() {}
            .width(100.percent)
            .height(100.percent)
            .backgroundColor(this.pageBackgroundColor())
            .expandSafeArea(types: [SafeAreaType.System], edges: [SafeAreaEdge.Top, SafeAreaEdge.Bottom])
    }

    @Builder
    func buildProfileTopBar() {
        Row() {
            Button("<")
                .width(40)
                .height(40)
                .backgroundColor(this.surfaceColor())
                .fontColor(this.primaryTextColor())
                .borderRadius(20)
                .onClick({ _ => this.goBack() })
            Blank()
            Row(space: 0) {
                Button("⚙")
                    .width(56)
                    .height(44)
                    .backgroundColor(this.surfaceColor())
                    .fontColor(this.primaryTextColor())
                    .borderRadius(22)
                    .onClick({ _ => this.openSettings() })
                Button("⇪")
                    .width(56)
                    .height(44)
                    .backgroundColor(this.surfaceColor())
                    .fontColor(this.primaryTextColor())
                    .borderRadius(22)
                    .onClick({ _ => this.shareProfile() })
            }
            .backgroundColor(this.surfaceColor())
            .borderRadius(24)
        }
        .width(100.percent)
    }

    @Builder
    func buildProfileIdentity() {
        Row(space: 16) {
            if (this.viewerAvatarUrl != "") {
                Image(this.viewerAvatarUrl)
                    .width(92)
                    .height(92)
                    .borderRadius(46)
                    .objectFit(ImageFit.Cover)
            } else {
                Row() {
                    Text("GH").fontSize(26).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
                }
                .width(92)
                .height(92)
                .backgroundColor(this.surfaceColor())
                .borderRadius(46)
                .justifyContent(FlexAlign.Center)
            }
            Column(space: 6) {
                Text(this.displayName()).fontSize(24).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
                if (this.viewerLogin != "") {
                    Text("@${this.viewerLogin}").fontSize(14).fontColor(this.secondaryTextColor())
                }
            }
            .alignItems(HorizontalAlign.Start)
            .justifyContent(FlexAlign.Center)
        }
        .width(100.percent)
    }

    @Builder
    func buildProfileStats() {
        Column() {
            this.buildProfileStatRow(0x4B4F5C, "⌘", "repositories", this.liveRepositoryCount, { => this.openRepositories() })
            this.buildProfileDivider()
            this.buildProfileStatRow(0xFFD54A, "☆", "starred", this.liveStarredCount, { => this.openStarred() })
            this.buildProfileDivider()
            this.buildProfileStatRow(0xF4A24B, "⌂", "organizations", this.liveOrganizationCount, { => this.openOrganizations() })
        }
        .width(100.percent)
        .backgroundColor(this.surfaceColor())
        .borderRadius(24)
        .padding(top: 2, bottom: 2)
    }

    @Builder
    func buildProfileStatRow(accentColor: Int64, iconText: String, titleKey: String, count: String, onTap: () -> Unit) {
        Row(space: 14) {
            Row() {
                Text(iconText).fontSize(15).fontWeight(FontWeight.Bold).fontColor(0xF8FAFC)
            }
            .width(40)
            .height(40)
            .backgroundColor(accentColor)
            .borderRadius(12)
            .justifyContent(FlexAlign.Center)

            Text(this.t(titleKey)).fontSize(18).fontWeight(FontWeight.Medium).fontColor(this.primaryTextColor())
            Blank()
            Text(count).fontSize(17).fontColor(this.secondaryTextColor())
            Text("›").fontSize(24).fontColor(this.secondaryTextColor())
        }
        .width(100.percent)
        .height(72)
        .padding(left: 18, right: 18)
        .onClick({ _ => onTap() })
    }

    @Builder
    func buildProfileDivider() {
        Blank()
            .width(100.percent)
            .height(1)
            .backgroundColor(this.mutedSurfaceColor())
    }

    @Builder
    func buildProfilePopular() {
        Column(space: 14) {
            Row(space: 10) {
                Text("☆").fontSize(18).fontColor(this.secondaryTextColor())
                Text(this.t("popular")).fontSize(18).fontWeight(FontWeight.Medium).fontColor(this.secondaryTextColor())
            }
            .width(100.percent)

            Column(space: 14) {
                ForEach(
                    this.liveRepositories,
                    itemGeneratorFunc: { item: GitHubRepositoryCardSnapshot, _: Int64 =>
                        this.buildProfileRepositoryCard(item)
                    }
                )
            }
            .width(100.percent)
        }
        .width(100.percent)
    }

    @Builder
    func buildProfileRepositoryCard(snapshot: GitHubRepositoryCardSnapshot) {
        Column(space: 12) {
            Row(space: 10) {
                if (this.viewerAvatarUrl != "") {
                    Image(this.viewerAvatarUrl)
                        .width(28)
                        .height(28)
                        .borderRadius(14)
                        .objectFit(ImageFit.Cover)
                }
                Text(this.displayName()).fontSize(13).fontColor(this.secondaryTextColor())
            }
            .width(100.percent)

            Text(snapshot.name).fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
            Text(snapshot.summary).fontSize(14).fontColor(this.primaryTextColor())
            Text(if (snapshot.isFork) { "Fork" } else if (snapshot.isPrivate) { "Private" } else { "Public" })
                .fontSize(13)
                .fontColor(this.secondaryTextColor())
        }
        .width(100.percent)
        .padding(18)
        .backgroundColor(this.surfaceColor())
        .borderRadius(28)
        .onClick({ _ => this.openRepositoryCard(snapshot) })
    }
}
