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
                .onClick({ _ => shell.setAuthMessage("GitHub Enterprise sign-in is not implemented yet.") })

            if (shell.authMessageValue() != "") {
                Text(shell.authMessageValue())
                    .fontSize(13)
                    .fontColor(0xFCA5A5)
                    .textAlign(TextAlign.Center)
            }

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
func buildFloatingNavigation(shell: AppShell) {
    Row(space: 8) {
        buildNavItem(shell, "home", "home_short")
        buildNavItem(shell, "inbox", "inbox_short")
        buildNavItem(shell, "explore", "explore_short")
        buildNavItem(shell, "cursor", "cursor_short")
    }
    .width(84.percent)
    .padding(left: 8, right: 8, top: 8, bottom: 8)
    .backgroundColor(shell.navBarOverlayColor())
    .borderRadius(22)
    .shadow(radius: 22.0, color: shell.shadowColor(), offsetX: 0.0, offsetY: 12.0)
    .margin(bottom: 8)
}

@Builder
func buildNavItem(shell: AppShell, id: String, shortTitleKey: String) {
    Button() {
        Column(space: 4) {
            Text(shell.t(shortTitleKey)).fontSize(14).fontWeight(FontWeight.Medium)
                .fontColor(if (shell.isActiveTab(id)) { shell.primaryTextColor() } else { shell.secondaryTextColor() })
        }
        .width(100.percent)
        .justifyContent(FlexAlign.Center)
    }
    .width(0)
    .layoutWeight(1)
    .height(50)
    .backgroundColor(if (shell.isActiveTab(id)) { shell.navSelectionColor() } else { shell.navBarColor() })
    .borderRadius(16)
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
    .margin(left: 18, right: 18)
}

@Builder
func buildWorkplaceOption(shell: AppShell, workplaceId: String) {
    Button() {
        Row() {
            Column() {
                Text(shell.t(workplaceSnapshot(workplaceId).titleKey)).fontSize(16).fontWeight(FontWeight.Medium).fontColor(shell.primaryTextColor())
            }
            .alignItems(HorizontalAlign.Start)
            Blank()
            Text(if (shell.isCurrentWorkplace(workplaceId)) { "ON" } else { "" }).fontSize(12).fontColor(shell.accentStrongColor())
        }
        .width(100.percent)
        .padding(left: 14, right: 14)
    }
    .width(100.percent)
    .height(64)
    .backgroundColor(if (shell.isCurrentWorkplace(workplaceId)) { shell.navSelectionColor() } else { shell.mutedSurfaceColor() })
    .borderRadius(18)
    .onClick({ _ => shell.switchWorkplace(workplaceId) })
}
