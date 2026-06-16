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
    else if (key == "home") { "Home" }
    else if (key == "home_short") { "Home" }
    else if (key == "inbox") { "Inbox" }
    else if (key == "inbox_short") { "Inbox" }
    else if (key == "explore") { "Explore" }
    else if (key == "explore_short") { "Explore" }
    else if (key == "copilot") { "Copilot" }
    else if (key == "cursor") { "Cursor" }
    else if (key == "cursor_short") { "Cursor" }
    else if (key == "all_workplaces") { "All Workplaces" }
    else if (key == "my_work") { "My Work" }
    else if (key == "favorites") { "Favorites" }
    else if (key == "shortcuts") { "Shortcuts" }
    else if (key == "recent") { "Recent" }
    else if (key == "activity") { "Activity" }
    else if (key == "issues") { "Issues" }
    else if (key == "pull_requests") { "Pull Requests" }
    else if (key == "discussions") { "Discussions" }
    else if (key == "projects") { "Projects" }
    else if (key == "top_repositories") { "Top Repositories" }
    else if (key == "organizations") { "Organizations" }
    else if (key == "starred") { "Starred" }
    else if (key == "favorites_empty") { "Add favorite repositories here to have quick access at any time, without having to search" }
    else if (key == "add_favorites") { "Add Favorites" }
    else if (key == "manage_favorites") { "Manage Favorites" }
    else if (key == "repository_summary_empty") { "No description provided." }
    else if (key == "shortcuts_title") { "The things you need, one tap away" }
    else if (key == "shortcuts_desc") { "Fast access to your lists of Issues, Pull Requests, or Discussions." }
    else if (key == "get_started") { "Get started" }
    else if (key == "recent_desc") { "Recent activity from GitHub will surface here. Open issues and pull requests you touched last appear first." }
    else if (key == "recent_empty") { "Issues and Pull Requests that you've interacted with recently will appear here." }
    else if (key == "activity_empty") { "No recent public activity yet." }
    else if (key == "event_issue_opened") { "Opened issue" }
    else if (key == "event_issue_closed") { "Closed issue" }
    else if (key == "event_issue_updated") { "Updated issue" }
    else if (key == "event_issue_commented") { "Commented on issue" }
    else if (key == "event_pr_opened") { "Opened pull request" }
    else if (key == "event_pr_closed") { "Closed pull request" }
    else if (key == "event_pr_updated") { "Updated pull request" }
    else if (key == "event_pr_reviewed") { "Reviewed pull request" }
    else if (key == "event_pr_commented") { "Commented on pull request" }
    else if (key == "event_push") { "Pushed commits" }
    else if (key == "event_starred") { "Starred repository" }
    else if (key == "event_forked") { "Forked repository" }
    else if (key == "event_created") { "Created" }
    else if (key == "event_deleted") { "Deleted" }
    else if (key == "event_released") { "Published release" }
    else if (key == "inbox_subtitle") { "Prioritize what needs your attention next." }
    else if (key == "explore_subtitle") { "Find code, trends and queues worth opening." }
    else if (key == "popular") { "Popular" }
    else if (key == "profile_repositories_hint") { "Tap Repositories to view all repositories." }
    else if (key == "agent_sessions") { "Agent sessions" }
    else if (key == "chats") { "Chats" }
    else if (key == "cursor_agent_title") { "Delegate tasks to Cursor cloud agents" }
    else if (key == "cursor_agent_desc") { "Let Cursor work independently in the background to complete tasks, then return to review the results." }
    else if (key == "cursor_upgrade") { "Connect Cursor account" }
    else if (key == "cursor_connected_title") { "Cursor account connected" }
    else if (key == "cursor_connected_desc") { "Your Cursor account is ready. Existing conversations and new chats can now use your cloud agents." }
    else if (key == "cursor_manage_account") { "Manage Cursor account" }
    else if (key == "cursor_no_chats") { "No chats yet" }
    else if (key == "cursor_no_chats_desc") { "Ask Cursor anything to start your first chat." }
    else if (key == "cursor_new_chat") { "New Chat" }
    else if (key == "cursor_new_conversation") { "New conversation" }
    else if (key == "cursor_notice") { "uses AI. Check for mistakes." }
    else if (key == "cursor_empty_conversation") { "Start with a suggestion below, or open a saved conversation." }
    else if (key == "cursor_message_failed") { "Message not delivered" }
    else if (key == "cursor_you") { "You" }
    else if (key == "cursor_ask") { "Ask Cursor" }
    else if (key == "cursor_local_agent_reply") { "Local demo reply: the Cursor API has not been connected yet, so this conversation is using on-device placeholder responses." }
    else if (key == "cursor_new_agent_session") { "New Agent Session" }
    else if (key == "cursor_new_agent_session_pending") { "Agent session creation will be connected after Cursor API access is in place." }
    else if (key == "cursor_view_all_conversations") { "View all conversations" }
    else if (key == "cursor_all_conversations") { "All conversations" }
    else if (key == "cursor_models") { "Models" }
    else if (key == "cursor_models_fast_group") { "Fast and cost-efficient" }
    else if (key == "cursor_models_versatile_group") { "Versatile and highly intelligent" }
    else if (key == "cursor_default_model") { "Claude Haiku 4.5" }
    else if (key == "cursor_now") { "Now" }
    else if (key == "cursor_account") { "Cursor Account" }
    else if (key == "cursor_api_key_title") { "Cursor API key" }
    else if (key == "cursor_api_key_desc") { "Paste the API key from your Cursor dashboard. RepoPilot stores it locally on this device and uses it to fetch your own Cursor agents." }
    else if (key == "cursor_api_key_placeholder") { "Paste your Cursor API key" }
    else if (key == "cursor_test_connection") { "Test connection" }
    else if (key == "cursor_api_key_saved") { "API key saved locally." }
    else if (key == "cursor_api_key_cleared") { "Cursor API key cleared." }
    else if (key == "cursor_api_key_missing") { "Paste an API key first." }
    else if (key == "cursor_api_key_testing") { "Testing Cursor connection..." }
    else if (key == "cursor_api_key_valid") { "Cursor connection succeeded" }
    else if (key == "cursor_connect_failed_title") { "Unable to connect Cursor" }
    else if (key == "cursor_api_key_missing_reason") { "No API key was provided. Save still completed locally, but there is nothing to test yet. Open Cursor Dashboard and create a User API key first." }
    else if (key == "cursor_error_400") { "Cursor rejected this request as invalid (400). The saved API key may be malformed, or the request data may not match the expected format." }
    else if (key == "cursor_error_401") { "Cursor did not accept this API key (401). Check that you copied the full User API key from Cursor Dashboard and that there are no extra spaces or missing characters." }
    else if (key == "cursor_error_403") { "Cursor refused this request (403). Common causes are: the key is not a User API key, the account has not enabled the required plan or feature yet, or this account does not have permission to use the agent endpoint." }
    else if (key == "cursor_error_404") { "Cursor could not find the requested resource (404). This usually means the API path or referenced conversation is no longer available for the current account." }
    else if (key == "cursor_error_409") { "Cursor reported a conflict (409). A previous agent or conversation operation may still be in progress. Wait a moment and try again." }
    else if (key == "cursor_error_429") { "Cursor is rate-limiting requests (429). Wait a little and try again, or check whether the current account has reached its temporary usage limit." }
    else if (key == "cursor_error_500") { "Cursor returned a server error (500). This is usually temporary on the service side. Try again in a moment." }
    else if (key == "cursor_error_network") { "The request did not reach Cursor successfully. Check network availability and try again." }
    else if (key == "cursor_error_no_response") { "Cursor did not return a response. This can happen with unstable network conditions or an upstream service problem." }
    else if (key == "cursor_error_unknown") { "Cursor returned an unexpected error. The original response is shown below." }
    else if (key == "cursor_open_dashboard") { "Open Cursor dashboard" }
    else if (key == "cursor_clear_api_key") { "Clear API key" }
    else if (key == "cursor_clear_input") { "Clear input" }
    else if (key == "cursor_reset_draft") { "Restore saved key" }
    else if (key == "cursor_api_key_restored") { "Restored the saved API key draft." }
    else if (key == "cursor_dashboard_opened") { "Cursor dashboard opened. Go to Integrations and create a User API key, then return here." }
    else if (key == "cursor_api_key_path_hint") { "Cursor Dashboard -> Integrations -> User API Keys" }
    else if (key == "cursor_browser_open_failed") { "Unable to open the browser. Please try again." }
    else if (key == "cursor_repository_required") { "Open or select a repository before starting a Cursor agent." }
    else if (key == "cursor_agent_started") { "Cursor agent started. You can return later to inspect progress." }
    else if (key == "cursor_followup_sent") { "Follow-up sent to Cursor agent." }
    else if (key == "cursor_subtitle") { "Use Cursor cloud agents to manage sessions and chats." }
    else if (key == "appearance") { "Appearance" }
    else if (key == "language") { "Language" }
    else if (key == "settings") { "Settings" }
    else if (key == "app_language") { "App Language" }
    else if (key == "app_icon") { "App Icon" }
    else if (key == "default_option") { "Default" }
    else if (key == "notifications") { "Notifications" }
    else if (key == "notifications_empty") { "No notifications available yet." }
    else if (key == "loading_more") { "Loading more..." }
    else if (key == "people") { "People" }
    else if (key == "open_on_github") { "Open on GitHub" }
    else if (key == "updated") { "Updated" }
    else if (key == "open_in_app") { "Open in app" }
    else if (key == "connect_github_first") { "Connect GitHub first." }
    else if (key == "repository_create_sign_in_required") { "Sign in to GitHub before creating a repository." }
    else if (key == "repository_created") { "Repository created on GitHub." }
    else if (key == "repository_create_scope_required") { "GitHub denied repository creation for the current OAuth token. Reconnect GitHub to refresh repository scopes, then try again." }
    else if (key == "repository_create_reconnect_action") { "Reconnect GitHub" }
    else if (key == "repository_fork_requested") { "Fork requested on GitHub." }
    else if (key == "repository_deleted") { "Repository deleted on GitHub." }
    else if (key == "issue_node_id_missing") { "This issue is missing a GitHub node id." }
    else if (key == "issue_closed") { "Closed the issue on GitHub." }
    else if (key == "not_available") { "This action is not available right now." }
    else if (key == "notification_opened_on_github") { "Opened on GitHub because this notification type does not yet have an in-app page." }
    else if (key == "search_placeholder") { "Enter a search query first." }
    else if (key == "setup_needed") { "Setup Needed" }
    else if (key == "code_options") { "Code Options" }
    else if (key == "external_links") { "External Links" }
    else if (key == "share_feedback") { "Share Feedback" }
    else if (key == "share") { "Share" }
    else if (key == "share_repository") { "Share Repository" }
    else if (key == "share_profile") { "Share Profile" }
    else if (key == "share_gist") { "Share Gist" }
    else if (key == "sign_out") { "Sign out" }
    else if (key == "terms_of_service") { "Terms of Service" }
    else if (key == "privacy_policy") { "Privacy Policy & Analytics" }
    else if (key == "feature_preview") { "Feature Preview" }
    else if (key == "manage_accounts") { "Manage Accounts" }
    else if (key == "app_lock") { "App Lock" }
    else if (key == "clear_cache") { "Clear cache" }
    else if (key == "repositories") { "Repositories" }
    else if (key == "gists") { "Gists" }
    else if (key == "gist_files") { "Gist files" }
    else if (key == "file_content") { "File content" }
    else if (key == "open_raw") { "Open raw file" }
    else if (key == "file_type") { "Type" }
    else if (key == "file_size") { "Size" }
    else if (key == "updated") { "Updated" }
    else if (key == "content_unavailable") { "Content not returned by GitHub. Open the raw file to inspect it." }
    else if (key == "repository_owner") { "Repository owner" }
    else if (key == "repositories_empty") { "No repositories available yet." }
    else if (key == "no_open_issues") { "No open issues." }
    else if (key == "no_open_pull_requests") { "No open pull requests." }
    else if (key == "view_all") { "View all" }
    else if (key == "gists_empty") { "No gists available yet." }
    else if (key == "starred_empty") { "No starred repositories yet." }
    else if (key == "issues_empty") { "No issues available yet." }
    else if (key == "pull_requests_empty") { "No pull requests available yet." }
    else if (key == "organizations_empty") { "No organizations available yet." }
    else if (key == "followers") { "Followers" }
    else if (key == "following") { "Following" }
    else if (key == "followers_empty") { "No followers available yet." }
    else if (key == "following_empty") { "No following accounts available yet." }
    else if (key == "watchers") { "Watchers" }
    else if (key == "watchers_empty") { "No watchers available yet." }
    else if (key == "stargazers") { "Stargazers" }
    else if (key == "stargazers_empty") { "No stargazers available yet." }
    else if (key == "forks") { "Forks" }
    else if (key == "forks_empty") { "No forks available yet." }
    else if (key == "commits") { "Commits" }
    else if (key == "commits_empty") { "No commits available yet." }
    else if (key == "commit_message") { "Commit message" }
    else if (key == "commit_sha") { "Commit" }
    else if (key == "commit_date") { "Date" }
    else if (key == "additions") { "Additions" }
    else if (key == "deletions") { "Deletions" }
    else if (key == "default_branch") { "Default branch" }
    else if (key == "view_more") { "View more" }
    else if (key == "open") { "Open" }
    else if (key == "browse_code") { "Browse code" }
    else if (key == "files") { "files" }
    else if (key == "public") { "Public" }
    else if (key == "private") { "Private" }
    else if (key == "system") { "Automatic" }
    else if (key == "light") { "Light" }
    else if (key == "dark") { "Dark" }
    else if (key == "lang_en") { "English" }
    else if (key == "lang_zh") { "中文" }
    else if (key == "save") { "Save" }
    else if (key == "close") { "Close" }
    else if (key == "add_short") { "+" }
    else if (key == "find_short") { "⌕" }
    else if (key == "sign_in_github") { "Sign in to GitHub.com" }
    else if (key == "sign_in_enterprise") { "Sign in with GitHub Enterprise" }
    else if (key == "auth_enterprise_hint") { "Requires server version 3.10.0 or higher." }
    else if (key == "auth_terms") { "By signing in you accept our Terms of Use and Privacy Policy." }
    else if (key == "auth_subtitle") { "Use your account to continue to RepoPilot." }
    else if (key == "auth_web_title") { "github.com" }
    else if (key == "auth_web_subtitle") { "Sign in to GitHub to continue to RepoPilot." }
    else if (key == "auth_connected_title") { "Connection ready" }
    else if (key == "auth_connected_body") { "Your workplace is ready to open." }
    else if (key == "auth_review_access") { "Review access before running tasks." }
    else if (key == "continue_to_workplace") { "Continue to workplace" }
    else if (key == "workplace") { "Workplace" }
    else if (key == "back") { "Back" }
    else if (key == "repository_detail") { "Repository Detail" }
    else if (key == "readme") { "README" }
    else if (key == "readme_empty") { "No README was found for this repository." }
    else if (key == "issue_detail") { "Issue Detail" }
    else if (key == "pull_request_detail") { "Pull Request" }
    else if (key == "create_task") { "Create Task" }
    else if (key == "task_detail") { "Task Detail" }
    else if (key == "diff_review") { "Diff Review" }
    else if (key == "open_issue") { "Open issue" }
    else if (key == "review_pr") { "Review pull request" }
    else if (key == "create_issue") { "Create issue" }
    else if (key == "create_pull_request") { "Create pull request" }
    else if (key == "context") { "Context" }
    else if (key == "status") { "Status" }
    else if (key == "sign_in_required") { "Connect GitHub first." }
    else if (key == "issue_editor") { "New issue" }
    else if (key == "pull_request_editor") { "New pull request" }
    else if (key == "composer_title_placeholder") { "Issue title" }
    else if (key == "composer_body_placeholder") { "Write in Markdown..." }
    else if (key == "composer_pr_title_placeholder") { "Pull request title" }
    else if (key == "composer_pr_body_placeholder") { "Describe the pull request in Markdown..." }
    else if (key == "composer_head_branch_placeholder") { "Head branch" }
    else if (key == "composer_base_branch_placeholder") { "Base branch" }
    else if (key == "composer_write") { "Write" }
    else if (key == "composer_preview") { "Preview" }
    else if (key == "composer_h1") { "H1" }
    else if (key == "composer_h2") { "H2" }
    else if (key == "composer_bullets") { "Bullets" }
    else if (key == "composer_numbers") { "Numbers" }
    else if (key == "composer_checklist") { "Checklist" }
    else if (key == "composer_quote") { "Quote" }
    else if (key == "composer_code") { "Code" }
    else if (key == "composer_link") { "Link" }
    else if (key == "composer_bold") { "Bold" }
    else if (key == "composer_italic") { "Italic" }
    else if (key == "composer_divider") { "Divider" }
    else if (key == "composer_title_required") { "Please enter a title first." }
    else if (key == "composer_branch_required") { "Please provide both head and base branches." }
    else if (key == "composer_branch_same") { "Head and base branches must be different." }
    else if (key == "composer_branch_unknown") { "Choose branches from the repository branch list." }
    else if (key == "composer_branch_source_required") { "Create another branch first, or enter owner:branch from a fork." }
    else if (key == "publish_issue") { "Publish issue" }
    else if (key == "publish_pull_request") { "Publish pull request" }
    else if (key == "issue_comment_editor") { "New issue comment" }
    else if (key == "pull_request_review_editor") { "New review" }
    else if (key == "composer_comment_placeholder") { "Write your comment in Markdown..." }
    else if (key == "composer_review_placeholder") { "Write your review in Markdown..." }
    else if (key == "publish_comment") { "Publish comment" }
    else if (key == "publish_review") { "Publish review" }
    else if (key == "composer_body_required") { "Please enter some content first." }
    else if (key == "review_type") { "Review type" }
    else if (key == "review_comment") { "Comment" }
    else if (key == "review_approve") { "Approve" }
    else if (key == "review_request_changes") { "Request changes" }
    else if (key == "close_issue") { "Close issue" }
    else if (key == "comment_issue") { "Comment on issue" }
    else if (key == "ask_agent") { "Ask agent to handle it" }
    else if (key == "approve_pr") { "Approve review" }
    else if (key == "request_changes") { "Request changes" }
    else if (key == "comment_pr") { "Comment on pull request" }
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
    else if (key == "draft_pr_pending") { "Draft pull request is still pending." }
    else if (key == "provider_github") { "GitHub" }
    else if (key == "account_ready") { "Connected" }
    else if (key == "trending_repositories") { "Trending Repositories" }
    else if (key == "discover_repositories") { "Discover active codebases worth watching." }
    else if (key == "awesome_lists") { "Awesome Lists" }
    else if (key == "curated_collections") { "Browse curated collections from the community." }
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
    else { key }
}

func localizedZh(key: String): String {
    if (key == "workplace_github") { "GitHub 工作区" }
    else if (key == "workplace_github_desc") { "聚焦仓库、Issue 和 Pull Request。" }
    else if (key == "workplace_unified") { "统一工作区" }
    else if (key == "workplace_unified_desc") { "统一查看仓库工作与 Agent 任务。" }
    else if (key == "home") { "首页" }
    else if (key == "home_short") { "首页" }
    else if (key == "inbox") { "收件箱" }
    else if (key == "inbox_short") { "收件箱" }
    else if (key == "explore") { "探索" }
    else if (key == "explore_short") { "探索" }
    else if (key == "copilot") { "Copilot" }
    else if (key == "cursor") { "Cursor" }
    else if (key == "cursor_short") { "Cursor" }
    else if (key == "all_workplaces") { "全部工作区" }
    else if (key == "my_work") { "我的工作" }
    else if (key == "favorites") { "收藏" }
    else if (key == "shortcuts") { "快捷入口" }
    else if (key == "recent") { "最近" }
    else if (key == "activity") { "活动" }
    else if (key == "issues") { "问题" }
    else if (key == "pull_requests") { "拉取请求" }
    else if (key == "discussions") { "讨论" }
    else if (key == "projects") { "项目" }
    else if (key == "top_repositories") { "重点仓库" }
    else if (key == "organizations") { "组织" }
    else if (key == "starred") { "已收藏" }
    else if (key == "favorites_empty") { "将常用仓库加入收藏后，就能随时快速进入，无需再次搜索。" }
    else if (key == "add_favorites") { "添加收藏" }
    else if (key == "manage_favorites") { "管理收藏" }
    else if (key == "repository_summary_empty") { "暂无仓库描述。" }
    else if (key == "shortcuts_title") { "常用内容，一键直达" }
    else if (key == "shortcuts_desc") { "快速访问你的 Issues、Pull Requests 或 Discussions 列表。" }
    else if (key == "get_started") { "开始使用" }
    else if (key == "recent_desc") { "GitHub 上最近的活动会显示在这里，你最近接触过的 Issue 和 Pull Request 会优先出现。" }
    else if (key == "recent_empty") { "你最近交互过的 Issues 和 Pull Requests 会显示在这里。" }
    else if (key == "activity_empty") { "暂时还没有最近的公开活动。" }
    else if (key == "event_issue_opened") { "创建了问题" }
    else if (key == "event_issue_closed") { "关闭了问题" }
    else if (key == "event_issue_updated") { "更新了问题" }
    else if (key == "event_issue_commented") { "评论了问题" }
    else if (key == "event_pr_opened") { "创建了拉取请求" }
    else if (key == "event_pr_closed") { "关闭了拉取请求" }
    else if (key == "event_pr_updated") { "更新了拉取请求" }
    else if (key == "event_pr_reviewed") { "审阅了拉取请求" }
    else if (key == "event_pr_commented") { "评论了拉取请求" }
    else if (key == "event_push") { "推送了提交" }
    else if (key == "event_starred") { "收藏了仓库" }
    else if (key == "event_forked") { "Fork 了仓库" }
    else if (key == "event_created") { "创建了" }
    else if (key == "event_deleted") { "删除了" }
    else if (key == "event_released") { "发布了版本" }
    else if (key == "inbox_subtitle") { "优先处理下一步最值得关注的事项。" }
    else if (key == "explore_subtitle") { "发现值得打开的代码、趋势和队列。" }
    else if (key == "popular") { "热门" }
    else if (key == "profile_repositories_hint") { "点击“仓库”查看全部仓库。" }
    else if (key == "agent_sessions") { "Agent 会话" }
    else if (key == "chats") { "聊天" }
    else if (key == "cursor_agent_title") { "将任务委派给 Cursor 云端 Agent" }
    else if (key == "cursor_agent_desc") { "让 Cursor 在后台独立完成任务，随后回到应用中查看结果。" }
    else if (key == "cursor_upgrade") { "连接 Cursor 账号" }
    else if (key == "cursor_connected_title") { "Cursor 账号已连接" }
    else if (key == "cursor_connected_desc") { "当前 Cursor 账号已经可用，已有会话和新建对话都可以直接使用你的云端 agents。" }
    else if (key == "cursor_manage_account") { "管理 Cursor 账号" }
    else if (key == "cursor_no_chats") { "还没有聊天" }
    else if (key == "cursor_no_chats_desc") { "向 Cursor 提问即可开始你的第一段对话。" }
    else if (key == "cursor_new_chat") { "新建对话" }
    else if (key == "cursor_new_conversation") { "新建会话" }
    else if (key == "cursor_notice") { "使用 AI。请注意校验结果。" }
    else if (key == "cursor_empty_conversation") { "从下方建议开始，或者打开一个已保存的会话。" }
    else if (key == "cursor_message_failed") { "消息未成功送达" }
    else if (key == "cursor_you") { "你" }
    else if (key == "cursor_ask") { "向 Cursor 提问" }
    else if (key == "cursor_local_agent_reply") { "本地演示回复：当前还没有接入真实 Cursor API，所以这段对话使用的是本地占位响应。" }
    else if (key == "cursor_new_agent_session") { "新建 Agent 会话" }
    else if (key == "cursor_new_agent_session_pending") { "等接入 Cursor API 之后，这里会连接真实的 Agent 会话创建流程。" }
    else if (key == "cursor_view_all_conversations") { "查看全部会话" }
    else if (key == "cursor_all_conversations") { "全部会话" }
    else if (key == "cursor_models") { "模型" }
    else if (key == "cursor_models_fast_group") { "快速且更省成本" }
    else if (key == "cursor_models_versatile_group") { "通用且能力更强" }
    else if (key == "cursor_default_model") { "Claude Haiku 4.5" }
    else if (key == "cursor_now") { "刚刚" }
    else if (key == "cursor_account") { "Cursor 账号" }
    else if (key == "cursor_api_key_title") { "Cursor API key" }
    else if (key == "cursor_api_key_desc") { "粘贴你在 Cursor Dashboard 中生成的 API key。RepoPilot 只会把它保存在当前设备上，并用它请求你自己的 Cursor agents。" }
    else if (key == "cursor_api_key_placeholder") { "粘贴你的 Cursor API key" }
    else if (key == "cursor_test_connection") { "测试连接" }
    else if (key == "cursor_api_key_saved") { "API key 已保存到本地。" }
    else if (key == "cursor_api_key_cleared") { "Cursor API key 已清除。" }
    else if (key == "cursor_api_key_missing") { "请先粘贴 API key。" }
    else if (key == "cursor_api_key_testing") { "正在测试 Cursor 连接..." }
    else if (key == "cursor_api_key_valid") { "Cursor 连接成功" }
    else if (key == "cursor_connect_failed_title") { "无法连接 Cursor" }
    else if (key == "cursor_api_key_missing_reason") { "当前没有提供 API key。保存动作仍然已经落到本地，但还没有可测试的凭证。请先前往 Cursor Dashboard 创建 User API key。" }
    else if (key == "cursor_error_400") { "Cursor 返回了无效请求（400）。常见原因是 API key 格式不正确，或者请求内容不符合该接口要求。" }
    else if (key == "cursor_error_401") { "Cursor 未接受当前 API key（401）。请确认你复制的是 Cursor Dashboard 中完整的 User API key，且没有多余空格或缺失字符。" }
    else if (key == "cursor_error_403") { "Cursor 拒绝了本次请求（403）。常见原因包括：当前 key 不是 User API key、账号尚未开通所需 plan 或功能、或者当前账号没有使用该 agent 接口的权限。" }
    else if (key == "cursor_error_404") { "Cursor 未找到对应资源（404）。这通常表示当前账号下没有对应资源，或者相关会话/路径已不可用。" }
    else if (key == "cursor_error_409") { "Cursor 返回了冲突状态（409）。可能是之前的 agent 或会话操作仍在处理中，请稍后重试。" }
    else if (key == "cursor_error_429") { "Cursor 当前触发了限流（429）。请稍等后再试，或检查当前账号是否已达到临时使用上限。" }
    else if (key == "cursor_error_500") { "Cursor 返回了服务端错误（500）。这通常是暂时性的服务问题，可以稍后重试。" }
    else if (key == "cursor_error_network") { "请求未能成功到达 Cursor，请检查网络状态后重试。" }
    else if (key == "cursor_error_no_response") { "Cursor 没有返回响应。这通常与网络不稳定或上游服务异常有关。" }
    else if (key == "cursor_error_unknown") { "Cursor 返回了未预期的错误，原始返回如下。" }
    else if (key == "cursor_open_dashboard") { "打开 Cursor 控制台" }
    else if (key == "cursor_clear_api_key") { "清除 API key" }
    else if (key == "cursor_clear_input") { "清空输入" }
    else if (key == "cursor_reset_draft") { "恢复已保存 key" }
    else if (key == "cursor_api_key_restored") { "已恢复为本地保存的 API key 草稿。" }
    else if (key == "cursor_dashboard_opened") { "已打开 Cursor 控制台。请前往 Integrations 创建 User API key，然后返回这里。" }
    else if (key == "cursor_api_key_path_hint") { "Cursor Dashboard -> Integrations -> User API Keys" }
    else if (key == "cursor_browser_open_failed") { "无法打开浏览器，请重试。" }
    else if (key == "cursor_repository_required") { "请先打开或选中一个仓库，再启动 Cursor agent。" }
    else if (key == "cursor_agent_started") { "Cursor agent 已启动，你可以稍后回来查看进度。" }
    else if (key == "cursor_followup_sent") { "已向 Cursor agent 发送 follow-up。" }
    else if (key == "cursor_subtitle") { "使用 Cursor 云端 Agent 管理会话与聊天。" }
    else if (key == "appearance") { "外观" }
    else if (key == "language") { "语言" }
    else if (key == "settings") { "设置" }
    else if (key == "app_language") { "应用语言" }
    else if (key == "app_icon") { "应用图标" }
    else if (key == "default_option") { "默认" }
    else if (key == "notifications") { "通知" }
    else if (key == "notifications_empty") { "暂时没有可展示的通知。" }
    else if (key == "loading_more") { "正在加载更多..." }
    else if (key == "people") { "用户" }
    else if (key == "open_on_github") { "在 GitHub 中打开" }
    else if (key == "updated") { "更新时间" }
    else if (key == "open_in_app") { "在应用中打开" }
    else if (key == "connect_github_first") { "请先连接 GitHub。" }
    else if (key == "repository_create_sign_in_required") { "创建仓库前请先连接 GitHub。" }
    else if (key == "repository_created") { "仓库已在 GitHub 上创建。" }
    else if (key == "repository_create_scope_required") { "GitHub 因当前 OAuth 令牌缺少仓库权限而拒绝了创建仓库。请重新连接 GitHub 刷新仓库 scopes 后再试。" }
    else if (key == "repository_create_reconnect_action") { "重新连接 GitHub" }
    else if (key == "repository_fork_requested") { "已在 GitHub 上发起 fork。" }
    else if (key == "repository_deleted") { "仓库已从 GitHub 删除。" }
    else if (key == "issue_node_id_missing") { "当前 Issue 缺少 GitHub 节点标识。" }
    else if (key == "issue_closed") { "Issue 已在 GitHub 上关闭。" }
    else if (key == "not_available") { "当前操作暂不可用。" }
    else if (key == "notification_opened_on_github") { "该通知类型暂时没有应用内页面，已为你转到 GitHub。" }
    else if (key == "search_placeholder") { "请先输入搜索内容。" }
    else if (key == "setup_needed") { "待设置" }
    else if (key == "code_options") { "代码选项" }
    else if (key == "external_links") { "外部链接" }
    else if (key == "share_feedback") { "分享反馈" }
    else if (key == "share") { "分享" }
    else if (key == "share_repository") { "分享仓库" }
    else if (key == "share_profile") { "分享主页" }
    else if (key == "share_gist") { "分享 Gist" }
    else if (key == "sign_out") { "退出登录" }
    else if (key == "terms_of_service") { "服务条款" }
    else if (key == "privacy_policy") { "隐私政策与分析" }
    else if (key == "feature_preview") { "功能预览" }
    else if (key == "manage_accounts") { "管理账号" }
    else if (key == "app_lock") { "应用锁" }
    else if (key == "clear_cache") { "清理缓存" }
    else if (key == "repositories") { "仓库" }
    else if (key == "gists") { "Gists" }
    else if (key == "gist_files") { "Gist 文件" }
    else if (key == "file_content") { "文件内容" }
    else if (key == "open_raw") { "打开原始文件" }
    else if (key == "file_type") { "类型" }
    else if (key == "file_size") { "大小" }
    else if (key == "updated") { "更新于" }
    else if (key == "content_unavailable") { "GitHub 没有返回文件内容，可直接打开原始文件查看。" }
    else if (key == "repository_owner") { "仓库所有者" }
    else if (key == "repositories_empty") { "暂时没有可展示的仓库。" }
    else if (key == "no_open_issues") { "没有打开的问题。" }
    else if (key == "no_open_pull_requests") { "没有打开的拉取请求。" }
    else if (key == "view_all") { "查看全部" }
    else if (key == "gists_empty") { "暂时没有可展示的 Gist。" }
    else if (key == "starred_empty") { "暂时没有已收藏的仓库。" }
    else if (key == "issues_empty") { "暂时没有可展示的 Issue。" }
    else if (key == "pull_requests_empty") { "暂时没有可展示的 Pull Request。" }
    else if (key == "organizations_empty") { "暂时没有可展示的组织。" }
    else if (key == "followers") { "关注者" }
    else if (key == "following") { "正在关注" }
    else if (key == "followers_empty") { "暂时没有可展示的关注者。" }
    else if (key == "following_empty") { "暂时没有可展示的正在关注账号。" }
    else if (key == "watchers") { "关注" }
    else if (key == "watchers_empty") { "暂时没有可展示的关注者。" }
    else if (key == "stargazers") { "Star 用户" }
    else if (key == "stargazers_empty") { "暂时没有可展示的 Star 用户。" }
    else if (key == "forks") { "Fork" }
    else if (key == "forks_empty") { "暂时没有可展示的 Fork 仓库。" }
    else if (key == "commits") { "提交" }
    else if (key == "commits_empty") { "暂时没有可展示的提交记录。" }
    else if (key == "commit_message") { "提交信息" }
    else if (key == "commit_sha") { "提交" }
    else if (key == "commit_date") { "日期" }
    else if (key == "additions") { "新增" }
    else if (key == "deletions") { "删除" }
    else if (key == "default_branch") { "默认分支" }
    else if (key == "view_more") { "查看更多" }
    else if (key == "open") { "打开" }
    else if (key == "browse_code") { "浏览代码" }
    else if (key == "files") { "个文件" }
    else if (key == "public") { "公开" }
    else if (key == "private") { "私有" }
    else if (key == "system") { "跟随系统" }
    else if (key == "light") { "浅色" }
    else if (key == "dark") { "深色" }
    else if (key == "lang_en") { "English" }
    else if (key == "lang_zh") { "中文" }
    else if (key == "save") { "保存" }
    else if (key == "close") { "关闭" }
    else if (key == "sign_in_github") { "登录 GitHub.com" }
    else if (key == "sign_in_enterprise") { "登录 GitHub Enterprise" }
    else if (key == "auth_enterprise_hint") { "需要 3.10.0 或更高版本服务端。" }
    else if (key == "auth_terms") { "登录即表示你接受我们的使用条款和隐私政策。" }
    else if (key == "auth_subtitle") { "使用你的账号继续使用 RepoPilot。" }
    else if (key == "auth_web_title") { "github.com" }
    else if (key == "auth_web_subtitle") { "登录 GitHub 以继续使用 RepoPilot。" }
    else if (key == "auth_connected_title") { "连接已就绪" }
    else if (key == "auth_connected_body") { "你的工作区已经可以打开。" }
    else if (key == "auth_review_access") { "在运行任务前检查授权范围。" }
    else if (key == "continue_to_workplace") { "继续进入工作区" }
    else if (key == "workplace") { "工作区" }
    else if (key == "back") { "返回" }
    else if (key == "repository_detail") { "仓库详情" }
    else if (key == "readme") { "README" }
    else if (key == "readme_empty") { "这个仓库暂时没有可展示的 README。" }
    else if (key == "issue_detail") { "Issue 详情" }
    else if (key == "pull_request_detail") { "Pull Request" }
    else if (key == "create_task") { "创建任务" }
    else if (key == "task_detail") { "任务详情" }
    else if (key == "diff_review") { "差异审阅" }
    else if (key == "open_issue") { "打开 Issue" }
    else if (key == "review_pr") { "审阅 Pull Request" }
    else if (key == "create_issue") { "创建 Issue" }
    else if (key == "create_pull_request") { "创建 Pull Request" }
    else if (key == "context") { "上下文" }
    else if (key == "status") { "状态" }
    else if (key == "sign_in_required") { "请先连接 GitHub。" }
    else if (key == "issue_editor") { "新建 Issue" }
    else if (key == "pull_request_editor") { "新建 Pull Request" }
    else if (key == "composer_title_placeholder") { "Issue 标题" }
    else if (key == "composer_body_placeholder") { "使用 Markdown 编写内容..." }
    else if (key == "composer_pr_title_placeholder") { "Pull Request 标题" }
    else if (key == "composer_pr_body_placeholder") { "使用 Markdown 描述这次 Pull Request..." }
    else if (key == "composer_head_branch_placeholder") { "Head 分支" }
    else if (key == "composer_base_branch_placeholder") { "Base 分支" }
    else if (key == "composer_write") { "编辑" }
    else if (key == "composer_preview") { "预览" }
    else if (key == "composer_h1") { "一级标题" }
    else if (key == "composer_h2") { "二级标题" }
    else if (key == "composer_bullets") { "列表" }
    else if (key == "composer_numbers") { "编号" }
    else if (key == "composer_checklist") { "清单" }
    else if (key == "composer_quote") { "引用" }
    else if (key == "composer_code") { "代码" }
    else if (key == "composer_link") { "链接" }
    else if (key == "composer_bold") { "加粗" }
    else if (key == "composer_italic") { "斜体" }
    else if (key == "composer_divider") { "分隔线" }
    else if (key == "composer_title_required") { "请先填写标题。" }
    else if (key == "composer_branch_required") { "请同时填写 head 和 base 分支。" }
    else if (key == "composer_branch_same") { "head 和 base 分支不能相同。" }
    else if (key == "composer_branch_unknown") { "请选择仓库里真实存在的分支。" }
    else if (key == "composer_branch_source_required") { "请先创建另一个分支，或填写 fork 的 owner:branch。" }
    else if (key == "publish_issue") { "发布 Issue" }
    else if (key == "publish_pull_request") { "发布 Pull Request" }
    else if (key == "issue_comment_editor") { "新建 Issue 评论" }
    else if (key == "pull_request_review_editor") { "新建审阅" }
    else if (key == "composer_comment_placeholder") { "使用 Markdown 编写评论..." }
    else if (key == "composer_review_placeholder") { "使用 Markdown 编写审阅内容..." }
    else if (key == "publish_comment") { "发布评论" }
    else if (key == "publish_review") { "发布审阅" }
    else if (key == "composer_body_required") { "请先填写内容。" }
    else if (key == "review_type") { "审阅类型" }
    else if (key == "review_comment") { "评论" }
    else if (key == "review_approve") { "批准" }
    else if (key == "review_request_changes") { "请求修改" }
    else if (key == "close_issue") { "关闭 Issue" }
    else if (key == "comment_issue") { "评论 Issue" }
    else if (key == "ask_agent") { "交给 Agent 处理" }
    else if (key == "approve_pr") { "批准审阅" }
    else if (key == "request_changes") { "请求修改" }
    else if (key == "comment_pr") { "评论 Pull Request" }
    else if (key == "fork_repository") { "Fork 仓库" }
    else if (key == "delete_repository") { "删除仓库" }
    else if (key == "prompt_draft") { "任务草稿" }
    else if (key == "execution_mode") { "执行模式" }
    else if (key == "validation_scope") { "验证范围" }
    else if (key == "output_target") { "输出目标" }
    else if (key == "create_task_action") { "创建任务" }
    else if (key == "validation_result") { "验证结果" }
    else if (key == "open_diff_review") { "打开差异审阅" }
    else if (key == "review_summary") { "审阅摘要" }
    else if (key == "draft_pr_title") { "Draft PR 标题" }
    else if (key == "draft_pr_body") { "Draft PR 内容" }
    else { localizedEn(key) }
}
