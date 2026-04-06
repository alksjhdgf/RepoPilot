package ohos_app_cangjie_entry.services.github

import std.collection.{ArrayList, HashMap}
import kit.NetworkKit.*
import ohos.net.http.{HttpData, HttpDataType, HttpRequestOptions, RequestMethod}
import ohos_app_cangjie_entry.domain.{GitHubIssueSnapshot, GitHubPullRequestSnapshot, GitHubRepositoryDetailSnapshot}
import ohos_app_cangjie_entry.infra.logging.{logDebug, logError, logInfo, logWarn}

let GITHUB_REPO_API_ACCEPT = "application/vnd.github+json"
let GITHUB_REPO_API_VERSION = "2022-11-28"

/**
 * 统一发起 GitHub REST GET 请求，供仓库详情、Issue 与 PR 读取链复用。
 * Sends a shared GitHub REST GET request for repository, issue, and pull request loading.
 */
func requestGitHubRepositoryJson(
    url: String,
    token: String,
    onSuccess: (String) -> Unit,
    onFailure: (String) -> Unit
): Unit {
    logInfo("GitHubRepoApi", "Requesting ${url}")
    let httpRequest = createHttp()
    let headers = HashMap<String, String>()
    headers.add("Accept", GITHUB_REPO_API_ACCEPT)
    headers.add("Authorization", "Bearer ${token}")
    headers.add("X-GitHub-Api-Version", GITHUB_REPO_API_VERSION)
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
                logError("GitHubRepoApi", "Request failed: ${networkError.code} ${networkError.message}")
                onFailure("Network error ${networkError.code}: ${networkError.message}")
                return
            }
            if (let Some(response) <- resp) {
                let body = match (response.result) {
                    case HttpData.StringData(content) => content
                    case _ => ""
                }
                httpRequest.destroy()
                logDebug("GitHubRepoApi", "Response ${response.responseCode} from ${url}")
                if (response.responseCode >= 200u32 && response.responseCode < 300u32) {
                    onSuccess(body)
                } else {
                    onFailure("GitHub API ${response.responseCode}")
                }
                return
            }
            httpRequest.destroy()
            logWarn("GitHubRepoApi", "Request returned no response for ${url}")
            onFailure("GitHub returned no response.")
        }
    )
}

/**
 * 读取指定仓库的基础详情，用于仓库详情页顶层摘要。
 * Fetches the selected repository summary for the repository detail page.
 */
public func fetchGitHubRepositoryDetail(
    token: String,
    repositoryName: String,
    onSuccess: (GitHubRepositoryDetailSnapshot) -> Unit,
    onFailure: (String) -> Unit
): Unit {
    requestGitHubRepositoryJson(
        "https://api.github.com/repos/${repositoryName}",
        token,
        { body =>
            let fullName = extractJsonStringField(body, "full_name")
            if (fullName == "") {
                onFailure("Unable to parse repository detail.")
                return
            }
            let summary = extractJsonStringField(body, "description")
            let defaultBranch = extractJsonStringField(body, "default_branch")
            let openIssueCount = extractJsonIntField(body, "open_issues_count")
            let visibilityLabel = if (extractJsonBoolField(body, "fork")) {
                "Fork"
            } else if (extractJsonBoolField(body, "private")) {
                "Private"
            } else {
                "Public"
            }
            onSuccess(
                GitHubRepositoryDetailSnapshot(
                    fullName,
                    if (summary == "") { "No description" } else { summary },
                    extractJsonStringField(body, "html_url"),
                    visibilityLabel,
                    "${openIssueCount}",
                    "--",
                    if (defaultBranch == "") { "main" } else { defaultBranch }
                )
            )
        },
        onFailure
    )
}

/**
 * 读取指定仓库的真实 Issue 列表，并过滤掉 Pull Request 项。
 * Fetches live issues for the selected repository and filters out pull-request entries.
 */
public func fetchGitHubRepositoryIssues(
    token: String,
    repositoryName: String,
    onSuccess: (ArrayList<GitHubIssueSnapshot>) -> Unit,
    onFailure: (String) -> Unit
): Unit {
    requestGitHubRepositoryJson(
        "https://api.github.com/repos/${repositoryName}/issues?state=open&per_page=20",
        token,
        { body =>
            let issues = ArrayList<GitHubIssueSnapshot>()
            for (item in extractTopLevelObjectArray(body)) {
                if (extractJsonStringField(item, "pull_request") != "") {
                    continue
                }
                let issueNumber = extractJsonIntField(item, "number")
                if (issueNumber <= 0) {
                    continue
                }
                let title = extractJsonStringField(item, "title")
                let summary = extractJsonStringField(item, "body")
                issues.add(
                    GitHubIssueSnapshot(
                        "${issueNumber}",
                        title,
                        if (summary == "") { "No description" } else { summary },
                        extractJsonStringField(item, "state"),
                        extractJsonStringField(item, "login"),
                        extractJsonStringField(item, "html_url")
                    )
                )
            }
            logInfo("GitHubRepoApi", "Loaded ${issues.size} issues for ${repositoryName}.")
            onSuccess(issues)
        },
        onFailure
    )
}

/**
 * 读取指定仓库的真实 Pull Request 列表。
 * Fetches live pull requests for the selected repository.
 */
public func fetchGitHubRepositoryPullRequests(
    token: String,
    repositoryName: String,
    onSuccess: (ArrayList<GitHubPullRequestSnapshot>) -> Unit,
    onFailure: (String) -> Unit
): Unit {
    requestGitHubRepositoryJson(
        "https://api.github.com/repos/${repositoryName}/pulls?state=open&per_page=20",
        token,
        { body =>
            let pullRequests = ArrayList<GitHubPullRequestSnapshot>()
            for (item in extractTopLevelObjectArray(body)) {
                let pullNumber = extractJsonIntField(item, "number")
                if (pullNumber <= 0) {
                    continue
                }
                let title = extractJsonStringField(item, "title")
                let summary = extractJsonStringField(item, "body")
                let status = if (extractJsonBoolField(item, "draft")) {
                    "draft"
                } else {
                    extractJsonStringField(item, "state")
                }
                pullRequests.add(
                    GitHubPullRequestSnapshot(
                        "${pullNumber}",
                        title,
                        if (summary == "") { "No description" } else { summary },
                        status,
                        extractJsonStringField(item, "login"),
                        extractJsonStringField(item, "html_url")
                    )
                )
            }
            logInfo("GitHubRepoApi", "Loaded ${pullRequests.size} pull requests for ${repositoryName}.")
            onSuccess(pullRequests)
        },
        onFailure
    )
}
