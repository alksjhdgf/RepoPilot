package ohos_app_cangjie_entry.pages.maps

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.Builder
import ohos_app_cangjie_entry.pages.repository.{IssueDetailPage, PullRequestDetailPage, RepositoryDetailPage}
import ohos_app_cangjie_entry.pages.agent.{CreateTaskPage, DiffReviewPage, TaskDetailPage}
import ohos_app_cangjie_entry.pages.common.HomePlaceholderPage
import ohos_app_cangjie_entry.pages.profile.ProfilePage
import ohos_app_cangjie_entry.pages.settings.{AppearanceSettingsPage, LanguageSettingsPage, SettingsPage}

@Builder
public func homePageMap(name: String, detailParam: Any) {
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
    } else if (name == "placeholder") {
        HomePlaceholderPage()
    } else if (name == "profilePage") {
        ProfilePage()
    } else if (name == "appearanceSettings") {
        AppearanceSettingsPage()
    } else if (name == "languageSettings") {
        LanguageSettingsPage()
    } else {
        SettingsPage()
    }
}
