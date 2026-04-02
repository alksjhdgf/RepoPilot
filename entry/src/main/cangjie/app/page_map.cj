package ohos_app_cangjie_entry.app

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.Builder
import ohos_app_cangjie_entry.pages.repository.{IssueDetailPage, PullRequestDetailPage, RepositoryDetailPage}
import ohos_app_cangjie_entry.pages.agent.{CreateTaskPage, DiffReviewPage, TaskDetailPage}
import ohos_app_cangjie_entry.pages.settings.SettingsPage

@Builder
public func pageMap(name: String, detailParam: Any) {
    if (name == "repositoryDetail") {
        RepositoryDetailPage()
    } else if (name == "issueDetail") {
        IssueDetailPage()
    } else if (name == "pullRequestDetail") {
        PullRequestDetailPage()
    } else if (name == "createTask") {
        CreateTaskPage()
    } else if (name == "taskDetail") {
        TaskDetailPage()
    } else if (name == "diffReview") {
        DiffReviewPage()
    } else {
        SettingsPage()
    }
}
