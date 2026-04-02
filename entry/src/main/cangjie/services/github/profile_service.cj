package ohos_app_cangjie_entry.services.github

import std.collection.{ArrayList, HashMap}
import kit.NetworkKit.*
import ohos.net.http.{HttpData, HttpDataType, HttpRequestOptions, RequestMethod}
import ohos_app_cangjie_entry.domain.{GitHubRepositoryCardSnapshot, GitHubViewerSnapshot}

let GITHUB_API_ACCEPT = "application/vnd.github+json"
let GITHUB_API_VERSION = "2022-11-28"

func requestGitHubJson(
    url: String,
    token: String,
    onSuccess: (String) -> Unit,
    onFailure: (String) -> Unit
): Unit {
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
                onFailure("Network error ${networkError.code}: ${networkError.message}")
                return
            }
            if (let Some(response) <- resp) {
                let body = match (response.result) {
                    case HttpData.StringData(content) => content
                    case _ => ""
                }
                httpRequest.destroy()
                if (response.responseCode >= 200u32 && response.responseCode < 300u32) {
                    onSuccess(body)
                } else {
                    onFailure("GitHub API ${response.responseCode}")
                }
                return
            }
            httpRequest.destroy()
            onFailure("GitHub returned no response.")
        }
    )
}

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
                onFailure("Unable to parse GitHub user profile.")
                return
            }
            let displayName = extractJsonStringField(body, "name")
            onSuccess(
                GitHubViewerSnapshot(
                    login,
                    if (displayName == "") { login } else { displayName },
                    extractJsonStringField(body, "html_url")
                )
            )
        },
        onFailure
    )
}

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
            onSuccess(repositories)
        },
        onFailure
    )
}
