#!/opt/homebrew/bin/bash -eu
# shellcheck disable=SC2034,SC2155
set -o pipefail
shopt -s inherit_errexit

script_dir="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

# shellcheck source=external/bash-mock/bash-inject.shlib
. "${script_dir}/external/bash-mock/bash-inject.shlib"

# shellcheck source=git-edit-pr.shlib
. "${script_dir}/git-edit-pr.shlib"

# edit pr

@inject "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

export CHROME_PROFILE="${CHROME_PROFILE:-Default}"

readonly branch="$(git branch --show-current)"

mapfile -t pr_urls < <(edit_parent_prs "${branch}" || true; edit_children_prs "${branch}" || true)

Google_Chrome \
    --new-window \
    --profile-directory="${CHROME_PROFILE}" \
    "${pr_urls[@]}"
