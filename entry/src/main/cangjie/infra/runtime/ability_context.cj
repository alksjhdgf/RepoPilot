package ohos_app_cangjie_entry.infra.runtime

import kit.AbilityKit.UIAbilityContext
import kit.ArkUI.{SystemBarProperties, Window}

var appAbilityContext: ?UIAbilityContext = None
var appMainWindow: ?Window = None
var appForegroundHandler: ?() -> Unit = None
var appAuthCallbackHandler: ?(String) -> Unit = None
var appPreferenceHandler: ?(String, String) -> Unit = None
var appDataRefreshHandler: ?(String, () -> Unit) -> Unit = None
var pendingAuthCallbackUri: ?String = None

/**
 * 保存主 Ability 上下文，供页面层拉起系统能力时复用。
 * Stores the main UIAbility context for page-level system interactions.
 */
public func setAppAbilityContext(context: UIAbilityContext): Unit {
    appAbilityContext = Some(context)
}

/**
 * 保存主窗口对象，供主题切换时同步系统状态栏样式。
 * Stores the main window so the app can refresh status bar appearance on theme changes.
 */
public func setAppMainWindow(window: Window): Unit {
    appMainWindow = Some(window)
}

/**
 * 获取当前应用的 UIAbility 上下文。
 * Returns the current app UIAbility context when it has been initialized.
 */
public func getAppAbilityContext(): UIAbilityContext {
    appAbilityContext.getOrThrow()
}

/**
 * 按当前主题刷新状态栏内容颜色，避免深色背景下状态栏图标仍为深色。
 * Updates the status bar content colors so they stay visible across theme changes.
 */
public func applyAppStatusBarStyle(isDarkTheme: Bool): Unit {
    if (let Some(window) <- appMainWindow) {
        let systemBarProperties = if (isDarkTheme) {
            SystemBarProperties(
                statusBarColor: "#00000000",
                isStatusBarLightIcon: true,
                statusBarContentColor: "#FFFFFFFF"
            )
        } else {
            SystemBarProperties(
                statusBarColor: "#00000000",
                isStatusBarLightIcon: false,
                statusBarContentColor: "#FF111827"
            )
        }
        window.setWindowSystemBarProperties(systemBarProperties)
    }
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
 * 注册偏好设置变更处理器，供设置页面把主题/语言修改统一交回 AppShell。
 * Registers a preference-change handler so settings pages can delegate updates back to AppShell.
 */
public func setAppPreferenceHandler(handler: (String, String) -> Unit): Unit {
    appPreferenceHandler = Some(handler)
}

/**
 * 清理偏好设置处理器，避免旧页面实例销毁后仍然接收设置动作。
 * Clears the preference handler when the active shell disappears.
 */
public func clearAppPreferenceHandler(): Unit {
    appPreferenceHandler = None
}

/**
 * 将主题或语言变更动作派发给当前 AppShell。
 * Forwards theme or language change requests into the active app shell.
 */
public func notifyAppPreferenceChange(kind: String, value: String): Unit {
    if (let Some(handler) <- appPreferenceHandler) {
        handler(kind, value)
    }
}

/**
 * 注册全局数据刷新处理器，供独立页面把刷新动作交回 AppShell。
 * Registers a shared data-refresh handler so standalone pages can delegate refresh work to AppShell.
 */
public func setAppDataRefreshHandler(handler: (String, () -> Unit) -> Unit): Unit {
    appDataRefreshHandler = Some(handler)
}

/**
 * 清理全局数据刷新处理器，避免旧壳层销毁后仍接收刷新动作。
 * Clears the shared data-refresh handler when the active shell disappears.
 */
public func clearAppDataRefreshHandler(): Unit {
    appDataRefreshHandler = None
}

/**
 * 将页面发起的数据刷新动作转交给当前 AppShell。
 * Forwards page-initiated data refresh actions into the active app shell.
 */
public func notifyAppDataRefresh(kind: String, onComplete: () -> Unit): Unit {
    if (let Some(handler) <- appDataRefreshHandler) {
        handler(kind, onComplete)
        return
    }
    onComplete()
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
