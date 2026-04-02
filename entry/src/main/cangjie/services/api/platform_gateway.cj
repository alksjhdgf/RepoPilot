package ohos_app_cangjie_entry.services.api

import std.collection.ArrayList
import ohos_app_cangjie_entry.domain.{AccountSnapshot, ExploreLaneSnapshot, InboxItemSnapshot, IssueSnapshot, PullRequestSnapshot, RepositorySnapshot, WorkplaceSnapshot}

public func loadActiveAccount(): AccountSnapshot {
    AccountSnapshot("provider_github", "repopilot-demo", "account_ready")
}

public func loadWorkplace(id: String): WorkplaceSnapshot {
    if (id == "github") {
        WorkplaceSnapshot("github", "workplace_github", "workplace_github_desc", "workplace_github_hero")
    } else {
        WorkplaceSnapshot("unified", "workplace_unified", "workplace_unified_desc", "workplace_unified_hero")
    }
}

public func loadPrimaryRepositoryId(workplaceId: String): String {
    if (workplaceId == "github") { "mobile" } else { "orchestrator" }
}

public func loadRepository(id: String): RepositorySnapshot {
    if (id == "orchestrator") {
        RepositorySnapshot("orchestrator", "repo_orchestrator", "repo_orchestrator_desc", "05", "18", "07", "taskSections", "prOrchestrator")
    } else if (id == "bff") {
        RepositorySnapshot("bff", "repo_bff", "repo_bff_desc", "02", "09", "03", "repoCard", "prBff")
    } else {
        RepositorySnapshot("mobile", "repo_mobile", "repo_mobile_desc", "03", "14", "05", "auth", "prMobile")
    }
}

public func loadIssue(id: String): IssueSnapshot {
    if (id == "taskSections") {
        IssueSnapshot("taskSections", "issue_task_sections", "issue_task_sections_desc", "issue_context_orchestrator", "executionRhythm")
    } else if (id == "repoCard") {
        IssueSnapshot("repoCard", "issue_repo_card", "issue_repo_card_desc", "issue_context_bff", "repoPolish")
    } else {
        IssueSnapshot("auth", "issue_auth", "issue_auth_desc", "issue_context_mobile", "loginFlow")
    }
}

public func loadPullRequest(id: String): PullRequestSnapshot {
    if (id == "prOrchestrator") {
        PullRequestSnapshot("prOrchestrator", "pr_orchestrator", "pr_orchestrator_desc", "pr_status_review")
    } else if (id == "prBff") {
        PullRequestSnapshot("prBff", "pr_bff", "pr_bff_desc", "pr_status_draft")
    } else {
        PullRequestSnapshot("prMobile", "pr_mobile", "pr_mobile_desc", "pr_status_ready")
    }
}

public func loadRepositoryIssues(repositoryId: String): ArrayList<IssueSnapshot> {
    let items = ArrayList<IssueSnapshot>()
    if (repositoryId == "orchestrator") {
        items.add(loadIssue("taskSections"))
    } else if (repositoryId == "bff") {
        items.add(loadIssue("repoCard"))
    } else {
        items.add(loadIssue("auth"))
    }
    items
}

public func loadRepositoryPullRequests(repositoryId: String): ArrayList<PullRequestSnapshot> {
    let items = ArrayList<PullRequestSnapshot>()
    if (repositoryId == "orchestrator") {
        items.add(loadPullRequest("prOrchestrator"))
    } else if (repositoryId == "bff") {
        items.add(loadPullRequest("prBff"))
    } else {
        items.add(loadPullRequest("prMobile"))
    }
    items
}

public func loadInboxItem(slot: Int64): InboxItemSnapshot {
    if (slot == 1) {
        InboxItemSnapshot("issue", "issue_item", "issue_item_desc")
    } else if (slot == 2) {
        InboxItemSnapshot("executor", "executor_item", "executor_item_desc")
    } else {
        InboxItemSnapshot("restricted", "restricted_item", "restricted_item_desc")
    }
}

public func loadExploreLane(slot: Int64): ExploreLaneSnapshot {
    if (slot == 1) {
        ExploreLaneSnapshot("trending", "trending_repositories", "discover_repositories", "mobile")
    } else {
        ExploreLaneSnapshot("awesome", "awesome_lists", "curated_collections", "orchestrator")
    }
}
