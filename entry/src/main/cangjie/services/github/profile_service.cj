package ohos_app_cangjie_entry.services.github

import std.collection.{ArrayList, HashMap}
import kit.NetworkKit.*
import ohos.net.http.{HttpData, HttpDataType, HttpRequestOptions, RequestMethod}
import ohos_app_cangjie_entry.domain.{GitHubProfileMetricsSnapshot, GitHubRepositoryCardSnapshot, GitHubViewerSnapshot}
import ohos_app_cangjie_entry.infra.logging.{logDebug, logError, logInfo, logWarn}

let GITHUB_API_ACCEPT = "application/vnd.github+json"
let GITHUB_API_VERSION = "2022-11-28"

/**
 * 对 GitHub REST API 发起统一的 GET 请求，并返回 JSON 字符串。
 * Sends a shared GitHub REST GET request and returns the JSON response body.
 */
func requestGitHubJson(
    url: String,
    token: String,
    onSuccess: (String) -> Unit,
    onFailure: (String) -> Unit
): Unit {
    logInfo("GitHubApi", "Requesting ${url}")
    let httpRequest = createHttp()
    let headers = HashMap<String, String>()
    headers.add("Accept", GITHUB_API_ACCEPT)
    headers.add("Authorization", "Bearer ${token}")
    headers.add("X-GitHub-Api-Version", GITHUB_API_VERSION)
    let options = HttpRequestOptions(
        method: RequestMethod.Get,
        header: headers,
        expectDataType: HttpDataType.StringValue
    )
    httpRequest.request(
        url,
        options,
        {
            err, resp =>
            if (let Some(networkError) <- err) {
                httpRequest.destroy()
                logError("GitHubApi", "Request failed: ${networkError.code} ${networkError.message}")
                onFailure("Network error ${networkError.code}: ${networkError.message}")
                return
            }
            if (let Some(response) <- resp) {
                let body = match (response.result) {
                    case HttpData.StringData(content) => content
                    case _ => ""
                }
                httpRequest.destroy()
                logDebug("GitHubApi", "Response ${response.responseCode} from ${url}")
                if (response.responseCode >= 200u32 && response.responseCode < 300u32) {
                    onSuccess(body)
                } else {
                    logWarn("GitHubApi", "Non-success response ${response.responseCode} from ${url}")
                    onFailure("GitHub API ${response.responseCode}")
                }
                return
            }
            httpRequest.destroy()
            logWarn("GitHubApi", "Request returned no response for ${url}")
            onFailure("GitHub returned no response.")
        }
    )
}

/**
 * 获取当前已登录 GitHub 用户的基础资料。
 * Fetches the currently authenticated GitHub user's basic profile.
 */
public func fetchGitHubViewer(
    token: String,
    onSuccess: (GitHubViewerSnapshot) -> Unit,
    onFailure: (String) -> Unit
): Unit {
    requestGitHubJson(
        "https://api.github.com/user",
        token,
        { body =>
            let login = extractJsonStringField(body, "login")
            if (login == "") {
                logError("GitHubApi", "Viewer payload parse failed.")
                onFailure("Unable to parse GitHub user profile.")
                return
            }
            let displayName = extractJsonStringField(body, "name")
            logInfo("GitHubApi", "Viewer loaded for ${login} ${displayName}")
            onSuccess(
                GitHubViewerSnapshot(
                    login,
                    if (displayName == "") { login } else { displayName },
                    extractJsonStringField(body, "html_url"),
                    extractJsonStringField(body, "avatar_url")
                )
            )
        },
        onFailure
    )
}

/**
 * 获取当前用户的仓库摘要列表，用于个人页和后续仓库流转。
 * Fetches a repository summary list for the current user.
 */
public func fetchGitHubRepositories(
    token: String,
    onSuccess: (ArrayList<GitHubRepositoryCardSnapshot>) -> Unit,
    onFailure: (String) -> Unit
): Unit {
    requestGitHubJson(
        "https://api.github.com/user/repos?sort=updated&per_page=12",
        token,
        { body =>
            let repositories = ArrayList<GitHubRepositoryCardSnapshot>()
            for (item in extractTopLevelObjectArray(body)) {
                let name = extractJsonStringField(item, "full_name")
                if (name == "") {
                    continue
                }
                let description = extractJsonStringField(item, "description")
                repositories.add(
                    GitHubRepositoryCardSnapshot(
                        name,
                        if (description == "") { "No description" } else { description },
                        extractJsonStringField(item, "html_url"),
                        extractJsonBoolField(item, "private"),
                        extractJsonBoolField(item, "fork")
                    )
                )
            }
            logInfo("GitHubApi", "Loaded ${repositories.size} repositories.")
            onSuccess(repositories)
        },
        onFailure
    )
}

/**
 * 获取当前用户个人页需要的真实计数信息。
 * Fetches the live counters needed by the standalone profile page.
 */
public func fetchGitHubProfileMetrics(
    token: String,
    onSuccess: (GitHubProfileMetricsSnapshot) -> Unit,
    onFailure: (String) -> Unit
): Unit {
    requestGitHubJson(
        "https://api.github.com/user/starred?per_page=100",
        token,
        { starredBody =>
            let starredCount = "${extractTopLevelObjectArray(starredBody).size}"
            requestGitHubJson(
                "https://api.github.com/user/orgs?per_page=100",
                token,
                { orgsBody =>
                    let organizationCount = "${extractTopLevelObjectArray(orgsBody).size}"
                    requestGitHubJson(
                        "https://api.github.com/user/repos?sort=updated&per_page=100",
                        token,
                        { repositoriesBody =>
                            onSuccess(
                                GitHubProfileMetricsSnapshot(
                                    "${extractTopLevelObjectArray(repositoriesBody).size}",
                                    starredCount,
                                    organizationCount
                                )
                            )
                        },
                        onFailure
                    )
                },
                onFailure
            )
        },
        onFailure
    )
}
