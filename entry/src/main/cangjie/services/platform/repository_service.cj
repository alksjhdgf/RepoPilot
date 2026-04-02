package ohos_app_cangjie_entry.services.platform

import ohos_app_cangjie_entry.domain.{ExploreLaneSnapshot, InboxItemSnapshot, RepositorySnapshot}
import ohos_app_cangjie_entry.services.api.{loadExploreLane, loadInboxItem, loadPrimaryRepositoryId, loadRepository}

public func primaryRepositoryId(workplaceId: String): String { loadPrimaryRepositoryId(workplaceId) }
public func repositorySnapshot(id: String): RepositorySnapshot { loadRepository(id) }
public func inboxItem(slot: Int64): InboxItemSnapshot { loadInboxItem(slot) }
public func exploreLane(slot: Int64): ExploreLaneSnapshot { loadExploreLane(slot) }
