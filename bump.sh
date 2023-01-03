
#!/bin/bash -e

if [ $1 = "-h" ] || [ $1 = "--help" ]; then
    echo "Usage: bump.sh <pod_name> [major|minor|patch]"
    echo "Example: bump.sh MyPod minor"
    echo "pod_name: The file name of your podspec"
    exit 0
fi

# get versiom from podspec
OLD_VERSION=`grep -m 1 -Eo "[0-9]+\.[0-9]+\.[0-9]+" $1.podspec`
if [ -z $2 ] || [ $2 = "minor" ]; then
    echo "Minor version bump"
    # add 1 to minor version
    VERSION=`echo $OLD_VERSION | awk -F. '{$NF = $NF + 1;} 1' | sed 's/ /./g'`
    sed -i '' "s/$OLD_VERSION/$VERSION/g" $1.podspec
elif [ $2 = "patch" ]; then
    echo "Patch version bump"
    # add 1 to patch version
    VERSION=`echo $OLD_VERSION | awk -F. '{$2 = $2 + 1;} 1' | sed 's/ /./g'`
    # reset minor version
    VERSION=`echo $VERSION | awk -F. '{$NF = 0;} 1' | sed 's/ /./g'`
    sed -i '' "s/$OLD_VERSION/$VERSION/g" $1.podspec
elif [ $2 = "major" ]; then
    echo "Major version bump"
    # add 1 to major version
    VERSION=`echo $OLD_VERSION | awk -F. '{$1 = $1 + 1;} 1' | sed 's/ /./g'`
    # reset minor and patch version
    VERSION=`echo $VERSION | awk -F. '{$2 = 0;} 1' | sed 's/ /./g'`
    VERSION=`echo $VERSION | awk -F. '{$NF = 0;} 1' | sed 's/ /./g'`
    sed -i '' "s/$OLD_VERSION/$VERSION/g" $1.podspec
elif [ $2 = "init" ]; then
    echo "Init version, not change version"
    VERSION=$OLD_VERSION
fi

if [ -f "Example/Podfile" ]; then
    pod install --project-directory=Example
fi

# Check if there are any changes
if ! git diff-index --quiet HEAD --; then
    echo "There are changes, commit them first"
    git add .
    git commit -m "Bump version to $VERSION"
fi

BRANCH=$(git rev-parse --abbrev-ref HEAD)
git push origin $BRANCH

# Check if default repository is set for this directory
# gh repo set-default

echo "Create release $VERSION"

gh release create $VERSION --title $VERSION --notes "Release $VERSION" --target $BRANCH --generate-notes

# Check if success
if [ $? -eq 0 ]; then
    echo "Release $VERSION success"
    pod trunk push $1.podspec --allow-warnings
else
    echo "Release $VERSION failed"
fi