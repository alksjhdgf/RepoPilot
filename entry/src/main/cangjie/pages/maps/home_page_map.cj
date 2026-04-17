package ohos_app_cangjie_entry.pages.maps

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.Builder
import ohos_app_cangjie_entry.pages.repository.{HomeIssueCommentComposerPage, HomeIssueComposerPage, HomeIssuesPage, HomeOrganizationsPage, HomePullRequestComposerPage, HomePullRequestReviewComposerPage, HomePullRequestsPage, HomeRepositoriesPage, HomeStarredRepositoriesPage, HomeTopRepositoriesPage, IssueDetailPage, PullRequestDetailPage, RepositoryDetailPage}
import ohos_app_cangjie_entry.pages.agent.{CreateTaskPage, DiffReviewPage, TaskDetailPage}
import ohos_app_cangjie_entry.pages.common.HomePlaceholderPage
import ohos_app_cangjie_entry.pages.profile.ProfilePage
import ohos_app_cangjie_entry.pages.settings.{AppearanceSettingsPage, LanguageSettingsPage, SettingsPage}

@Builder
public func homePageMap(name: String, detailParam: Any) {
    if (name == "repositoryDetail") {
        RepositoryDetailPage()
    } else if (name == "repositoriesPage") {
        HomeRepositoriesPage()
    } else if (name == "starredRepositoriesPage") {
        HomeStarredRepositoriesPage()
    } else if (name == "topRepositoriesPage") {
        HomeTopRepositoriesPage()
    } else if (name == "issuesPage") {
        HomeIssuesPage()
    } else if (name == "pullRequestsPage") {
        HomePullRequestsPage()
    } else if (name == "organizationsPage") {
        HomeOrganizationsPage()
    } else if (name == "issueDetail") {
        IssueDetailPage()
    } else if (name == "pullRequestDetail") {
        PullRequestDetailPage()
    } else if (name == "issueComposer") {
        HomeIssueComposerPage()
    } else if (name == "pullRequestComposer") {
        HomePullRequestComposerPage()
    } else if (name == "issueCommentComposer") {
        HomeIssueCommentComposerPage()
    } else if (name == "pullRequestReviewComposer") {
        HomePullRequestReviewComposerPage()
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
