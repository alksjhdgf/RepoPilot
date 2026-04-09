package ohos_app_cangjie_entry.domain

public class CursorConversationSnapshot {
    public let id: String
    public let title: String
    public let modelId: String
    public let preview: String
    public let updatedAtLabel: String

    public init(id: String, title: String, modelId: String, preview: String, updatedAtLabel: String) {
        this.id = id
        this.title = title
        this.modelId = modelId
        this.preview = preview
        this.updatedAtLabel = updatedAtLabel
    }
}

public class CursorMessageSnapshot {
    public let id: String
    public let role: String
    public let body: String

    public init(id: String, role: String, body: String) {
        this.id = id
        this.role = role
        this.body = body
    }
}

public class CursorModelSnapshot {
    public let id: String
    public let title: String
    public let providerLabel: String
    public let groupKey: String

    public init(id: String, title: String, providerLabel: String, groupKey: String) {
        this.id = id
        this.title = title
        this.providerLabel = providerLabel
        this.groupKey = groupKey
    }
}

public class CursorPromptSuggestionSnapshot {
    public let title: String
    public let subtitle: String

    public init(title: String, subtitle: String) {
        this.title = title
        this.subtitle = subtitle
    }
}
