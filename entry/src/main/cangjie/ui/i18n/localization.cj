package ohos_app_cangjie_entry.ui.i18n

public func appResolveLanguage(preference: String, systemLanguageCode: String): String {
    if (preference == "system") {
        if (systemLanguageCode.startsWith("zh")) { "zh" } else { "en" }
    } else {
        preference
    }
}

public func appLocalizedText(language: String, key: String): String {
    if (language == "zh") { localizedZh(key) } else { localizedEn(key) }
}

func localizedEn(key: String): String {
    if (key == "workplace_github") { "GitHub Workplace" }
    else if (key == "workplace_github_desc") { "Focus on repos, issues and pull requests." }
    else if (key == "workplace_github_hero") { "Ship changes across GitHub." }
    else if (key == "workplace_unified") { "Unified Workplace" }
    else if (key == "workplace_unified_desc") { "Blend repository work with agent tasks." }
    else if (key == "workplace_unified_hero") { "Coordinate work across repos." }
    else if (key == "repo_mobile") { "github/mobile" }
    else if (key == "repo_mobile_desc") { "Mobile client shell, sign-in flow and release polish." }
    else if (key == "repo_bff") { "github/bff" }
    else if (key == "repo_bff_desc") { "Repository summaries, notification shaping and API orchestration." }
    else if (key == "repo_orchestrator") { "github/orchestrator" }
    else if (key == "repo_orchestrator_desc") { "Task execution pacing and draft PR sequencing." }
    else if (key == "issue_item") { "Never miss what's important to you." }
    else if (key == "issue_item_desc") { "Customize notifications, quiet hours and review routing." }
    else if (key == "executor_item") { "Agent run finished on mobile shell." }
    else if (key == "executor_item_desc") { "Ready to review diff notes and draft a pull request." }
    else if (key == "restricted_item") { "Restricted repo needs a fallback route." }
    else if (key == "restricted_item_desc") { "Keep degraded access paths ready for region-limited GitHub use." }
    else if (key == "trending_repositories") { "Trending Repositories" }
    else if (key == "discover_repositories") { "Discover active codebases worth watching." }
    else if (key == "awesome_lists") { "Awesome Lists" }
    else if (key == "curated_collections") { "Browse curated collections from the community." }
    else if (key == "task_login_flow") { "Refine login flow handoff" }
    else if (key == "task_login_flow_desc") { "Polish the journey from sign-in to workplace entry." }
    else if (key == "task_repo_polish") { "Tighten repository detail rhythm" }
    else if (key == "task_repo_polish_desc") { "Give repository cards and action areas a calmer cadence." }
    else if (key == "task_execution_rhythm") { "Rebalance execution rhythm" }
    else if (key == "task_execution_rhythm_desc") { "Keep agent work visible without overwhelming the feed." }
    else if (key == "provider_github") { "GitHub" }
    else if (key == "account_ready") { "Connected" }
    else if (key == "home") { "Home" }
    else if (key == "home_short") { "Home" }
    else if (key == "inbox") { "Inbox" }
    else if (key == "inbox_short") { "Inbox" }
    else if (key == "explore") { "Explore" }
    else if (key == "explore_short") { "Explore" }
    else if (key == "profile") { "Profile" }
    else if (key == "profile_short") { "Profile" }
    else if (key == "recent_repositories") { "Recent Repositories" }
    else if (key == "recent_tasks") { "Recent Tasks" }
    else if (key == "see_all") { "See all" }
    else if (key == "focus_label") { "Focus" }
    else if (key == "running_tasks") { "Running" }
    else if (key == "reviews") { "Reviews" }
    else if (key == "inbox_subtitle") { "Prioritize what needs your attention next." }
    else if (key == "explore_subtitle") { "Find code, trends and queues worth opening." }
    else if (key == "profile_subtitle") { "Tune language, appearance and account posture." }
    else if (key == "settings_subtitle") { "Adjust runtime preferences and account posture." }
    else if (key == "profile_account_prefix") { "Account" }
    else if (key == "appearance") { "Appearance" }
    else if (key == "language") { "Language" }
    else if (key == "system") { "Automatic" }
    else if (key == "light") { "Light" }
    else if (key == "dark") { "Dark" }
    else if (key == "lang_en") { "English" }
    else if (key == "lang_zh") { "Chinese" }
    else if (key == "sign_in_github") { "Sign in to GitHub.com" }
    else if (key == "sign_in_enterprise") { "Sign in with GitHub Enterprise" }
    else if (key == "auth_enterprise_hint") { "Requires server version 3.10.0 or higher." }
    else if (key == "auth_terms") { "By signing in you accept our Terms of Use and Privacy Policy." }
    else if (key == "auth_subtitle") { "Use your account to continue to RepoPilot." }
    else if (key == "auth_web_title") { "github.com" }
    else if (key == "auth_web_subtitle") { "Sign in to GitHub to continue to RepoPilot." }
    else if (key == "username_email") { "Username or email address" }
    else if (key == "password") { "Password" }
    else if (key == "auth_connected_title") { "Connection ready" }
    else if (key == "auth_connected_body") { "Your workplace is ready to open." }
    else if (key == "auth_review_access") { "Review access before running tasks." }
    else if (key == "continue_to_workplace") { "Continue to workplace" }
    else if (key == "create_repository") { "Create repository" }
    else if (key == "sign_out") { "Sign out" }
    else if (key == "workplace") { "Workplace" }
    else if (key == "add_short") { "+" }
    else if (key == "find_short") { "Search" }
    else if (key == "draft_pr_pending") { "Draft pull request is still pending." }
    else { key }
}

func localizedZh(key: String): String { localizedEn(key) }
