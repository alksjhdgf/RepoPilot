package ohos_app_cangjie_entry.services.github

import std.collection.HashMap
import kit.NetworkKit.*
import ohos.net.http.{HttpData, HttpDataType, HttpRequestOptions, RequestMethod}
import ohos_app_cangjie_entry.domain.{GitHubAccessTokenSnapshot, GitHubStoredSessionSnapshot}
import ohos_app_cangjie_entry.infra.logging.{logDebug, logError, logInfo, logWarn}

let GITHUB_OAUTH_CLIENT_ID = "Ov23liM4Ky6UX6B2Kf3B"
let GITHUB_OAUTH_CLIENT_SECRET = "f4a47664933d40eda4c88d0c98968c30c4ff34cd"
let GITHUB_OAUTH_REDIRECT_URI = "repopilot://auth/callback"
let GITHUB_OAUTH_SCOPE = "repo delete_repo notifications gist read:org user:follow read:user"
let AUTHORIZE_URL = "https://github.com/login/oauth/authorize"
let ACCESS_TOKEN_URL = "https://github.com/login/oauth/access_token"

func exchangeGitHubTokenPayload(
    payload: String,
    onSuccess: (GitHubAccessTokenSnapshot) -> Unit,
    onFailure: (String) -> Unit
): Unit {
    let httpRequest = createHttp()
    let headers = HashMap<String, String>()
    headers.add("Accept", "application/json")
    headers.add("Content-Type", "application/x-www-form-urlencoded")
    let options = HttpRequestOptions(
        method: RequestMethod.Post,
        header: headers,
        extraData: HttpData.StringData(payload),
        expectDataType: HttpDataType.StringValue
    )
    httpRequest.request(
        ACCESS_TOKEN_URL,
        options,
        {
            err, resp =>
            if (let Some(networkError) <- err) {
                httpRequest.destroy()
                logError("AuthService", "Token exchange failed: ${networkError.code} ${networkError.message}")
                onFailure("Network error ${networkError.code}: ${networkError.message}")
                return
            }
            if (let Some(response) <- resp) {
                logDebug("AuthService", "Web token exchange response code: ${response.responseCode}")
                let body = match (response.result) {
                    case HttpData.StringData(content) => content
                    case _ => ""
                }
                let accessToken = extractJsonStringField(body, "access_token")
                if (accessToken == "") {
                    let errorCode = extractJsonStringField(body, "error")
                    let errorDescription = extractJsonStringField(body, "error_description")
                    logWarn("AuthService", "Web token exchange failed: ${errorCode} ${errorDescription}")
                    if (errorCode != "") {
                        onFailure("${errorCode}: ${errorDescription}")
                    } else {
                        onFailure("GitHub web token exchange did not return an access token.")
                    }
                    httpRequest.destroy()
                    return
                }
                onSuccess(
                    GitHubAccessTokenSnapshot(
                        accessToken,
                        extractJsonStringField(body, "token_type"),
                        extractJsonStringField(body, "scope"),
                        extractJsonStringField(body, "refresh_token"),
                        extractJsonIntField(body, "expires_in"),
                        extractJsonIntField(body, "refresh_token_expires_in")
                    )
                )
                logInfo("AuthService", "GitHub access token acquired through web authorization.")
                httpRequest.destroy()
                return
            }
            httpRequest.destroy()
            logWarn("AuthService", "Web token exchange returned no response.")
            onFailure("GitHub returned no response.")
        }
    )
}

/**
 * 构建 GitHub OAuth Web 授权页链接，供客户端直接拉起网页登录与授权。
 * Builds the GitHub OAuth web authorization URL for direct browser sign-in and consent.
 */
public func buildGitHubAuthorizationUri(state: String): String {
    let encodedScope = GITHUB_OAUTH_SCOPE.replace(" ", "%20")
    "${AUTHORIZE_URL}?client_id=${GITHUB_OAUTH_CLIENT_ID}&redirect_uri=${GITHUB_OAUTH_REDIRECT_URI}&scope=${encodedScope}&state=${state}"
}

/**
 * 使用 GitHub 授权回调中的 code 交换用户访问令牌。
 * Exchanges the callback code from GitHub web auth for a user access token.
 */
public func exchangeGitHubWebCode(
    code: String,
    onSuccess: (GitHubAccessTokenSnapshot) -> Unit,
    onFailure: (String) -> Unit
): Unit {
    logInfo("AuthService", "Exchanging GitHub callback code for access token.")
    let payload = "client_id=${GITHUB_OAUTH_CLIENT_ID}&client_secret=${GITHUB_OAUTH_CLIENT_SECRET}&code=${code}&redirect_uri=${GITHUB_OAUTH_REDIRECT_URI}"
    exchangeGitHubTokenPayload(payload, onSuccess, onFailure)
}

/**
 * 使用 refresh token 获取新的 GitHub 用户访问令牌，避免每次启动都重新登录。
 * Refreshes a GitHub user access token so the app can restore sign-in across launches.
 */
public func refreshGitHubWebToken(
    refreshToken: String,
    onSuccess: (GitHubAccessTokenSnapshot) -> Unit,
    onFailure: (String) -> Unit
): Unit {
    logInfo("AuthService", "Refreshing GitHub access token.")
    let payload =
        "client_id=${GITHUB_OAUTH_CLIENT_ID}&client_secret=${GITHUB_OAUTH_CLIENT_SECRET}" +
        "&grant_type=refresh_token&refresh_token=${refreshToken}"
    exchangeGitHubTokenPayload(payload, onSuccess, onFailure)
}

func escapeJsonString(value: String): String {
    value.replace("\\", "\\\\").replace("\"", "\\\"")
}

/**
 * 将 GitHub token 快照转换为 databoard 使用的 JSON 字符串。
 * Serializes a GitHub token snapshot into the databoard JSON payload format.
 */
public func serializeGitHubStoredSession(snapshot: GitHubStoredSessionSnapshot): String {
    "{\"access_token\":\"${escapeJsonString(snapshot.accessToken)}\"," +
    "\"token_type\":\"${escapeJsonString(snapshot.tokenType)}\"," +
    "\"scope\":\"${escapeJsonString(snapshot.scope)}\"," +
    "\"refresh_token\":\"${escapeJsonString(snapshot.refreshToken)}\"," +
    "\"access_expires_at\":${snapshot.accessTokenExpiresAtMillis}," +
    "\"refresh_expires_at\":${snapshot.refreshTokenExpiresAtMillis}}"
}

/**
 * 从 databoard 的 JSON 字符串恢复 GitHub 会话；缺失 access token 时返回空。
 * Restores a GitHub session snapshot from databoard JSON and rejects empty sessions.
 */
public func deserializeGitHubStoredSession(payload: String): ?GitHubStoredSessionSnapshot {
    let accessToken = extractJsonStringField(payload, "access_token")
    if (accessToken == "") {
        return None
    }
    Some(
        GitHubStoredSessionSnapshot(
            accessToken,
            extractJsonStringField(payload, "token_type"),
            extractJsonStringField(payload, "scope"),
            extractJsonStringField(payload, "refresh_token"),
            extractJsonIntField(payload, "access_expires_at"),
            extractJsonIntField(payload, "refresh_expires_at")
        )
    )
}

/**
 * 从回调 URL 中提取 query 参数，用于读取 GitHub 回传的 code、state 或 error。
 * Extracts query parameters from the callback URL for code, state, or error values.
 */
public func extractUrlQueryParameter(url: String, key: String): String {
    let marker = "${key}="
    match (url.indexOf(marker)) {
        case Some(start) =>
            let valueStart = Int64(start + marker.size)
            let tail = url[valueStart..url.size]
            match (tail.indexOf("&")) {
                case Some(endOffset) => tail[0..Int64(endOffset)]
                case None => tail
            }
        case None => ""
    }
}
