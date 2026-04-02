package ohos_app_cangjie_entry.domain

public class WorkplaceSnapshot {
    public let id: String
    public let titleKey: String
    public let summaryKey: String
    public let heroTitleKey: String
    public init(id: String, titleKey: String, summaryKey: String, heroTitleKey: String) {
        this.id = id
        this.titleKey = titleKey
        this.summaryKey = summaryKey
        this.heroTitleKey = heroTitleKey
    }
}

public class AccountSnapshot {
    public let providerKey: String
    public let accountLabel: String
    public let statusKey: String
    public init(providerKey: String, accountLabel: String, statusKey: String) {
        this.providerKey = providerKey
        this.accountLabel = accountLabel
        this.statusKey = statusKey
    }
}

public class RepositorySnapshot {
    public let id: String
    public let titleKey: String
    public let summaryKey: String
    public let activeCount: String
    public let issueCount: String
    public let reviewCount: String
    public let primaryIssueId: String
    public init(id: String, titleKey: String, summaryKey: String, activeCount: String, issueCount: String, reviewCount: String, primaryIssueId: String) {
        this.id = id
        this.titleKey = titleKey
        this.summaryKey = summaryKey
        this.activeCount = activeCount
        this.issueCount = issueCount
        this.reviewCount = reviewCount
        this.primaryIssueId = primaryIssueId
    }
}

public class InboxItemSnapshot {
    public let id: String
    public let titleKey: String
    public let bodyKey: String
    public init(id: String, titleKey: String, bodyKey: String) {
        this.id = id
        this.titleKey = titleKey
        this.bodyKey = bodyKey
    }
}

public class ExploreLaneSnapshot {
    public let id: String
    public let titleKey: String
    public let summaryKey: String
    public let repositoryId: String
    public init(id: String, titleKey: String, summaryKey: String, repositoryId: String) {
        this.id = id
        this.titleKey = titleKey
        this.summaryKey = summaryKey
        this.repositoryId = repositoryId
    }
}
