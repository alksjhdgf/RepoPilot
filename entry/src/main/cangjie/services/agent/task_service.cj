package ohos_app_cangjie_entry.services.agent

import ohos_app_cangjie_entry.domain.TaskSnapshot

public func taskIdForIssue(issueId: String): String {
    if (issueId == "taskSections") { "executionRhythm" }
    else if (issueId == "repoCard") { "repoPolish" }
    else { "loginFlow" }
}

public func taskSnapshot(id: String): TaskSnapshot {
    if (id == "executionRhythm") {
        TaskSnapshot("executionRhythm", "task_execution_rhythm", "task_execution_rhythm_desc")
    } else if (id == "repoPolish") {
        TaskSnapshot("repoPolish", "task_repo_polish", "task_repo_polish_desc")
    } else {
        TaskSnapshot("loginFlow", "task_login_flow", "task_login_flow_desc")
    }
}
