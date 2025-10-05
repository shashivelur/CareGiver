# Fix Core Data Entity Errors

## Problem
Getting errors like:
- `Cannot find type 'CalendarTask' in scope`
- `Cannot find type 'CalendarSettings' in scope`

## Solution: Regenerate Core Data Entity Files in Xcode

Follow these steps **in Xcode**:

### Step 1: Open the Core Data Model
1. In Xcode, navigate to: `CareGiver/Models/CareGiver.xcdatamodeld`
2. Click on `CareGiver.xcdatamodel` to open the visual editor

### Step 2: Verify Entities Exist
You should see these entities in the left panel:
- ✅ CalendarTask
- ✅ CalendarSettings
- ✅ CompletedTask
- ✅ Caregiver
- ✅ Patient

If you don't see the first 3 entities, you may need to reopen the project or refresh.

### Step 3: Regenerate Core Data Classes
1. Select the `CareGiver.xcdatamodel` file in the Project Navigator
2. Open the **File Inspector** (View → Inspectors → File or Cmd+Option+1)
3. Find the **Codegen** dropdown under "Class"
4. Change it from "Manual/None" to **"Class Definition"**
5. Build the project (Cmd+B)
6. Then change it back to **"Manual/None"**
7. Build again (Cmd+B)

### Step 4: Verify Files Are in Target
1. Select each of these files in Project Navigator:
   - `CalendarTask+CoreDataClass.swift`
   - `CalendarTask+CoreDataProperties.swift`
   - `CalendarSettings+CoreDataClass.swift`
   - `CalendarSettings+CoreDataProperties.swift`
   - `CompletedTask+CoreDataClass.swift`
   - `CompletedTask+CoreDataProperties.swift`

2. For each file, check the **File Inspector** (Cmd+Option+1)
3. Under "Target Membership", make sure **CareGiver** is checked ✅

### Step 5: Clean Build Folder
1. In Xcode menu: **Product → Clean Build Folder** (Shift+Cmd+K)
2. Then **Product → Build** (Cmd+B)

### Alternative Solution: Delete Derived Data
If the above doesn't work:

1. In Xcode menu: **Product → Clean Build Folder** (Shift+Cmd+K)
2. Close Xcode
3. Delete Derived Data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/CareGiver-*
   ```
4. Reopen Xcode
5. Build the project (Cmd+B)

### Alternative: Manual File Import
If entities still aren't found, manually add the files to the project:

1. In Xcode, right-click on the `Models` folder
2. Select **Add Files to "CareGiver"...**
3. Navigate to and select these files:
   - `CalendarTask+CoreDataClass.swift`
   - `CalendarTask+CoreDataProperties.swift`
   - `CalendarSettings+CoreDataClass.swift`
   - `CalendarSettings+CoreDataProperties.swift`
   - `CompletedTask+CoreDataClass.swift`
   - `CompletedTask+CoreDataProperties.swift`
4. Make sure "Copy items if needed" is **unchecked** (they're already in the right place)
5. Make sure "Add to targets: CareGiver" is **checked**
6. Click "Add"

## Verify It's Fixed

After following the steps above, you should be able to:
1. Build the project without errors (Cmd+B)
2. See the Core Data entity types recognized by autocomplete
3. No red errors in `CalendarViewController.swift`

## Still Having Issues?

If you're still seeing errors, try:
1. Restart Xcode completely
2. Clean the build folder again
3. Make sure all the Core Data entity files have public class declarations
4. Check that `import CoreData` is at the top of `CalendarViewController.swift`


