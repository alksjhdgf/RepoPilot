package ohos_app_cangjie_entry.services.github

import std.convert.*

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
