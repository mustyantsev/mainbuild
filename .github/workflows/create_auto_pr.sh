#!/bin/bash

# GitHub repository and release details
#client_cpp_repo_name="client-cpp"
repo_org="mustyantsev"
repo_name="mainbuild"
#wrapper_repos=("client-python" "client-go" "client-csharp" "client-java")
WRAPPER_REPOS=("wrapperbuild" "wrapperbuild2")
LATEST_VERSION=$(curl -s 'https://api.github.com/repos/'${repo_org}'/'${repo_name}'/releases/latest' | jq -r '.tag_name');
WORKFLOW_FILE=".github/workflows/build.yaml"
CONAN_FILE="conanfile.py"
echo "Latest Release info"
echo $LATEST_VERSION

PAT="$ACCESS_TOKEN"

if [[ $LATEST_VERSION =~ ([0-9]+\.[0-9]+\.[0-9]+) ]]; then
  EXTRACTED_VERSION="${BASH_REMATCH[1]}"
else
  echo "Invalid version format"
  exit 1
fi
# Initialize GitHub API
#unset GITHUB_TOKEN
#gh auth login --with-token
#gh repo view "mustyantsev/mainbuild" --json name --jq ".name"

if [ $? -ne 0 ]; then
  echo "Failed to authenticate with GitHub."
  exit 1
fi


# Loop through wrapper repositories and update files
for wrapper_repo_name in "${WRAPPER_REPOS[@]}"; do
  git config --global user.name "${GITHUB_ACTOR}"
  git config --global user.email "${GITHUB_ACTOR}@users.noreply.github.com"
  branch_name="automatic-update-to-$EXTRACTED_VERSION"
  WRAPPER_FOLDER="bin/"${wrapper_repo_name}
  # Create a new branch in the wrapper repository
  git clone \
      --depth=1 \
      --branch=main \
      https://$PAT@github.com/${repo_org}'/'${wrapper_repo_name} \
      $WRAPPER_FOLDER

  cd $WRAPPER_FOLDER

  git checkout -b $branch_name

  # Update conanfile.py
  conanfile_path=$CONAN_FILE
  config_conan=$(cat $conanfile_path)
  search_line='self.requires("opentdf-client/'
  new_conanfile_content=$(echo "$config_conan" | sed "s|${search_line}[0-9.]*@|${search_line}${EXTRACTED_VERSION}@|")
  echo "$new_conanfile_content" > "$conanfile_path"
  git add "$conanfile_path"

  # Update build.yml
  build_yml_path=$WORKFLOW_FILE
  config_yaml=$(cat $build_yml_path)
  new_build_yml_content=$(echo "$config_yaml" | sed "s/VCLIENT_CPP_VER: .*/VCLIENT_CPP_VER: $EXTRACTED_VERSION/")
  echo "$new_build_yml_content" > "$build_yml_path"
  git add "$build_yml_path"

  # Commit changes
  git commit -m "Update to client-cpp $LATEST_VERSION"

  git push origin "$branch_name"

  gh pr create \
     --body "Automated PR created by GitHub Actions" \
     --title "Update to client-cpp $LATEST_VERSION" \
     --head "$branch_name" \
     --base "main"
  echo "Created PR in $wrapper_repo_name."
  cd ..
done
