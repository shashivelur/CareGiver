#!/bin/bash

echo "🔧 Fixing Xcode Project - Adding Core Data Files"
echo ""

# Make sure we're in the right directory
if [ ! -f "CareGiver.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Must run this from the CareGiver project root"
    exit 1
fi

# Close Xcode if it's running
echo "⚠️  Please close Xcode before continuing!"
echo "Press Enter when Xcode is closed..."
read

# Run the Python script
if [ -f "add_coredata_files.py" ]; then
    echo "📝 Running Python script to modify project file..."
    python3 add_coredata_files.py
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Success! Core Data files have been added to the project"
        echo ""
        echo "Next steps:"
        echo "1. Open Xcode"
        echo "2. Clean Build Folder (Shift+Cmd+K)"
        echo "3. Build the project (Cmd+B)"
        echo ""
        echo "The errors should be gone! 🎉"
    else
        echo "❌ Script failed. Please check the error messages above."
        exit 1
    fi
else
    echo "❌ Error: add_coredata_files.py not found"
    exit 1
fi


