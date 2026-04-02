package ohos_app_cangjie_entry.services.agent

import ohos_app_cangjie_entry.domain.{DraftPullRequestSnapshot, TaskDraftSnapshot, TaskSnapshot, ValidationSnapshot}

public func taskIdForIssue(issueId: String): String {
    if (issueId == "taskSections") { "executionRhythm" }
    else if (issueId == "repoCard") { "repoPolish" }
    else { "loginFlow" }
}

public func taskSnapshot(id: String): TaskSnapshot {
    if (id == "executionRhythm") {
        TaskSnapshot("executionRhythm", "task_execution_rhythm", "task_execution_rhythm_desc", "task_execution_context")
    } else if (id == "repoPolish") {
        TaskSnapshot("repoPolish", "task_repo_polish", "task_repo_polish_desc", "task_repo_context")
    } else {
        TaskSnapshot("loginFlow", "task_login_flow", "task_login_flow_desc", "task_login_context")
    }
}

public func taskDraftForIssue(issueId: String): TaskDraftSnapshot {
    if (issueId == "taskSections") {
        TaskDraftSnapshot("prompt_orchestrator", "execution_agent", "validation_smoke", "output_diff")
    } else if (issueId == "repoCard") {
        TaskDraftSnapshot("prompt_bff", "execution_manual", "validation_ui", "output_summary")
    } else {
        TaskDraftSnapshot("prompt_mobile", "execution_agent", "validation_auth", "output_patch")
    }
}

public func validationSnapshot(taskId: String): ValidationSnapshot {
    if (taskId == "executionRhythm") {
        ValidationSnapshot("validation_result", "validation_execution_desc")
    } else if (taskId == "repoPolish") {
        ValidationSnapshot("validation_result", "validation_repo_desc")
    } else {
        ValidationSnapshot("validation_result", "validation_login_desc")
    }
}

public func draftPullRequest(taskId: String): DraftPullRequestSnapshot {
    if (taskId == "executionRhythm") {
        DraftPullRequestSnapshot("draft_pr_orchestrator_title", "draft_pr_orchestrator_body", "pr_status_review")
    } else if (taskId == "repoPolish") {
        DraftPullRequestSnapshot("draft_pr_bff_title", "draft_pr_bff_body", "pr_status_draft")
    } else {
        DraftPullRequestSnapshot("draft_pr_mobile_title", "draft_pr_mobile_body", "pr_status_ready")
    }
}
