package ohos_app_cangjie_entry.services.cursor

import std.collection.ArrayList
import ohos_app_cangjie_entry.domain.{CursorConversationSnapshot, CursorMessageSnapshot}
import ohos_app_cangjie_entry.infra.databoard.{dataBoardDelete, dataBoardGet, dataBoardSet}

let CURSOR_API_KEY_STORE_KEY = "cursor_api_key"
let CURSOR_CONVERSATIONS_STORE_KEY = "cursor_cached_conversations"
let CURSOR_MESSAGES_STORE_KEY_PREFIX = "cursor_cached_messages_"

func isBackslash(ch: UInt8): Bool { ch == UInt8(UInt32(r'\\')) }
func isNewline(ch: UInt8): Bool { ch == UInt8(UInt32(r'\n')) }
func isTab(ch: UInt8): Bool { ch == UInt8(UInt32(r'\t')) }
func isCharN(ch: UInt8): Bool { ch == UInt8(UInt32(r'n')) }
func isCharT(ch: UInt8): Bool { ch == UInt8(UInt32(r't')) }
func isCharSlash(ch: UInt8): Bool { ch == UInt8(UInt32(r'\\')) }

func escapeStoreField(value: String): String {
    value
        .replace("\\", "\\\\")
        .replace("\n", "\\n")
        .replace("\t", "\\t")
}

func unescapeStoreField(value: String): String {
    var result = ""
    var index = 0
    while (index < value.size) {
        let ch = value[index]
        if (isBackslash(ch) && index + 1 < value.size) {
            let next = value[index + 1]
            if (isCharN(next)) {
                result += "\n"
            } else if (isCharT(next)) {
                result += "\t"
            } else if (isCharSlash(next)) {
                result += "\\"
            } else {
                result += value[index..index + 2]
            }
            index += 2
            continue
        }
        result += value[index..index + 1]
        index += 1
    }
    result
}

func splitEscaped(value: String, delimiter: UInt8): ArrayList<String> {
    let items = ArrayList<String>()
    if (value == "") {
        return items
    }
    var start = 0
    var index = 0
    var escaping = false
    while (index < value.size) {
        let ch = value[index]
        if (escaping) {
            escaping = false
            index += 1
            continue
        }
        if (isBackslash(ch)) {
            escaping = true
            index += 1
            continue
        }
        if (ch == delimiter) {
            items.add(unescapeStoreField(value[start..index]))
            start = index + 1
        }
        index += 1
    }
    items.add(unescapeStoreField(value[start..value.size]))
    items
}

func joinEscapedFields(fields: ArrayList<String>, delimiter: String): String {
    var result = ""
    for (index in 0..fields.size) {
        if (index > 0) {
            result += delimiter
        }
        result += escapeStoreField(fields[index])
    }
    result
}

func serializeConversation(snapshot: CursorConversationSnapshot): String {
    let fields = ArrayList<String>()
    fields.add(snapshot.id)
    fields.add(snapshot.title)
    fields.add(snapshot.modelId)
    fields.add(snapshot.preview)
    fields.add(snapshot.updatedAtLabel)
    joinEscapedFields(fields, "\t")
}

func deserializeConversation(value: String): ?CursorConversationSnapshot {
    let fields = splitEscaped(value, UInt8(UInt32(r'\t')))
    if (fields.size < 5) {
        return None
    }
    Some(CursorConversationSnapshot(fields[0], fields[1], fields[2], fields[3], fields[4]))
}

func serializeConversations(items: ArrayList<CursorConversationSnapshot>): String {
    var result = ""
    for (index in 0..items.size) {
        if (index > 0) {
            result += "\n"
        }
        result += serializeConversation(items[index])
    }
    result
}

func deserializeConversations(value: String): ArrayList<CursorConversationSnapshot> {
    let items = ArrayList<CursorConversationSnapshot>()
    for (record in splitEscaped(value, UInt8(UInt32(r'\n')))) {
        if (record == "") {
            continue
        }
        if (let Some(snapshot) <- deserializeConversation(record)) {
            items.add(snapshot)
        }
    }
    items
}

func serializeMessage(snapshot: CursorMessageSnapshot): String {
    let fields = ArrayList<String>()
    fields.add(snapshot.id)
    fields.add(snapshot.role)
    fields.add(snapshot.body)
    fields.add(if (snapshot.failed) { "1" } else { "0" })
    fields.add(snapshot.failureReason)
    joinEscapedFields(fields, "\t")
}

func deserializeMessage(value: String): ?CursorMessageSnapshot {
    let fields = splitEscaped(value, UInt8(UInt32(r'\t')))
    if (fields.size < 5) {
        return None
    }
    Some(CursorMessageSnapshot(fields[0], fields[1], fields[2], fields[3] == "1", fields[4]))
}

func serializeMessages(items: ArrayList<CursorMessageSnapshot>): String {
    var result = ""
    for (index in 0..items.size) {
        if (index > 0) {
            result += "\n"
        }
        result += serializeMessage(items[index])
    }
    result
}

func deserializeMessages(value: String): ArrayList<CursorMessageSnapshot> {
    let items = ArrayList<CursorMessageSnapshot>()
    for (record in splitEscaped(value, UInt8(UInt32(r'\n')))) {
        if (record == "") {
            continue
        }
        if (let Some(snapshot) <- deserializeMessage(record)) {
            items.add(snapshot)
        }
    }
    items
}

func messageCacheKey(conversationId: String): String {
    "${CURSOR_MESSAGES_STORE_KEY_PREFIX}${conversationId}"
}

func findConversationIndex(items: ArrayList<CursorConversationSnapshot>, conversationId: String): Int64 {
    for (index in 0..items.size) {
        if (items[index].id == conversationId) {
            return index
        }
    }
    -1
}

func messageDedupKey(snapshot: CursorMessageSnapshot): String {
    "${snapshot.role}\n${snapshot.body}"
}

func countMatchingMessages(items: ArrayList<CursorMessageSnapshot>, key: String): Int64 {
    var count = 0
    for (item in items) {
        if (messageDedupKey(item) == key) {
            count += 1
        }
    }
    count
}

public func isLocalCursorConversationId(conversationId: String): Bool {
    conversationId.startsWith("conv_local_")
}

public func loadStoredCursorApiKey(): String {
    dataBoardGet(CURSOR_API_KEY_STORE_KEY)
}

public func persistStoredCursorApiKey(apiKey: String): Unit {
    dataBoardSet(CURSOR_API_KEY_STORE_KEY, apiKey)
}

public func clearStoredCursorApiKey(): Unit {
    dataBoardDelete(CURSOR_API_KEY_STORE_KEY)
}

public func loadStoredCursorConversations(): ArrayList<CursorConversationSnapshot> {
    deserializeConversations(dataBoardGet(CURSOR_CONVERSATIONS_STORE_KEY))
}

public func persistStoredCursorConversations(items: ArrayList<CursorConversationSnapshot>): Unit {
    dataBoardSet(CURSOR_CONVERSATIONS_STORE_KEY, serializeConversations(items))
}

public func upsertStoredCursorConversation(snapshot: CursorConversationSnapshot): ArrayList<CursorConversationSnapshot> {
    let items = loadStoredCursorConversations()
    let existingIndex = findConversationIndex(items, snapshot.id)
    if (existingIndex >= 0) {
        items[existingIndex] = snapshot
    } else {
        items.add(snapshot)
    }
    persistStoredCursorConversations(items)
    items
}

public func removeStoredCursorConversation(conversationId: String): ArrayList<CursorConversationSnapshot> {
    let items = ArrayList<CursorConversationSnapshot>()
    for (item in loadStoredCursorConversations()) {
        if (item.id != conversationId) {
            items.add(item)
        }
    }
    persistStoredCursorConversations(items)
    dataBoardDelete(messageCacheKey(conversationId))
    items
}

public func replaceStoredCursorConversation(fromConversationId: String, snapshot: CursorConversationSnapshot): ArrayList<CursorConversationSnapshot> {
    let items = removeStoredCursorConversation(fromConversationId)
    let existingIndex = findConversationIndex(items, snapshot.id)
    if (existingIndex >= 0) {
        items[existingIndex] = snapshot
    } else {
        items.add(snapshot)
    }
    persistStoredCursorConversations(items)
    items
}

public func mergeStoredCursorConversations(cloudItems: ArrayList<CursorConversationSnapshot>): ArrayList<CursorConversationSnapshot> {
    let merged = ArrayList<CursorConversationSnapshot>()
    let stored = loadStoredCursorConversations()
    for (item in cloudItems) {
        merged.add(item)
    }
    for (item in stored) {
        if (findConversationIndex(merged, item.id) < 0) {
            merged.add(item)
        }
    }
    persistStoredCursorConversations(merged)
    merged
}

public func loadStoredCursorMessages(conversationId: String): ArrayList<CursorMessageSnapshot> {
    if (conversationId == "") {
        return ArrayList<CursorMessageSnapshot>()
    }
    deserializeMessages(dataBoardGet(messageCacheKey(conversationId)))
}

public func persistStoredCursorMessages(conversationId: String, items: ArrayList<CursorMessageSnapshot>): Unit {
    if (conversationId == "") {
        return
    }
    dataBoardSet(messageCacheKey(conversationId), serializeMessages(items))
}

public func migrateStoredCursorMessages(fromConversationId: String, toConversationId: String): Unit {
    if (fromConversationId == "" || toConversationId == "" || fromConversationId == toConversationId) {
        return
    }
    let items = loadStoredCursorMessages(fromConversationId)
    persistStoredCursorMessages(toConversationId, items)
    dataBoardDelete(messageCacheKey(fromConversationId))
}

public func mergeStoredCursorMessages(
    conversationId: String,
    cloudItems: ArrayList<CursorMessageSnapshot>
): ArrayList<CursorMessageSnapshot> {
    let localItems = loadStoredCursorMessages(conversationId)
    if (localItems.size == 0) {
        persistStoredCursorMessages(conversationId, cloudItems)
        return cloudItems
    }
    let merged = ArrayList<CursorMessageSnapshot>()
    for (item in cloudItems) {
        merged.add(item)
    }
    for (item in localItems) {
        if (item.failed) {
            merged.add(item)
            continue
        }
        let key = messageDedupKey(item)
        if (countMatchingMessages(cloudItems, key) <= 0) {
            merged.add(item)
        }
    }
    persistStoredCursorMessages(conversationId, merged)
    merged
}

public func validateCursorSession(
    apiKey: String,
    onSuccess: (ArrayList<CursorConversationSnapshot>) -> Unit,
    onFailure: (String) -> Unit
): Unit {
    fetchCursorAgents(
        apiKey,
        { items => onSuccess(mergeStoredCursorConversations(items)) },
        onFailure
    )
}

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
