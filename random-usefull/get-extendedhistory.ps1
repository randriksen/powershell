# Define a function called Split-History
function Split-History {
    # Read the content of the PowerShell history file
    $historyContent = Get-Content (Get-PSReadlineOption).HistorySavePath

    # Initialize arrays to store commands and the current command being processed
    $commands = @()
    $currentCommand = ""

    # Loop through each line in the history file
    foreach ($line in $historyContent) {
        # Check if the line ends with "``" (backtick), indicating a continuation of a multiline command
        if ($line.EndsWith("``")) {
            # Remove the backtick and append the line to the current command
            $currentCommand += $line.Substring(0, $line.Length - 1)
        } else {
            # If the line doesn't end with a backtick, it's a standalone command
            $currentCommand += $line
            # Add the complete command to the list of commands, trimming any leading/trailing whitespace
            $commands += $currentCommand.Trim()
            # Reset the current command string
            $currentCommand = ""
        }
    }

    # Add the last command if it exists
    if ($currentCommand -ne "") {
        $commands += $currentCommand.Trim()
    }

    # Return the array of individual commands
    return $commands
}

# Define a function called get-extendedhistory
function Get-ExtendedHistory {
    # Call the Split-History function to split the history into coherent commands
    $hist = split-history

    # Output headers for displaying command history
    write-host "Id`tCommand"
    write-host "-----------------------"

    # Loop through the commands in the history
    for ($i = 0; $i -lt $hist.Length; $i++) {
        # If a command is very long (over 200 characters), add separators for readability
        if ($hist[$i].length -gt 200) {
            write-host "`n--------------------------------------------------------------------------------------------"
        }

        # Output the command's index and the command itself
        write-host ($i) "`t" $hist[$i]

        # If a command is very long (over 200 characters), add separators for readability
        if ($hist[$i].length -gt 200) {
            write-host "--------------------------------------------------------------------------------------------`n"
        }
    }
}

# Define a function called invoke-extendedhistory
function Invoke-ExtendedHistory {
    param([int]$i)
    # Call the Split-History function to split the history into coherent commands
    $hist = split-history
    # Retrieve the command at the specified index
    $line = $hist[$i]
    # Execute the command using Invoke-Expression
    Invoke-Expression -Command $line
}
