package ohos_app_cangjie_entry.app

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.Builder
import ohos_app_cangjie_entry.domain.{ExploreLaneSnapshot, GitHubRepositoryCardSnapshot, InboxItemSnapshot, PullRequestSnapshot, RepositorySnapshot, TaskSnapshot}

@Builder
func buildTopBar(shell: AppShell) {
    Row() {
        Column(space: 4) {
            Text(shell.mainTitle()).fontSize(34).fontWeight(FontWeight.Bold).fontColor(shell.primaryTextColor())
            Text(shell.mainSubtitle()).fontSize(13).fontColor(shell.secondaryTextColor())
        }
        .alignItems(HorizontalAlign.Start)
        Blank()
        Row(space: 10) {
            buildCircleAction(shell, shell.t("add_short"))
            buildCircleAction(shell, shell.t("find_short"))
        }
    }
    .width(100.percent)
}

@Builder
func buildActiveTabContent(shell: AppShell) {
    Stack() {
        if (shell.isActiveTab("home")) { buildHomeTab(shell) }
        if (shell.isActiveTab("inbox")) { buildInboxTab(shell) }
        if (shell.isActiveTab("explore")) { buildExploreTab(shell) }
        if (shell.isActiveTab("profile")) { buildProfileTab(shell) }
    }
    .width(100.percent)
}

@Builder
func buildHomeTab(shell: AppShell) {
    Column(space: 18) {
        Column(space: 12) {
            Text(shell.currentWorkplaceTitle()).fontSize(14).fontColor(shell.accentStrongColor())
            Text(shell.currentWorkplaceHeroTitle()).fontSize(28).fontWeight(FontWeight.Bold).fontColor(shell.heroTextColor())
            Text(shell.currentWorkplaceSummary()).fontSize(13).fontColor(shell.heroSubTextColor())
            Row(space: 12) {
                buildStatChip(shell, "12", shell.t("inbox"))
                buildStatChip(shell, "06", shell.t("running_tasks"))
                buildStatChip(shell, "09", shell.t("reviews"))
            }
        }
        .width(100.percent)
        .padding(22)
        .backgroundColor(shell.heroCardColor())
        .borderRadius(30)
        .shadow(radius: 28.0, color: shell.shadowColor(), offsetX: 0.0, offsetY: 16.0)

        buildSectionHeader(shell, shell.t("recent_repositories"), shell.t("see_all"))
        buildRepositoryCard(shell, shell.primaryHomeRepository())
        buildRepositoryCard(shell, shell.secondaryHomeRepository())
        buildRepositoryCard(shell, shell.tertiaryHomeRepository())

        buildSectionHeader(shell, shell.t("pull_requests"), shell.t("see_all"))
        buildPullRequestCard(shell, shell.highlightedPullRequest())

        buildSectionHeader(shell, shell.t("recent_tasks"), shell.t("focus_label"))
        buildTaskPreviewCard(shell, shell.focusedTask())
        buildTaskPreviewCard(shell, shell.reviewTask())
    }
    .width(100.percent)
}

@Builder
func buildInboxTab(shell: AppShell) {
    Column(space: 18) {
        buildInboxMessage(shell, shell.inboxPrimary())
        buildInboxMessage(shell, shell.inboxSecondary())
        buildInboxMessage(shell, shell.inboxTertiary())
    }
    .width(100.percent)
}

@Builder
func buildExploreTab(shell: AppShell) {
    Column(space: 18) {
        buildExploreLane(shell, shell.firstExploreLane())
        buildExploreLane(shell, shell.secondExploreLane())
    }
    .width(100.percent)
}

@Builder
func buildProfileTab(shell: AppShell) {
    Column(space: 18) {
        Column(space: 12) {
            Text("RepoPilot").fontSize(24).fontWeight(FontWeight.Bold).fontColor(shell.primaryTextColor())
            Text(shell.accountCaption()).fontSize(13).fontColor(shell.secondaryTextColor())
            Text(shell.t("settings_subtitle")).fontSize(13).fontColor(shell.secondaryTextColor())
        }
        .width(100.percent)
        .padding(20)
        .backgroundColor(shell.surfaceColor())
        .borderRadius(28)

        buildPreferenceSection(shell, shell.t("appearance"), shell.themePreferenceValue(), "theme")
        buildPreferenceSection(shell, shell.t("language"), shell.languagePreferenceValue(), "language")

        Button(shell.t("create_repository"))
            .width(100.percent).height(48).backgroundColor(shell.surfaceColor()).fontColor(shell.primaryTextColor())
            .onClick({ _ => shell.createScratchRepository() })
        if (shell.hasLiveRepositories()) {
            buildSectionHeader(shell, "GitHub", "live")
            ForEach(
                shell.visibleLiveRepositories(),
                itemGeneratorFunc: { item: GitHubRepositoryCardSnapshot, _: Int64 =>
                    buildLiveRepositoryCard(shell, item)
                }
            )
        }
        Button(shell.t("settings"))
            .width(100.percent).height(48).backgroundColor(shell.surfaceColor()).fontColor(shell.primaryTextColor())
            .onClick({ _ => shell.openSettings() })
        Button(shell.t("sign_out"))
            .width(100.percent).height(48).backgroundColor(shell.mutedSurfaceColor()).fontColor(shell.primaryTextColor())
            .onClick({ _ => shell.signOut() })
    }
    .width(100.percent)
}

@Builder
func buildLiveRepositoryCard(shell: AppShell, snapshot: GitHubRepositoryCardSnapshot) {
    Column(space: 8) {
        Text(snapshot.name).fontSize(17).fontWeight(FontWeight.Bold).fontColor(shell.primaryTextColor())
        Text(snapshot.summary).fontSize(12).fontColor(shell.secondaryTextColor())
        Text(if (snapshot.isFork) { "Fork" } else if (snapshot.isPrivate) { "Private" } else { "Public" })
            .fontSize(11).fontColor(shell.accentStrongColor())
    }
    .width(100.percent)
    .padding(18)
    .backgroundColor(shell.surfaceColor())
    .borderRadius(24)
}

@Builder
func buildSectionHeader(shell: AppShell, title: String, action: String) {
    Row() {
        Text(title).fontSize(22).fontWeight(FontWeight.Bold).fontColor(shell.primaryTextColor())
        Blank()
        Text(action).fontSize(13).fontColor(shell.accentStrongColor())
    }
    .width(100.percent)
}

@Builder
func buildCircleAction(shell: AppShell, label: String) {
    Button(label)
        .width(42).height(42).borderRadius(21).backgroundColor(shell.surfaceColor()).fontColor(shell.primaryTextColor())
}

@Builder
func buildStatChip(shell: AppShell, value: String, label: String) {
    Column(space: 4) {
        Text(value).fontSize(18).fontWeight(FontWeight.Bold).fontColor(shell.heroTextColor())
        Text(label).fontSize(11).fontColor(shell.heroSubTextColor())
    }
    .padding(left: 12, right: 12, top: 10, bottom: 10)
    .backgroundColor(0x20FFFFFF)
    .borderRadius(18)
}

@Builder
func buildRepositoryCard(shell: AppShell, snapshot: RepositorySnapshot) {
    Button() {
        Column(space: 10) {
            Text(shell.t(snapshot.titleKey)).fontSize(18).fontWeight(FontWeight.Bold).fontColor(shell.primaryTextColor())
            Text(shell.t(snapshot.summaryKey)).fontSize(13).fontColor(shell.secondaryTextColor())
        }
        .width(100.percent)
    }
    .width(100.percent)
    .padding(18)
    .backgroundColor(shell.surfaceColor())
    .borderRadius(24)
    .onClick({ _ => shell.openRepository(snapshot.id) })
}

@Builder
func buildPullRequestCard(shell: AppShell, snapshot: PullRequestSnapshot) {
    Button() {
        Column(space: 10) {
            Text(shell.t(snapshot.titleKey)).fontSize(18).fontWeight(FontWeight.Bold).fontColor(shell.primaryTextColor())
            Text(shell.t(snapshot.summaryKey)).fontSize(13).fontColor(shell.secondaryTextColor())
            Text(shell.t(snapshot.statusKey)).fontSize(12).fontColor(shell.accentStrongColor())
        }
        .width(100.percent)
    }
    .width(100.percent)
    .padding(18)
    .backgroundColor(shell.surfaceColor())
    .borderRadius(24)
    .onClick({ _ => shell.openSelectedPullRequest() })
}

@Builder
func buildTaskPreviewCard(shell: AppShell, snapshot: TaskSnapshot) {
    Button() {
        Column(space: 8) {
            Text(shell.t(snapshot.titleKey)).fontSize(18).fontWeight(FontWeight.Bold).fontColor(shell.primaryTextColor())
            Text(shell.t(snapshot.summaryKey)).fontSize(13).fontColor(shell.secondaryTextColor())
        }
        .width(100.percent)
    }
    .width(100.percent)
    .padding(18)
    .backgroundColor(shell.surfaceColor())
    .borderRadius(24)
    .onClick({ _ => shell.openTaskDetail(snapshot.id) })
}

@Builder
func buildInboxMessage(shell: AppShell, snapshot: InboxItemSnapshot) {
    Column(space: 8) {
        Text(shell.t(snapshot.titleKey)).fontSize(18).fontWeight(FontWeight.Bold).fontColor(shell.primaryTextColor())
        Text(shell.t(snapshot.bodyKey)).fontSize(13).fontColor(shell.secondaryTextColor())
    }
    .width(100.percent)
    .padding(18)
    .backgroundColor(shell.surfaceColor())
    .borderRadius(24)
}

@Builder
func buildExploreLane(shell: AppShell, snapshot: ExploreLaneSnapshot) {
    Button() {
        Column(space: 8) {
            Text(shell.t(snapshot.titleKey)).fontSize(18).fontWeight(FontWeight.Bold).fontColor(shell.primaryTextColor())
            Text(shell.t(snapshot.summaryKey)).fontSize(13).fontColor(shell.secondaryTextColor())
        }
        .width(100.percent)
    }
    .width(100.percent)
    .padding(18)
    .backgroundColor(shell.surfaceColor())
    .borderRadius(24)
    .onClick({ _ => shell.openRepository(snapshot.repositoryId) })
}

@Builder
func buildPreferenceSection(shell: AppShell, title: String, value: String, kind: String) {
    Column(space: 10) {
        Text(title).fontSize(18).fontWeight(FontWeight.Bold).fontColor(shell.primaryTextColor())
        Row(space: 10) {
            buildPreferenceChip(shell, kind, "system")
            if (kind == "theme") {
                buildPreferenceChip(shell, kind, "light")
                buildPreferenceChip(shell, kind, "dark")
            } else {
                buildPreferenceChip(shell, kind, "en")
                buildPreferenceChip(shell, kind, "zh")
            }
        }
        Text(shell.preferenceLabel(kind, value)).fontSize(12).fontColor(shell.secondaryTextColor())
    }
    .width(100.percent)
    .padding(18)
    .backgroundColor(shell.surfaceColor())
    .borderRadius(24)
}

@Builder
func buildPreferenceChip(shell: AppShell, kind: String, value: String) {
    Button(shell.preferenceLabel(kind, value))
        .backgroundColor(shell.navSelectionColor())
        .fontColor(shell.primaryTextColor())
        .onClick({ _ => shell.applyRootPreference(kind, value) })
}
