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
    else if (key == "issue_auth") { "Tighten sign-in routing" }
    else if (key == "issue_auth_desc") { "Reduce friction between auth web handoff and workplace entry." }
    else if (key == "issue_task_sections") { "Rework task sections on mobile" }
    else if (key == "issue_task_sections_desc") { "Clarify execution phases and reduce context switching." }
    else if (key == "issue_repo_card") { "Rebalance repository card density" }
    else if (key == "issue_repo_card_desc") { "Make repository state easier to scan under load." }
    else if (key == "issue_context_mobile") { "Current app build needs a steadier auth handoff and fewer dead ends." }
    else if (key == "issue_context_orchestrator") { "Agent output is landing well, but execution sections are too noisy." }
    else if (key == "issue_context_bff") { "Cards should surface repo health before secondary metadata." }
    else if (key == "pr_mobile") { "Draft: polish mobile auth landing" }
    else if (key == "pr_mobile_desc") { "Refine the transition from sign-in confirmation into the main workplace shell." }
    else if (key == "pr_bff") { "Draft: settle repository detail spacing" }
    else if (key == "pr_bff_desc") { "Reduce visual churn inside repository cards and detail sections." }
    else if (key == "pr_orchestrator") { "Review: align agent execution checkpoints" }
    else if (key == "pr_orchestrator_desc") { "Reshape the execution summary so reviewers can approve faster." }
    else if (key == "pr_status_ready") { "Ready for review" }
    else if (key == "pr_status_draft") { "Draft in progress" }
    else if (key == "pr_status_review") { "Needs reviewer attention" }
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
    else if (key == "task_login_context") { "Focus on the handoff from auth confirmation into the first useful screen." }
    else if (key == "task_repo_polish") { "Tighten repository detail rhythm" }
    else if (key == "task_repo_polish_desc") { "Give repository cards and action areas a calmer cadence." }
    else if (key == "task_repo_context") { "Trim visual weight and make action priorities easier to read." }
    else if (key == "task_execution_rhythm") { "Rebalance execution rhythm" }
    else if (key == "task_execution_rhythm_desc") { "Keep agent work visible without overwhelming the feed." }
    else if (key == "task_execution_context") { "Sequence task phases so agent context remains understandable in a quick pass." }
    else if (key == "prompt_mobile") { "Review the current mobile sign-in experience and propose the smallest high-confidence fix set." }
    else if (key == "prompt_bff") { "Rework repository detail density without losing action clarity." }
    else if (key == "prompt_orchestrator") { "Reshape task execution sections so approval state remains obvious throughout the run." }
    else if (key == "execution_agent") { "Agent execution" }
    else if (key == "execution_manual") { "Manual review pass" }
    else if (key == "validation_smoke") { "Smoke verification on the main task path" }
    else if (key == "validation_ui") { "UI structure and visual regression pass" }
    else if (key == "validation_auth") { "Authentication and handoff regression pass" }
    else if (key == "output_diff") { "Patch + review notes" }
    else if (key == "output_summary") { "Annotated UI summary" }
    else if (key == "output_patch") { "Implementation patch" }
    else if (key == "validation_execution_desc") { "Execution checkpoints now surface as a single readable sequence." }
    else if (key == "validation_repo_desc") { "Repository detail surfaces are calmer and faster to scan." }
    else if (key == "validation_login_desc") { "The auth transition is clearer and less abrupt on first entry." }
    else if (key == "draft_pr_mobile_title") { "Draft PR: polish auth landing transition" }
    else if (key == "draft_pr_mobile_body") { "Refine the auth handoff, reduce transition roughness and keep workplace entry legible." }
    else if (key == "draft_pr_bff_title") { "Draft PR: tighten repository detail pacing" }
    else if (key == "draft_pr_bff_body") { "Reduce metadata noise and give primary actions a steadier reading order." }
    else if (key == "draft_pr_orchestrator_title") { "Draft PR: align execution checkpoints" }
    else if (key == "draft_pr_orchestrator_body") { "Collapse scattered execution notes into a single review-ready flow." }
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
    else if (key == "copilot") { "Copilot" }
    else if (key == "copilot_short") { "Copilot" }
    else if (key == "recent_repositories") { "Recent Repositories" }
    else if (key == "recent_tasks") { "Recent Tasks" }
    else if (key == "see_all") { "See all" }
    else if (key == "focus_label") { "Focus" }
    else if (key == "running_tasks") { "Running" }
    else if (key == "reviews") { "Reviews" }
    else if (key == "inbox_subtitle") { "Prioritize what needs your attention next." }
    else if (key == "explore_subtitle") { "Find code, trends and queues worth opening." }
    else if (key == "profile_subtitle") { "Tune language, appearance and account posture." }
    else if (key == "copilot_subtitle") { "Prepare agent integrations and future Copilot workflows." }
    else if (key == "settings_subtitle") { "Adjust runtime preferences and account posture." }
    else if (key == "profile_account_prefix") { "Account" }
    else if (key == "appearance") { "Appearance" }
    else if (key == "language") { "Language" }
    else if (key == "settings") { "Settings" }
    else if (key == "repositories") { "Repositories" }
    else if (key == "starred") { "Starred" }
    else if (key == "organizations") { "Organizations" }
    else if (key == "popular") { "Popular" }
    else if (key == "copilot_sdk") { "Copilot SDK" }
    else if (key == "copilot_sdk_desc") { "Prepare authentication, provider switching, and session handling for cloud agent access." }
    else if (key == "copilot_agent") { "Agent Routing" }
    else if (key == "copilot_agent_desc") { "Use this tab as the future entry for Copilot requests, task drafts, and agent output." }
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
    else if (key == "back") { "Back" }
    else if (key == "repository_detail") { "Repository Detail" }
    else if (key == "issue_detail") { "Issue Detail" }
    else if (key == "pull_request_detail") { "Pull Request" }
    else if (key == "create_task") { "Create Task" }
    else if (key == "task_detail") { "Task Detail" }
    else if (key == "diff_review") { "Diff Review" }
    else if (key == "issues") { "Issues" }
    else if (key == "pull_requests") { "Pull Requests" }
    else if (key == "open_issue") { "Open issue" }
    else if (key == "review_pr") { "Review pull request" }
    else if (key == "context") { "Context" }
    else if (key == "status") { "Status" }
    else if (key == "close_issue") { "Close issue" }
    else if (key == "comment_issue") { "Comment on issue" }
    else if (key == "ask_agent") { "Ask agent to handle it" }
    else if (key == "close_issue_mock") { "Issue close flow is mocked in this build." }
    else if (key == "comment_issue_mock") { "Issue comment drafted locally." }
    else if (key == "approve_pr") { "Approve review" }
    else if (key == "request_changes") { "Request changes" }
    else if (key == "comment_pr") { "Comment on pull request" }
    else if (key == "approve_pr_mock") { "Approval note drafted locally." }
    else if (key == "request_changes_mock") { "Change request note drafted locally." }
    else if (key == "fork_repository") { "Fork repository" }
    else if (key == "delete_repository") { "Delete repository" }
    else if (key == "prompt_draft") { "Prompt draft" }
    else if (key == "execution_mode") { "Execution mode" }
    else if (key == "validation_scope") { "Validation scope" }
    else if (key == "output_target") { "Output target" }
    else if (key == "create_task_action") { "Create task" }
    else if (key == "validation_result") { "Validation result" }
    else if (key == "open_diff_review") { "Open diff review" }
    else if (key == "review_summary") { "Review summary" }
    else if (key == "draft_pr_title") { "Draft PR title" }
    else if (key == "draft_pr_body") { "Draft PR body" }
    else if (key == "empty_state") { "No items yet." }
    else if (key == "add_short") { "+" }
    else if (key == "find_short") { "⌕" }
    else if (key == "draft_pr_pending") { "Draft pull request is still pending." }
    else { key }
}

func localizedZh(key: String): String { localizedEn(key) }
