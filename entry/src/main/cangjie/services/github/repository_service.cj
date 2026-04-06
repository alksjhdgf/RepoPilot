package ohos_app_cangjie_entry.services.github

import std.collection.{ArrayList, HashMap}
import kit.NetworkKit.*
import ohos.net.http.{HttpData, HttpDataType, HttpRequestOptions, RequestMethod}
import ohos_app_cangjie_entry.domain.{GitHubCommentSnapshot, GitHubIssueSnapshot, GitHubPullRequestSnapshot, GitHubRepositoryDetailSnapshot}
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
    onFailure: (String) -> Unit,
    method!: RequestMethod = RequestMethod.Get,
    payload!: String = ""
): Unit {
    logInfo("GitHubRepoApi", "Requesting ${url}")
    let httpRequest = createHttp()
    let headers = HashMap<String, String>()
    headers.add("Accept", GITHUB_REPO_API_ACCEPT)
    headers.add("Authorization", "Bearer ${token}")
    headers.add("X-GitHub-Api-Version", GITHUB_REPO_API_VERSION)
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
                    let githubMessage = extractJsonStringField(body, "message")
                    if (githubMessage == "") {
                        onFailure("GitHub API ${response.responseCode}")
                    } else {
                        onFailure("GitHub API ${response.responseCode}: ${githubMessage}")
                    }
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
                        extractJsonStringField(item, "node_id"),
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

func escapeRepositoryJson(value: String): String {
    value.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n")
}

/**
 * 读取 Issue 或 Pull Request 下的评论列表，供详情页展示真实互动内容。
 * Fetches issue-style comments for an issue or pull request detail surface.
 */
public func fetchGitHubIssueComments(
    token: String,
    repositoryName: String,
    issueNumber: String,
    onSuccess: (ArrayList<GitHubCommentSnapshot>) -> Unit,
    onFailure: (String) -> Unit
): Unit {
    requestGitHubRepositoryJson(
        "https://api.github.com/repos/${repositoryName}/issues/${issueNumber}/comments?per_page=30",
        token,
        { body =>
            let comments = ArrayList<GitHubCommentSnapshot>()
            for (item in extractTopLevelObjectArray(body)) {
                let id = extractJsonIntField(item, "id")
                if (id <= 0) {
                    continue
                }
                comments.add(
                    GitHubCommentSnapshot(
                        "${id}",
                        extractJsonStringField(item, "body"),
                        extractJsonStringField(item, "login"),
                        extractJsonStringField(item, "html_url")
                    )
                )
            }
            onSuccess(comments)
        },
        onFailure
    )
}

/**
 * 在指定 Issue 或 Pull Request 下创建评论，供移动端完成基础讨论闭环。
 * Creates an issue-style comment on the selected issue or pull request.
 */
public func createGitHubIssueComment(
    token: String,
    repositoryName: String,
    issueNumber: String,
    body: String,
    onSuccess: (GitHubCommentSnapshot) -> Unit,
    onFailure: (String) -> Unit
): Unit {
    requestGitHubRepositoryJson(
        "https://api.github.com/repos/${repositoryName}/issues/${issueNumber}/comments",
        token,
        { payload =>
            let id = extractJsonIntField(payload, "id")
            onSuccess(
                GitHubCommentSnapshot(
                    if (id > 0) { "${id}" } else { "${issueNumber}-comment" },
                    extractJsonStringField(payload, "body"),
                    extractJsonStringField(payload, "login"),
                    extractJsonStringField(payload, "html_url")
                )
            )
        },
        onFailure,
        method: RequestMethod.Post,
        payload: "{\"body\":\"${escapeRepositoryJson(body)}\"}"
    )
}

/**
 * 创建一个新的 GitHub 仓库，用于验证客户端侧仓库写操作是否落地。
 * Creates a new GitHub repository to verify end-to-end repository mutations.
 */
public func createGitHubRepository(
    token: String,
    name: String,
    description: String,
    onSuccess: () -> Unit,
    onFailure: (String) -> Unit
): Unit {
    requestGitHubRepositoryJson(
        "https://api.github.com/user/repos",
        token,
        { _ => onSuccess() },
        onFailure,
        method: RequestMethod.Post,
        payload: "{\"name\":\"${escapeRepositoryJson(name)}\",\"description\":\"${escapeRepositoryJson(description)}\",\"private\":false}"
    )
}

/**
 * 发起 fork 操作，供仓库详情页快速验证 GitHub 仓库复制能力。
 * Creates a fork of the selected repository.
 */
public func forkGitHubRepository(
    token: String,
    repositoryName: String,
    onSuccess: () -> Unit,
    onFailure: (String) -> Unit
): Unit {
    requestGitHubRepositoryJson(
        "https://api.github.com/repos/${repositoryName}/forks",
        token,
        { _ => onSuccess() },
        onFailure,
        method: RequestMethod.Post,
        payload: "{}"
    )
}

/**
 * 删除当前选中的仓库；这是高影响操作，因此仅在用户已明确需要能力时暴露。
 * Deletes the selected repository.
 */
public func deleteGitHubRepository(
    token: String,
    repositoryName: String,
    onSuccess: () -> Unit,
    onFailure: (String) -> Unit
): Unit {
    requestGitHubRepositoryJson(
        "https://api.github.com/repos/${repositoryName}",
        token,
        { _ => onSuccess() },
        onFailure,
        method: RequestMethod.Delete
    )
}

/**
 * 通过 GraphQL 关闭 Issue，绕开当前 NetworkKit 缺少 PATCH 的限制。
 * Closes an issue through GraphQL because the current NetworkKit binding lacks PATCH.
 */
public func closeGitHubIssue(
    token: String,
    issueNodeId: String,
    onSuccess: () -> Unit,
    onFailure: (String) -> Unit
): Unit {
    requestGitHubRepositoryJson(
        "https://api.github.com/graphql",
        token,
        { _ => onSuccess() },
        onFailure,
        method: RequestMethod.Post,
        payload: "{\"query\":\"mutation { closeIssue(input:{issueId:\\\"${escapeRepositoryJson(issueNodeId)}\\\"}) { issue { id state } } }\"}"
    )
}

/**
 * 提交 Pull Request review，用于 approve、request changes 和普通评论。
 * Submits a pull request review for approve, request-changes, or comment events.
 */
public func submitGitHubPullRequestReview(
    token: String,
    repositoryName: String,
    pullRequestNumber: String,
    event: String,
    body: String,
    onSuccess: () -> Unit,
    onFailure: (String) -> Unit
): Unit {
    requestGitHubRepositoryJson(
        "https://api.github.com/repos/${repositoryName}/pulls/${pullRequestNumber}/reviews",
        token,
        { _ => onSuccess() },
        onFailure,
        method: RequestMethod.Post,
        payload: "{\"body\":\"${escapeRepositoryJson(body)}\",\"event\":\"${escapeRepositoryJson(event)}\"}"
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
