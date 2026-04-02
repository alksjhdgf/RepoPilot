package ohos_app_cangjie_entry.services.platform

import std.collection.ArrayList
import ohos_app_cangjie_entry.domain.{ExploreLaneSnapshot, InboxItemSnapshot, IssueSnapshot, PullRequestSnapshot, RepositorySnapshot}
import ohos_app_cangjie_entry.services.api.{loadExploreLane, loadInboxItem, loadIssue, loadPrimaryRepositoryId, loadPullRequest, loadRepository, loadRepositoryIssues, loadRepositoryPullRequests}

public func primaryRepositoryId(workplaceId: String): String { loadPrimaryRepositoryId(workplaceId) }
public func repositorySnapshot(id: String): RepositorySnapshot { loadRepository(id) }
public func issueSnapshot(id: String): IssueSnapshot { loadIssue(id) }
public func pullRequestSnapshot(id: String): PullRequestSnapshot { loadPullRequest(id) }
public func repositoryIssues(repositoryId: String): ArrayList<IssueSnapshot> { loadRepositoryIssues(repositoryId) }
public func repositoryPullRequests(repositoryId: String): ArrayList<PullRequestSnapshot> { loadRepositoryPullRequests(repositoryId) }
public func inboxItem(slot: Int64): InboxItemSnapshot { loadInboxItem(slot) }
public func exploreLane(slot: Int64): ExploreLaneSnapshot { loadExploreLane(slot) }
