package ohos_app_cangjie_entry.pages.maps

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.Builder
import ohos_app_cangjie_entry.pages.repository.{ExploreIssueCommentComposerPage, ExploreIssueComposerPage, ExploreIssueDetailPage, ExploreIssuesPage, ExplorePullRequestComposerPage, ExplorePullRequestDetailPage, ExplorePullRequestReviewComposerPage, ExplorePullRequestsPage, ExploreRepositoryDetailPage}
import ohos_app_cangjie_entry.pages.agent.{ExploreCreateTaskPage, ExploreDiffReviewPage, ExploreTaskDetailPage}
import ohos_app_cangjie_entry.pages.common.ExplorePlaceholderPage

@Builder
public func explorePageMap(name: String, detailParam: Any) {
    if (name == "repositoryDetail") {
        ExploreRepositoryDetailPage()
    } else if (name == "issuesPage") {
        ExploreIssuesPage()
    } else if (name == "pullRequestsPage") {
        ExplorePullRequestsPage()
    } else if (name == "issueDetail") {
        ExploreIssueDetailPage()
    } else if (name == "pullRequestDetail") {
        ExplorePullRequestDetailPage()
    } else if (name == "issueComposer") {
        ExploreIssueComposerPage()
    } else if (name == "pullRequestComposer") {
        ExplorePullRequestComposerPage()
    } else if (name == "issueCommentComposer") {
        ExploreIssueCommentComposerPage()
    } else if (name == "pullRequestReviewComposer") {
        ExplorePullRequestReviewComposerPage()
    } else if (name == "createTask") {
        ExploreCreateTaskPage()
    } else if (name == "taskDetail") {
        ExploreTaskDetailPage()
    } else if (name == "diffReview") {
        ExploreDiffReviewPage()
    } else {
        ExplorePlaceholderPage()
    }
}
