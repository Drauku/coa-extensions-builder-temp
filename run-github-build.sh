#!/usr/bin/env bash
set -euo pipefail

builder_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$builder_dir"

owner="$(gh api user --jq .login)"
repo_name="coa-extensions-builder-temp"
repo="$owner/$repo_name"

if [ ! -d .git ]; then
    git init -b main
    git config user.name "CoA Extensions Builder"
    git config user.email "${owner}@users.noreply.github.com"
fi

git add .github/workflows/build-extensions.yml README.md .gitignore run-github-build.sh
if ! git diff --cached --quiet; then
    git commit -m "build: add temporary Windows Extensions.dll builder"
fi

if gh repo view "$repo" >/dev/null 2>&1; then
    if ! git remote get-url origin >/dev/null 2>&1; then
        git remote add origin "https://github.com/$repo.git"
    fi
    git push -u origin main
else
    gh repo create "$repo" --public --source . --remote origin --push \
        --description "Temporary reproducible builder for the CoA Extensions.dll reconstruction"
fi

previous_run_id="$(gh run list --repo "$repo" --workflow build-extensions.yml \
    --event workflow_dispatch --limit 1 --json databaseId --jq '.[0].databaseId // empty' \
    2>/dev/null || true)"

gh workflow run build-extensions.yml --repo "$repo" -f source_ref=main

run_id=""
for attempt in 1 2 3 4 5 6 7 8 9 10; do
    candidate_run_id="$(gh run list --repo "$repo" --workflow build-extensions.yml \
        --event workflow_dispatch --limit 1 --json databaseId --jq '.[0].databaseId // empty')"
    if [ -n "$candidate_run_id" ] && [ "$candidate_run_id" != "$previous_run_id" ]; then
        run_id="$candidate_run_id"
        break
    fi
    sleep 3
done

if [ -z "$run_id" ]; then
    echo "The workflow was dispatched, but its run ID was not visible yet." >&2
    echo "Check https://github.com/$repo/actions" >&2
    exit 1
fi

gh run watch "$run_id" --repo "$repo" --exit-status

output_dir="$builder_dir/output/run-$run_id"
mkdir -p "$output_dir"
gh run download "$run_id" --repo "$repo" --name extensions-dll --dir "$output_dir"

echo
echo "Downloaded build output to: $output_dir"
sha256sum "$output_dir/Extensions.dll"
cat "$output_dir/BUILD-METADATA.txt"

