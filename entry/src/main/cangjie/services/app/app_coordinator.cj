package ohos_app_cangjie_entry.services.app

import std.collection.ArrayList
import kit.BasicServicesKit.SystemDateTime
import ohos_app_cangjie_entry.domain.{GitHubAccessTokenSnapshot, GitHubAuthLaunchSnapshot, GitHubIssueSnapshot, GitHubProfileMetricsSnapshot, GitHubPullRequestSnapshot, GitHubRepositoryCardSnapshot, GitHubRepositoryDetailSnapshot, GitHubSessionRestorePlan, GitHubStoredSessionSnapshot, GitHubViewerSnapshot, WorkspaceSelectionSnapshot}
import ohos_app_cangjie_entry.services.agent.taskIdForIssue
import ohos_app_cangjie_entry.services.github.{buildGitHubAuthorizationUri, createGitHubRepository, exchangeGitHubWebCode, fetchGitHubProfileMetrics, fetchGitHubRepositories, fetchGitHubRepositoryDetail, fetchGitHubRepositoryIssues, fetchGitHubRepositoryPullRequests, fetchGitHubViewer, refreshGitHubWebToken}
import ohos_app_cangjie_entry.services.platform.{primaryRepositoryId, repositorySnapshot}

public func buildGitHubAuthLaunchSnapshot(requestSequence: Int64): GitHubAuthLaunchSnapshot {
    let authState = "repopilot-auth-${requestSequence}"
    GitHubAuthLaunchSnapshot(authState, buildGitHubAuthorizationUri(authState))
}

public func buildPersistedGitHubStoredSession(
    snapshot: GitHubAccessTokenSnapshot,
    issuedAtMillis: Int64
): GitHubStoredSessionSnapshot {
    let accessExpiresAt =
        if (snapshot.accessTokenExpiresInSeconds > 0) {
            issuedAtMillis + snapshot.accessTokenExpiresInSeconds * 1000
        } else {
            0
        }
    let refreshExpiresAt =
        if (snapshot.refreshTokenExpiresInSeconds > 0) {
            issuedAtMillis + snapshot.refreshTokenExpiresInSeconds * 1000
        } else {
            0
        }
    GitHubStoredSessionSnapshot(
        snapshot.accessToken,
        snapshot.tokenType,
        snapshot.scope,
        snapshot.refreshToken,
        accessExpiresAt,
        refreshExpiresAt
    )
}

public func planStoredGitHubSession(session: GitHubStoredSessionSnapshot, nowMillis: Int64): GitHubSessionRestorePlan {
    if (session.accessTokenExpiresAtMillis == 0 || nowMillis < session.accessTokenExpiresAtMillis) {
        return GitHubSessionRestorePlan("restore", session.accessToken, session.refreshToken)
    }
    if (
        session.refreshToken != "" &&
        (session.refreshTokenExpiresAtMillis == 0 || nowMillis < session.refreshTokenExpiresAtMillis)
    ) {
        return GitHubSessionRestorePlan("refresh", "", session.refreshToken)
    }
    GitHubSessionRestorePlan("discard", "", "")
}

public func restoreMockWorkplaceSelection(workplaceId: String): WorkspaceSelectionSnapshot {
    let repositoryId = primaryRepositoryId(workplaceId)
    let repository = repositorySnapshot(repositoryId)
    WorkspaceSelectionSnapshot(
        repositoryId,
        repository.primaryIssueId,
        repository.primaryPullRequestId,
        taskIdForIssue(repository.primaryIssueId)
    )
}

public func ensureSelectionSnapshot(
    currentWorkplace: String,
    hasAuthAccessToken: Bool,
    selectedRepository: String,
    selectedIssue: String,
    selectedPullRequest: String,
    selectedTask: String,
    hasLiveRepositories: Bool,
    hasLiveIssues: Bool,
    hasLivePullRequests: Bool
): WorkspaceSelectionSnapshot {
    let workplaceId = if (currentWorkplace == "") { "github" } else { currentWorkplace }
    var nextRepository = selectedRepository
    if (nextRepository == "" && (!hasAuthAccessToken || !hasLiveRepositories)) {
        nextRepository = primaryRepositoryId(workplaceId)
    }

    var nextIssue = selectedIssue
    if (nextIssue == "" && nextRepository != "" && (!hasAuthAccessToken || !hasLiveIssues)) {
        nextIssue = repositorySnapshot(nextRepository).primaryIssueId
    }

    var nextPullRequest = selectedPullRequest
    if (nextPullRequest == "" && nextRepository != "" && (!hasAuthAccessToken || !hasLivePullRequests)) {
        nextPullRequest = repositorySnapshot(nextRepository).primaryPullRequestId
    }

    var nextTask = selectedTask
    if (nextTask == "") {
        nextTask = taskIdForIssue(nextIssue)
    }
    WorkspaceSelectionSnapshot(nextRepository, nextIssue, nextPullRequest, nextTask)
}

public func resolveSelectedRepositoryId(
    selectedRepository: String,
    repositories: ArrayList<GitHubRepositoryCardSnapshot>
): String {
    if (repositories.size == 0) {
        return selectedRepository
    }
    if (selectedRepository == "") {
        return repositories[0].name
    }
    selectedRepository
}

public func resolveSelectedIssueState(
    selectedIssue: String,
    items: ArrayList<GitHubIssueSnapshot>
): WorkspaceSelectionSnapshot {
    if (items.size == 0) {
        return WorkspaceSelectionSnapshot("", "", "", "")
    }
    for (item in items) {
        if (item.id == selectedIssue) {
            return WorkspaceSelectionSnapshot("", item.id, "", taskIdForIssue(item.id))
        }
    }
    let first = items[0]
    WorkspaceSelectionSnapshot("", first.id, "", taskIdForIssue(first.id))
}

public func resolveSelectedPullRequestId(
    selectedPullRequest: String,
    items: ArrayList<GitHubPullRequestSnapshot>
): String {
    if (items.size == 0) {
        return selectedPullRequest
    }
    for (item in items) {
        if (item.id == selectedPullRequest) {
            return selectedPullRequest
        }
    }
    items[0].id
}

public func exchangeGitHubAuthCode(
    authCode: String,
    onSuccess: (GitHubAccessTokenSnapshot) -> Unit,
    onFailure: (String) -> Unit
): Unit {
    exchangeGitHubWebCode(authCode, onSuccess, onFailure)
}

public func refreshStoredGitHubSession(
    refreshToken: String,
    onSuccess: (GitHubAccessTokenSnapshot) -> Unit,
    onFailure: (String) -> Unit
): Unit {
    refreshGitHubWebToken(refreshToken, onSuccess, onFailure)
}

public func refreshGitHubProfileData(
    token: String,
    onViewerSuccess: (GitHubViewerSnapshot) -> Unit,
    onMetricsSuccess: (GitHubProfileMetricsSnapshot) -> Unit,
    onRepositoriesSuccess: (ArrayList<GitHubRepositoryCardSnapshot>) -> Unit,
    onFailure: (String) -> Unit
): Unit {
    fetchGitHubViewer(token, onViewerSuccess, onFailure)
    fetchGitHubProfileMetrics(token, onMetricsSuccess, onFailure)
    fetchGitHubRepositories(token, onRepositoriesSuccess, onFailure)
}

public func refreshGitHubRepositoryBundle(
    token: String,
    repositoryName: String,
    onDetailSuccess: (GitHubRepositoryDetailSnapshot) -> Unit,
    onIssuesSuccess: (ArrayList<GitHubIssueSnapshot>) -> Unit,
    onPullRequestsSuccess: (ArrayList<GitHubPullRequestSnapshot>) -> Unit,
    onFailure: (String) -> Unit
): Unit {
    fetchGitHubRepositoryDetail(token, repositoryName, onDetailSuccess, onFailure)
    fetchGitHubRepositoryIssues(token, repositoryName, onIssuesSuccess, onFailure)
    fetchGitHubRepositoryPullRequests(token, repositoryName, onPullRequestsSuccess, onFailure)
}

public func createScratchGitHubRepository(
    token: String,
    onSuccess: (String) -> Unit,
    onFailure: (String) -> Unit
): Unit {
    let repositoryName = "repopilot-scratch-${SystemDateTime.getTime()}"
    createGitHubRepository(
        token,
        repositoryName,
        "Scratch repository created from RepoPilot.",
        { => onSuccess(repositoryName) },
        onFailure
    )
}
