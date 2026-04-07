package ohos_app_cangjie_entry.pages.profile

import kit.AbilityKit.Want
import kit.ArkUI.*
import ohos.arkui.state_macro_manage.*
import ohos.business_exception.BusinessException
import std.collection.ArrayList
import ohos_app_cangjie_entry.domain.GitHubRepositoryCardSnapshot
import ohos_app_cangjie_entry.infra.runtime.getAppAbilityContext
import ohos_app_cangjie_entry.pages.common.detailBackgroundCommon
import ohos_app_cangjie_entry.ui.i18n.{appLocalizedText, appResolveLanguage}
import ohos_app_cangjie_entry.ui.theme.{appResolveIsDarkTheme, appThemeColor}

@Component
public class ProfilePage {
    @Consume var stack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var viewerLogin: String
    @Consume var viewerDisplayName: String
    @Consume var viewerAvatarUrl: String
    @Consume var viewerProfileUrl: String
    @Consume var liveRepositoryCount: String
    @Consume var liveStarredCount: String
    @Consume var liveOrganizationCount: String
    @Consume var liveRepositories: ArrayList<GitHubRepositoryCardSnapshot>

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    public func build() {
        NavDestination() {
            Stack() {
                detailBackgroundCommon(this.pageBackgroundColor())

                Scroll {
                    Column(space: 24) {
                        buildProfileTopBar(this)
                        buildProfileIdentity(this)
                        buildProfileStats(this)
                        buildProfilePopular(this)
                    }
                    .width(100.percent)
                    .padding(left: 18, right: 18, top: 18, bottom: 32)
                }
                .width(100.percent)
                .height(100.percent)
                .scrollBar(BarState.Off)
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

    func hasViewerAvatar(): Bool { this.viewerAvatarUrl != "" }
    func viewerAvatarUrlValue(): String { this.viewerAvatarUrl }
    func viewerLoginValue(): String { this.viewerLogin }
    func repositoryCountValue(): String { this.liveRepositoryCount }
    func starredCountValue(): String { this.liveStarredCount }
    func organizationCountValue(): String { this.liveOrganizationCount }
    func visibleRepositories(): ArrayList<GitHubRepositoryCardSnapshot> { this.liveRepositories }

    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func mutedSurfaceColor(): Int64 { appThemeColor("mutedSurface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
    func accentStrongColor(): Int64 { appThemeColor("accentStrong", this.isDarkTheme()) }
    func shadowColor(): Int64 { appThemeColor("shadow", this.isDarkTheme()) }
    func isDarkTheme(): Bool { appResolveIsDarkTheme(this.themePreference, this.systemColorMode) }
    func t(key: String): String { appLocalizedText(appResolveLanguage(this.languagePreference, this.systemLanguageCode), key) }
}

@Builder
func buildProfileTopBar(page: ProfilePage) {
    Row() {
        Button("<")
            .width(40)
            .height(40)
            .backgroundColor(page.surfaceColor())
            .fontColor(page.primaryTextColor())
            .borderRadius(20)
            .onClick({ _ => page.goBack() })
        Blank()
        Row(space: 0) {
            Button("⚙")
                .width(56)
                .height(44)
                .backgroundColor(page.surfaceColor())
                .fontColor(page.primaryTextColor())
                .borderRadius(22)
                .onClick({ _ => page.openSettings() })
            Button("⇪")
                .width(56)
                .height(44)
                .backgroundColor(page.surfaceColor())
                .fontColor(page.primaryTextColor())
                .borderRadius(22)
                .onClick({ _ => page.shareProfile() })
        }
        .backgroundColor(page.surfaceColor())
        .borderRadius(24)
    }
    .width(100.percent)
}

@Builder
func buildProfileIdentity(page: ProfilePage) {
    Row(space: 16) {
        if (page.hasViewerAvatar()) {
            Image(page.viewerAvatarUrlValue())
                .width(92)
                .height(92)
                .borderRadius(46)
                .objectFit(ImageFit.Cover)
        } else {
            Row() {
                Text("GH").fontSize(26).fontWeight(FontWeight.Bold).fontColor(page.primaryTextColor())
            }
            .width(92)
            .height(92)
            .backgroundColor(page.surfaceColor())
            .borderRadius(46)
            .justifyContent(FlexAlign.Center)
        }
        Column(space: 6) {
            Text(page.displayName()).fontSize(24).fontWeight(FontWeight.Bold).fontColor(page.primaryTextColor())
            if (page.viewerLoginValue() != "") {
                Text("@${page.viewerLoginValue()}").fontSize(14).fontColor(page.secondaryTextColor())
            }
        }
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Center)
    }
    .width(100.percent)
}

@Builder
func buildProfileStats(page: ProfilePage) {
    Column() {
        buildProfileStatRow(page, 0x4B4F5C, "⌘", page.t("repositories"), page.repositoryCountValue())
        buildProfileDivider(page)
        buildProfileStatRow(page, 0xFFD54A, "☆", page.t("starred"), page.starredCountValue())
        buildProfileDivider(page)
        buildProfileStatRow(page, 0xF4A24B, "⌂", page.t("organizations"), page.organizationCountValue())
    }
    .width(100.percent)
    .backgroundColor(page.surfaceColor())
    .borderRadius(24)
    .padding(top: 2, bottom: 2)
}

@Builder
func buildProfileStatRow(page: ProfilePage, accentColor: Int64, iconText: String, title: String, count: String) {
    Row(space: 14) {
        Row() {
            Text(iconText).fontSize(15).fontWeight(FontWeight.Bold).fontColor(0xF8FAFC)
        }
        .width(40)
        .height(40)
        .backgroundColor(accentColor)
        .borderRadius(12)
        .justifyContent(FlexAlign.Center)

        Text(title).fontSize(18).fontWeight(FontWeight.Medium).fontColor(page.primaryTextColor())
        Blank()
        Text(count).fontSize(17).fontColor(page.secondaryTextColor())
        Text("›").fontSize(24).fontColor(page.secondaryTextColor())
    }
    .width(100.percent)
    .height(72)
    .padding(left: 18, right: 18)
}

@Builder
func buildProfileDivider(page: ProfilePage) {
    Blank()
        .width(100.percent)
        .height(1)
        .backgroundColor(page.mutedSurfaceColor())
}

@Builder
func buildProfilePopular(page: ProfilePage) {
    Column(space: 14) {
        Row(space: 10) {
            Text("☆").fontSize(18).fontColor(page.secondaryTextColor())
            Text(page.t("popular")).fontSize(18).fontWeight(FontWeight.Medium).fontColor(page.secondaryTextColor())
        }
        .width(100.percent)

        Column(space: 14) {
            ForEach(
                page.visibleRepositories(),
                itemGeneratorFunc: { item: GitHubRepositoryCardSnapshot, _: Int64 =>
                    buildProfileRepositoryCard(page, item)
                }
            )
        }
        .width(100.percent)
    }
    .width(100.percent)
}

@Builder
func buildProfileRepositoryCard(page: ProfilePage, snapshot: GitHubRepositoryCardSnapshot) {
    Column(space: 12) {
        Row(space: 10) {
            if (page.hasViewerAvatar()) {
                Image(page.viewerAvatarUrlValue())
                    .width(28)
                    .height(28)
                    .borderRadius(14)
                    .objectFit(ImageFit.Cover)
            }
            Text(page.displayName()).fontSize(13).fontColor(page.secondaryTextColor())
        }
        .width(100.percent)

        Text(snapshot.name).fontSize(18).fontWeight(FontWeight.Bold).fontColor(page.primaryTextColor())
        Text(snapshot.summary).fontSize(14).fontColor(page.primaryTextColor())
        Text(if (snapshot.isFork) { "Fork" } else if (snapshot.isPrivate) { "Private" } else { "Public" })
            .fontSize(13)
            .fontColor(page.secondaryTextColor())
    }
    .width(100.percent)
    .padding(18)
    .backgroundColor(page.surfaceColor())
    .borderRadius(28)
}
