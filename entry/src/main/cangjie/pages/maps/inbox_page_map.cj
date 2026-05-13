package ohos_app_cangjie_entry.pages.maps

import kit.ArkUI.*
import ohos.arkui.state_macro_manage.Builder
import ohos_app_cangjie_entry.pages.inbox.InboxNotificationDetailPage
import ohos_app_cangjie_entry.pages.repository.{ExploreIssueDetailPage, ExplorePullRequestDetailPage, ExploreRepositoryDetailPage}

@Builder
public func inboxPageMap(name: String, detailParam: Any) {
    if (name == "notificationDetail") {
        InboxNotificationDetailPage()
    } else if (name == "repositoryDetail") {
        ExploreRepositoryDetailPage()
    } else if (name == "issueDetail") {
        ExploreIssueDetailPage()
    } else if (name == "pullRequestDetail") {
        ExplorePullRequestDetailPage()
    } else {
        Blank()
    }
}
