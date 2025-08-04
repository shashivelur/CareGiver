#!/bin/bash

echo "🚀 CareGiver iOS App - Project Verification"
echo "=========================================="

# Check if we're in the right directory
if [ ! -f "CareGiver.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Run this script from the CareGiver project root directory"
    exit 1
fi

echo "📁 Checking project structure..."

# Check essential files
files_to_check=(
    "CareGiver.xcodeproj/project.pbxproj"
    "CareGiver/AppDelegate.swift"
    "CareGiver/SceneDelegate.swift"
    "CareGiver/Info.plist"
    "CareGiver/Resources/Base.lproj/Main.storyboard"
    "CareGiver/Resources/Base.lproj/LaunchScreen.storyboard"
    "CareGiver/Resources/Assets.xcassets/Contents.json"
    "CareGiver/Models/CoreDataManager.swift"
    "CareGiver/Models/CareGiver.xcdatamodeld/CareGiver.xcdatamodel/contents"
)

missing_files=0
for file in "${files_to_check[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ Missing: $file"
        missing_files=$((missing_files + 1))
    fi
done

# Check directories
directories_to_check=(
    "CareGiver/ViewControllers"
    "CareGiver/Models"
    "CareGiver/Resources"
    "CareGiver/Resources/Assets.xcassets"
    "CareGiver/Resources/Base.lproj"
)

for dir in "${directories_to_check[@]}"; do
    if [ -d "$dir" ]; then
        echo "✅ Directory: $dir"
    else
        echo "❌ Missing directory: $dir"
        missing_files=$((missing_files + 1))
    fi
done

# Count Swift files
swift_files=$(find . -name "*.swift" | wc -l | tr -d ' ')
echo ""
echo "📊 Project Statistics:"
echo "   Swift files: $swift_files"
echo "   Storyboards: $(find . -name "*.storyboard" | wc -l | tr -d ' ')"
echo "   View Controllers: $(find CareGiver/ViewControllers -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')"

# Check if scheme exists
if [ -f "CareGiver.xcodeproj/xcshareddata/xcschemes/CareGiver.xcscheme" ]; then
    echo "✅ Build scheme configured"
else
    echo "⚠️  Build scheme not found (Xcode will create automatically)"
fi

echo ""
if [ $missing_files -eq 0 ]; then
    echo "🎉 Project verification PASSED!"
    echo ""
    echo "Next steps:"
    echo "1. Open CareGiver.xcodeproj in Xcode"
    echo "2. Select iPhone simulator (iOS 17.0+)"
    echo "3. Press Cmd+R to build and run"
    echo ""
    echo "Expected app flow:"
    echo "• Launch screen → Login screen"
    echo "• Register new caregiver → Login"
    echo "• Main app with 5 tabs + hamburger menu"
else
    echo "❌ Project verification FAILED!"
    echo "Missing $missing_files essential files/directories"
    echo "Please check the project structure"
fi

echo ""
echo "📚 See DEPLOYMENT_GUIDE.md for detailed instructions"
