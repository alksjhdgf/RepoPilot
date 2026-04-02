package ohos_app_cangjie_entry.domain

public class TaskSnapshot {
    public let id: String
    public let titleKey: String
    public let summaryKey: String
    public init(id: String, titleKey: String, summaryKey: String) {
        this.id = id
        this.titleKey = titleKey
        this.summaryKey = summaryKey
    }
}
