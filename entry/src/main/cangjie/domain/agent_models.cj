package ohos_app_cangjie_entry.domain

public class TaskSnapshot {
    public let id: String
    public let titleKey: String
    public let summaryKey: String
    public let contextKey: String
    public init(id: String, titleKey: String, summaryKey: String, contextKey: String) {
        this.id = id
        this.titleKey = titleKey
        this.summaryKey = summaryKey
        this.contextKey = contextKey
    }
}

public class TaskDraftSnapshot {
    public let promptKey: String
    public let executionModeKey: String
    public let validationKey: String
    public let outputKey: String
    public init(promptKey: String, executionModeKey: String, validationKey: String, outputKey: String) {
        this.promptKey = promptKey
        this.executionModeKey = executionModeKey
        this.validationKey = validationKey
        this.outputKey = outputKey
    }
}

public class ValidationSnapshot {
    public let titleKey: String
    public let summaryKey: String
    public init(titleKey: String, summaryKey: String) {
        this.titleKey = titleKey
        this.summaryKey = summaryKey
    }
}

public class DraftPullRequestSnapshot {
    public let titleKey: String
    public let bodyKey: String
    public let statusKey: String
    public init(titleKey: String, bodyKey: String, statusKey: String) {
        this.titleKey = titleKey
        this.bodyKey = bodyKey
        this.statusKey = statusKey
    }
}
