package ohos_app_cangjie_entry.infra.runtime

import kit.AbilityKit.UIAbilityContext

var appAbilityContext: ?UIAbilityContext = None

/**
 * 保存主 Ability 上下文，供页面层拉起系统能力时复用。
 * Stores the main UIAbility context for page-level system interactions.
 */
public func setAppAbilityContext(context: UIAbilityContext): Unit {
    appAbilityContext = context
}

/**
 * 获取当前应用的 UIAbility 上下文。
 * Returns the current app UIAbility context when it has been initialized.
 */
public func getAppAbilityContext(): UIAbilityContext {
    appAbilityContext.getOrThrow()
}
