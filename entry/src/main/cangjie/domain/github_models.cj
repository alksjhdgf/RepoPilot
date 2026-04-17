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
    public let accessTokenExpiresInSeconds: Int64
    public let refreshTokenExpiresInSeconds: Int64

    public init(
        accessToken: String,
        tokenType: String,
        scope: String,
        refreshToken: String,
        accessTokenExpiresInSeconds: Int64,
        refreshTokenExpiresInSeconds: Int64
    ) {
        this.accessToken = accessToken
        this.tokenType = tokenType
        this.scope = scope
        this.refreshToken = refreshToken
        this.accessTokenExpiresInSeconds = accessTokenExpiresInSeconds
        this.refreshTokenExpiresInSeconds = refreshTokenExpiresInSeconds
    }
}

public class GitHubStoredSessionSnapshot {
    public let accessToken: String
    public let tokenType: String
    public let scope: String
    public let refreshToken: String
    public let accessTokenExpiresAtMillis: Int64
    public let refreshTokenExpiresAtMillis: Int64

    public init(
        accessToken: String,
        tokenType: String,
        scope: String,
        refreshToken: String,
        accessTokenExpiresAtMillis: Int64,
        refreshTokenExpiresAtMillis: Int64
    ) {
        this.accessToken = accessToken
        this.tokenType = tokenType
        this.scope = scope
        this.refreshToken = refreshToken
        this.accessTokenExpiresAtMillis = accessTokenExpiresAtMillis
        this.refreshTokenExpiresAtMillis = refreshTokenExpiresAtMillis
    }
}

public class GitHubViewerSnapshot {
    public let login: String
    public let displayName: String
    public let profileUrl: String
    public let avatarUrl: String

    public init(login: String, displayName: String, profileUrl: String, avatarUrl: String) {
        this.login = login
        this.displayName = displayName
        this.profileUrl = profileUrl
        this.avatarUrl = avatarUrl
    }
}

public class GitHubProfileMetricsSnapshot {
    public let repositoryCount: String
    public let starredCount: String
    public let organizationCount: String

    public init(repositoryCount: String, starredCount: String, organizationCount: String) {
        this.repositoryCount = repositoryCount
        this.starredCount = starredCount
        this.organizationCount = organizationCount
    }
}

public class GitHubRepositoryCardSnapshot {
    public let name: String
    public let summary: String
    public let repoUrl: String
    public let isPrivate: Bool
    public let isFork: Bool
    public let starCount: Int64
    public let viewerStarred: Bool

    public init(name: String, summary: String, repoUrl: String, isPrivate: Bool, isFork: Bool, starCount: Int64, viewerStarred: Bool) {
        this.name = name
        this.summary = summary
        this.repoUrl = repoUrl
        this.isPrivate = isPrivate
        this.isFork = isFork
        this.starCount = starCount
        this.viewerStarred = viewerStarred
    }
}

public class GitHubOrganizationSnapshot {
    public let login: String
    public let description: String
    public let profileUrl: String

    public init(login: String, description: String, profileUrl: String) {
        this.login = login
        this.description = description
        this.profileUrl = profileUrl
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
    public let nodeId: String
    public let title: String
    public let summary: String
    public let status: String
    public let authorLogin: String
    public let issueUrl: String

    public init(id: String, nodeId: String, title: String, summary: String, status: String, authorLogin: String, issueUrl: String) {
        this.id = id
        this.nodeId = nodeId
        this.title = title
        this.summary = summary
        this.status = status
        this.authorLogin = authorLogin
        this.issueUrl = issueUrl
    }
}

public class GitHubCommentSnapshot {
    public let id: String
    public let body: String
    public let authorLogin: String
    public let commentUrl: String

    public init(id: String, body: String, authorLogin: String, commentUrl: String) {
        this.id = id
        this.body = body
        this.authorLogin = authorLogin
        this.commentUrl = commentUrl
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
