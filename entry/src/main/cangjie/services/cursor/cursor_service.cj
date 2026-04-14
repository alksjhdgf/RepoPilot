package ohos_app_cangjie_entry.services.cursor

import std.collection.{ArrayList, HashMap}
import kit.NetworkKit.*
import ohos.net.http.{HttpData, HttpDataType, HttpRequestOptions, RequestMethod}
import ohos_app_cangjie_entry.domain.{CursorConversationSnapshot, CursorMessageSnapshot, CursorModelSnapshot}
import ohos_app_cangjie_entry.infra.logging.{logDebug, logError, logInfo, logWarn}

let CURSOR_API_BASE = "https://api.cursor.com/v0"

func extractCursorStringField(payload: String, key: String): String {
    let marker = "\"${key}\":"
    match (payload.indexOf(marker)) {
        case Some(start) =>
            let afterMarker = Int64(start + marker.size)
            let remainder = payload[afterMarker..payload.size]
            match (remainder.indexOf("\"")) {
                case Some(openOffset) =>
                    let valueStart = Int64(afterMarker + openOffset + 1)
                    let tail = payload[valueStart..payload.size]
                    match (tail.indexOf("\"")) {
                        case Some(closeOffset) => payload[valueStart..Int64(valueStart + closeOffset)]
                        case None => ""
                    }
                case None => ""
            }
        case None => ""
    }
}

func extractCursorObjectArrayField(payload: String, key: String): ArrayList<String> {
    let items = ArrayList<String>()
    let marker = "\"${key}\":["
    match (payload.indexOf(marker)) {
        case Some(start) =>
            let begin = Int64(start + marker.size)
            let tail = payload[begin..payload.size]
            var objectStart = -1
            var depth = 0
            var inString = false
            var escaping = false
            for (index in 0..tail.size - 1) {
                let current = tail[index]
                if (escaping) {
                    escaping = false
                    continue
                }
                if (current == UInt8(UInt32(r'\\'))) {
                    escaping = true
                    continue
                }
                if (current == UInt8(UInt32(r'"'))) {
                    inString = !inString
                    continue
                }
                if (inString) {
                    continue
                }
                if (current == UInt8(UInt32(r'{'))) {
                    if (depth == 0) {
                        objectStart = index
                    }
                    depth++
                    continue
                }
                if (current == UInt8(UInt32(r'}'))) {
                    depth--
                    if (depth == 0 && objectStart >= 0) {
                        items.add(tail[objectStart..index + 1])
                        objectStart = -1
                    }
                    continue
                }
                if (depth == 0 && current == UInt8(UInt32(r']'))) {
                    break
                }
            }
        case None => ()
    }
    items
}

func extractCursorStringArrayField(payload: String, key: String): ArrayList<String> {
    let items = ArrayList<String>()
    let marker = "\"${key}\":["
    match (payload.indexOf(marker)) {
        case Some(start) =>
            let begin = Int64(start + marker.size)
            let tail = payload[begin..payload.size]
            var stringStart = -1
            var escaping = false
            for (index in 0..tail.size - 1) {
                let ch = tail[index]
                if (escaping) {
                    escaping = false
                    continue
                }
                if (ch == UInt8(UInt32(r'\\'))) {
                    escaping = true
                    continue
                }
                if (ch == UInt8(UInt32(r'"'))) {
                    if (stringStart < 0) {
                        stringStart = index + 1
                    } else {
                        items.add(tail[stringStart..index])
                        stringStart = -1
                    }
                    continue
                }
                if (stringStart < 0 && ch == UInt8(UInt32(r']'))) {
                    break
                }
            }
        case None => ()
    }
    items
}

func requestCursorJson(
    url: String,
    apiKey: String,
    onSuccess: (String) -> Unit,
    onFailure: (String) -> Unit,
    method!: RequestMethod = RequestMethod.Get,
    payload!: String = ""
): Unit {
    logInfo("CursorApi", "Requesting ${url}")
    let httpRequest = createHttp()
    let headers = HashMap<String, String>()
    headers.add("Authorization", "Bearer ${apiKey}")
    if (payload != "") {
        headers.add("Content-Type", "application/json")
    }
    let options = HttpRequestOptions(
        method: method,
        header: headers,
        extraData: HttpData.StringData(payload),
        expectDataType: HttpDataType.StringValue
    )
    httpRequest.request(
        url,
        options,
        {
            err, resp =>
            if (let Some(networkError) <- err) {
                httpRequest.destroy()
                logError("CursorApi", "Request failed: ${networkError.code} ${networkError.message}")
                onFailure("Cursor network error ${networkError.code}: ${networkError.message}")
                return
            }
            if (let Some(response) <- resp) {
                let body = match (response.result) {
                    case HttpData.StringData(content) => content
                    case _ => ""
                }
                httpRequest.destroy()
                logDebug("CursorApi", "Response ${response.responseCode} from ${url}")
                if (response.responseCode >= 200u32 && response.responseCode < 300u32) {
                    onSuccess(body)
                } else {
                    let message = extractCursorStringField(body, "message")
                    if (message == "") {
                        onFailure("Cursor API ${response.responseCode}")
                    } else {
                        onFailure("Cursor API ${response.responseCode}: ${message}")
                    }
                }
                return
            }
            httpRequest.destroy()
            logWarn("CursorApi", "Cursor returned no response for ${url}")
            onFailure("Cursor returned no response.")
        }
    )
}

/**
 * 拉取当前账号下的 Cursor agents 列表，并映射为应用内的会话摘要。
 * Loads Cursor background agents and maps them into conversation summaries for the client.
 */
public func fetchCursorAgents(
    apiKey: String,
    onSuccess: (ArrayList<CursorConversationSnapshot>) -> Unit,
    onFailure: (String) -> Unit
): Unit {
    requestCursorJson(
        "${CURSOR_API_BASE}/agents",
        apiKey,
        { body =>
            let items = ArrayList<CursorConversationSnapshot>()
            for (item in extractCursorObjectArrayField(body, "agents")) {
                let id = extractCursorStringField(item, "id")
                if (id == "") {
                    continue
                }
                let name = extractCursorStringField(item, "name")
                let summary = extractCursorStringField(item, "summary")
                let status = extractCursorStringField(item, "status")
                let createdAt = extractCursorStringField(item, "createdAt")
                items.add(
                    CursorConversationSnapshot(
                        id,
                        if (name == "") { id } else { name },
                        "claude-haiku-4.5",
                        if (summary == "") { status } else { summary },
                        if (createdAt == "") { status } else { createdAt }
                    )
                )
            }
            logInfo("CursorApi", "Loaded ${items.size} Cursor agents.")
            onSuccess(items)
        },
        onFailure
    )
}

/**
 * 拉取指定 Cursor agent 的对话历史。
 * Loads the message history for a specific Cursor background agent.
 */
public func fetchCursorAgentConversation(
    apiKey: String,
    agentId: String,
    onSuccess: (ArrayList<CursorMessageSnapshot>) -> Unit,
    onFailure: (String) -> Unit
): Unit {
    requestCursorJson(
        "${CURSOR_API_BASE}/agents/${agentId}/conversation",
        apiKey,
        { body =>
            let items = ArrayList<CursorMessageSnapshot>()
            for (item in extractCursorObjectArrayField(body, "messages")) {
                let id = extractCursorStringField(item, "id")
                let role = extractCursorStringField(item, "type")
                let text = extractCursorStringField(item, "text")
                if (id == "" || text == "") {
                    continue
                }
                items.add(
                    CursorMessageSnapshot(
                        id,
                        if (role == "assistant_message") { "assistant" } else { "user" },
                        text
                    )
                )
            }
            logInfo("CursorApi", "Loaded ${items.size} Cursor messages for ${agentId}.")
            onSuccess(items)
        },
        onFailure
    )
}

func cursorModelGroup(modelId: String): String {
    if (
        modelId.contains("mini") ||
        modelId.contains("haiku") ||
        modelId == "o3"
    ) {
        return "fast"
    }
    "versatile"
}

func cursorModelProvider(modelId: String): String {
    if (modelId.contains("claude")) {
        return "AI"
    }
    if (modelId.contains("gpt") || modelId == "o3" || modelId.contains("o4")) {
        return "OA"
    }
    "AI"
}

func cursorModelTitleFromId(modelId: String): String {
    modelId
}

public func fetchCursorModels(
    apiKey: String,
    onSuccess: (ArrayList<CursorModelSnapshot>) -> Unit,
    onFailure: (String) -> Unit
): Unit {
    requestCursorJson(
        "${CURSOR_API_BASE}/models",
        apiKey,
        { body =>
            let items = ArrayList<CursorModelSnapshot>()
            let models = extractCursorStringArrayField(body, "models")
            for (modelId in models) {
                items.add(
                    CursorModelSnapshot(
                        modelId,
                        cursorModelTitleFromId(modelId),
                        cursorModelProvider(modelId),
                        cursorModelGroup(modelId)
                    )
                )
            }
            logInfo("CursorApi", "Loaded ${items.size} Cursor models.")
            onSuccess(items)
        },
        onFailure
    )
}

func escapeCursorJson(value: String): String {
    value.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n")
}

/**
 * 启动新的 Cursor background agent。
 * Launches a new Cursor background agent for the selected repository.
 */
public func launchCursorAgent(
    apiKey: String,
    prompt: String,
    repositoryUrl: String,
    branchName: String,
    modelId: String,
    onSuccess: (CursorConversationSnapshot) -> Unit,
    onFailure: (String) -> Unit
): Unit {
    let payload =
        "{\"prompt\":{\"text\":\"${escapeCursorJson(prompt)}\"},\"source\":{\"repository\":\"${escapeCursorJson(repositoryUrl)}\",\"ref\":\"${escapeCursorJson(branchName)}\"},\"model\":\"${escapeCursorJson(modelId)}\",\"target\":{\"autoCreatePr\":false}}"
    requestCursorJson(
        "${CURSOR_API_BASE}/agents",
        apiKey,
        { body =>
            let id = extractCursorStringField(body, "id")
            if (id == "") {
                onFailure("Cursor did not return an agent id.")
                return
            }
            let name = extractCursorStringField(body, "name")
            let summary = extractCursorStringField(body, "summary")
            let createdAt = extractCursorStringField(body, "createdAt")
            onSuccess(
                CursorConversationSnapshot(
                    id,
                    if (name == "") { prompt } else { name },
                    modelId,
                    if (summary == "") { prompt } else { summary },
                    if (createdAt == "") { "RUNNING" } else { createdAt }
                )
            )
        },
        onFailure,
        method: RequestMethod.Post,
        payload: payload
    )
}

/**
 * 向运行中的 Cursor agent 发送 follow-up。
 * Sends an additional follow-up instruction to an existing Cursor background agent.
 */
public func sendCursorAgentFollowup(
    apiKey: String,
    agentId: String,
    prompt: String,
    onSuccess: () -> Unit,
    onFailure: (String) -> Unit
): Unit {
    let payload = "{\"text\":\"${escapeCursorJson(prompt)}\"}"
    requestCursorJson(
        "${CURSOR_API_BASE}/agents/${agentId}/followup",
        apiKey,
        { _ => onSuccess() },
        onFailure,
        method: RequestMethod.Post,
        payload: payload
    )
}
