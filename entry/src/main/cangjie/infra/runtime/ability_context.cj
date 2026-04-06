package ohos_app_cangjie_entry.infra.runtime

import kit.AbilityKit.UIAbilityContext

var appAbilityContext: ?UIAbilityContext = None
var appForegroundHandler: ?() -> Unit = None
var appAuthCallbackHandler: ?(String) -> Unit = None
var pendingAuthCallbackUri: ?String = None

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

/**
 * 注册应用回到前台时的回调，供页面层在授权返回后执行一次状态检查。
 * Registers a foreground callback so UI code can react when the app becomes active again.
 */
public func setAppForegroundHandler(handler: () -> Unit): Unit {
    appForegroundHandler = Some(handler)
}

/**
 * 清理前台回调，避免旧页面实例在销毁后继续被调用。
 * Clears the foreground callback to avoid calling stale UI instances.
 */
public func clearAppForegroundHandler(): Unit {
    appForegroundHandler = None
}

/**
 * 由 UIAbility 生命周期触发前台通知，转发给当前页面壳层。
 * Forwards foreground lifecycle notifications from UIAbility into the active app shell.
 */
public func notifyAppForeground(): Unit {
    if (let Some(handler) <- appForegroundHandler) {
        handler()
    }
}

/**
 * 注册 GitHub 授权回调处理器，供 UI 层接收 deep link 返回的 URL。
 * Registers a GitHub auth callback handler so UI code can receive the deep-link URL.
 */
public func setAppAuthCallbackHandler(handler: (String) -> Unit): Unit {
    appAuthCallbackHandler = Some(handler)
}

/**
 * 清理 GitHub 授权回调处理器，避免页面销毁后仍接收回调。
 * Clears the GitHub auth callback handler when the shell is no longer active.
 */
public func clearAppAuthCallbackHandler(): Unit {
    appAuthCallbackHandler = None
}

/**
 * 转发 GitHub 授权 deep link；若页面尚未挂起处理器，则先暂存本次回调。
 * Forwards a GitHub auth deep link or stores it until the shell registers a handler.
 */
public func notifyAppAuthCallback(uri: String): Unit {
    if (let Some(handler) <- appAuthCallbackHandler) {
        handler(uri)
        return
    }
    pendingAuthCallbackUri = Some(uri)
}

/**
 * 取出启动前暂存的授权回调地址，供首次渲染完成后补处理。
 * Returns any buffered auth callback URL that arrived before the shell was ready.
 */
public func consumePendingAuthCallback(): ?String {
    let value = pendingAuthCallbackUri
    pendingAuthCallbackUri = None
    value
}
