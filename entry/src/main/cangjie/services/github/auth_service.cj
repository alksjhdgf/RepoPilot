package ohos_app_cangjie_entry.services.github

import std.collection.HashMap
import kit.NetworkKit.*
import ohos.net.http.{HttpData, HttpDataType, HttpRequestOptions, RequestMethod}
import ohos_app_cangjie_entry.domain.{GitHubAccessTokenSnapshot, GitHubDeviceCodeSnapshot}
import ohos_app_cangjie_entry.infra.logging.{logDebug, logError, logInfo, logWarn}

let GITHUB_APP_CLIENT_ID = "Iv23lidHotlwYwAflJsH"
let DEVICE_CODE_URL = "https://github.com/login/device/code"
let ACCESS_TOKEN_URL = "https://github.com/login/oauth/access_token"

/**
 * 发起 GitHub Device Flow 的第一步请求，获取 device code 与 user code。
 * Requests the first GitHub Device Flow payload and returns device and user codes.
 */
public func requestGitHubDeviceCode(
    onSuccess: (GitHubDeviceCodeSnapshot) -> Unit,
    onFailure: (String) -> Unit
): Unit {
    logInfo("AuthService", "Requesting GitHub device code.")
    let httpRequest = createHttp()
    let headers = HashMap<String, String>()
    headers.add("Accept", "application/json")
    headers.add("Content-Type", "application/x-www-form-urlencoded")
    let options = HttpRequestOptions(
        method: RequestMethod.Post,
        header: headers,
        extraData: HttpData.StringData("client_id=${GITHUB_APP_CLIENT_ID}"),
        expectDataType: HttpDataType.StringValue
    )
    httpRequest.request(
        DEVICE_CODE_URL,
        options,
        {
            err, resp =>
            if (let Some(networkError) <- err) {
                httpRequest.destroy()
                logError("AuthService", "Device code request failed: ${networkError.code} ${networkError.message}")
                onFailure("Network error ${networkError.code}: ${networkError.message}")
                return
            }
            if (let Some(response) <- resp) {
                logDebug("AuthService", "Device code response code: ${response.responseCode}")
                let payload = match (response.result) {
                    case HttpData.StringData(content) => content
                    case _ => ""
                }
                let deviceCode = extractJsonStringField(payload, "device_code")
                let userCode = extractJsonStringField(payload, "user_code")
                let verificationUri = extractJsonStringField(payload, "verification_uri")
                if (deviceCode == "" || userCode == "" || verificationUri == "") {
                    logError("AuthService", "Device code payload parse failed: ${payload}")
                    onFailure("Unable to parse GitHub device code response.")
                    return
                }
                logInfo("AuthService", "Device code acquired. verificationUri=${verificationUri}")
                onSuccess(
                    GitHubDeviceCodeSnapshot(
                        deviceCode,
                        userCode,
                        verificationUri,
                        extractJsonIntField(payload, "expires_in"),
                        extractJsonIntField(payload, "interval")
                    )
                )
                httpRequest.destroy()
                return
            }
            httpRequest.destroy()
            logWarn("AuthService", "Device code request returned no response.")
            onFailure("GitHub returned no response.")
        }
    )
}

/**
 * 使用 device code 轮询 GitHub，尝试换取用户访问令牌。
 * Exchanges a device code for a user access token through GitHub polling.
 */
public func exchangeGitHubDeviceCode(
    deviceCode: String,
    onSuccess: (GitHubAccessTokenSnapshot) -> Unit,
    onPending: (String, String) -> Unit,
    onFailure: (String) -> Unit
): Unit {
    logInfo("AuthService", "Polling GitHub access token.")
    let httpRequest = createHttp()
    let headers = HashMap<String, String>()
    headers.add("Accept", "application/json")
    headers.add("Content-Type", "application/x-www-form-urlencoded")
    let payload = "client_id=${GITHUB_APP_CLIENT_ID}&device_code=${deviceCode}&grant_type=urn:ietf:params:oauth:grant-type:device_code"
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
                logDebug("AuthService", "Token exchange response code: ${response.responseCode}")
                let body = match (response.result) {
                    case HttpData.StringData(content) => content
                    case _ => ""
                }
                let accessToken = extractJsonStringField(body, "access_token")
                if (accessToken == "") {
                    let errorCode = extractJsonStringField(body, "error")
                    let errorDescription = extractJsonStringField(body, "error_description")
                    logWarn("AuthService", "Token exchange incomplete: ${errorCode} ${errorDescription}")
                    if (errorCode == "authorization_pending" || errorCode == "slow_down") {
                        onPending(errorCode, errorDescription)
                    } else if (errorCode != "") {
                        onFailure("${errorCode}: ${errorDescription}")
                    } else {
                        onFailure("GitHub token exchange did not return an access token.")
                    }
                    return
                }
                onSuccess(
                    GitHubAccessTokenSnapshot(
                        accessToken,
                        extractJsonStringField(body, "token_type"),
                        extractJsonStringField(body, "scope"),
                        extractJsonStringField(body, "refresh_token"),
                        extractJsonIntField(body, "refresh_token_expires_in")
                    )
                )
                logInfo("AuthService", "GitHub access token acquired.")
                httpRequest.destroy()
                return
            }
            httpRequest.destroy()
            logWarn("AuthService", "Token exchange returned no response.")
            onFailure("GitHub returned no response.")
        }
    )
}
