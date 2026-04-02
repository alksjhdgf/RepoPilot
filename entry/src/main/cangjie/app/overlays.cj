package ohos_app_cangjie_entry.app

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.Builder
import ohos_app_cangjie_entry.services.platform.workplaceSnapshot

@Builder
func buildAuthWelcome(shell: AppShell) {
    Column(space: 22) {
        Blank()
        Column(space: 20) {
            Column() {
                Text("GH")
                    .fontSize(32)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(0x101828)
            }
            .width(92)
            .height(92)
            .backgroundColor(0xFFFFFF)
            .borderRadius(46)
            .justifyContent(FlexAlign.Center)

            Button(shell.t("sign_in_github"))
                .width(100.percent)
                .height(56)
                .backgroundColor(0xFFFFFF)
                .fontColor(0x111827)
                .fontSize(18)
                .borderRadius(18)
                .onClick({ _ => shell.beginAuth() })

            Button(shell.t("sign_in_enterprise"))
                .width(100.percent)
                .height(56)
                .backgroundColor(0x27272A)
                .fontColor(0xF8FAFC)
                .fontSize(18)
                .borderRadius(18)

            Text(shell.t("auth_enterprise_hint"))
                .fontSize(13)
                .fontColor(0x98A2B3)

            Text(shell.t("auth_terms"))
                .fontSize(13)
                .fontColor(0x98A2B3)
                .textAlign(TextAlign.Center)
        }
        .width(100.percent)
        .padding(left: 24, right: 24)
        Blank()
    }
    .width(100.percent)
    .height(100.percent)
}

@Builder
func buildAuthCredentials(shell: AppShell) {
    Column() {
        Row() {
            Button("X")
                .width(40).height(40).backgroundColor(0x1E232C).fontColor(0xF8FAFC).borderRadius(20)
                .onClick({ _ => shell.returnToAuthWelcome() })
            Blank()
            Text(shell.t("auth_web_title")).fontSize(20).fontWeight(FontWeight.Bold).fontColor(0xF8FAFC)
            Blank()
            Button("...").width(40).height(40).backgroundColor(0x1E232C).fontColor(0xF8FAFC).borderRadius(20)
        }
        .width(100.percent)
        .padding(left: 18, right: 18, top: 16)

        Column(space: 18) {
            Blank().height(32)
            Text(shell.t("auth_web_subtitle")).fontSize(16).fontColor(0xE5E7EB).textAlign(TextAlign.Center)
            Text(shell.authMessageText()).fontSize(14).fontColor(0x98A2B3).textAlign(TextAlign.Center)
            buildAuthField("Verification URL", shell.authVerificationHint())
            buildAuthField("User Code", shell.authUserCodeValue())
            Button(shell.t("sign_in_github"))
                .width(100.percent).height(48).backgroundColor(0x458D45).fontColor(0xF8FAFC).fontSize(18).borderRadius(10)
                .onClick({ _ => shell.confirmAuth() })
        }
        .width(100.percent)
        .padding(left: 18, right: 18, top: 24)
    }
    .width(100.percent)
    .height(100.percent)
    .backgroundColor(0x11151B)
}

@Builder
func buildAuthConnected(shell: AppShell) {
    Column(space: 18) {
        Blank()
        Column(space: 14) {
            Text(shell.t("auth_connected_title")).fontSize(30).fontWeight(FontWeight.Bold).fontColor(shell.primaryTextColor())
            Text(shell.t("auth_connected_body")).fontSize(14).fontColor(shell.secondaryTextColor())
            Text(shell.t("auth_review_access")).fontSize(13).fontColor(shell.accentStrongColor())
        }
        .width(100.percent)
        .padding(24)
        .backgroundColor(shell.surfaceColor())
        .borderRadius(28)

        Button(shell.t("continue_to_workplace"))
            .width(100.percent).height(52).backgroundColor(shell.surfaceStrongColor()).fontColor(shell.heroTextColor()).fontSize(18).borderRadius(18)
            .onClick({ _ => shell.enterWorkspace() })
        Blank()
    }
    .width(100.percent)
    .height(100.percent)
    .padding(left: 18, right: 18, top: 48, bottom: 42)
}

@Builder
func buildAuthField(label: String, value: String) {
    Column(space: 8) {
        Text(label).fontSize(14).fontWeight(FontWeight.Medium).fontColor(0xE5E7EB)
        Row() {
            Text(value).fontSize(15).fontColor(0xF8FAFC)
            Blank()
        }
            .width(100.percent).height(56).padding(left: 14, right: 14)
            .borderRadius(10).backgroundColor(0x151A21).opacity(0.92)
    }
    .width(100.percent)
}

@Builder
func buildFloatingNavigation(shell: AppShell) {
    Row(space: 8) {
        buildNavItem(shell, "home", shell.t("home"), shell.t("home_short"))
        buildNavItem(shell, "inbox", shell.t("inbox"), shell.t("inbox_short"))
        buildNavItem(shell, "explore", shell.t("explore"), shell.t("explore_short"))
        buildNavItem(shell, "profile", shell.t("profile"), shell.t("profile_short"))
    }
    .width(100.percent)
    .padding(left: 12, right: 12, top: 10, bottom: 10)
    .backgroundColor(shell.navBarColor())
    .borderRadius(26)
    .shadow(radius: 22.0, color: shell.shadowColor(), offsetX: 0.0, offsetY: 12.0)
    .margin(left: 18, right: 18, bottom: 22)
}

@Builder
func buildNavItem(shell: AppShell, id: String, title: String, shortTitle: String) {
    Button() {
        Column(space: 6) {
            Text(shortTitle).fontSize(13).fontWeight(FontWeight.Medium)
                .fontColor(if (shell.isActiveTab(id)) { shell.primaryTextColor() } else { shell.secondaryTextColor() })
            Text(title).fontSize(10)
                .fontColor(if (shell.isActiveTab(id)) { shell.primaryTextColor() } else { shell.secondaryTextColor() })
        }
        .width(100.percent)
    }
    .width(0)
    .layoutWeight(1)
    .height(56)
    .backgroundColor(if (shell.isActiveTab(id)) { shell.navSelectionColor() } else { 0x00000000 })
    .borderRadius(20)
    .onClick({ _ => shell.handleTabTap(id) })
}

@Builder
func buildWorkplacePicker(shell: AppShell) {
    Column(space: 14) {
        Text(shell.t("workplace")).fontSize(14).fontWeight(FontWeight.Bold).fontColor(shell.primaryTextColor())
        buildWorkplaceOption(shell, "unified")
        buildWorkplaceOption(shell, "github")
    }
    .width(100.percent)
    .padding(18)
    .backgroundColor(shell.surfaceColor())
    .borderRadius(24)
    .shadow(radius: 24.0, color: shell.shadowColor(), offsetX: 0.0, offsetY: 16.0)
    .margin(left: 18, right: 18, top: 140)
}

@Builder
func buildWorkplaceOption(shell: AppShell, workplaceId: String) {
    Button() {
        Row() {
            Column(space: 4) {
                Text(shell.t(workplaceSnapshot(workplaceId).titleKey)).fontSize(16).fontWeight(FontWeight.Medium).fontColor(shell.primaryTextColor())
                Text(shell.t(workplaceSnapshot(workplaceId).summaryKey)).fontSize(12).fontColor(shell.secondaryTextColor())
            }
            .alignItems(HorizontalAlign.Start)
            Blank()
            Text(if (shell.isCurrentWorkplace(workplaceId)) { "ON" } else { "" }).fontSize(12).fontColor(shell.accentStrongColor())
        }
        .width(100.percent)
    }
    .width(100.percent)
    .height(64)
    .backgroundColor(if (shell.isCurrentWorkplace(workplaceId)) { shell.navSelectionColor() } else { shell.mutedSurfaceColor() })
    .borderRadius(18)
    .onClick({ _ => shell.switchWorkplace(workplaceId) })
}
