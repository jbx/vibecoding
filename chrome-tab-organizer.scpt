#!/usr/bin/osascript

-- Configuration options (can be overridden by command line arguments)
property silentMode : false
property showConfirmation : true
property sortByDomain : false -- true = sort by domain, false = sort by full URL

-- Parse command line arguments
on run argv
    set shouldRunMain to true
    
    repeat with arg in argv
        if arg is "--sort-by-url" or arg is "-u" then
            set sortByDomain to false
        else if arg is "--sort-by-domain" or arg is "-d" then
            set sortByDomain to true
        else if arg is "--silent" or arg is "-s" then
            set silentMode to true
        else if arg is "--no-confirm" or arg is "-n" then
            set showConfirmation to false
        else if arg is "--help" or arg is "-h" then
            do shell script "printf '%s\\n' 'Chrome Tab Organizer Options:' '' '--sort-by-url, -u     Sort by full URL instead of domain' '--sort-by-domain, -d  Sort by domain (default)' '--silent, -s          Silent mode (no audio feedback)' '--no-confirm, -n      Skip confirmation dialog' '--help, -h            Show this help message'"
            set shouldRunMain to false
            exit repeat
        end if
    end repeat
    
    -- Continue with main script execution only if not showing help
    if shouldRunMain then
        main()
    end if
end run


-- Main script logic
on main()
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
    
    -- Voice feedback for start (if not in silent mode)
    if not silentMode then
        say "Starting tab organization..."
    end if
    
    -- Initialize tracking variables
    set allTabs to {} -- Will store {url, title, sortKey}
    set totalTabsCollected to 0
    set windowsProcessed to 0
    
    tell application "Google Chrome"
        activate
        
        -- First pass: collect all tabs from all windows
        repeat with theWindow in every window
            set windowsProcessed to windowsProcessed + 1
            repeat with theTab in every tab of theWindow
                set tabUrl to URL of theTab as string
                set tabTitle to title of theTab as string
                
                -- Determine sort key based on sortByDomain setting
                if sortByDomain then
                    -- Sort by domain: extract just the domain part
                    set sortKey to tabUrl
                    -- Remove protocol
                    if sortKey starts with "https://" then
                        set sortKey to text 9 thru -1 of sortKey
                    else if sortKey starts with "http://" then
                        set sortKey to text 8 thru -1 of sortKey
                    end if
                    
                    -- Remove path (everything after first /)
                    if sortKey contains "/" then
                        set AppleScript's text item delimiters to "/"
                        set sortKey to text item 1 of sortKey
                        set AppleScript's text item delimiters to ""
                    end if
                    
                    -- Remove www. prefix for better grouping
                    if sortKey starts with "www." then
                        set sortKey to text 5 thru -1 of sortKey
                    end if
                else
                    -- Sort by full URL: use the complete URL as-is
                    set sortKey to tabUrl
                end if
                
                set tabInfo to {tabUrl, tabTitle, sortKey}
                copy tabInfo to the end of allTabs
                set totalTabsCollected to totalTabsCollected + 1
            end repeat
        end repeat
    end tell
    
    -- Show confirmation dialog if confirmation enabled
    if showConfirmation and totalTabsCollected > 0 then
        set confirmMsg to "Found " & totalTabsCollected & " tabs across " & windowsProcessed & " windows." & return & return
        set confirmMsg to confirmMsg & "Collect tabs from all windows and sort by URL?"
        try
            set userChoice to display dialog confirmMsg buttons {"Cancel", "Organize Tabs"} default button "Organize Tabs" with title "Confirm Tab Organization" with icon caution
        on error number -128
            -- User clicked Cancel or pressed Escape
            if not silentMode then
                say "Organization cancelled"
            end if
            return
        end try
    end if
    
    -- Sort tabs by sort key (domain or full URL)
    if totalTabsCollected > 1 then
        -- Simple bubble sort implementation for AppleScript
        repeat with i from 1 to (totalTabsCollected - 1)
            repeat with j from 1 to (totalTabsCollected - i)
                set currentSortKey to item 3 of item j of allTabs
                set nextSortKey to item 3 of item (j + 1) of allTabs
                
                if currentSortKey > nextSortKey then
                    -- Swap items
                    set tempTab to item j of allTabs
                    set item j of allTabs to item (j + 1) of allTabs
                    set item (j + 1) of allTabs to tempTab
                end if
            end repeat
        end repeat
    end if
    
    tell application "Google Chrome"
        -- Close all existing windows except one
        if (count of windows) > 1 then
            repeat with i from 2 to (count of windows)
                close window 2
            end repeat
        end if
        
        -- Clear the remaining window
        if (count of windows) > 0 then
            set targetWindow to window 1
            -- Close all tabs except one (can't close all tabs)
            repeat while (count of tabs of targetWindow) > 1
                close tab -1 of targetWindow
            end repeat
        else
            -- Create a new window if none exist
            make new window
            set targetWindow to window 1
        end if
        
        -- Create tabs for all collected tabs in sorted order
        repeat with tabInfo in allTabs
            set tabUrl to item 1 of tabInfo
            -- Create new tab and navigate to URL
            make new tab at end of tabs of targetWindow with properties {URL:tabUrl}
        end repeat
        
        -- Close the first empty tab if it exists and is empty
        if (count of tabs of targetWindow) > totalTabsCollected then
            set firstTabUrl to URL of tab 1 of targetWindow
            if firstTabUrl is "chrome://newtab/" or firstTabUrl contains "newtab" then
                close tab 1 of targetWindow
            end if
        end if
        
        -- Activate the first tab
        if (count of tabs of targetWindow) > 0 then
            set active tab index of targetWindow to 1
        end if
    end tell
    
    -- Final summary dialog
    set summaryMsg to "Tab Organization Summary:" & return & return
    set summaryMsg to summaryMsg & "• Total tabs organized: " & totalTabsCollected & return
    set summaryMsg to summaryMsg & "• Original windows: " & windowsProcessed & return
    set summaryMsg to summaryMsg & "• Final windows: 1" & return
    if sortByDomain then
        set summaryMsg to summaryMsg & "• Sorted by: Domain" & return
    else
        set summaryMsg to summaryMsg & "• Sorted by: Full URL" & return
    end if
    
    display dialog summaryMsg buttons {"OK"} default button "OK" with title "Tab Organization Completed" with icon note
    
    -- Final voice feedback (if not in silent mode)
    if not silentMode then
        say "Tab organization completed"
    end if
    
on error errMsg number errNum
    -- Comprehensive error handling
    set errorDialog to "An error occurred during tab organization:" & return & return
    set errorDialog to errorDialog & "Error: " & errMsg & return
    set errorDialog to errorDialog & "Error Code: " & errNum
    
    display dialog errorDialog buttons {"OK"} default button "OK" with icon stop
    
    if not silentMode then
        say "Error occurred during organization"
    end if
end try

end main