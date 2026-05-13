package ohos_app_cangjie_entry.services.github

import std.collection.ArrayList
import ohos_app_cangjie_entry.domain.{GitHubIssueSnapshot, GitHubNotificationSnapshot, GitHubPullRequestSnapshot, GitHubRepositoryCardSnapshot, GitHubSearchUserSnapshot}

public func fetchGitHubNotifications(
    token: String,
    onSuccess: (ArrayList<GitHubNotificationSnapshot>) -> Unit,
    onFailure: (String) -> Unit,
    page!: Int64 = 1
): Unit {
    requestGitHubJson(
        "https://api.github.com/notifications?all=true&participating=true&per_page=30&page=${page}",
        token,
        { body =>
            let notifications = ArrayList<GitHubNotificationSnapshot>()
            for (item in extractTopLevelObjectArray(body)) {
                let repositoryPayload = extractJsonObjectField(item, "repository")
                let subjectPayload = extractJsonObjectField(item, "subject")
                let repositoryName = extractJsonStringField(repositoryPayload, "full_name")
                let repositoryUrl = extractJsonStringField(repositoryPayload, "html_url")
                let subjectTitle = extractJsonStringField(subjectPayload, "title")
                let subjectType = extractJsonStringField(subjectPayload, "type")
                let subjectApiUrl = extractJsonStringField(subjectPayload, "url")
                let id = extractJsonStringField(item, "id")
                if (id == "" || repositoryName == "") {
                    continue
                }
                notifications.add(
                    GitHubNotificationSnapshot(
                        id,
                        repositoryName,
                        repositoryUrl,
                        if (subjectTitle == "") { repositoryName } else { subjectTitle },
                        if (subjectType == "") { "Repository" } else { subjectType },
                        extractJsonStringField(item, "reason"),
                        subjectApiUrl,
                        extractJsonBoolField(item, "unread"),
                        extractJsonStringField(item, "updated_at")
                    )
                )
            }
            onSuccess(notifications)
        },
        onFailure
    )
}

public func searchGitHubRepositories(
    token: String,
    query: String,
    onSuccess: (ArrayList<GitHubRepositoryCardSnapshot>) -> Unit,
    onFailure: (String) -> Unit
): Unit {
    let queryParam = query.replace(" ", "+")
    requestGitHubJson(
        "https://api.github.com/search/repositories?q=${queryParam}&per_page=20",
        token,
        { body =>
            let repositories = ArrayList<GitHubRepositoryCardSnapshot>()
            for (item in extractNamedObjectArray(body, "items")) {
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

public func searchGitHubIssuesAndPullRequests(
    token: String,
    query: String,
    onIssuesSuccess: (ArrayList<GitHubIssueSnapshot>) -> Unit,
    onPullRequestsSuccess: (ArrayList<GitHubPullRequestSnapshot>) -> Unit,
    onFailure: (String) -> Unit,
    page!: Int64 = 1
): Unit {
    let queryParam = query.replace(" ", "+")
    requestGitHubJson(
        "https://api.github.com/search/issues?q=${queryParam}&per_page=20&page=${page}",
        token,
        { body =>
            let issues = ArrayList<GitHubIssueSnapshot>()
            let pullRequests = ArrayList<GitHubPullRequestSnapshot>()
            for (item in extractNamedObjectArray(body, "items")) {
                let title = extractJsonStringField(item, "title")
                let summary = extractJsonStringField(item, "body")
                let state = extractJsonStringField(item, "state")
                let userPayload = extractJsonObjectField(item, "user")
                let author = extractJsonStringField(userPayload, "login")
                let htmlUrl = extractJsonStringField(item, "html_url")
                let id = extractJsonIntField(item, "number")
                if (id <= 0 || htmlUrl == "") {
                    continue
                }
                if (extractJsonObjectField(item, "pull_request") != "") {
                    pullRequests.add(
                        GitHubPullRequestSnapshot(
                            "${id}",
                            title,
                            if (summary == "") { "No description" } else { summary },
                            state,
                            author,
                            htmlUrl
                        )
                    )
                } else {
                    issues.add(
                        GitHubIssueSnapshot(
                            "${id}",
                            extractJsonStringField(item, "node_id"),
                            title,
                            if (summary == "") { "No description" } else { summary },
                            state,
                            author,
                            htmlUrl
                        )
                    )
                }
            }
            onIssuesSuccess(issues)
            onPullRequestsSuccess(pullRequests)
        },
        onFailure
    )
}

public func searchGitHubUsers(
    token: String,
    query: String,
    onSuccess: (ArrayList<GitHubSearchUserSnapshot>) -> Unit,
    onFailure: (String) -> Unit
): Unit {
    let queryParam = query.replace(" ", "+")
    requestGitHubJson(
        "https://api.github.com/search/users?q=${queryParam}&per_page=20",
        token,
        { body =>
            let users = ArrayList<GitHubSearchUserSnapshot>()
            for (item in extractNamedObjectArray(body, "items")) {
                let login = extractJsonStringField(item, "login")
                if (login == "") {
                    continue
                }
                users.add(
                    GitHubSearchUserSnapshot(
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

public func fetchGitHubUserIssues(
    token: String,
    login: String,
    onSuccess: (ArrayList<GitHubIssueSnapshot>) -> Unit,
    onFailure: (String) -> Unit,
    page!: Int64 = 1
): Unit {
    searchGitHubIssuesAndPullRequests(
        token,
        "is:issue author:${login}",
        onSuccess,
        { _ => },
        onFailure,
        page: page
    )
}

public func fetchGitHubUserPullRequests(
    token: String,
    login: String,
    onSuccess: (ArrayList<GitHubPullRequestSnapshot>) -> Unit,
    onFailure: (String) -> Unit,
    page!: Int64 = 1
): Unit {
    searchGitHubIssuesAndPullRequests(
        token,
        "is:pr author:${login}",
        { _ => },
        onSuccess,
        onFailure,
        page: page
    )
}

public func repositoryNameFromApiUrl(apiUrl: String): String {
    var path = ""
    let apiMarker = "https://api.github.com/repos/"
    let htmlMarker = "https://github.com/"
    if (apiUrl.startsWith(apiMarker)) {
        path = apiUrl[apiMarker.size..apiUrl.size]
    } else if (apiUrl.startsWith(htmlMarker)) {
        path = apiUrl[htmlMarker.size..apiUrl.size]
    } else {
        return ""
    }
    if (path.contains("?")) {
        path = path.split("?")[0]
    }
    let segments = path.split("/")
    if (segments.size < 2) {
        return ""
    }
    "${segments[0]}/${segments[1]}"
}

public func resourceNumberFromApiUrl(apiUrl: String): String {
    let segments = apiUrl.split("/")
    if (segments.size == 0) {
        return ""
    }
    segments[segments.size - 1]
}
