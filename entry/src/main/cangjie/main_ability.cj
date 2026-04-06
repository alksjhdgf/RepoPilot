package ohos_app_cangjie_entry

import kit.PerformanceAnalysisKit.Hilog
import kit.AbilityKit.Want
import kit.AbilityKit.UIAbility
import kit.AbilityKit.LaunchParam
import kit.AbilityKit.LaunchReason
import kit.ArkUI.WindowStage
import ohos_app_cangjie_entry.infra.runtime.{notifyAppForeground, setAppAbilityContext}

class MainAbility <: UIAbility {
    public init() {
        super()
        registerSelf()
    }

    public override func onCreate(want: Want, launchParam: LaunchParam): Unit {
        Hilog.info(1, "Cangjie", "MainAbility OnCreated.${want.abilityName}")
        match (launchParam.launchReason) {
            case LaunchReason.StartAbility => Hilog.info(1, "Cangjie", "START_ABILITY")
            case _ => ()
        }
    }

    public override func onWindowStageCreate(windowStage: WindowStage): Unit {
        Hilog.info(1, "Cangjie", "MainAbility onWindowStageCreate.")
        setAppAbilityContext(this.context)
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
}
