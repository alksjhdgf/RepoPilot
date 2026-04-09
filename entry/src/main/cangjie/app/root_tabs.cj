package ohos_app_cangjie_entry.app

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.Builder
import ohos_app_cangjie_entry.domain.{ExploreLaneSnapshot, GitHubPullRequestSnapshot, GitHubRepositoryCardSnapshot, InboxItemSnapshot, PullRequestSnapshot, RepositorySnapshot, TaskSnapshot}

@Builder
func buildTopBar(shell: AppShell) {
    Row() {
        if (shell.isActiveTab("home")) {
            Row(space: 12) {
                if (shell.isCurrentWorkplace("github")) {
                    Button() {
                        if (shell.hasViewerAvatar()) {
                            Image(shell.viewerAvatarUrlValue())
                                .width(100.percent)
                                .height(100.percent)
                                .borderRadius(20)
                                .objectFit(ImageFit.Cover)
                        } else {
                            Row() {
                                Text("GH")
                                    .fontSize(15)
                                    .fontWeight(FontWeight.Bold)
                                    .fontColor(shell.primaryTextColor())
                            }
                            .width(100.percent)
                            .height(100.percent)
                            .justifyContent(FlexAlign.Center)
                        }
                    }
                    .width(40)
                    .height(40)
                    .backgroundColor(shell.surfaceColor())
                    .borderRadius(20)
                    .onClick({ _ => shell.openProfilePage() })
                } else {
                    Row() {
                        Text("RP")
                            .fontSize(14)
                            .fontWeight(FontWeight.Bold)
                            .fontColor(shell.primaryTextColor())
                    }
                    .width(40)
                    .height(40)
                    .backgroundColor(shell.surfaceColor())
                    .borderRadius(20)
                    .justifyContent(FlexAlign.Center)
                }
                Column(space: 2) {
                    Text(shell.currentHeaderWorkplaceTitle())
                        .fontSize(18)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(shell.primaryTextColor())
                }
                .alignItems(HorizontalAlign.Start)
            }
        } else {
            Column(space: 4) {
                Text(shell.mainTitle())
                    .fontSize(30)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(shell.primaryTextColor())
                Text(shell.mainSubtitle()).fontSize(12).fontColor(shell.secondaryTextColor())
            }
            .alignItems(HorizontalAlign.Start)
        }
        Blank()
        Row(space: 8) {
            if (shell.canCreateFromCurrentWorkplace()) {
                buildCircleAction(shell, shell.t("add_short"), { => shell.openPendingPage("Create", "该页面待开发") })
            }
            buildCircleAction(shell, shell.t("find_short"), { => shell.openPendingPage("Search", "该页面待开发") })
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
        if (shell.isActiveTab("copilot")) { buildCursorTab(shell) }
    }
    .width(100.percent)
}

@Builder
func buildHomeTab(shell: AppShell) {
    Column(space: 16) {
        buildHomeSectionHeader(shell, shell.t("my_work"))
        buildHomeWorkPanel(shell)
        buildHomeSectionHeader(shell, shell.t("favorites"))
        buildHomeFavoritesPanel(shell)
        buildHomeSectionHeader(shell, shell.t("shortcuts"))
        buildHomeShortcutsPanel(shell)
        buildHomeSectionHeader(shell, shell.t("recent"))
        buildHomeRecentPanel(shell)
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
func buildCursorTab(shell: AppShell) {
    Column(space: 18) {
        Text(shell.t("cursor")).fontSize(40).fontWeight(FontWeight.Bold).fontColor(shell.primaryTextColor())

        buildCursorSectionHeader(shell, shell.t("agent_sessions"))
        buildCursorAgentSessionsCard(shell)

        buildCursorSectionHeader(shell, shell.t("chats"))
        buildCursorChatsCard(shell)
    }
    .width(100.percent)
}

@Builder
func buildCursorSectionHeader(shell: AppShell, title: String) {
    Row() {
        Text(title).fontSize(18).fontWeight(FontWeight.Bold).fontColor(shell.primaryTextColor())
        Blank()
    }
    .width(100.percent)
}

@Builder
func buildCursorAgentSessionsCard(shell: AppShell) {
    Column(space: 18) {
        Row(space: 0) {
            buildCursorSignalDot(0x31333B, "☁")
            buildCursorSignalDot(0x243A63, "◎")
            buildCursorSignalDot(0x27492D, "⎇")
        }
        .width(100.percent)
        .justifyContent(FlexAlign.Center)

        Text(shell.t("cursor_agent_title"))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
            .fontColor(shell.primaryTextColor())

        Text(shell.t("cursor_agent_desc"))
            .fontSize(13)
            .lineHeight(22)
            .textAlign(TextAlign.Center)
            .fontColor(shell.secondaryTextColor())

        Button(shell.t("cursor_upgrade"))
            .width(100.percent)
            .height(48)
            .backgroundColor(shell.navSelectionColor())
            .fontColor(shell.accentStrongColor())
            .fontSize(16)
            .borderRadius(14)
            .onClick({ _ => shell.openPendingPage(shell.t("cursor_upgrade"), "该页面待开发") })
    }
    .width(100.percent)
    .padding(left: 20, right: 20, top: 22, bottom: 22)
    .backgroundColor(shell.surfaceColor())
    .borderRadius(26)
}

@Builder
func buildCursorSignalDot(color: Int64, symbol: String) {
    Row() {
        Text(symbol).fontSize(14).fontWeight(FontWeight.Bold).fontColor(0xF8FAFC)
    }
    .width(52)
    .height(52)
    .backgroundColor(color)
    .borderRadius(26)
    .justifyContent(FlexAlign.Center)
}

@Builder
func buildCursorChatsCard(shell: AppShell) {
    Stack(alignContent: Alignment.BottomEnd) {
        Column(space: 18) {
            Row() {
                Text("⌘").fontSize(20).fontColor(shell.secondaryTextColor())
            }
            .width(64)
            .height(64)
            .backgroundColor(shell.navBarColor())
            .borderRadius(32)
            .justifyContent(FlexAlign.Center)

            Text(shell.t("cursor_no_chats"))
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(shell.primaryTextColor())

            Text(shell.t("cursor_no_chats_desc"))
                .fontSize(13)
                .lineHeight(22)
                .textAlign(TextAlign.Center)
                .fontColor(shell.secondaryTextColor())

            Button(shell.t("cursor_new_chat"))
                .width(100.percent)
                .height(46)
                .backgroundColor(shell.mutedSurfaceColor())
                .fontColor(shell.accentStrongColor())
                .fontSize(16)
                .borderRadius(14)
                .onClick({ _ => shell.openPendingPage(shell.t("cursor_new_chat"), "该页面待开发") })
        }
        .width(100.percent)
        .alignItems(HorizontalAlign.Center)
        .padding(left: 20, right: 20, top: 22, bottom: 22)

        Button("✎")
            .width(58)
            .height(58)
            .backgroundColor(shell.navBarColor())
            .fontColor(shell.primaryTextColor())
            .fontSize(20)
            .borderRadius(29)
            .shadow(ShadowStyle.OUTER_DEFAULT_LG)
            .margin(right: 18, bottom: 18)
            .onClick({ _ => shell.openPendingPage(shell.t("cursor_new_chat"), "该页面待开发") })
    }
    .width(100.percent)
    .backgroundColor(shell.surfaceColor())
    .borderRadius(26)
}

@Builder
func detailCard(shell: AppShell, title: String, body: String, onTap: () -> Unit) {
    Column(space: 8) {
        Text(title).fontSize(17).fontWeight(FontWeight.Bold).fontColor(shell.primaryTextColor())
        Text(body).fontSize(13).fontColor(shell.secondaryTextColor())
    }
    .width(100.percent)
    .padding(18)
    .backgroundColor(shell.surfaceColor())
    .borderRadius(22)
    .onClick({ _ => onTap() })
}

@Builder
func buildLiveRepositoryCard(shell: AppShell, snapshot: GitHubRepositoryCardSnapshot) {
    // 真实 GitHub 仓库卡片，优先用于验证认证链和数据读取链是否闭环。
    // Live GitHub repository card used to verify that auth and read flows are wired correctly.
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
    .onClick({ _ => shell.openRepository(snapshot.name) })
}

@Builder
func buildLivePullRequestCard(shell: AppShell, snapshot: GitHubPullRequestSnapshot) {
    Column(space: 8) {
        Text(snapshot.title).fontSize(17).fontWeight(FontWeight.Bold).fontColor(shell.primaryTextColor())
        Text(snapshot.summary).fontSize(12).fontColor(shell.secondaryTextColor())
        Text("${snapshot.status} / @${snapshot.authorLogin}")
            .fontSize(11).fontColor(shell.accentStrongColor())
    }
    .width(100.percent)
    .padding(18)
    .backgroundColor(shell.surfaceColor())
    .borderRadius(24)
    .onClick({ _ => shell.openLivePullRequest(snapshot.id) })
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
func buildHomeSectionHeader(shell: AppShell, title: String) {
    Row() {
        Text(title).fontSize(16).fontWeight(FontWeight.Bold).fontColor(shell.primaryTextColor())
        Blank()
        Text("...").fontSize(14).fontWeight(FontWeight.Bold).fontColor(shell.secondaryTextColor())
    }
    .width(100.percent)
}

@Builder
func buildHomeWorkPanel(shell: AppShell) {
    Column() {
        buildHomeWorkRow(shell, 0x68D968, "◎", shell.t("issues"), {
            =>
            if (shell.hasLiveIssues()) {
                shell.openSelectedIssue()
            } else {
                shell.openPendingPage(shell.t("issues"), "该页面待开发")
            }
        })
        buildHomeDivider(shell)
        buildHomeWorkRow(shell, 0x4B88FF, "⎇", shell.t("pull_requests"), {
            =>
            if (shell.hasLivePullRequests()) {
                shell.openSelectedPullRequest()
            } else {
                shell.openPendingPage(shell.t("pull_requests"), "该页面待开发")
            }
        })
        buildHomeDivider(shell)
        buildHomeWorkRow(shell, 0x7B56E8, "◫", shell.t("discussions"), { => shell.openPendingPage(shell.t("discussions"), "该页面待开发") })
        buildHomeDivider(shell)
        buildHomeWorkRow(shell, 0xB0B4C0, "□", shell.t("projects"), { => shell.openPendingPage(shell.t("projects"), "该页面待开发") })
        buildHomeDivider(shell)
        buildHomeWorkRow(shell, 0x4B4F5C, "⌘", shell.t("top_repositories"), { => shell.openPendingPage(shell.t("top_repositories"), "该页面待开发") })
        buildHomeDivider(shell)
        buildHomeWorkRow(shell, 0xF4A24B, "⌂", shell.t("organizations"), { => shell.openPendingPage(shell.t("organizations"), "该页面待开发") })
        buildHomeDivider(shell)
        buildHomeWorkRow(shell, 0xFFD54A, "☆", shell.t("starred"), { => shell.openPendingPage(shell.t("starred"), "该页面待开发") })
    }
    .width(100.percent)
    .backgroundColor(shell.surfaceColor())
    .borderRadius(20)
    .padding(top: 2, bottom: 2)
}

@Builder
func buildHomeWorkRow(shell: AppShell, accentColor: Int64, iconText: String, title: String, onTap: () -> Unit) {
    Row(space: 14) {
        Row() {
            Text(iconText).fontSize(14).fontWeight(FontWeight.Bold).fontColor(0xF8FAFC)
        }
        .width(36)
        .height(36)
        .backgroundColor(accentColor)
        .borderRadius(9)
        .justifyContent(FlexAlign.Center)

        Text(title).fontSize(15).fontColor(shell.primaryTextColor())
        Blank()
        Text("›").fontSize(20).fontColor(shell.secondaryTextColor())
    }
    .width(100.percent)
    .height(58)
    .borderRadius(20)
    .padding(left: 13, right: 13)
    .backgroundColor(shell.surfaceColor())
    .onClick({ _ => onTap() })
}

@Builder
func buildHomeDivider(shell: AppShell) {
    Column() {}
        .width(100.percent)
        .height(1)
        .margin(left: 12, right: 12)
        .backgroundColor(shell.mutedSurfaceColor())
}

@Builder
func buildHomeFavoritesPanel(shell: AppShell) {
    Column(space: 14) {
        Text(shell.t("favorites_empty"))
            .fontSize(13)
            .lineHeight(20)
            .fontColor(shell.primaryTextColor())
        Button(shell.t("add_favorites"))
            .width(100.percent)
            .height(44)
            .backgroundColor(shell.mutedSurfaceColor())
            .fontColor(shell.accentStrongColor())
            .fontSize(15)
            .borderRadius(12)
            .onClick({ _ => shell.openPendingPage(shell.t("favorites"), "该页面待开发") })
    }
    .width(100.percent)
    .padding(18)
    .backgroundColor(shell.surfaceColor())
    .borderRadius(20)
}

@Builder
func buildHomeShortcutsPanel(shell: AppShell) {
    Column(space: 12) {
        Row(space: 8) {
            buildShortcutDot(0x3D404B, "⚡")
            buildShortcutDot(0x3E6D46, "◎")
            buildShortcutDot(0x35599A, "⎇")
            buildShortcutDot(0x5B46A3, "◫")
            buildShortcutDot(0x80573A, "⌂")
            buildShortcutDot(0x7A4854, "⌘")
            buildShortcutDot(0x5A4C79, "□")
            buildShortcutDot(0x42454D, "+")
        }
        .width(100.percent)
        .justifyContent(FlexAlign.Center)

        Text(shell.t("shortcuts_title")).fontSize(15).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center).fontColor(shell.primaryTextColor())
        Text(shell.t("shortcuts_desc"))
            .fontSize(13)
            .lineHeight(20)
            .textAlign(TextAlign.Center)
            .fontColor(shell.secondaryTextColor())
        Button(shell.t("get_started"))
            .width(100.percent)
            .height(44)
            .backgroundColor(shell.mutedSurfaceColor())
            .fontColor(shell.accentStrongColor())
            .fontSize(15)
            .borderRadius(12)
            .onClick({ _ => shell.openPendingPage(shell.t("shortcuts"), "该页面待开发") })
    }
    .width(100.percent)
    .padding(18)
    .backgroundColor(shell.surfaceColor())
    .borderRadius(20)
}

@Builder
func buildShortcutDot(color: Int64, text: String) {
    Row() {
        Text(text).fontSize(12).fontWeight(FontWeight.Bold).fontColor(0xF8FAFC)
    }
    .width(30)
    .height(30)
    .backgroundColor(color)
    .borderRadius(15)
    .justifyContent(FlexAlign.Center)
}

@Builder
func buildHomeRecentPanel(shell: AppShell) {
    Column(space: 10) {
        if (shell.hasLiveIssues()) {
            Text(shell.t("recent_desc"))
                .fontSize(13)
                .lineHeight(20)
                .fontColor(shell.secondaryTextColor())
            buildHomeRecentItem(shell, shell.visibleLiveIssues()[0].title, shell.visibleLiveIssues()[0].summary)
            if (shell.hasLivePullRequests()) {
                buildHomeRecentItem(shell, shell.visibleLivePullRequests()[0].title, shell.visibleLivePullRequests()[0].summary)
            }
        } else {
            Text(shell.t("recent_empty"))
                .fontSize(13)
                .lineHeight(20)
                .fontColor(shell.primaryTextColor())
                .textAlign(TextAlign.Center)
        }
    }
    .width(100.percent)
    .padding(18)
    .backgroundColor(shell.surfaceColor())
    .borderRadius(20)
}

@Builder
func buildHomeRecentItem(shell: AppShell, title: String, summary: String) {
    Column(space: 8) {
        Text(title).fontSize(14).fontWeight(FontWeight.Bold).fontColor(shell.primaryTextColor())
        Text(summary).fontSize(11).lineHeight(17).fontColor(shell.secondaryTextColor())
    }
    .width(100.percent)
}

@Builder
func buildCircleAction(shell: AppShell, label: String, onTap: () -> Unit) {
    Button(label)
        .width(40).height(40).borderRadius(20).backgroundColor(shell.surfaceColor()).fontColor(shell.primaryTextColor()).fontSize(16)
        .onClick({ _ => onTap() })
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
