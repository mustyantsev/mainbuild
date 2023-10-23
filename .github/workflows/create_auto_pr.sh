#!/bin/bash

# GitHub repository and release details
client_cpp_repo_name="client-cpp"
#wrapper_repos=("client-python" "client-go" "client-csharp" "client-java")
wrapper_repos=("wrapperbuild" "wrapperbuild2")
new_version="$V_VERSION"  # Replace with the actual version
LATEST_VERSION=$(curl -s 'https://api.github.com/repos/mustyantsev/mainbuild/releases/latest' | jq -r '.tag_name');
echo "Latest Release info"
echo $LATEST_VERSION
# GitHub token (Make sure it's available as a secret in your repository)
github_token="$ACCESS_TOKEN"

# Initialize GitHub API
#unset GITHUB_TOKEN
#gh auth login --with-token
gh repo view "mustyantsev/mainbuild" --json name --jq ".name"

if [ $? -ne 0 ]; then
  echo "Failed to authenticate with GitHub."
  exit 1
fi

# Get the release details (you might need to adapt this)
release_info=$(gh release view "mustyantsev/mainbuild" latest --json tag_name --jq "v1.0.0")
echo "Release info"
echo $release_info

if [ $? -ne 0 ]; then
  echo "Failed to fetch release details for client-cpp."
  exit 1
fi



# Loop through wrapper repositories and update files
for wrapper_repo_name in "${wrapper_repos[@]}"; do
  branch_name="update-to-$new_version"
echo "before checkout info"
FOLDER="bin/mustyantsev/$wrapper_repo_name"
  # Create a new branch in the wrapper repository
  git clone \
              --depth=1 \
              --branch=main \
              https://$github_token@github.com/"mustyantsev/$wrapper_repo_name" \
              $FOLDER

            cd $FOLDER

            # Setup the committers identity.
            git config user.name "${GITHUB_ACTOR}"
            echo "User name"
            echo ${GITHUB_ACTOR}
            git config user.email "mustyantsev@lohika.com"

            # Create a new feature branch for the changes.
            git checkout -b $branch_name
echo "after checkout info"
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
  echo "before push"
  git push origin "$branch_name"
  #git push "https://$GITHUB_ACTOR:${{ secrets.ACCESS_TOKEN }}
  echo "after push"
  echo "$github_token" > token.txt
  # Create a Pull Request
  #gh auth login --with-token < token.txt
  gh pr create \
            --body "" \
            --title "chore: update scripts to $LATEST_TAG" \
            --head "$branch_name" \
            --base "main"
  echo "Created PR in $wrapper_repo_name."
done
