package ohos_app_cangjie_entry.domain

public class GitHubDeviceCodeSnapshot {
    public let deviceCode: String
    public let userCode: String
    public let verificationUri: String
    public let expiresInSeconds: Int64
    public let pollIntervalSeconds: Int64

    public init(
        deviceCode: String,
        userCode: String,
        verificationUri: String,
        expiresInSeconds: Int64,
        pollIntervalSeconds: Int64
    ) {
        this.deviceCode = deviceCode
        this.userCode = userCode
        this.verificationUri = verificationUri
        this.expiresInSeconds = expiresInSeconds
        this.pollIntervalSeconds = pollIntervalSeconds
    }
}

public class GitHubAccessTokenSnapshot {
    public let accessToken: String
    public let tokenType: String
    public let scope: String
    public let refreshToken: String
    public let refreshTokenExpiresInSeconds: Int64

    public init(
        accessToken: String,
        tokenType: String,
        scope: String,
        refreshToken: String,
        refreshTokenExpiresInSeconds: Int64
    ) {
        this.accessToken = accessToken
        this.tokenType = tokenType
        this.scope = scope
        this.refreshToken = refreshToken
        this.refreshTokenExpiresInSeconds = refreshTokenExpiresInSeconds
    }
}

public class GitHubViewerSnapshot {
    public let login: String
    public let displayName: String
    public let profileUrl: String

    public init(login: String, displayName: String, profileUrl: String) {
        this.login = login
        this.displayName = displayName
        this.profileUrl = profileUrl
    }
}

public class GitHubRepositoryCardSnapshot {
    public let name: String
    public let summary: String
    public let repoUrl: String
    public let isPrivate: Bool
    public let isFork: Bool

    public init(name: String, summary: String, repoUrl: String, isPrivate: Bool, isFork: Bool) {
        this.name = name
        this.summary = summary
        this.repoUrl = repoUrl
        this.isPrivate = isPrivate
        this.isFork = isFork
    }
}

public class GitHubRepositoryDetailSnapshot {
    public let name: String
    public let summary: String
    public let repoUrl: String
    public let visibilityLabel: String
    public let issueCount: String
    public let pullRequestCount: String
    public let defaultBranch: String

    public init(
        name: String,
        summary: String,
        repoUrl: String,
        visibilityLabel: String,
        issueCount: String,
        pullRequestCount: String,
        defaultBranch: String
    ) {
        this.name = name
        this.summary = summary
        this.repoUrl = repoUrl
        this.visibilityLabel = visibilityLabel
        this.issueCount = issueCount
        this.pullRequestCount = pullRequestCount
        this.defaultBranch = defaultBranch
    }
}

public class GitHubIssueSnapshot {
    public let id: String
    public let title: String
    public let summary: String
    public let status: String
    public let authorLogin: String
    public let issueUrl: String

    public init(id: String, title: String, summary: String, status: String, authorLogin: String, issueUrl: String) {
        this.id = id
        this.title = title
        this.summary = summary
        this.status = status
        this.authorLogin = authorLogin
        this.issueUrl = issueUrl
    }
}

public class GitHubPullRequestSnapshot {
    public let id: String
    public let title: String
    public let summary: String
    public let status: String
    public let authorLogin: String
    public let pullRequestUrl: String

    public init(id: String, title: String, summary: String, status: String, authorLogin: String, pullRequestUrl: String) {
        this.id = id
        this.title = title
        this.summary = summary
        this.status = status
        this.authorLogin = authorLogin
        this.pullRequestUrl = pullRequestUrl
    }
}
