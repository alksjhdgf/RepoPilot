package ohos_app_cangjie_entry

import kit.PerformanceAnalysisKit.Hilog
import kit.AbilityKit.Want
import kit.AbilityKit.UIAbility
import kit.AbilityKit.LaunchParam
import kit.AbilityKit.LaunchReason
import kit.ArkUI.{Window, WindowStage}
import ohos_app_cangjie_entry.infra.logging.logInfo
import ohos_app_cangjie_entry.infra.runtime.{applyAppStatusBarStyle, notifyAppAuthCallback, notifyAppForeground, setAppAbilityContext, setAppMainWindow}
import ohos.arkui.state_management.AppStorage

class MainAbility <: UIAbility {
    public init() {
        super()
        registerSelf()
    }

    public override func onCreate(want: Want, launchParam: LaunchParam): Unit {
        Hilog.info(1, "Cangjie", "MainAbility OnCreated.${want.abilityName}")
        this.handleIncomingWant(want)
        match (launchParam.launchReason) {
            case LaunchReason.StartAbility => Hilog.info(1, "Cangjie", "START_ABILITY")
            case _ => ()
        }
    }

    public override func onWindowStageCreate(windowStage: WindowStage): Unit {
        Hilog.info(1, "Cangjie", "MainAbility onWindowStageCreate.")
        setAppAbilityContext(this.context)
        let mainWindow: Window = windowStage.getMainWindow()
        setAppMainWindow(mainWindow)
        applyAppStatusBarStyle(false)
        windowStage.loadContent("EntryView")
    }

    /**
     * 应用回到前台时转发通知给 UI 壳层，让认证流程执行一次补偿检查。
     * Forwards foreground lifecycle events so the shell can re-check auth completion.
     */
    public override func onForeground(): Unit {
        Hilog.info(1, "Cangjie", "MainAbility onForeground.")
        notifyAppForeground()
    }

    /**
     * 处理热启动 deep link，接住 GitHub 授权回调的 code。
     * Handles hot-start deep links and forwards GitHub auth callback codes.
     */
    public override func onNewWant(want: Want, launchParam: LaunchParam): Unit {
        Hilog.info(1, "Cangjie", "MainAbility onNewWant.")
        this.handleIncomingWant(want)
    }

    /**
     * 识别回调 scheme 并把完整 URI 转发给应用壳层。
     * Detects the auth callback scheme and forwards the full URI into the app shell.
     */
    func handleIncomingWant(want: Want): Unit {
        if (want.uri == "") {
            return
        }
        let uri = want.uri
        if (!uri.startsWith("repopilot://auth/callback")) {
            return
        }
        logInfo("MainAbility", "Received GitHub auth callback URI.")
        notifyAppAuthCallback(uri)
    }
}
