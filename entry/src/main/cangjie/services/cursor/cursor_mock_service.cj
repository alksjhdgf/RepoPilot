package ohos_app_cangjie_entry.services.cursor

import std.collection.ArrayList
import ohos_app_cangjie_entry.domain.{CursorConversationSnapshot, CursorMessageSnapshot, CursorModelSnapshot, CursorPromptSuggestionSnapshot}

/**
 * 提供 Cursor 页面的本地演示数据，后续接真实 API 时只替换这里的数据源即可。
 * Provides local demo data for Cursor flows so the UI can be wired before live API integration.
 */
public func defaultCursorConversations(): ArrayList<CursorConversationSnapshot> {
    let items = ArrayList<CursorConversationSnapshot>()
    items.add(
        CursorConversationSnapshot(
            "conv_frontend",
            "Front-end frameworks and libraries",
            "claude-haiku-4.5",
            "How to use Svelte for web apps?",
            "5m"
        )
    )
    items.add(
        CursorConversationSnapshot(
            "conv_algorithms",
            "Algorithms",
            "gpt-4.1",
            "Explain binary search tree balancing with examples.",
            "18m"
        )
    )
    items.add(
        CursorConversationSnapshot(
            "conv_repo_review",
            "Repo review",
            "gpt-5-mini",
            "Review this repository onboarding flow and suggest the smallest patch set.",
            "1h"
        )
    )
    items
}

public func defaultCursorModels(): ArrayList<CursorModelSnapshot> {
    let items = ArrayList<CursorModelSnapshot>()
    items.add(CursorModelSnapshot("gpt-5-mini", "GPT-5 mini", "OpenAI", "fast"))
    items.add(CursorModelSnapshot("claude-haiku-4.5", "Claude Haiku 4.5", "Anthropic", "versatile"))
    items.add(CursorModelSnapshot("gpt-4.1", "GPT-4.1", "OpenAI", "versatile"))
    items.add(CursorModelSnapshot("gpt-4o", "GPT-4o", "OpenAI", "versatile"))
    items
}

public func defaultCursorSuggestions(): ArrayList<CursorPromptSuggestionSnapshot> {
    let items = ArrayList<CursorPromptSuggestionSnapshot>()
    items.add(CursorPromptSuggestionSnapshot("Front-end Frameworks and Libraries", "How to use Svelte for web apps?"))
    items.add(CursorPromptSuggestionSnapshot("Algorithms", "Explain binary tree balancing." ))
    items.add(CursorPromptSuggestionSnapshot("Repository Review", "Summarize the riskiest files in this repo."))
    items
}

public func messagesForCursorConversation(conversationId: String): ArrayList<CursorMessageSnapshot> {
    let items = ArrayList<CursorMessageSnapshot>()
    if (conversationId == "conv_frontend") {
        items.add(CursorMessageSnapshot("front_1", "user", "How to use Svelte for web apps?"))
        items.add(
            CursorMessageSnapshot(
                "front_2",
                "assistant",
                "Svelte compiles components ahead of time, so the browser receives minimal runtime code. A practical path is to start with routes, keep state close to features, and let components stay small enough to read in one pass."
            )
        )
    } else if (conversationId == "conv_algorithms") {
        items.add(CursorMessageSnapshot("alg_1", "user", "Explain binary search tree balancing with examples."))
        items.add(
            CursorMessageSnapshot(
                "alg_2",
                "assistant",
                "Balanced trees keep insert and lookup close to O(log n). AVL trees rotate aggressively, while red-black trees tolerate a little imbalance to reduce restructuring."
            )
        )
    } else if (conversationId == "conv_repo_review") {
        items.add(CursorMessageSnapshot("repo_1", "user", "Review this repository onboarding flow and suggest the smallest patch set."))
        items.add(
            CursorMessageSnapshot(
                "repo_2",
                "assistant",
                "I would first isolate sign-in handoff, page-load errors, and dead-end navigation. The smallest patch set is likely to add clearer auth recovery, one navigation fallback, and a tighter initial workspace load."
            )
        )
    }
    items
}

public func modelForCursorConversation(conversationId: String): String {
    if (conversationId == "conv_algorithms") {
        return "gpt-4.1"
    }
    if (conversationId == "conv_repo_review") {
        return "gpt-5-mini"
    }
    "claude-haiku-4.5"
}

public func findCursorConversationTitle(
    items: ArrayList<CursorConversationSnapshot>,
    conversationId: String
): String {
    for (item in items) {
        if (item.id == conversationId) {
            return item.title
        }
    }
    ""
}

public func findCursorModelTitle(items: ArrayList<CursorModelSnapshot>, modelId: String): String {
    for (item in items) {
        if (item.id == modelId) {
            return item.title
        }
    }
    ""
}
