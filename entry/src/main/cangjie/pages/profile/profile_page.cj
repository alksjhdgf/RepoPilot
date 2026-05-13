package ohos_app_cangjie_entry.pages.profile

import kit.ArkUI.*
import kit.AbilityKit.Want
import ohos.arkui.state_macro_manage.*
import ohos.base.UIThread
import ohos.business_exception.BusinessException
import std.collection.ArrayList
import ohos_app_cangjie_entry.domain.{GitHubEventSnapshot, GitHubGistSnapshot, GitHubIssueSnapshot, GitHubProfileMetricsSnapshot, GitHubPullRequestSnapshot, GitHubRepositoryCardSnapshot, GitHubRepositoryDetailSnapshot, GitHubSimpleUserSnapshot, GitHubUserProfileSnapshot, GitHubViewerSnapshot}
import ohos_app_cangjie_entry.infra.runtime.{applyAppStatusBarStyle, getAppAbilityContext, shareExternalLink}
import ohos_app_cangjie_entry.services.agent.taskIdForIssue
import ohos_app_cangjie_entry.services.app.{refreshGitHubProfileData, refreshGitHubRepositoryBundle}
import ohos_app_cangjie_entry.services.github.{fetchGitHubUserActivity, fetchGitHubUserFollowers, fetchGitHubUserFollowing, fetchGitHubUserGists, fetchGitHubUserIssues, fetchGitHubUserProfile, fetchGitHubUserPullRequests, fetchGitHubUserRepositories}
import ohos_app_cangjie_entry.ui.i18n.{appLocalizedText, appResolveLanguage}
import ohos_app_cangjie_entry.ui.theme.{appResolveIsDarkTheme, appThemeColor}

@Component
public class ProfilePage {
    @Consume var homeStack: NavPathStack
    @Consume var themePreference: String
    @Consume var languagePreference: String
    @Consume var viewerLogin: String
    @Consume var viewerAvatarUrl: String
    @Consume var viewerProfileUrl: String
    @Consume var sharedAuthAccessToken: String
    @Consume var liveRepositoryCount: String
    @Consume var liveStarredCount: String
    @Consume var liveOrganizationCount: String
    @Consume var liveGistCount: String
    @Consume var liveFollowerCount: String
    @Consume var liveFollowingCount: String
    @Consume var liveRepositories: ArrayList<GitHubRepositoryCardSnapshot>
    @Consume var selectedRepository: String
    @Consume var selectedIssue: String
    @Consume var selectedPullRequest: String
    @Consume var selectedTask: String
    @Consume var liveRepositoryDetail: GitHubRepositoryDetailSnapshot
    @Consume var liveIssues: ArrayList<GitHubIssueSnapshot>
    @Consume var livePullRequests: ArrayList<GitHubPullRequestSnapshot>
    @Consume var selectedGitHubUserLogin: String
    @Consume var selectedGitHubUserProfile: GitHubUserProfileSnapshot
    @Consume var selectedGitHubUserRepositories: ArrayList<GitHubRepositoryCardSnapshot>
    @Consume var selectedGitHubUserIssues: ArrayList<GitHubIssueSnapshot>
    @Consume var selectedGitHubUserPullRequests: ArrayList<GitHubPullRequestSnapshot>
    @Consume var selectedGitHubUserGists: ArrayList<GitHubGistSnapshot>
    @Consume var selectedGitHubFollowers: ArrayList<GitHubSimpleUserSnapshot>
    @Consume var selectedGitHubFollowing: ArrayList<GitHubSimpleUserSnapshot>

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @State
    var profileRefreshing: Bool = false
    @State
    var currentUserIssues: ArrayList<GitHubIssueSnapshot> = ArrayList<GitHubIssueSnapshot>()
    @State
    var currentUserPullRequests: ArrayList<GitHubPullRequestSnapshot> = ArrayList<GitHubPullRequestSnapshot>()
    @State
    var currentUserActivity: ArrayList<GitHubEventSnapshot> = ArrayList<GitHubEventSnapshot>()

    protected override func aboutToAppear(): Unit {
        applyAppStatusBarStyle(this.isDarkTheme())
        this.refreshProfileContent()
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
                                this.buildProfileActivity()
                                this.buildProfilePopular()
                            }
                            .width(100.percent)
                            .padding(left: 18, right: 18, top: 18, bottom: 120)
                        }
                        .width(100.percent)
                        .scrollBar(BarState.Off)
                    }
                    .layoutWeight(1)
                    .width(100.percent)
                    .onRefreshing({ =>
                        this.refreshProfileContent(showRefreshIndicator: true)
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
        this.homeStack.pushPath(NavPathInfo(name: "settings", param: ""), options: NavigationOptions(animated: true))
    }

    func goBack(): Unit {
        this.homeStack.pop(animated: true)
    }

    func runOnUi(task: () -> Unit): Unit {
        spawn(UIThread) { => task() }
    }

    func refreshProfileContent(showRefreshIndicator!: Bool = false): Unit {
        if (showRefreshIndicator) {
            this.profileRefreshing = true
        }
        if (this.sharedAuthAccessToken == "") {
            this.profileRefreshing = false
            return
        }
        refreshGitHubProfileData(
            this.sharedAuthAccessToken,
            { snapshot => this.applyViewer(snapshot) },
            { snapshot => this.applyMetrics(snapshot) },
            { repositories => this.applyRepositories(repositories) },
            { _ => this.runOnUi({ => this.profileRefreshing = false }) }
        )
    }

    func applyViewer(snapshot: GitHubViewerSnapshot): Unit {
        this.runOnUi({
            =>
            this.viewerLogin = snapshot.login
            this.viewerAvatarUrl = snapshot.avatarUrl
            this.viewerProfileUrl = snapshot.profileUrl
        })
        if (snapshot.login != "" && this.sharedAuthAccessToken != "") {
            this.refreshCurrentUserDetails(snapshot.login)
        }
    }

    func applyMetrics(snapshot: GitHubProfileMetricsSnapshot): Unit {
        this.runOnUi({
            =>
            this.liveRepositoryCount = snapshot.repositoryCount
            this.liveStarredCount = snapshot.starredCount
            this.liveOrganizationCount = snapshot.organizationCount
        })
    }

    func applyRepositories(repositories: ArrayList<GitHubRepositoryCardSnapshot>): Unit {
        this.runOnUi({
            =>
            this.liveRepositories = repositories
            this.profileRefreshing = false
        })
    }

    func refreshCurrentUserDetails(login: String): Unit {
        fetchGitHubUserIssues(this.sharedAuthAccessToken, login, { items => this.runOnUi({ =>
            this.currentUserIssues = items
            this.selectedGitHubUserIssues = items
        }) }, { _ => this.runOnUi({ =>
            this.currentUserIssues = ArrayList<GitHubIssueSnapshot>()
            this.selectedGitHubUserIssues = ArrayList<GitHubIssueSnapshot>()
        }) })
        fetchGitHubUserPullRequests(this.sharedAuthAccessToken, login, { items => this.runOnUi({ =>
            this.currentUserPullRequests = items
            this.selectedGitHubUserPullRequests = items
        }) }, { _ => this.runOnUi({ =>
            this.currentUserPullRequests = ArrayList<GitHubPullRequestSnapshot>()
            this.selectedGitHubUserPullRequests = ArrayList<GitHubPullRequestSnapshot>()
        }) })
        fetchGitHubUserActivity(this.sharedAuthAccessToken, login, { items => this.runOnUi({ =>
            this.currentUserActivity = items
        }) }, { _ => this.runOnUi({ =>
            this.currentUserActivity = ArrayList<GitHubEventSnapshot>()
        }) })
    }

    func shareProfile(): Unit {
        if (this.viewerProfileUrl == "") {
            return
        }
        shareExternalLink(this.viewerProfileUrl, title: this.displayName(), abstract: this.t("share_profile"))
    }

    func displayName(): String {
        if (this.viewerLogin != "") {
            return this.viewerLogin
        }
        "GitHub"
    }
    func repositoryDisplayName(snapshot: GitHubRepositoryCardSnapshot): String {
        let parts = snapshot.name.split("/")
        if (parts.size > 0) {
            return parts[parts.size - 1]
        }
        snapshot.name
    }
    func visiblePopularRepositories(): ArrayList<GitHubRepositoryCardSnapshot> {
        let topItems = ArrayList<GitHubRepositoryCardSnapshot>()
        let usedNames = ArrayList<String>()
        var rank: Int64 = 0
        while (rank < 5) {
            var found = false
            var best = GitHubRepositoryCardSnapshot("", "", "", false, false, 0, false)
            var bestStars: Int64 = -1
            for (item in this.liveRepositories) {
                var alreadyUsed = false
                for (usedName in usedNames) {
                    if (usedName == item.name) {
                        alreadyUsed = true
                        break
                    }
                }
                if (alreadyUsed) {
                    continue
                }
                let stars = item.starCount
                if (!found || stars > bestStars) {
                    found = true
                    best = item
                    bestStars = stars
                }
            }
            if (!found) {
                break
            }
            topItems.add(best)
            usedNames.add(best.name)
            rank += 1
        }
        topItems
    }

    func openRepositories(): Unit {
        this.homeStack.pushPath(NavPathInfo(name: "repositoriesPage", param: ""), options: NavigationOptions(animated: true))
    }
    func openStarred(): Unit {
        this.homeStack.pushPath(NavPathInfo(name: "starredRepositoriesPage", param: ""), options: NavigationOptions(animated: true))
    }
    func openOrganizations(): Unit {
        this.homeStack.pushPath(NavPathInfo(name: "organizationsPage", param: ""), options: NavigationOptions(animated: true))
    }
    func openCurrentUserIssues(): Unit {
        this.prepareCurrentViewerDetail()
        this.selectedGitHubUserIssues = this.currentUserIssues
        this.homeStack.pushPath(NavPathInfo(name: "userIssuesPage", param: ""), options: NavigationOptions(animated: true))
    }
    func openCurrentUserPullRequests(): Unit {
        this.prepareCurrentViewerDetail()
        this.selectedGitHubUserPullRequests = this.currentUserPullRequests
        this.homeStack.pushPath(NavPathInfo(name: "userPullRequestsPage", param: ""), options: NavigationOptions(animated: true))
    }
    func openGists(): Unit {
        this.prepareCurrentViewerDetail()
        this.homeStack.pushPath(NavPathInfo(name: "userGistsPage", param: ""), options: NavigationOptions(animated: true))
    }
    func openFollowers(): Unit {
        this.prepareCurrentViewerDetail()
        this.homeStack.pushPath(NavPathInfo(name: "userFollowersPage", param: ""), options: NavigationOptions(animated: true))
    }
    func openFollowing(): Unit {
        this.prepareCurrentViewerDetail()
        this.homeStack.pushPath(NavPathInfo(name: "userFollowingPage", param: ""), options: NavigationOptions(animated: true))
    }
    func openCurrentUserActivity(): Unit {
        this.prepareCurrentViewerDetail()
        this.homeStack.pushPath(NavPathInfo(name: "userActivityPage", param: ""), options: NavigationOptions(animated: true))
    }
    func openRepositoryCard(snapshot: GitHubRepositoryCardSnapshot): Unit {
        this.openRepository(snapshot.name)
    }
    func prepareCurrentViewerDetail(): Unit {
        if (this.sharedAuthAccessToken == "" || this.viewerLogin == "") {
            return
        }
        this.selectedGitHubUserLogin = this.viewerLogin
        this.selectedGitHubUserProfile = GitHubUserProfileSnapshot("", "", "", "", "", "", "", "", "0", "0", "0", "0")
        this.selectedGitHubUserRepositories = ArrayList<GitHubRepositoryCardSnapshot>()
        this.selectedGitHubUserGists = ArrayList<GitHubGistSnapshot>()
        this.selectedGitHubFollowers = ArrayList<GitHubSimpleUserSnapshot>()
        this.selectedGitHubFollowing = ArrayList<GitHubSimpleUserSnapshot>()
        this.selectedGitHubUserIssues = this.currentUserIssues
        this.selectedGitHubUserPullRequests = this.currentUserPullRequests
        fetchGitHubUserProfile(this.sharedAuthAccessToken, this.viewerLogin, { snapshot => this.runOnUi({ => this.selectedGitHubUserProfile = snapshot }) }, { _ => })
        fetchGitHubUserRepositories(this.sharedAuthAccessToken, this.viewerLogin, { items => this.runOnUi({ => this.selectedGitHubUserRepositories = items }) }, { _ => })
        fetchGitHubUserGists(this.sharedAuthAccessToken, this.viewerLogin, { items => this.runOnUi({ => this.selectedGitHubUserGists = items }) }, { _ => })
        fetchGitHubUserFollowers(this.sharedAuthAccessToken, this.viewerLogin, { items => this.runOnUi({ => this.selectedGitHubFollowers = items }) }, { _ => })
        fetchGitHubUserFollowing(this.sharedAuthAccessToken, this.viewerLogin, { items => this.runOnUi({ => this.selectedGitHubFollowing = items }) }, { _ => })
    }
    func openRepository(repositoryId: String): Unit {
        this.selectedRepository = repositoryId
        this.liveRepositoryDetail = GitHubRepositoryDetailSnapshot(repositoryId, "Loading repository details...", "", "", "0", "0", "main")
        this.liveIssues = ArrayList<GitHubIssueSnapshot>()
        this.livePullRequests = ArrayList<GitHubPullRequestSnapshot>()
        this.selectedIssue = ""
        this.selectedPullRequest = ""
        this.selectedTask = ""
        if (this.sharedAuthAccessToken != "") {
            refreshGitHubRepositoryBundle(
                this.sharedAuthAccessToken,
                repositoryId,
                { snapshot => this.liveRepositoryDetail = snapshot },
                { _ => },
                { items =>
                    this.liveIssues = items
                    if (items.size > 0) {
                        this.selectedIssue = items[0].id
                        this.selectedTask = taskIdForIssue(items[0].id)
                    }
                },
                { items =>
                    this.livePullRequests = items
                    if (items.size > 0) {
                        this.selectedPullRequest = items[0].id
                    }
                },
                { _ => }
            )
        }
        this.homeStack.pushPath(NavPathInfo(name: "repositoryDetail", param: ""), options: NavigationOptions(animated: true))
    }

    func pageBackgroundColor(): Int64 { appThemeColor("pageBackground", this.isDarkTheme()) }
    func surfaceColor(): Int64 { appThemeColor("surface", this.isDarkTheme()) }
    func mutedSurfaceColor(): Int64 { appThemeColor("mutedSurface", this.isDarkTheme()) }
    func primaryTextColor(): Int64 { appThemeColor("primaryText", this.isDarkTheme()) }
    func secondaryTextColor(): Int64 { appThemeColor("secondaryText", this.isDarkTheme()) }
    func accentStrongColor(): Int64 { appThemeColor("accentStrong", this.isDarkTheme()) }
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
                    .width(76)
                    .height(76)
                    .borderRadius(38)
                    .objectFit(ImageFit.Cover)
            } else {
                Row() {
                    Text("GH").fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
                }
                .width(76)
                .height(76)
                .backgroundColor(this.surfaceColor())
                .borderRadius(38)
                .justifyContent(FlexAlign.Center)
            }
            Column() {
                Text(this.displayName()).fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
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
            this.buildProfileStatRow(0x4C8DFF, "#", "issues", "${this.currentUserIssues.size}", { => this.openCurrentUserIssues() })
            this.buildProfileDivider()
            this.buildProfileStatRow(0x7B56E8, "⇅", "pull_requests", "${this.currentUserPullRequests.size}", { => this.openCurrentUserPullRequests() })
            this.buildProfileDivider()
            this.buildProfileStatRow(0xFFD54A, "☆", "starred", this.liveStarredCount, { => this.openStarred() })
            this.buildProfileDivider()
            this.buildProfileStatRow(0xF4A24B, "⌂", "organizations", this.liveOrganizationCount, { => this.openOrganizations() })
            this.buildProfileDivider()
            this.buildProfileStatRow(0x4B88FF, "◌", "gists", this.liveGistCount, { => this.openGists() })
            this.buildProfileDivider()
            this.buildProfileStatRow(0x68D968, "◎", "followers", this.liveFollowerCount, { => this.openFollowers() })
            this.buildProfileDivider()
            this.buildProfileStatRow(0x7B56E8, "⇄", "following", this.liveFollowingCount, { => this.openFollowing() })
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
                Text(iconText).fontSize(14).fontWeight(FontWeight.Bold).fontColor(0xF8FAFC)
            }
            .width(38)
            .height(38)
            .backgroundColor(accentColor)
            .borderRadius(11)
            .justifyContent(FlexAlign.Center)

            Text(this.t(titleKey)).fontSize(17).fontWeight(FontWeight.Medium).fontColor(this.primaryTextColor())
            Blank()
            Text(count).fontSize(16).fontColor(this.secondaryTextColor())
            Text("›").fontSize(22).fontColor(this.secondaryTextColor())
        }
        .width(100.percent)
        .height(68)
        .padding(left: 16, right: 16)
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
        Column(space: 12) {
            Row(space: 10) {
                Text("☆").fontSize(17).fontColor(this.secondaryTextColor())
                Text(this.t("popular")).fontSize(17).fontWeight(FontWeight.Medium).fontColor(this.secondaryTextColor())
            }
            .width(100.percent)

            Column(space: 12) {
                ForEach(
                    this.visiblePopularRepositories(),
                    itemGeneratorFunc: { item: GitHubRepositoryCardSnapshot, _: Int64 =>
                        this.buildProfileRepositoryCard(item)
                    }
                )
            }
            .width(100.percent)

            if (this.liveRepositories.size > 5) {
                Text(this.t("profile_repositories_hint"))
                    .fontSize(13)
                    .lineHeight(20)
                    .fontColor(this.secondaryTextColor())
                    .width(100.percent)
            }
        }
        .width(100.percent)
    }

    @Builder
    func buildProfileActivity() {
        Column(space: 12) {
            Row() {
                Text(this.t("activity")).fontSize(17).fontWeight(FontWeight.Medium).fontColor(this.secondaryTextColor())
                Blank()
                Text(this.t("view_all")).fontSize(12).fontColor(this.secondaryTextColor())
            }
            .width(100.percent)
            .onClick({ _ => this.openCurrentUserActivity() })

            if (this.currentUserActivity.size > 0) {
                Column(space: 12) {
                    ForEach(this.topActivityEvents(), itemGeneratorFunc: { item: GitHubEventSnapshot, _: Int64 =>
                        this.buildActivityRow(item)
                    })
                }
                .width(100.percent)
            } else {
                Text(this.t("activity_empty"))
                    .fontSize(13)
                    .lineHeight(20)
                    .fontColor(this.secondaryTextColor())
                    .width(100.percent)
            }
        }
        .width(100.percent)
    }

    @Builder
    func buildActivityRow(item: GitHubEventSnapshot) {
        Column(space: 8) {
            Text(if (item.repoName == "") { item.targetTitle } else { item.repoName })
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.primaryTextColor())
                .width(100.percent)
            Text(this.eventSummary(item))
                .fontSize(12)
                .lineHeight(18)
                .fontColor(this.secondaryTextColor())
                .width(100.percent)
        }
        .width(100.percent)
        .padding(18)
        .backgroundColor(this.surfaceColor())
        .borderRadius(24)
        .onClick({ _ => this.openActivityTarget(item.targetUrl) })
    }

    func topActivityEvents(): ArrayList<GitHubEventSnapshot> {
        let top = ArrayList<GitHubEventSnapshot>()
        var index: Int64 = 0
        for (item in this.currentUserActivity) {
            if (index >= 5) { break }
            top.add(item)
            index += 1
        }
        top
    }

    func eventSummary(item: GitHubEventSnapshot): String {
        if (item.eventType == "IssuesEvent") {
            if (item.action == "opened") { return "${this.t("event_issue_opened")} · ${item.targetTitle}" }
            if (item.action == "closed") { return "${this.t("event_issue_closed")} · ${item.targetTitle}" }
            return "${this.t("event_issue_updated")} · ${item.targetTitle}"
        }
        if (item.eventType == "IssueCommentEvent") { return "${this.t("event_issue_commented")} · ${item.targetTitle}" }
        if (item.eventType == "PullRequestEvent") {
            if (item.action == "opened") { return "${this.t("event_pr_opened")} · ${item.targetTitle}" }
            if (item.action == "closed") { return "${this.t("event_pr_closed")} · ${item.targetTitle}" }
            return "${this.t("event_pr_updated")} · ${item.targetTitle}"
        }
        if (item.eventType == "PullRequestReviewEvent") { return "${this.t("event_pr_reviewed")} · ${item.targetTitle}" }
        if (item.eventType == "PullRequestReviewCommentEvent") { return "${this.t("event_pr_commented")} · ${item.targetTitle}" }
        if (item.eventType == "PushEvent") { return "${this.t("event_push")} · ${item.targetTitle}" }
        if (item.eventType == "WatchEvent") { return "${this.t("event_starred")} · ${item.repoName}" }
        if (item.eventType == "ForkEvent") { return "${this.t("event_forked")} · ${item.repoName}" }
        if (item.eventType == "CreateEvent") { return "${this.t("event_created")} · ${item.targetTitle}" }
        if (item.eventType == "DeleteEvent") { return "${this.t("event_deleted")} · ${item.targetTitle}" }
        if (item.eventType == "ReleaseEvent") { return "${this.t("event_released")} · ${item.targetTitle}" }
        if (item.targetTitle != "") { return item.targetTitle }
        item.eventType
    }

    func openActivityTarget(url: String): Unit {
        if (url == "") { return }
        try {
            getAppAbilityContext().startAbility(Want(uri: url, action: "ohos.want.action.viewData"))
        } catch (_: BusinessException) {}
    }

    @Builder
    func buildProfileRepositoryCard(snapshot: GitHubRepositoryCardSnapshot) {
        Column(space: 10) {
            Row(space: 10) {
                if (this.viewerAvatarUrl != "") {
                    Image(this.viewerAvatarUrl)
                        .width(24)
                        .height(24)
                        .borderRadius(12)
                        .objectFit(ImageFit.Cover)
                }
                Text(this.displayName()).fontSize(12).fontColor(this.secondaryTextColor())
            }
            .width(100.percent)

            Text(this.repositoryDisplayName(snapshot))
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.primaryTextColor())
                .width(100.percent)
                .textAlign(TextAlign.Start)
            Row(space: 8) {
                Text(if (snapshot.viewerStarred) { "★" } else { "☆" })
                    .fontSize(15)
                    .fontColor(if (snapshot.viewerStarred) { 0xFFD54A } else { this.secondaryTextColor() })
                Text("${snapshot.starCount}").fontSize(13).fontColor(this.secondaryTextColor())
            }
            .width(100.percent)
            .justifyContent(FlexAlign.Start)
        }
        .width(100.percent)
        .padding(16)
        .backgroundColor(this.surfaceColor())
        .borderRadius(24)
        .onClick({ _ => this.openRepositoryCard(snapshot) })
    }
}
