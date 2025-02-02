---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: index, reference
---

# Suggest changes **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/25381) custom commit messages for suggestions in GitLab 13.9 [with a flag](../../../../administration/feature_flags.md) named `suggestions_custom_commit`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/297404) in GitLab 13.10. Feature flag `suggestions_custom_commit` removed.

Reviewers can suggest code changes with a Markdown syntax in merge request diff threads.
The merge request author (or other users with the appropriate role) can apply any or
all of the suggestions from the GitLab UI. Applying suggestions adds a commit to the
merge request, authored by the user who suggested the changes.

## Create suggestions

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Merge requests** and find your merge request.
1. On the secondary menu, select **Changes**.
1. Find the line of code you want to change. Hover over the line number, and
   select **Add a comment to this line** (**{comment}**).
1. In the comment toolbar, select **Insert suggestion** (**{doc-code}**). GitLab
   inserts a pre-populated code block into your comment, like this:

   ````markdown
   ```suggestion:-0+0
   The content of the line you selected is shown here.
   ```
   ````

1. Edit the pre-populated code block to add your suggestion.
1. Select either **Start a review** or **Add to review** to add your comment to a
   [review](index.md), or **Add comment now** to add the comment to the thread immediately.

## Apply suggestions

The merge request author can apply suggested changes directly from the merge request:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Merge requests** and find your merge request.
1. Find the comment containing the suggestion you want to apply.
   - To apply suggestions individually, select **Apply suggestion**.
   - To apply multiple suggestions in a single commit, select **Add suggestion to batch**.
1. Optional. Provide a custom commit message to describe your change. If you don't provide a custom message, the default commit message is used.
1. Select **Apply**.

After a suggestion is applied:

- The suggestion is marked as **Applied**.
- The comment thread is resolved.
- GitLab creates a new commit with the changes.
- If the user has the Developer role, GitLab pushes
  the suggested change directly into the codebase in the merge request's branch.

## Multi-line suggestions

> [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/232339) in GitLab 13.11: suggestions in multi-line comments also become multi-line.

Reviewers can also suggest changes to multiple lines with a single suggestion
within merge request diff threads by selecting and dragging selection to all
relevant line numbers or by adjusting the range offsets. The
offsets are relative to the position of the diff thread, and specify the
range to be replaced by the suggestion when it is applied.

![Multi-line suggestion syntax](img/multi-line-suggestion-syntax.png)

In the previous example, the suggestion covers three lines above and four lines
below the commented line. When applied, it would replace from 3 lines _above_
to 4 lines _below_ the commented line, with the suggested change.

![Multi-line suggestion preview](img/multi-line-suggestion-preview.png)

NOTE:
Suggestions for multiple lines are limited to 100 lines _above_ and 100
lines _below_ the commented diff line. This allows for up to 200 changed lines per
suggestion.

## Code block nested in suggestions

To add a suggestion that includes a
[fenced code block](../../../markdown.md#code-spans-and-blocks), wrap your suggestion
in four backticks instead of three:

`````markdown
````suggestion:-0+2
```shell
git config --global receive.advertisepushoptions true
```
````
`````

![Output of a comment with a suggestion with a fenced code block](img/suggestion_code_block_output_v12_8.png)

## Configure the commit message for applied suggestions

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/13086) in GitLab 12.7.

GitLab uses a default commit message
when applying suggestions: `Apply %{suggestions_count} suggestion(s) to %{files_count} file(s)`

<!-- vale gitlab.BadPlurals = NO -->

For example, consider that a user applied 3 suggestions to 2 different files, the
default commit message is: **Apply 3 suggestion(s) to 2 file(s)**

<!-- vale gitlab.BadPlurals = YES -->

These commit messages can be customized to follow any guidelines you might have.
To do so, expand the **Merge requests** tab within your project's **General**
settings and change the **Merge suggestions** text:

![Custom commit message for applied suggestions](img/suggestions_custom_commit_messages_v14_7.png)

You can also use following variables besides static text:

| Variable               | Description | Output example |
|------------------------|-------------|----------------|
| `%{branch_name}`       | The name of the branch to which suggestions were applied. | `my-feature-branch` |
| `%{files_count}`       | The number of files to which suggestions were applied.| **2** |
| `%{file_paths}`        | The paths of the file to which suggestions were applied. Paths are separated by commas.| `docs/index.md, docs/about.md` |
| `%{project_path}`      | The project path. | `my-group/my-project` |
| `%{project_name}`      | The human-readable name of the project. | **My Project** |
| `%{suggestions_count}` | The number of suggestions applied.| **3** |
| `%{username}`          | The username of the user applying suggestions. | `user_1` |
| `%{user_full_name}`    | The full name of the user applying suggestions. | **User 1** |

For example, to customize the commit message to output
**Addresses user_1's review**, set the custom text to
`Addresses %{username}'s review`.

For merge requests created from forks, GitLab uses the template defined in target project.

NOTE:
Custom commit messages for each applied suggestion is
introduced by [#25381](https://gitlab.com/gitlab-org/gitlab/-/issues/25381).

## Batch suggestions

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/25486) in GitLab 13.1 as an [alpha feature](../../../../policy/alpha-beta-support.md#alpha-features) with a flag named `batch_suggestions`, disabled by default.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/227799) in GitLab 13.2.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/320755) in GitLab 13.11. [Feature flag `batch_suggestions`](https://gitlab.com/gitlab-org/gitlab/-/issues/320755) removed.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/326168) custom commit messages for batch suggestions in GitLab 14.4.

You can apply multiple suggestions at once to reduce the number of commits added
to your branch to address your reviewers' requests.

1. To start a batch of suggestions to apply with a single commit, select **Add suggestion to batch**:

   ![A code change suggestion displayed, with the add-suggestion option highlighted.](img/add_first_suggestion_to_batch_v13_1.jpg "Add a suggestion to a batch")

1. Add as many additional suggestions to the batch as you wish:

   ![A code change suggestion displayed, with the add-more suggestion option highlighted.](img/add_another_suggestion_to_batch_v13_1.jpg "Add another suggestion to a batch")

1. To remove suggestions, select **Remove from batch**:

   ![A code change suggestion displayed, with the option to remove that suggestion from its batch highlighted.](img/remove_suggestion_from_batch_v13_1.jpg "Remove a suggestion from a batch")

1. Having added all the suggestions to your liking, when ready, select **Apply suggestions**. You
   can optionally specify a custom commit message for [batch suggestions](#batch-suggestions)
   (GitLab 14.4 and later) to describe your change. If you don't specify it, the default commit
   message is used.

   ![A code change suggestion displayed, with the option to apply the batch of suggestions highlighted.](img/apply_batch_of_suggestions_v13_1.jpg "Apply a batch of suggestions")

WARNING:
Suggestions applied from multiple authors creates a commit authored by the user applying the suggestions.

## Related topics

- [Suggestions API](../../../../api/suggestions.md)
