package ohos_app_cangjie_entry.pages.tabs

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.*
import ohos.base.UIThread
import ohos_app_cangjie_entry.pages.maps.inboxPageMap
import std.collection.ArrayList
import ohos_app_cangjie_entry.domain.{GitHubCommitSnapshot, GitHubGistFileSnapshot, GitHubGistSnapshot, GitHubIssueSnapshot, GitHubNotificationSnapshot, GitHubPullRequestSnapshot, GitHubRepositoryCardSnapshot, GitHubRepositoryDetailSnapshot, GitHubSimpleUserSnapshot, GitHubUserProfileSnapshot}
import ohos_app_cangjie_entry.services.agent.taskIdForIssue
import ohos_app_cangjie_entry.services.app.refreshGitHubRepositoryBundle
import ohos_app_cangjie_entry.services.github.{fetchGitHubNotifications, resourceNumberFromApiUrl}

@Component
public class InboxTabHost {
    @Consume var inboxStack: NavPathStack = NavPathStack()
    @Consume var themePreference: String = "system"
    @Consume var languagePreference: String = "system"
    @Consume var sharedAuthAccessToken: String = ""

    @Provide var selectedNotificationTitle: String = ""
    @Provide var exploreStack: NavPathStack = NavPathStack()
    @Provide var selectedNotificationRepository: String = ""
    @Provide var selectedNotificationReason: String = ""
    @Provide var selectedNotificationType: String = ""
    @Provide var selectedNotificationApiUrl: String = ""
    @Provide var selectedNotificationRepositoryUrl: String = ""
    @Provide var selectedNotificationUpdatedAt: String = ""
    @Provide var selectedRepository: String = ""
    @Provide var selectedIssue: String = ""
    @Provide var selectedPullRequest: String = ""
    @Provide var selectedTask: String = ""
    @Provide var liveRepositoryDetail: GitHubRepositoryDetailSnapshot = GitHubRepositoryDetailSnapshot("", "", "", "", "0", "0", "main")
    @Provide var liveRepositoryReadme: String = ""
    @Provide var liveIssues: ArrayList<GitHubIssueSnapshot> = ArrayList<GitHubIssueSnapshot>()
    @Provide var livePullRequests: ArrayList<GitHubPullRequestSnapshot> = ArrayList<GitHubPullRequestSnapshot>()
    @Provide var selectedGitHubUserLogin: String = ""
    @Provide var selectedGitHubUserProfile: GitHubUserProfileSnapshot = GitHubUserProfileSnapshot("", "", "", "", "", "", "", "", "0", "0", "0", "0")
    @Provide var selectedGitHubUserRepositories: ArrayList<GitHubRepositoryCardSnapshot> = ArrayList<GitHubRepositoryCardSnapshot>()
    @Provide var selectedGitHubUserGists: ArrayList<GitHubGistSnapshot> = ArrayList<GitHubGistSnapshot>()
    @Provide var selectedGitHubGistFiles: ArrayList<GitHubGistFileSnapshot> = ArrayList<GitHubGistFileSnapshot>()
    @Provide var selectedGitHubGistId: String = ""
    @Provide var selectedGitHubFollowers: ArrayList<GitHubSimpleUserSnapshot> = ArrayList<GitHubSimpleUserSnapshot>()
    @Provide var selectedGitHubFollowing: ArrayList<GitHubSimpleUserSnapshot> = ArrayList<GitHubSimpleUserSnapshot>()
    @Provide var liveRepositoryWatchers: ArrayList<GitHubSimpleUserSnapshot> = ArrayList<GitHubSimpleUserSnapshot>()
    @Provide var liveRepositoryStargazers: ArrayList<GitHubSimpleUserSnapshot> = ArrayList<GitHubSimpleUserSnapshot>()
    @Provide var liveRepositoryForks: ArrayList<GitHubRepositoryCardSnapshot> = ArrayList<GitHubRepositoryCardSnapshot>()
    @Provide var liveRepositoryCommits: ArrayList<GitHubCommitSnapshot> = ArrayList<GitHubCommitSnapshot>()

    @StorageProp["colorMode"]
    let systemColorMode: ColorMode = ColorMode.Light

    @StorageProp["languageCode"]
    let systemLanguageCode: String = "en"

    @State var notifications: ArrayList<GitHubNotificationSnapshot> = ArrayList<GitHubNotificationSnapshot>()
    @State var inboxRefreshing: Bool = false
    @State var inboxActionMessage: String = ""
    @State var inboxPage: Int64 = 1
    @State var inboxLoadingMore: Bool = false
    @State var inboxHasMore: Bool = true

    protected override func aboutToAppear(): Unit {
        this.exploreStack = this.inboxStack
        this.refreshInboxContent()
    }

    public func build() {
        Navigation(this.inboxStack) {
            Stack(alignContent: Alignment.Top) {
                this.buildTabBackground()
                Column(space: 0) {
                    this.buildTopBar()
                    Refresh(RefreshOptions(refreshing: @Binder(inboxRefreshing))) {
                        Scroll {
                            Column(space: 18) {
                                if (this.inboxActionMessage != "") {
                                    this.buildActionMessage()
                                }
                                if (this.notifications.size > 0) {
                                    ForEach(this.notifications, itemGeneratorFunc: { item: GitHubNotificationSnapshot, _: Int64 =>
                                        this.buildInboxMessage(item)
                                    })
                                } else {
                                    this.buildEmptyMessage()
                                }
                                if (this.inboxLoadingMore) {
                                    this.buildLoadingMoreMessage()
                                }
                            }
                            .width(100.percent)
                            .padding(left: 18, right: 18, top: 18, bottom: 100)
                        }
                        .width(100.percent)
                        .height(100.percent)
                        .scrollBar(BarState.Off)
                        .onReachEnd({ => this.loadMoreNotifications() })
                    }
                    .width(100.percent)
                    .layoutWeight(1)
                    .expandSafeArea(types: [SafeAreaType.System], edges: [SafeAreaEdge.Bottom])
                    .onRefreshing({ => this.refreshInboxContent(showRefreshIndicator: true) })
                }
                .width(100.percent)
                .height(100.percent)
            }
            .width(100.percent)
            .height(100.percent)
        }
        .width(100.percent)
        .height(100.percent)
        .hideTitleBar(true)
        .navDestination(bind(inboxPageMap, this))
    }

    func t(key: String): String { tabText(this.languagePreference, this.systemLanguageCode, key) }
    func isDarkTheme(): Bool { tabIsDarkTheme(this.themePreference, this.systemColorMode) }
    func surfaceColor(): Int64 { tabColor("surface", this.themePreference, this.systemColorMode) }
    func primaryTextColor(): Int64 { tabColor("primaryText", this.themePreference, this.systemColorMode) }
    func secondaryTextColor(): Int64 { tabColor("secondaryText", this.themePreference, this.systemColorMode) }
    func topBarOverlayColor(): Int64 { if (this.isDarkTheme()) { 0xE0090B10 } else { 0xEAF2F3F7 } }

    func runOnUi(task: () -> Unit): Unit {
        spawn(UIThread) { => task() }
    }

    func refreshInboxContent(showRefreshIndicator!: Bool = false): Unit {
        if (showRefreshIndicator) {
            this.inboxRefreshing = true
        }
        this.inboxPage = 1
        this.inboxHasMore = true
        this.inboxLoadingMore = false
        if (this.sharedAuthAccessToken == "") {
            this.notifications = ArrayList<GitHubNotificationSnapshot>()
            this.inboxActionMessage = this.t("connect_github_first")
            this.inboxRefreshing = false
            return
        }
        fetchGitHubNotifications(
            this.sharedAuthAccessToken,
            { items =>
                this.runOnUi({
                    =>
                    this.notifications = items
                    this.inboxHasMore = items.size >= 30
                    this.inboxActionMessage = ""
                    this.inboxRefreshing = false
                })
            },
            { message =>
                this.runOnUi({
                    =>
                    this.notifications = ArrayList<GitHubNotificationSnapshot>()
                    this.inboxHasMore = false
                    this.inboxActionMessage = message
                    this.inboxRefreshing = false
                })
            },
            page: 1
        )
    }

    func loadMoreNotifications(): Unit {
        if (this.inboxRefreshing || this.inboxLoadingMore || !this.inboxHasMore || this.sharedAuthAccessToken == "") {
            return
        }
        this.inboxLoadingMore = true
        let nextPage = this.inboxPage + 1
        fetchGitHubNotifications(
            this.sharedAuthAccessToken,
            { items =>
                this.runOnUi({
                    =>
                    this.notifications = this.mergeNotifications(this.notifications, items)
                    this.inboxPage = nextPage
                    this.inboxHasMore = items.size >= 30
                    this.inboxLoadingMore = false
                })
            },
            { _ =>
                this.runOnUi({
                    =>
                    this.inboxLoadingMore = false
                    this.inboxHasMore = false
                })
            },
            page: nextPage
        )
    }

    func openNotification(snapshot: GitHubNotificationSnapshot): Unit {
        this.selectedNotificationTitle = snapshot.subjectTitle
        this.selectedNotificationRepository = snapshot.repositoryName
        this.selectedNotificationReason = snapshot.reason
        this.selectedNotificationType = snapshot.subjectType
        this.selectedNotificationApiUrl = snapshot.subjectApiUrl
        this.selectedNotificationRepositoryUrl = snapshot.repositoryUrl
        this.selectedNotificationUpdatedAt = snapshot.updatedAt
        if (snapshot.unread) {
            this.applyNotificationReadLocally(snapshot.id)
        }
        this.inboxStack.pushPath(NavPathInfo(name: "notificationDetail", param: ""), options: NavigationOptions(animated: true))
    }

    func applyNotificationReadLocally(threadId: String): Unit {
        let refreshed = ArrayList<GitHubNotificationSnapshot>()
        for (item in this.notifications) {
            if (item.id == threadId && item.unread) {
                refreshed.add(
                    GitHubNotificationSnapshot(
                        item.id,
                        item.repositoryName,
                        item.repositoryUrl,
                        item.subjectTitle,
                        item.subjectType,
                        item.reason,
                        item.subjectApiUrl,
                        false,
                        item.updatedAt
                    )
                )
            } else {
                refreshed.add(item)
            }
        }
        this.notifications = refreshed
    }

    func mergeNotifications(existing: ArrayList<GitHubNotificationSnapshot>, incoming: ArrayList<GitHubNotificationSnapshot>): ArrayList<GitHubNotificationSnapshot> {
        let merged = ArrayList<GitHubNotificationSnapshot>()
        for (item in existing) {
            merged.add(item)
        }
        for (candidate in incoming) {
            var duplicate = false
            for (current in merged) {
                if (current.id == candidate.id) {
                    duplicate = true
                    break
                }
            }
            if (!duplicate) {
                merged.add(candidate)
            }
        }
        merged
    }

    func openNotificationTargetInApp(repositoryName: String, subjectType: String, subjectApiUrl: String): Unit {
        if (repositoryName == "") {
            return
        }
        this.selectedRepository = repositoryName
        this.liveRepositoryDetail = GitHubRepositoryDetailSnapshot(repositoryName, "Loading repository details...", "", "", "0", "0", "main")
        this.liveRepositoryReadme = ""
        this.liveIssues = ArrayList<GitHubIssueSnapshot>()
        this.livePullRequests = ArrayList<GitHubPullRequestSnapshot>()
        if (this.sharedAuthAccessToken != "") {
            refreshGitHubRepositoryBundle(
                this.sharedAuthAccessToken,
                repositoryName,
                { snapshot => this.runOnUi({ => this.liveRepositoryDetail = snapshot }) },
                { markdown => this.runOnUi({ => this.liveRepositoryReadme = markdown }) },
                { items => this.runOnUi({ => this.liveIssues = items }) },
                { items => this.runOnUi({ => this.livePullRequests = items }) },
                { _ => }
            )
        }
        if (subjectType == "Issue") {
            this.selectedIssue = resourceNumberFromApiUrl(subjectApiUrl)
            this.selectedTask = taskIdForIssue(this.selectedIssue)
            this.inboxStack.pushPath(NavPathInfo(name: "issueDetail", param: ""), options: NavigationOptions(animated: true))
        } else if (subjectType == "PullRequest") {
            this.selectedPullRequest = resourceNumberFromApiUrl(subjectApiUrl)
            this.inboxStack.pushPath(NavPathInfo(name: "pullRequestDetail", param: ""), options: NavigationOptions(animated: true))
        } else {
            this.inboxStack.pushPath(NavPathInfo(name: "repositoryDetail", param: ""), options: NavigationOptions(animated: true))
        }
    }

    @Builder
    func buildTopBar() {
        Row() {
            Column(space: 4) {
                Text(this.t("inbox")).fontSize(30).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
                Text(this.t("inbox_subtitle")).fontSize(12).fontColor(this.secondaryTextColor())
            }.alignItems(HorizontalAlign.Start)
            Blank()
        }
        .width(100.percent)
        .padding(left: 18, right: 18, top: 16, bottom: 12)
        .backgroundColor(this.topBarOverlayColor())
    }

    @Builder
    func buildActionMessage() {
        Text(this.inboxActionMessage)
            .width(100.percent)
            .padding(left: 16, right: 16, top: 14, bottom: 14)
            .backgroundColor(this.surfaceColor())
            .borderRadius(18)
            .fontSize(14)
            .fontColor(this.primaryTextColor())
    }

    @Builder
    func buildEmptyMessage() {
        Column(space: 8) {
            Text(this.t("notifications")).fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
            Text(this.t("notifications_empty")).fontSize(13).fontColor(this.secondaryTextColor())
        }
        .width(100.percent)
        .padding(18)
        .backgroundColor(this.surfaceColor())
        .borderRadius(24)
    }

    @Builder
    func buildLoadingMoreMessage() {
        Text(this.t("loading_more"))
            .width(100.percent)
            .padding(left: 16, right: 16, top: 14, bottom: 14)
            .backgroundColor(this.surfaceColor())
            .borderRadius(18)
            .fontSize(13)
            .fontColor(this.secondaryTextColor())
    }

    @Builder
    func buildInboxMessage(snapshot: GitHubNotificationSnapshot) {
        Row() {
            Column(space: 4) {
                Text(this.reasonGlyph(snapshot.reason)).fontSize(18).fontColor(this.reasonColor(snapshot.reason))
                Text("•")
                    .fontSize(18)
                    .fontColor(if (snapshot.unread) { 0x4C8DFF } else { 0x00000000 })
            }
            .width(28)
            .alignItems(HorizontalAlign.Center)
            Column(space: 8) {
                Text(snapshot.repositoryName).fontSize(13).fontColor(this.secondaryTextColor())
                Text(snapshot.subjectTitle).fontSize(17).fontWeight(FontWeight.Bold).fontColor(this.primaryTextColor())
                Row(space: 8) {
                    Text(snapshot.reason).fontSize(11).fontColor(this.reasonColor(snapshot.reason))
                        .padding(left: 8, right: 8, top: 4, bottom: 4)
                        .backgroundColor(this.reasonTint(snapshot.reason))
                        .borderRadius(8)
                    Blank()
                    Text(this.compactUpdatedAt(snapshot.updatedAt)).fontSize(11).fontColor(this.secondaryTextColor())
                }
                .width(100.percent)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
        }
        .width(100.percent)
        .padding(18)
        .backgroundColor(this.surfaceColor())
        .borderRadius(24)
        .alignItems(VerticalAlign.Top)
        .onClick({ _ => this.openNotification(snapshot) })
    }

    func reasonGlyph(reason: String): String {
        if (reason == "mention") { return "@" }
        if (reason == "author") { return "✎" }
        if (reason == "comment") { return "💬" }
        if (reason == "subscribed") { return "👁" }
        if (reason == "review_requested") { return "⇄" }
        if (reason == "security_alert") { return "!" }
        "•"
    }

    func reasonColor(reason: String): Int64 {
        if (reason == "mention") { return 0xD19A00 }
        if (reason == "author") { return 0x2E9E5B }
        if (reason == "comment") { return 0x2E78F2 }
        if (reason == "subscribed") { return 0xD97706 }
        if (reason == "review_requested") { return 0x7C3AED }
        if (reason == "security_alert") { return 0xD64545 }
        this.secondaryTextColor()
    }

    func reasonTint(reason: String): Int64 {
        if (reason == "mention") { return if (this.isDarkTheme()) { 0x33D19A00 } else { 0x1FD19A00 } }
        if (reason == "author") { return if (this.isDarkTheme()) { 0x332E9E5B } else { 0x1F2E9E5B } }
        if (reason == "comment") { return if (this.isDarkTheme()) { 0x332E78F2 } else { 0x1F2E78F2 } }
        if (reason == "subscribed") { return if (this.isDarkTheme()) { 0x33D97706 } else { 0x1FD97706 } }
        if (reason == "review_requested") { return if (this.isDarkTheme()) { 0x337C3AED } else { 0x1F7C3AED } }
        if (reason == "security_alert") { return if (this.isDarkTheme()) { 0x33D64545 } else { 0x1FD64545 } }
        if (this.isDarkTheme()) { 0x22FFFFFF } else { 0x12090B10 }
    }

    func compactUpdatedAt(value: String): String {
        if (value == "") {
            return ""
        }
        let parts = value.split("T")
        if (parts.size > 0) {
            let dateParts = parts[0].split("-")
            if (dateParts.size == 3) {
                return "${dateParts[1]}-${dateParts[2]}"
            }
            return parts[0]
        }
        value
    }

    @Builder
    func buildTabBackground() {
        Column() { Blank() }
            .width(100.percent)
            .height(100.percent)
            .backgroundColor(tabColor("pageBackground", this.themePreference, this.systemColorMode))
            .expandSafeArea(types: [SafeAreaType.System], edges: [SafeAreaEdge.Top, SafeAreaEdge.Bottom])
    }
}
