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
    public let gistCount: String
    public let followersCount: String
    public let followingCount: String

    public init(
        repositoryCount: String,
        starredCount: String,
        organizationCount: String,
        gistCount!: String = "0",
        followersCount!: String = "0",
        followingCount!: String = "0"
    ) {
        this.repositoryCount = repositoryCount
        this.starredCount = starredCount
        this.organizationCount = organizationCount
        this.gistCount = gistCount
        this.followersCount = followersCount
        this.followingCount = followingCount
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
    public let ownerLogin: String
    public let ownerAvatarUrl: String
    public let primaryLanguage: String
    public let starCount: String
    public let forkCount: String
    public let watcherCount: String
    public let readmeMarkdown: String

    public init(
        name: String,
        summary: String,
        repoUrl: String,
        visibilityLabel: String,
        issueCount: String,
        pullRequestCount: String,
        defaultBranch: String,
        ownerLogin!: String = "",
        ownerAvatarUrl!: String = "",
        primaryLanguage!: String = "",
        starCount!: String = "0",
        forkCount!: String = "0",
        watcherCount!: String = "0",
        readmeMarkdown!: String = ""
    ) {
        this.name = name
        this.summary = summary
        this.repoUrl = repoUrl
        this.visibilityLabel = visibilityLabel
        this.issueCount = issueCount
        this.pullRequestCount = pullRequestCount
        this.defaultBranch = defaultBranch
        this.ownerLogin = ownerLogin
        this.ownerAvatarUrl = ownerAvatarUrl
        this.primaryLanguage = primaryLanguage
        this.starCount = starCount
        this.forkCount = forkCount
        this.watcherCount = watcherCount
        this.readmeMarkdown = readmeMarkdown
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

public class GitHubNotificationSnapshot {
    public let id: String
    public let repositoryName: String
    public let repositoryUrl: String
    public let subjectTitle: String
    public let subjectType: String
    public let reason: String
    public let subjectApiUrl: String
    public let unread: Bool
    public let updatedAt: String

    public init(
        id: String,
        repositoryName: String,
        repositoryUrl: String,
        subjectTitle: String,
        subjectType: String,
        reason: String,
        subjectApiUrl: String,
        unread: Bool,
        updatedAt: String
    ) {
        this.id = id
        this.repositoryName = repositoryName
        this.repositoryUrl = repositoryUrl
        this.subjectTitle = subjectTitle
        this.subjectType = subjectType
        this.reason = reason
        this.subjectApiUrl = subjectApiUrl
        this.unread = unread
        this.updatedAt = updatedAt
    }
}

public class GitHubSearchUserSnapshot {
    public let login: String
    public let profileUrl: String
    public let avatarUrl: String

    public init(login: String, profileUrl: String, avatarUrl: String) {
        this.login = login
        this.profileUrl = profileUrl
        this.avatarUrl = avatarUrl
    }
}

public class GitHubSimpleUserSnapshot {
    public let login: String
    public let profileUrl: String
    public let avatarUrl: String
    public let subtitle: String

    public init(login: String, profileUrl: String, avatarUrl: String, subtitle!: String = "") {
        this.login = login
        this.profileUrl = profileUrl
        this.avatarUrl = avatarUrl
        this.subtitle = subtitle
    }
}

public class GitHubEventSnapshot {
    public let id: String
    public let eventType: String
    public let action: String
    public let repoName: String
    public let targetTitle: String
    public let targetUrl: String
    public let createdAt: String
    public let actorLogin: String

    public init(
        id: String,
        eventType: String,
        action: String,
        repoName: String,
        targetTitle: String,
        targetUrl: String,
        createdAt: String,
        actorLogin: String
    ) {
        this.id = id
        this.eventType = eventType
        this.action = action
        this.repoName = repoName
        this.targetTitle = targetTitle
        this.targetUrl = targetUrl
        this.createdAt = createdAt
        this.actorLogin = actorLogin
    }
}

public class GitHubCommitSnapshot {
    public let sha: String
    public let message: String
    public let authorLogin: String
    public let commitUrl: String

    public init(sha: String, message: String, authorLogin: String, commitUrl: String) {
        this.sha = sha
        this.message = message
        this.authorLogin = authorLogin
        this.commitUrl = commitUrl
    }
}

public class GitHubCommitDetailSnapshot {
    public let sha: String
    public let message: String
    public let authorLogin: String
    public let authorName: String
    public let authorAvatarUrl: String
    public let committedAt: String
    public let additions: Int64
    public let deletions: Int64
    public let commitUrl: String

    public init(
        sha: String,
        message: String,
        authorLogin: String,
        authorName: String,
        authorAvatarUrl: String,
        committedAt: String,
        additions: Int64,
        deletions: Int64,
        commitUrl: String
    ) {
        this.sha = sha
        this.message = message
        this.authorLogin = authorLogin
        this.authorName = authorName
        this.authorAvatarUrl = authorAvatarUrl
        this.committedAt = committedAt
        this.additions = additions
        this.deletions = deletions
        this.commitUrl = commitUrl
    }
}

public class GitHubGistSnapshot {
    public let id: String
    public let description: String
    public let gistUrl: String
    public let isPublic: Bool
    public let updatedAt: String
    public let fileCount: String
    public let ownerLogin: String
    public let ownerAvatarUrl: String
    public let primaryFilename: String

    public init(
        id: String,
        description: String,
        gistUrl: String,
        isPublic: Bool,
        updatedAt: String,
        fileCount: String,
        ownerLogin: String,
        ownerAvatarUrl: String,
        primaryFilename: String
    ) {
        this.id = id
        this.description = description
        this.gistUrl = gistUrl
        this.isPublic = isPublic
        this.updatedAt = updatedAt
        this.fileCount = fileCount
        this.ownerLogin = ownerLogin
        this.ownerAvatarUrl = ownerAvatarUrl
        this.primaryFilename = primaryFilename
    }
}

public class GitHubGistFileSnapshot {
    public let filename: String
    public let language: String
    public let fileType: String
    public let size: String
    public let content: String
    public let rawUrl: String

    public init(filename: String, language: String, fileType: String, size: String, content: String, rawUrl: String) {
        this.filename = filename
        this.language = language
        this.fileType = fileType
        this.size = size
        this.content = content
        this.rawUrl = rawUrl
    }
}

public class GitHubUserProfileSnapshot {
    public let login: String
    public let displayName: String
    public let avatarUrl: String
    public let profileUrl: String
    public let bio: String
    public let location: String
    public let company: String
    public let website: String
    public let repositoryCount: String
    public let gistCount: String
    public let followersCount: String
    public let followingCount: String

    public init(
        login: String,
        displayName: String,
        avatarUrl: String,
        profileUrl: String,
        bio: String,
        location: String,
        company: String,
        website: String,
        repositoryCount: String,
        gistCount: String,
        followersCount: String,
        followingCount: String
    ) {
        this.login = login
        this.displayName = displayName
        this.avatarUrl = avatarUrl
        this.profileUrl = profileUrl
        this.bio = bio
        this.location = location
        this.company = company
        this.website = website
        this.repositoryCount = repositoryCount
        this.gistCount = gistCount
        this.followersCount = followersCount
        this.followingCount = followingCount
    }
}
