package ohos_app_cangjie_entry.infra.logging

import ohos.hilog.Hilog

let APP_LOG_DOMAIN: UInt32 = 0x1001u32
let APP_LOG_TAG = "RPDIAG"

/**
 * 统一记录调试日志，便于后续替换为日志收集或上报实现。
 * Records debug logs through a single entry so later collection changes stay localized.
 */
public func logDebug(scope: String, message: String): Unit {
    Hilog.debug(APP_LOG_DOMAIN, APP_LOG_TAG, "[${scope}] ${message}", [])
}

/**
 * 统一记录信息日志，用于观察正常链路的关键节点。
 * Records info logs for expected flow checkpoints.
 */
public func logInfo(scope: String, message: String): Unit {
    Hilog.info(APP_LOG_DOMAIN, APP_LOG_TAG, "[${scope}] ${message}", [])
}

/**
 * 统一记录警告日志，用于表示可恢复但异常的状态。
 * Records warning logs for recoverable but unexpected states.
 */
public func logWarn(scope: String, message: String): Unit {
    Hilog.warn(APP_LOG_DOMAIN, APP_LOG_TAG, "[${scope}] ${message}", [])
}

/**
 * 统一记录错误日志，用于表示认证、网络或解析失败。
 * Records error logs for auth, network, or parsing failures.
 */
public func logError(scope: String, message: String): Unit {
    Hilog.error(APP_LOG_DOMAIN, APP_LOG_TAG, "[${scope}] ${message}", [])
}
