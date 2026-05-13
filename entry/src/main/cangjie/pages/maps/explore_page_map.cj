package ohos_app_cangjie_entry.pages.maps

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.Builder
import ohos_app_cangjie_entry.pages.repository.{ExploreGistDetailPage, ExploreGistFileContentPage, ExploreIssueCommentComposerPage, ExploreIssueComposerPage, ExploreIssueDetailPage, ExploreIssuesPage, ExplorePullRequestComposerPage, ExplorePullRequestDetailPage, ExplorePullRequestReviewComposerPage, ExplorePullRequestsPage, ExploreRepositoryCommitDetailPage, ExploreRepositoryCommitsPage, ExploreRepositoryForksPage, ExploreRepositoryDetailPage, ExploreRepositoryStargazersPage, ExploreRepositoryWatchersPage, ExploreSearchIssuesPage, ExploreSearchPullRequestsPage, ExploreSearchRepositoriesPage, ExploreSearchUsersPage, ExploreUserActivityPage, ExploreUserFollowersPage, ExploreUserFollowingPage, ExploreUserGistsPage, ExploreUserIssuesPage, ExploreUserProfilePage, ExploreUserPullRequestsPage, ExploreUserRepositoriesPage}
import ohos_app_cangjie_entry.pages.agent.{ExploreCreateTaskPage, ExploreDiffReviewPage, ExploreTaskDetailPage}
import ohos_app_cangjie_entry.pages.common.ExplorePlaceholderPage

@Builder
public func explorePageMap(name: String, detailParam: Any) {
    if (name == "repositoryDetail") {
        ExploreRepositoryDetailPage()
    } else if (name == "searchRepositoriesPage") {
        ExploreSearchRepositoriesPage()
    } else if (name == "searchIssuesPage") {
        ExploreSearchIssuesPage()
    } else if (name == "searchPullRequestsPage") {
        ExploreSearchPullRequestsPage()
    } else if (name == "searchUsersPage") {
        ExploreSearchUsersPage()
    } else if (name == "issuesPage") {
        ExploreIssuesPage()
    } else if (name == "pullRequestsPage") {
        ExplorePullRequestsPage()
    } else if (name == "watchersPage") {
        ExploreRepositoryWatchersPage()
    } else if (name == "stargazersPage") {
        ExploreRepositoryStargazersPage()
    } else if (name == "forksPage") {
        ExploreRepositoryForksPage()
    } else if (name == "commitsPage") {
        ExploreRepositoryCommitsPage()
    } else if (name == "commitDetailPage") {
        ExploreRepositoryCommitDetailPage()
    } else if (name == "userProfilePage") {
        ExploreUserProfilePage()
    } else if (name == "userFollowersPage") {
        ExploreUserFollowersPage()
    } else if (name == "userFollowingPage") {
        ExploreUserFollowingPage()
    } else if (name == "userRepositoriesPage") {
        ExploreUserRepositoriesPage()
    } else if (name == "userIssuesPage") {
        ExploreUserIssuesPage()
    } else if (name == "userPullRequestsPage") {
        ExploreUserPullRequestsPage()
    } else if (name == "userActivityPage") {
        ExploreUserActivityPage()
    } else if (name == "userGistsPage") {
        ExploreUserGistsPage()
    } else if (name == "gistDetailPage") {
        ExploreGistDetailPage()
    } else if (name == "gistFileContentPage") {
        ExploreGistFileContentPage()
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
