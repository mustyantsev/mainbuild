#!/bin/bash

WORKFLOW_FILE=".github/workflows/build.yaml"
CONAN_FILE="main-src/conanfile.py"

git config --global user.name "${GITHUB_ACTOR}"
git config --global user.email "${GITHUB_ACTOR}@users.noreply.github.com"
BRANCH_NAME="automatic-update-to-client-cpp-$NEW_VERSION"
ls
git checkout -b $BRANCH_NAME
echo "after new branch"
# Update conanfile.py
conanfile_path=$CONAN_FILE
config_conan=$(cat $conanfile_path)
search_line='self.requires("opentdf-client/'
new_conanfile_content=$(echo "$config_conan" | sed "s|${search_line}[0-9.]*@|${search_line}${NEW_VERSION}@|")
echo "$new_conanfile_content" > "$conanfile_path"
git add "$conanfile_path"
cat $conanfile_path
echo "after add1"
# Update build.yml
build_yml_path=$WORKFLOW_FILE
config_yaml=$(cat $build_yml_path)
new_build_yml_content=$(echo "$config_yaml" | sed "s/VCLIENT_CPP_VER: .*/VCLIENT_CPP_VER: $NEW_VERSION/")
echo "$new_build_yml_content" > "$build_yml_path"
git add "$build_yml_path"
cat $build_yml_path
echo "after add2"
# Commit changes
git commit -m "Automatic update to client-cpp $NEW_VERSION"
echo "after commit"
git push --set-upstream origin HEAD:"$BRANCH_NAME" -f
echo "after push"
sleep 5
gh pr create \
    --body "Automated PR created by GitHub Actions" \
    --title "Update to client-cpp $NEW_VERSION" \
    --head "$BRANCH_NAME" \
    --base "main"

