package ohos_app_cangjie_entry.domain

public class GitHubAuthLaunchSnapshot {
    public let authState: String
    public let authorizationUri: String

    public init(authState: String, authorizationUri: String) {
        this.authState = authState
        this.authorizationUri = authorizationUri
    }
}

public class GitHubSessionRestorePlan {
    public let action: String
    public let accessToken: String
    public let refreshToken: String

    public init(action: String, accessToken: String, refreshToken: String) {
        this.action = action
        this.accessToken = accessToken
        this.refreshToken = refreshToken
    }
}

public class WorkspaceSelectionSnapshot {
    public let repositoryId: String
    public let issueId: String
    public let pullRequestId: String
    public let taskId: String

    public init(repositoryId: String, issueId: String, pullRequestId: String, taskId: String) {
        this.repositoryId = repositoryId
        this.issueId = issueId
        this.pullRequestId = pullRequestId
        this.taskId = taskId
    }
}
