package ohos_app_cangjie_entry.services.cursor

import std.collection.ArrayList
import ohos_app_cangjie_entry.domain.CursorConversationSnapshot
import ohos_app_cangjie_entry.infra.databoard.{dataBoardDelete, dataBoardGet, dataBoardSet}

let CURSOR_API_KEY_STORE_KEY = "cursor_api_key"

/**
 * 读取本地保存的 Cursor API key。
 * Loads the persisted Cursor API key from local storage.
 */
public func loadStoredCursorApiKey(): String {
    dataBoardGet(CURSOR_API_KEY_STORE_KEY)
}

/**
 * 持久化保存 Cursor API key。
 * Persists the Cursor API key into local storage.
 */
public func persistStoredCursorApiKey(apiKey: String): Unit {
    dataBoardSet(CURSOR_API_KEY_STORE_KEY, apiKey)
}

/**
 * 清空本地保存的 Cursor API key。
 * Clears the persisted Cursor API key from local storage.
 */
public func clearStoredCursorApiKey(): Unit {
    dataBoardDelete(CURSOR_API_KEY_STORE_KEY)
}

/**
 * 使用显式提供的 API key 校验 Cursor 连接并拉取 agents 列表。
 * Validates a Cursor API key and loads the agent list.
 */
public func validateCursorSession(
    apiKey: String,
    onSuccess: (ArrayList<CursorConversationSnapshot>) -> Unit,
    onFailure: (String) -> Unit
): Unit {
    fetchCursorAgents(apiKey, onSuccess, onFailure)
}

/**
 * 使用本地保存的 API key 刷新 Cursor 会话状态。
 * Refreshes Cursor session state using the persisted API key.
 */
public func refreshStoredCursorSession(
    onSuccess: (ArrayList<CursorConversationSnapshot>) -> Unit,
    onMissingKey: () -> Unit,
    onFailure: (String) -> Unit
): Unit {
    let apiKey = loadStoredCursorApiKey()
    if (apiKey == "") {
        onMissingKey()
        return
    }
    validateCursorSession(apiKey, onSuccess, onFailure)
}
