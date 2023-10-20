#!/bin/bash

# GitHub repository and release details
client_cpp_repo_name="client-cpp"
#wrapper_repos=("client-python" "client-go" "client-csharp" "client-java")
wrapper_repos=("wrapperbuild" "wrapperbuild1")
new_version="$V_VERSION"  # Replace with the actual version

# GitHub token (Make sure it's available as a secret in your repository)
github_token="$GITHUB_TOKEN"

# Initialize GitHub API
#gh auth login --with-token <<<"$github_token"
gh repo view "mustyantsev/mainbuild" --json name --jq ".name"

if [ $? -ne 0 ]; then
  echo "Failed to authenticate with GitHub."
  exit 1
fi

# Get the release details (you might need to adapt this)
release_info=$(gh release view "mustyantsev/mainbuild" latest --json tag_name --jq "v1.0.0")

echo $release_info

if [ $? -ne 0 ]; then
  echo "Failed to fetch release details for client-cpp."
  exit 1
fi

# Loop through wrapper repositories and update files
for wrapper_repo_name in "${wrapper_repos[@]}"; do
  branch_name="update-to-$new_version"

  # Create a new branch in the wrapper repository
  gh repo fork "mustyantsev/$wrapper_repo_name" --clone true --remote true
  git checkout -b "$branch_name"

  # Update conanfile.py
  conanfile_path="conanfile.py"
  new_conanfile_content="
# Updated conanfile content
version = \"$new_version\"
# Add other conanfile configuration as needed
"
  echo "$new_conanfile_content" > "$conanfile_path"
  git add "$conanfile_path"

  # Update build.yml
  build_yml_path="build.yml"
  new_build_yml_content="
# Updated build.yml content
version: $new_version
# Add other build.yml configuration as needed
"
  echo "$new_build_yml_content" > "$build_yml_path"
  git add "$build_yml_path"

  # Commit changes
  git commit -m "Update to client-cpp $new_version"
  git push origin "$branch_name"

  # Create a Pull Request
  gh pr create "mustyantsev/$wrapper_repo_name" --base "main" --head "$branch_name" --title "Update to client-cpp $new_version" --body "Automated PR created by GitHub Actions"
  echo "Created PR in $wrapper_repo_name."
done
