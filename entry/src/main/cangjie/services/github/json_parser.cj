package ohos_app_cangjie_entry.services.github

import std.collection.ArrayList
import std.convert.*

/**
 * 从简单 JSON 对象中读取字符串字段，适用于当前 GitHub 认证链的轻量解析。
 * Reads a string field from a simple JSON object for the current lightweight GitHub flow.
 */
func extractJsonStringField(payload: String, key: String): String {
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

/**
 * 从简单 JSON 对象中读取整数字段。
 * Reads an integer field from a simple JSON object.
 */
func extractJsonIntField(payload: String, key: String): Int64 {
    let marker = "\"${key}\":"
    match (payload.indexOf(marker)) {
        case Some(start) =>
            let afterMarker = Int64(start + marker.size)
            let tail = payload[afterMarker..payload.size]
            var digits = ""
            for (char in tail) {
                if (char == UInt8(UInt32(r' ')) || char == UInt8(UInt32(r'\n'))) {
                    continue
                }
                if (char >= UInt8(UInt32(r'0')) && char <= UInt8(UInt32(r'9'))) {
                    digits = digits + String.fromUtf8([char])
                    continue
                }
                if (digits != "") {
                    break
                }
                break
            }
            if (digits == "") { 0 } else { Int64.parse(digits) }
        case None => 0
    }
}

/**
 * 从简单 JSON 对象中读取布尔字段。
 * Reads a boolean field from a simple JSON object.
 */
func extractJsonBoolField(payload: String, key: String): Bool {
    let marker = "\"${key}\":"
    match (payload.indexOf(marker)) {
        case Some(start) =>
            let afterMarker = Int64(start + marker.size)
            let tail = payload[afterMarker..payload.size]
            let compact = tail.replace(" ", "").replace("\n", "")
            if (compact.startsWith("true")) { true } else { false }
        case None => false
    }
}

/**
 * 解析顶层 JSON 数组中的对象片段，供仓库列表做最小依赖解析。
 * Extracts top-level object fragments from a JSON array for low-dependency list parsing.
 */
func extractTopLevelObjectArray(payload: String): ArrayList<String> {
    let items = ArrayList<String>()
    var objectStart = -1
    var depth = 0
    var inString = false
    var escaping = false
    for (index in 0..payload.size - 1) {
        let current = payload[index]
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
                items.add(payload[objectStart..index + 1])
                objectStart = -1
            }
        }
    }
    items
}

func extractJsonObjectField(payload: String, key: String): String {
    let marker = "\"${key}\":"
    match (payload.indexOf(marker)) {
        case Some(start) =>
            let afterMarker = Int64(start + marker.size)
            var objectStart = Int64(-1)
            var depth = 0
            var inString = false
            var escaping = false
            for (index in afterMarker..payload.size - 1) {
                let current = payload[index]
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
                if (current == UInt8(UInt32(r' ')) || current == UInt8(UInt32(r'\n'))) {
                    continue
                }
                if (current != UInt8(UInt32(r'{'))) {
                    return ""
                }
                objectStart = index
                depth = 1
                for (inner in index + 1..payload.size - 1) {
                    let next = payload[inner]
                    if (escaping) {
                        escaping = false
                        continue
                    }
                    if (next == UInt8(UInt32(r'\\'))) {
                        escaping = true
                        continue
                    }
                    if (next == UInt8(UInt32(r'"'))) {
                        inString = !inString
                        continue
                    }
                    if (inString) {
                        continue
                    }
                    if (next == UInt8(UInt32(r'{'))) {
                        depth++
                    } else if (next == UInt8(UInt32(r'}'))) {
                        depth--
                        if (depth == 0) {
                            return payload[objectStart..inner + 1]
                        }
                    }
                }
                return ""
            }
            ""
        case None => ""
    }
}

func extractGitHubUserLogin(payload: String): String {
    let userPayload = extractJsonObjectField(payload, "user")
    if (userPayload != "") {
        let nestedLogin = extractJsonStringField(userPayload, "login")
        if (nestedLogin != "") {
            return nestedLogin
        }
    }
    extractJsonStringField(payload, "login")
}

func extractNamedObjectArray(payload: String, key: String): ArrayList<String> {
    let marker = "\"${key}\":"
    match (payload.indexOf(marker)) {
        case Some(start) =>
            let afterMarker = Int64(start + marker.size)
            var arrayStart = Int64(-1)
            var inString = false
            var escaping = false
            for (index in afterMarker..payload.size - 1) {
                let current = payload[index]
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
                if (current == UInt8(UInt32(r' ')) || current == UInt8(UInt32(r'\n'))) {
                    continue
                }
                if (current != UInt8(UInt32(r'['))) {
                    return ArrayList<String>()
                }
                arrayStart = index
                break
            }
            if (arrayStart < 0) {
                return ArrayList<String>()
            }
            var depth = 0
            for (index in arrayStart..payload.size - 1) {
                let current = payload[index]
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
                if (current == UInt8(UInt32(r'['))) {
                    depth++
                } else if (current == UInt8(UInt32(r']'))) {
                    depth--
                    if (depth == 0) {
                        return extractTopLevelObjectArray(payload[arrayStart..index + 1])
                    }
                }
            }
            ArrayList<String>()
        case None => ArrayList<String>()
    }
}
