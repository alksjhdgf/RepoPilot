package ohos_app_cangjie_entry.infra.databoard

import kit.ArkData.*
import std.sync.*
import ohos.business_exception.BusinessException
import ohos_app_cangjie_entry.infra.logging.{logDebug, logWarn}
import ohos_app_cangjie_entry.infra.runtime.getAppAbilityContext

let DATABOARD_STORE_NAME = "repopilot_databoard"
let dataBoardMonitor = Monitor()
var dataBoardPreferences: ?Preferences = None

/**
 * 获取全局 databoard 的 Preferences 实例，并将实例缓存到进程内。
 * Returns the cached Preferences instance backing the global databoard store.
 */
func resolveDataBoardPreferencesUnsafe(): Preferences {
    if (let Some(existing) <- dataBoardPreferences) {
        return existing
    }
    let created = Preferences.getPreferences(getAppAbilityContext(), PreferencesOptions(DATABOARD_STORE_NAME))
    dataBoardPreferences = Some(created)
    created
}

/**
 * 读取 databoard 中的 JSON 字符串值；读操作也会经过锁保护，避免并发访问冲突。
 * Reads a JSON string from databoard under the shared monitor to avoid concurrent races.
 */
public func dataBoardGet(key: String): String {
    synchronized(dataBoardMonitor) {
        try {
            let value = resolveDataBoardPreferencesUnsafe().get(key, PreferencesValueType.StringData(""))
            match (value) {
                case PreferencesValueType.StringData(content) => content
                case _ => ""
            }
        } catch (e: BusinessException) {
            logWarn("DataBoard", "Read failed for ${key}: ${e.code} ${e.message}")
            ""
        }
    }
}

/**
 * 将 JSON 字符串写入 databoard，并立即 flush 到磁盘；写操作通过锁串行化。
 * Stores a JSON string in databoard and flushes it under a shared process lock.
 */
public func dataBoardSet(key: String, value: String): Unit {
    synchronized(dataBoardMonitor) {
        try {
            let preferences = resolveDataBoardPreferencesUnsafe()
            preferences.put(key, PreferencesValueType.StringData(value))
            preferences.flush()
            logDebug("DataBoard", "Persisted ${key}.")
        } catch (e: BusinessException) {
            logWarn("DataBoard", "Write failed for ${key}: ${e.code} ${e.message}")
        }
    }
}

/**
 * 删除 databoard 中的指定键，并立即持久化清理结果。
 * Deletes a databoard entry and flushes the change immediately.
 */
public func dataBoardDelete(key: String): Unit {
    synchronized(dataBoardMonitor) {
        try {
            let preferences = resolveDataBoardPreferencesUnsafe()
            preferences.delete(key)
            preferences.flush()
            logDebug("DataBoard", "Deleted ${key}.")
        } catch (e: BusinessException) {
            logWarn("DataBoard", "Delete failed for ${key}: ${e.code} ${e.message}")
        }
    }
}
