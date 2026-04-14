package ohos_app_cangjie_entry.services.github

import kit.BasicServicesKit.SystemDateTime
import ohos_app_cangjie_entry.domain.{GitHubAccessTokenSnapshot, GitHubStoredSessionSnapshot}
import ohos_app_cangjie_entry.infra.databoard.{dataBoardDelete, dataBoardGet, dataBoardSet}

let GITHUB_SESSION_STORE_KEY = "github_auth_session"

func buildPersistedStoredSession(
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

func shouldRestoreStoredAccessToken(session: GitHubStoredSessionSnapshot, nowMillis: Int64): Bool {
    if (session.accessTokenExpiresAtMillis == 0 || nowMillis < session.accessTokenExpiresAtMillis) {
        return true
    }
    false
}

func shouldRefreshStoredAccessToken(session: GitHubStoredSessionSnapshot, nowMillis: Int64): Bool {
    if (
        session.refreshToken != "" &&
        (session.refreshTokenExpiresAtMillis == 0 || nowMillis < session.refreshTokenExpiresAtMillis)
    ) {
        return true
    }
    false
}

/**
 * 将最新的 GitHub token 快照持久化到本地，以便应用重启时自动恢复。
 * Persists the latest GitHub token snapshot so the app can restore it on the next launch.
 */
public func persistStoredGitHubSession(snapshot: GitHubAccessTokenSnapshot): Unit {
    let storedSession = buildPersistedStoredSession(snapshot, SystemDateTime.getTime())
    dataBoardSet(GITHUB_SESSION_STORE_KEY, serializeGitHubStoredSession(storedSession))
}

/**
 * 清除本地保存的 GitHub 会话。
 * Clears the persisted GitHub session.
 */
public func clearStoredGitHubSession(): Unit {
    dataBoardDelete(GITHUB_SESSION_STORE_KEY)
}

/**
 * 尝试恢复本地 GitHub 会话，并将动作分派给调用方。
 * Attempts to restore the persisted GitHub session and dispatches the next action to the caller.
 */
public func restoreStoredGitHubSession(
    onRestoreAccessToken: (String) -> Unit,
    onRefreshToken: (String) -> Unit,
    onMissingOrInvalid: () -> Unit
): Unit {
    let rawSession = dataBoardGet(GITHUB_SESSION_STORE_KEY)
    if (rawSession == "") {
        onMissingOrInvalid()
        return
    }
    if (let Some(session) <- deserializeGitHubStoredSession(rawSession)) {
        let nowMillis = SystemDateTime.getTime()
        if (shouldRestoreStoredAccessToken(session, nowMillis)) {
            onRestoreAccessToken(session.accessToken)
            return
        }
        if (shouldRefreshStoredAccessToken(session, nowMillis)) {
            onRefreshToken(session.refreshToken)
            return
        }
    }
    clearStoredGitHubSession()
    onMissingOrInvalid()
}
