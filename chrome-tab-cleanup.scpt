#!/usr/bin/osascript

-- Configuration options
property silentMode : false
property showConfirmation : true
property normalizeUrls : true
property whitelistDomains : {"localhost", "127.0.0.1"}


-- Main execution with comprehensive error handling
try
    -- Check if Chrome is running
    tell application "System Events"
        set chromeRunning to (name of processes) contains "Google Chrome"
    end tell
    
    if not chromeRunning then
        try
            tell application "Google Chrome" to activate
            delay 2 -- Give Chrome time to start
        on error
            display dialog "Error: Google Chrome is not available or not running" buttons {"OK"} default button "OK" with icon stop
            return
        end try
    end if
    
    -- Terminal feedback for start (if not in silent mode)
    if not silentMode then
        do shell script "echo 'Starting tab cleanup...'"
    end if
    
    -- Initialize tracking variables
    set seenUrls to {}
    set duplicateTabsInfo to {} -- Will store {url, title, windowIndex, tabIndex}
    set totalDuplicatesFound to 0
    set totalTabsProcessed to 0
    set windowsProcessed to 0
    
    tell application "Google Chrome"
        activate
        
        -- First pass: collect all unique URLs and identify duplicates with details
        set windowIndex to 0
        repeat with theWindow in every window
            set windowIndex to windowIndex + 1
            set windowsProcessed to windowsProcessed + 1
            set tabIndex to 0
            
            repeat with theTab in every tab of theWindow
                set tabIndex to tabIndex + 1
                set totalTabsProcessed to totalTabsProcessed + 1
                set rawUrl to URL of theTab as string
                set tabTitle to title of theTab as string
                
                -- Inline URL normalization
                set currentUrl to rawUrl
                if normalizeUrls then
                    -- Remove everything after ? (query parameters and flags)
                    if currentUrl contains "?" then
                        set AppleScript's text item delimiters to "?"
                        set currentUrl to text item 1 of currentUrl
                        set AppleScript's text item delimiters to ""
                    end if
                    
                    -- Remove fragment (everything after #)
                    if currentUrl contains "#" then
                        set AppleScript's text item delimiters to "#"
                        set currentUrl to text item 1 of currentUrl
                        set AppleScript's text item delimiters to ""
                    end if
                end if
                
                -- Check if domain is whitelisted (inline)
                set isWhitelisted to false
                repeat with domain in whitelistDomains
                    if currentUrl contains domain then
                        set isWhitelisted to true
                        exit repeat
                    end if
                end repeat
                
                if not isWhitelisted then
                    set isDuplicate to false
                    repeat with seenUrl in seenUrls
                        if (seenUrl as string = currentUrl as string) then
                            -- Store duplicate tab info for preview
                            set duplicateInfo to {tabTitle, rawUrl, windowIndex, tabIndex}
                            copy duplicateInfo to the end of duplicateTabsInfo
                            set totalDuplicatesFound to totalDuplicatesFound + 1
                            set isDuplicate to true
                            exit repeat
                        end if
                    end repeat
                    
                    if not isDuplicate then
                        copy currentUrl to the end of seenUrls
                    end if
                end if
            end repeat
        end repeat
        
    end tell
    
    -- Show confirmation dialog with preview if duplicates found and confirmation enabled
    if totalDuplicatesFound > 0 and showConfirmation then
        -- Build preview list of duplicate tabs
        set previewMsg to "The following " & totalDuplicatesFound & " duplicate tabs will be closed:" & return & return
        
        set itemCount to 1
        repeat with duplicateInfo in duplicateTabsInfo
            set tabTitle to item 1 of duplicateInfo
            set tabUrl to item 2 of duplicateInfo
            set windowNum to item 3 of duplicateInfo
            set tabNum to item 4 of duplicateInfo
            
            -- Truncate long titles and URLs for readability
            if (length of tabTitle) > 50 then
                set displayTitle to (text 1 thru 47 of tabTitle) & "..."
            else
                set displayTitle to tabTitle
            end if
            
            if (length of tabUrl) > 60 then
                set displayUrl to (text 1 thru 57 of tabUrl) & "..."
            else
                set displayUrl to tabUrl
            end if
            
            set previewMsg to previewMsg & itemCount & ". " & displayTitle & return
            set previewMsg to previewMsg & "   " & displayUrl & return
            set previewMsg to previewMsg & "   (Window " & windowNum & ", Tab " & tabNum & ")" & return & return
            
            set itemCount to itemCount + 1
            
            -- Limit preview to first 10 items to avoid dialog overflow
            if itemCount > 10 then
                set remainingCount to totalDuplicatesFound - 10
                if remainingCount > 0 then
                    set previewMsg to previewMsg & "... and " & remainingCount & " more duplicates"
                end if
                exit repeat
            end if
        end repeat
        
        -- Show preview dialog with scrollable text
        set confirmTitle to "Confirm Tab Cleanup"
        try
            set userChoice to display dialog previewMsg buttons {"Cancel", "Close These Duplicates"} default button "Close These Duplicates" with title confirmTitle with icon caution
        on error number -128
            -- User clicked Cancel or pressed Escape
            if not silentMode then
                do shell script "echo 'Cleanup cancelled'"
            end if
            return
        end try
    end if
    
    tell application "Google Chrome"
        
        -- Second pass: actually close the duplicates
        if totalDuplicatesFound > 0 then
            set seenUrls to {} -- Reset for actual cleanup
            set actualTabsClosed to 0
            
            repeat with theWindow in every window
                set toClose to {}
                set tabIndex to 1
                
                repeat with theTab in every tab of theWindow
                    set rawUrl to URL of theTab as string
                    
                    -- Inline URL normalization (same as first pass)
                    set currentUrl to rawUrl
                    if normalizeUrls then
                        -- Remove everything after ? (query parameters and flags)
                        if currentUrl contains "?" then
                            set AppleScript's text item delimiters to "?"
                            set currentUrl to text item 1 of currentUrl
                            set AppleScript's text item delimiters to ""
                        end if
                        
                        -- Remove fragment (everything after #)
                        if currentUrl contains "#" then
                            set AppleScript's text item delimiters to "#"
                            set currentUrl to text item 1 of currentUrl
                            set AppleScript's text item delimiters to ""
                        end if
                    end if
                    
                    -- Check if domain is whitelisted (inline)
                    set isWhitelisted to false
                    repeat with domain in whitelistDomains
                        if currentUrl contains domain then
                            set isWhitelisted to true
                            exit repeat
                        end if
                    end repeat
                    
                    if not isWhitelisted then
                        set isDuplicate to false
                        repeat with seenUrl in seenUrls
                            if (seenUrl as string = currentUrl as string) then
                                copy tabIndex to the end of toClose
                                set isDuplicate to true
                                exit repeat
                            end if
                        end repeat
                        
                        if not isDuplicate then
                            copy currentUrl to the end of seenUrls
                        end if
                    end if
                    
                    set tabIndex to tabIndex + 1
                end repeat
                
                -- Close duplicate tabs (in reverse order to maintain indices)
                set closing to reverse of toClose
                repeat with closeIndex in closing
                    try
                        close tab closeIndex of theWindow
                        set actualTabsClosed to actualTabsClosed + 1
                    on error
                        -- Skip if tab can't be closed
                    end try
                end repeat
            end repeat
        end if
    end tell
    
    -- Final summary and dialogs (outside Chrome block to avoid scope issues)
    if totalDuplicatesFound > 0 then
        set summaryMsg to "Cleanup Summary:" & return & return
        set summaryMsg to summaryMsg & "• Total tabs processed: " & totalTabsProcessed & return
        set summaryMsg to summaryMsg & "• Windows processed: " & windowsProcessed & return
        set summaryMsg to summaryMsg & "• Duplicate tabs found: " & totalDuplicatesFound & return
        set summaryMsg to summaryMsg & "• Tabs actually closed: " & actualTabsClosed & return
        
        if actualTabsClosed > 0 then
            if not silentMode then
                do shell script "echo '" & (actualTabsClosed as string) & " tabs closed'"
            end if
            display dialog summaryMsg buttons {"OK"} default button "OK" with title "Tab Cleanup Completed" with icon note
        else
            display dialog summaryMsg buttons {"OK"} default button "OK" with title "Tab Cleanup Completed" with icon caution
        end if
    else
        -- No duplicates found
        set summaryMsg to "Cleanup Summary:" & return & return
        set summaryMsg to summaryMsg & "• Total tabs processed: " & totalTabsProcessed & return
        set summaryMsg to summaryMsg & "• Windows processed: " & windowsProcessed & return
        set summaryMsg to summaryMsg & "• No duplicate tabs found"
        
        display dialog summaryMsg buttons {"OK"} default button "OK" with title "Tab Cleanup Completed" with icon note
    end if
    
    -- Final terminal feedback (if not in silent mode)
    if not silentMode then
        do shell script "echo 'Tab cleanup completed'"
    end if
    
on error errMsg number errNum
    -- Comprehensive error handling
    set errorDialog to "An error occurred during tab cleanup:" & return & return
    set errorDialog to errorDialog & "Error: " & errMsg & return
    set errorDialog to errorDialog & "Error Code: " & errNum
    
    display dialog errorDialog buttons {"OK"} default button "OK" with icon stop
    
    if not silentMode then
        do shell script "echo 'Error occurred during cleanup'"
    end if
end try