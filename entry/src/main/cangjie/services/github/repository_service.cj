package ohos_app_cangjie_entry.services.github

import std.collection.{ArrayList, HashMap}
import kit.NetworkKit.*
import ohos.net.http.{HttpData, HttpDataType, HttpRequestOptions, RequestMethod}
import ohos_app_cangjie_entry.domain.{GitHubCommentSnapshot, GitHubCommitDetailSnapshot, GitHubCommitSnapshot, GitHubEventSnapshot, GitHubGistFileSnapshot, GitHubGistSnapshot, GitHubIssueSnapshot, GitHubPullRequestSnapshot, GitHubRepositoryCardSnapshot, GitHubRepositoryDetailSnapshot, GitHubSimpleUserSnapshot, GitHubUserProfileSnapshot}
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
    payload!: String = "",
    acceptHeader!: String = GITHUB_REPO_API_ACCEPT
): Unit {
    logInfo("GitHubRepoApi", "Requesting ${url}")
    let httpRequest = createHttp()
    let headers = HashMap<String, String>()
    headers.add("Accept", acceptHeader)
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

public func fetchGitHubRepositoryReadme(
    token: String,
    repositoryName: String,
    defaultBranch: String,
    onSuccess: (String) -> Unit,
    onFailure: (String) -> Unit
): Unit {
    let readmeRef = if (defaultBranch == "") { "main" } else { defaultBranch }
    requestGitHubRepositoryJson(
        "https://api.github.com/repos/${repositoryName}/readme?ref=${readmeRef}",
        token,
        onSuccess,
        { _ => onSuccess("") },
        acceptHeader: "application/vnd.github.raw+json"
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
            let ownerPayload = extractJsonObjectField(body, "owner")
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
                    if (defaultBranch == "") { "main" } else { defaultBranch },
                    ownerLogin: extractJsonStringField(ownerPayload, "login"),
                    ownerAvatarUrl: extractJsonStringField(ownerPayload, "avatar_url"),
                    primaryLanguage: extractJsonStringField(body, "language"),
                    starCount: "${extractJsonIntField(body, "stargazers_count")}",
                    forkCount: "${extractJsonIntField(body, "forks_count")}",
                    watcherCount: "${extractJsonIntField(body, "subscribers_count")}"
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

func buildGitHubEventSnapshot(item: String): GitHubEventSnapshot {
    let payload = extractJsonObjectField(item, "payload")
    let repoPayload = extractJsonObjectField(item, "repo")
    let issuePayload = extractJsonObjectField(payload, "issue")
    let pullRequestPayload = extractJsonObjectField(payload, "pull_request")
    let releasePayload = extractJsonObjectField(payload, "release")
    let eventType = extractJsonStringField(item, "type")
    let repoName = extractJsonStringField(repoPayload, "name")
    let action = extractJsonStringField(payload, "action")

    var targetTitle = ""
    var targetUrl = ""

    if (issuePayload != "") {
        targetTitle = extractJsonStringField(issuePayload, "title")
        targetUrl = extractJsonStringField(issuePayload, "html_url")
    } else if (pullRequestPayload != "") {
        targetTitle = extractJsonStringField(pullRequestPayload, "title")
        targetUrl = extractJsonStringField(pullRequestPayload, "html_url")
    } else if (releasePayload != "") {
        targetTitle = extractJsonStringField(releasePayload, "name")
        targetUrl = extractJsonStringField(releasePayload, "html_url")
    }

    if (targetTitle == "") {
        if (eventType == "PushEvent") {
            targetTitle = extractJsonStringField(payload, "ref")
        } else if (eventType == "CreateEvent" || eventType == "DeleteEvent") {
            let refType = extractJsonStringField(payload, "ref_type")
            let refName = extractJsonStringField(payload, "ref")
            targetTitle = if (refName == "") { refType } else { "${refType} ${refName}" }
        } else {
            targetTitle = repoName
        }
    }

    if (targetUrl == "") {
        targetUrl = if (repoName == "") { "" } else { "https://github.com/${repoName}" }
    }

    GitHubEventSnapshot(
        extractJsonStringField(item, "id"),
        eventType,
        action,
        repoName,
        targetTitle,
        targetUrl,
        extractJsonStringField(item, "created_at"),
        extractJsonStringField(item, "login")
    )
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
                    extractGitHubUserLogin(payload),
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
 * 在指定仓库中创建一个新的 Issue，供客户端打通基础创建工作流。
 * Creates a new issue in the selected repository.
 */
public func createGitHubIssue(
    token: String,
    repositoryName: String,
    title: String,
    body: String,
    onSuccess: (GitHubIssueSnapshot) -> Unit,
    onFailure: (String) -> Unit
): Unit {
    requestGitHubRepositoryJson(
        "https://api.github.com/repos/${repositoryName}/issues",
        token,
        { payload =>
            let issueNumber = extractJsonIntField(payload, "number")
            onSuccess(
                GitHubIssueSnapshot(
                    if (issueNumber > 0) { "${issueNumber}" } else { "0" },
                    extractJsonStringField(payload, "node_id"),
                    extractJsonStringField(payload, "title"),
                    extractJsonStringField(payload, "body"),
                    extractJsonStringField(payload, "state"),
                    extractGitHubUserLogin(payload),
                    extractJsonStringField(payload, "html_url")
                )
            )
        },
        onFailure,
        method: RequestMethod.Post,
        payload: "{\"title\":\"${escapeRepositoryJson(title)}\",\"body\":\"${escapeRepositoryJson(body)}\"}"
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
                        extractGitHubUserLogin(item),
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

/**
 * 读取指定仓库的分支列表，供 Issue / Pull Request 编辑页选择 base 分支。
 * Fetches repository branches so composer pages can offer base branch choices.
 */
public func fetchGitHubRepositoryBranches(
    token: String,
    repositoryName: String,
    onSuccess: (ArrayList<String>) -> Unit,
    onFailure: (String) -> Unit
): Unit {
    requestGitHubRepositoryJson(
        "https://api.github.com/repos/${repositoryName}/branches?per_page=100",
        token,
        { body =>
            let branches = ArrayList<String>()
            for (item in extractTopLevelObjectArray(body)) {
                let branchName = extractJsonStringField(item, "name")
                if (branchName != "") {
                    branches.add(branchName)
                }
            }
            onSuccess(branches)
        },
        onFailure
    )
}

/**
 * 创建一个新的 Pull Request。
 * Creates a new pull request for the selected repository.
 */
public func createGitHubPullRequest(
    token: String,
    repositoryName: String,
    title: String,
    body: String,
    head: String,
    base: String,
    onSuccess: (GitHubPullRequestSnapshot) -> Unit,
    onFailure: (String) -> Unit
): Unit {
    requestGitHubRepositoryJson(
        "https://api.github.com/repos/${repositoryName}/pulls",
        token,
        { payload =>
            let pullNumber = extractJsonIntField(payload, "number")
            onSuccess(
                GitHubPullRequestSnapshot(
                    if (pullNumber > 0) { "${pullNumber}" } else { "0" },
                    extractJsonStringField(payload, "title"),
                    extractJsonStringField(payload, "body"),
                    if (extractJsonBoolField(payload, "draft")) { "draft" } else { extractJsonStringField(payload, "state") },
                    extractGitHubUserLogin(payload),
                    extractJsonStringField(payload, "html_url")
                )
            )
        },
        onFailure,
        method: RequestMethod.Post,
        payload: "{\"title\":\"${escapeRepositoryJson(title)}\",\"body\":\"${escapeRepositoryJson(body)}\",\"head\":\"${escapeRepositoryJson(head)}\",\"base\":\"${escapeRepositoryJson(base)}\"}"
    )
}

public func fetchGitHubRepositoryStargazers(
    token: String,
    repositoryName: String,
    onSuccess: (ArrayList<GitHubSimpleUserSnapshot>) -> Unit,
    onFailure: (String) -> Unit,
    page!: Int64 = 1
): Unit {
    requestGitHubRepositoryJson(
        "https://api.github.com/repos/${repositoryName}/stargazers?per_page=50&page=${page}",
        token,
        { body =>
            let users = ArrayList<GitHubSimpleUserSnapshot>()
            for (item in extractTopLevelObjectArray(body)) {
                let login = extractJsonStringField(item, "login")
                if (login == "") {
                    continue
                }
                users.add(
                    GitHubSimpleUserSnapshot(
                        login,
                        extractJsonStringField(item, "html_url"),
                        extractJsonStringField(item, "avatar_url")
                    )
                )
            }
            onSuccess(users)
        },
        onFailure
    )
}

public func fetchGitHubRepositoryWatchers(
    token: String,
    repositoryName: String,
    onSuccess: (ArrayList<GitHubSimpleUserSnapshot>) -> Unit,
    onFailure: (String) -> Unit,
    page!: Int64 = 1
): Unit {
    requestGitHubRepositoryJson(
        "https://api.github.com/repos/${repositoryName}/subscribers?per_page=50&page=${page}",
        token,
        { body =>
            let users = ArrayList<GitHubSimpleUserSnapshot>()
            for (item in extractTopLevelObjectArray(body)) {
                let login = extractJsonStringField(item, "login")
                if (login == "") {
                    continue
                }
                users.add(
                    GitHubSimpleUserSnapshot(
                        login,
                        extractJsonStringField(item, "html_url"),
                        extractJsonStringField(item, "avatar_url")
                    )
                )
            }
            onSuccess(users)
        },
        onFailure
    )
}

public func fetchGitHubRepositoryForks(
    token: String,
    repositoryName: String,
    onSuccess: (ArrayList<GitHubRepositoryCardSnapshot>) -> Unit,
    onFailure: (String) -> Unit,
    page!: Int64 = 1
): Unit {
    requestGitHubRepositoryJson(
        "https://api.github.com/repos/${repositoryName}/forks?per_page=50&page=${page}",
        token,
        { body =>
            let repositories = ArrayList<GitHubRepositoryCardSnapshot>()
            for (item in extractTopLevelObjectArray(body)) {
                let fullName = extractJsonStringField(item, "full_name")
                if (fullName == "") {
                    continue
                }
                repositories.add(
                    GitHubRepositoryCardSnapshot(
                        fullName,
                        extractJsonStringField(item, "description"),
                        extractJsonStringField(item, "html_url"),
                        extractJsonBoolField(item, "private"),
                        extractJsonBoolField(item, "fork"),
                        extractJsonIntField(item, "stargazers_count"),
                        false
                    )
                )
            }
            onSuccess(repositories)
        },
        onFailure
    )
}

public func fetchGitHubRepositoryCommits(
    token: String,
    repositoryName: String,
    onSuccess: (ArrayList<GitHubCommitSnapshot>) -> Unit,
    onFailure: (String) -> Unit,
    page!: Int64 = 1
): Unit {
    requestGitHubRepositoryJson(
        "https://api.github.com/repos/${repositoryName}/commits?per_page=50&page=${page}",
        token,
        { body =>
            let commits = ArrayList<GitHubCommitSnapshot>()
            for (item in extractTopLevelObjectArray(body)) {
                let sha = extractJsonStringField(item, "sha")
                if (sha == "") {
                    continue
                }
                let commitPayload = extractJsonObjectField(item, "commit")
                let authorPayload = extractJsonObjectField(item, "author")
                commits.add(
                    GitHubCommitSnapshot(
                        sha,
                        extractJsonStringField(commitPayload, "message"),
                        extractJsonStringField(authorPayload, "login"),
                        extractJsonStringField(item, "html_url")
                    )
                )
            }
            onSuccess(commits)
        },
        onFailure
    )
}

public func fetchGitHubRepositoryCommitDetail(
    token: String,
    repositoryName: String,
    sha: String,
    onSuccess: (GitHubCommitDetailSnapshot) -> Unit,
    onFailure: (String) -> Unit
): Unit {
    requestGitHubRepositoryJson(
        "https://api.github.com/repos/${repositoryName}/commits/${sha}",
        token,
        { body =>
            let resolvedSha = extractJsonStringField(body, "sha")
            if (resolvedSha == "") {
                onFailure("Unable to parse commit detail.")
                return
            }
            let commitPayload = extractJsonObjectField(body, "commit")
            let commitAuthorPayload = extractJsonObjectField(commitPayload, "author")
            let authorPayload = extractJsonObjectField(body, "author")
            let statsPayload = extractJsonObjectField(body, "stats")
            onSuccess(
                GitHubCommitDetailSnapshot(
                    resolvedSha,
                    extractJsonStringField(commitPayload, "message"),
                    extractJsonStringField(authorPayload, "login"),
                    extractJsonStringField(commitAuthorPayload, "name"),
                    extractJsonStringField(authorPayload, "avatar_url"),
                    extractJsonStringField(commitAuthorPayload, "date"),
                    extractJsonIntField(statsPayload, "additions"),
                    extractJsonIntField(statsPayload, "deletions"),
                    extractJsonStringField(body, "html_url")
                )
            )
        },
        onFailure
    )
}

public func fetchGitHubUserProfile(
    token: String,
    login: String,
    onSuccess: (GitHubUserProfileSnapshot) -> Unit,
    onFailure: (String) -> Unit
): Unit {
    requestGitHubRepositoryJson(
        "https://api.github.com/users/${login}",
        token,
        { body =>
            let profileLogin = extractJsonStringField(body, "login")
            if (profileLogin == "") {
                onFailure("Unable to parse user profile.")
                return
            }
            onSuccess(
                GitHubUserProfileSnapshot(
                    profileLogin,
                    extractJsonStringField(body, "name"),
                    extractJsonStringField(body, "avatar_url"),
                    extractJsonStringField(body, "html_url"),
                    extractJsonStringField(body, "bio"),
                    extractJsonStringField(body, "location"),
                    extractJsonStringField(body, "company"),
                    extractJsonStringField(body, "blog"),
                    "${extractJsonIntField(body, "public_repos")}",
                    "${extractJsonIntField(body, "public_gists")}",
                    "${extractJsonIntField(body, "followers")}",
                    "${extractJsonIntField(body, "following")}"
                )
            )
        },
        onFailure
    )
}

public func fetchGitHubUserRepositories(
    token: String,
    login: String,
    onSuccess: (ArrayList<GitHubRepositoryCardSnapshot>) -> Unit,
    onFailure: (String) -> Unit,
    page!: Int64 = 1
): Unit {
    requestGitHubRepositoryJson(
        "https://api.github.com/users/${login}/repos?sort=updated&per_page=50&page=${page}",
        token,
        { body =>
            let repositories = ArrayList<GitHubRepositoryCardSnapshot>()
            for (item in extractTopLevelObjectArray(body)) {
                let fullName = extractJsonStringField(item, "full_name")
                if (fullName == "") {
                    continue
                }
                repositories.add(
                    GitHubRepositoryCardSnapshot(
                        fullName,
                        extractJsonStringField(item, "description"),
                        extractJsonStringField(item, "html_url"),
                        extractJsonBoolField(item, "private"),
                        extractJsonBoolField(item, "fork"),
                        extractJsonIntField(item, "stargazers_count"),
                        false
                    )
                )
            }
            onSuccess(repositories)
        },
        onFailure
    )
}

public func fetchGitHubViewerActivity(
    token: String,
    login: String,
    onSuccess: (ArrayList<GitHubEventSnapshot>) -> Unit,
    onFailure: (String) -> Unit
): Unit {
    requestGitHubRepositoryJson(
        "https://api.github.com/users/${login}/received_events?per_page=20",
        token,
        { body =>
            let events = ArrayList<GitHubEventSnapshot>()
            for (item in extractTopLevelObjectArray(body)) {
                let eventId = extractJsonStringField(item, "id")
                if (eventId == "") {
                    continue
                }
                events.add(buildGitHubEventSnapshot(item))
            }
            onSuccess(events)
        },
        onFailure
    )
}

public func fetchGitHubUserActivity(
    token: String,
    login: String,
    onSuccess: (ArrayList<GitHubEventSnapshot>) -> Unit,
    onFailure: (String) -> Unit,
    page!: Int64 = 1
): Unit {
    requestGitHubRepositoryJson(
        "https://api.github.com/users/${login}/events/public?per_page=20&page=${page}",
        token,
        { body =>
            let events = ArrayList<GitHubEventSnapshot>()
            for (item in extractTopLevelObjectArray(body)) {
                let eventId = extractJsonStringField(item, "id")
                if (eventId == "") {
                    continue
                }
                events.add(buildGitHubEventSnapshot(item))
            }
            onSuccess(events)
        },
        onFailure
    )
}

public func fetchGitHubUserFollowers(
    token: String,
    login: String,
    onSuccess: (ArrayList<GitHubSimpleUserSnapshot>) -> Unit,
    onFailure: (String) -> Unit,
    page!: Int64 = 1
): Unit {
    requestGitHubRepositoryJson(
        "https://api.github.com/users/${login}/followers?per_page=50&page=${page}",
        token,
        { body =>
            let users = ArrayList<GitHubSimpleUserSnapshot>()
            for (item in extractTopLevelObjectArray(body)) {
                let followerLogin = extractJsonStringField(item, "login")
                if (followerLogin == "") {
                    continue
                }
                users.add(
                    GitHubSimpleUserSnapshot(
                        followerLogin,
                        extractJsonStringField(item, "html_url"),
                        extractJsonStringField(item, "avatar_url")
                    )
                )
            }
            onSuccess(users)
        },
        onFailure
    )
}

public func fetchGitHubUserFollowing(
    token: String,
    login: String,
    onSuccess: (ArrayList<GitHubSimpleUserSnapshot>) -> Unit,
    onFailure: (String) -> Unit,
    page!: Int64 = 1
): Unit {
    requestGitHubRepositoryJson(
        "https://api.github.com/users/${login}/following?per_page=50&page=${page}",
        token,
        { body =>
            let users = ArrayList<GitHubSimpleUserSnapshot>()
            for (item in extractTopLevelObjectArray(body)) {
                let followingLogin = extractJsonStringField(item, "login")
                if (followingLogin == "") {
                    continue
                }
                users.add(
                    GitHubSimpleUserSnapshot(
                        followingLogin,
                        extractJsonStringField(item, "html_url"),
                        extractJsonStringField(item, "avatar_url")
                    )
                )
            }
            onSuccess(users)
        },
        onFailure
    )
}

public func fetchGitHubUserGists(
    token: String,
    login: String,
    onSuccess: (ArrayList<GitHubGistSnapshot>) -> Unit,
    onFailure: (String) -> Unit,
    page!: Int64 = 1
): Unit {
    requestGitHubRepositoryJson(
        "https://api.github.com/users/${login}/gists?per_page=50&page=${page}",
        token,
        { body =>
            let gists = ArrayList<GitHubGistSnapshot>()
            for (item in extractTopLevelObjectArray(body)) {
                let gistId = extractJsonStringField(item, "id")
                if (gistId == "") {
                    continue
                }
                let filesPayload = extractJsonObjectField(item, "files")
                let fileEntries = extractTopLevelObjectArray(filesPayload)
                var primaryFilename = ""
                if (fileEntries.size > 0) {
                    primaryFilename = extractJsonStringField(fileEntries[0], "filename")
                }
                let ownerPayload = extractJsonObjectField(item, "owner")
                gists.add(
                    GitHubGistSnapshot(
                        gistId,
                        extractJsonStringField(item, "description"),
                        extractJsonStringField(item, "html_url"),
                        extractJsonBoolField(item, "public"),
                        extractJsonStringField(item, "updated_at"),
                        "${fileEntries.size}",
                        extractJsonStringField(ownerPayload, "login"),
                        extractJsonStringField(ownerPayload, "avatar_url"),
                        primaryFilename
                    )
                )
            }
            onSuccess(gists)
        },
        onFailure
    )
}

public func fetchGitHubGistFiles(
    token: String,
    gistId: String,
    onSuccess: (ArrayList<GitHubGistFileSnapshot>) -> Unit,
    onFailure: (String) -> Unit
): Unit {
    requestGitHubRepositoryJson(
        "https://api.github.com/gists/${gistId}",
        token,
        { body =>
            let filesPayload = extractJsonObjectField(body, "files")
            let files = ArrayList<GitHubGistFileSnapshot>()
            for (item in extractTopLevelObjectArray(filesPayload)) {
                let filename = extractJsonStringField(item, "filename")
                if (filename == "") {
                    continue
                }
                files.add(
                    GitHubGistFileSnapshot(
                        filename,
                        extractJsonStringField(item, "language"),
                        extractJsonStringField(item, "type"),
                        "${extractJsonIntField(item, "size")}",
                        extractJsonStringField(item, "content"),
                        extractJsonStringField(item, "raw_url")
                    )
                )
            }
            onSuccess(files)
        },
        onFailure
    )
}
