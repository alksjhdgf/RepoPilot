package ohos_app_cangjie_entry.services.api

import ohos_app_cangjie_entry.domain.{AccountSnapshot, ExploreLaneSnapshot, InboxItemSnapshot, RepositorySnapshot, WorkplaceSnapshot}

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
        RepositorySnapshot("orchestrator", "repo_orchestrator", "repo_orchestrator_desc", "05", "18", "07", "taskSections")
    } else if (id == "bff") {
        RepositorySnapshot("bff", "repo_bff", "repo_bff_desc", "02", "09", "03", "repoCard")
    } else {
        RepositorySnapshot("mobile", "repo_mobile", "repo_mobile_desc", "03", "14", "05", "auth")
    }
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
