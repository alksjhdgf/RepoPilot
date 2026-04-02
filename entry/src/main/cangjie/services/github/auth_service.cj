package ohos_app_cangjie_entry.services.github

import std.collection.HashMap
import ohos.hilog.Hilog
import kit.NetworkKit.*
import ohos.net.http.{HttpData, HttpDataType, HttpRequestOptions, RequestMethod}
import ohos_app_cangjie_entry.domain.{GitHubAccessTokenSnapshot, GitHubDeviceCodeSnapshot}

let GITHUB_APP_CLIENT_ID = "Iv23lidHotlwYwAflJsH"
let DEVICE_CODE_URL = "https://github.com/login/device/code"
let ACCESS_TOKEN_URL = "https://github.com/login/oauth/access_token"

public func requestGitHubDeviceCode(
    onSuccess: (GitHubDeviceCodeSnapshot) -> Unit,
    onFailure: (String) -> Unit
): Unit {
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
                onFailure("Network error ${networkError.code}: ${networkError.message}")
                return
            }
            if (let Some(response) <- resp) {
                let payload = match (response.result) {
                    case HttpData.StringData(content) => content
                    case _ => ""
                }
                let deviceCode = extractJsonStringField(payload, "device_code")
                let userCode = extractJsonStringField(payload, "user_code")
                let verificationUri = extractJsonStringField(payload, "verification_uri")
                if (deviceCode == "" || userCode == "" || verificationUri == "") {
                    Hilog.error(0, "RepoPilot", "GitHub device code parse failed: ${payload}")
                    onFailure("Unable to parse GitHub device code response.")
                    return
                }
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
            onFailure("GitHub returned no response.")
        }
    )
}

public func exchangeGitHubDeviceCode(
    deviceCode: String,
    onSuccess: (GitHubAccessTokenSnapshot) -> Unit,
    onFailure: (String) -> Unit
): Unit {
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
                onFailure("Network error ${networkError.code}: ${networkError.message}")
                return
            }
            if (let Some(response) <- resp) {
                let body = match (response.result) {
                    case HttpData.StringData(content) => content
                    case _ => ""
                }
                let accessToken = extractJsonStringField(body, "access_token")
                if (accessToken == "") {
                    let errorCode = extractJsonStringField(body, "error")
                    let errorDescription = extractJsonStringField(body, "error_description")
                    if (errorCode != "") {
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
                httpRequest.destroy()
                return
            }
            httpRequest.destroy()
            onFailure("GitHub returned no response.")
        }
    )
}
