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
