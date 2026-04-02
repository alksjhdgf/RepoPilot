package ohos_app_cangjie_entry.services.platform

import ohos_app_cangjie_entry.domain.{AccountSnapshot, WorkplaceSnapshot}
import ohos_app_cangjie_entry.services.api.{loadActiveAccount, loadWorkplace}

public func activeAccountSnapshot(): AccountSnapshot { loadActiveAccount() }
public func workplaceSnapshot(id: String): WorkplaceSnapshot { loadWorkplace(id) }
public func defaultWorkplace(): String { "github" }
