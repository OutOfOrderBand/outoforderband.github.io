# Function to generate a new GUID
function New-Guid {
    [System.Guid]::NewGuid().ToString()
}

# Function to create JSON entries
function Create-JsonEntries {
    param (
        [DateTime]$StartDate,
        [DateTime]$EndDate,
        [string]$JsonFilePath,
        [string]$Description
    )

    # Check if the JSON file exists
    if (-Not (Test-Path -Path $JsonFilePath)) {
        Write-Error "JSON file not found: $JsonFilePath"
        return
    }

    # Read the existing JSON file and remove "var gData = "
    $jsonContent = Get-Content -Path $JsonFilePath -Raw
    $jsonContent = $jsonContent -replace '^var gData =', '' # Remove prefix if present

    # Convert from JSON
    $json = $jsonContent | ConvertFrom-Json

    # Debugging output to check the JSON structure before modification
    Write-Output "JSON structure before modification:"
    $json | ConvertTo-Json -Depth 3

    # Check if GDates property exists, if not, initialize it
    if (-not $json.PSObject.Properties['GDates']) {
        Write-Output "GDates property not found. Initializing it."
        $json | Add-Member -MemberType NoteProperty -Name GDates -Value @()
    } else {
        Write-Output "GDates property found."
    }

    # Loop through each day between the start and end dates
    for ($date = $StartDate; $date -le $EndDate; $date = $date.AddDays(1)) {
        $entry = @{
            Id = New-Guid
            Date = $date.ToString("ddd dd MMM yyyy") + " (" + $date.ToString("dd/MM/yyyy") + ")"
            Description = $Description
        }
        $json.GDates += $entry
    }

    # Debugging output to check the JSON structure after modification
    Write-Output "JSON structure after modification:"
    $json | ConvertTo-Json -Depth 3

    # Convert back to JSON and re-add "var gData ="
    $jsonOutput = "var gData = " + ($json | ConvertTo-Json -Depth 3)

    # Save back to file
    $jsonOutput | Set-Content -Path $JsonFilePath
}

# Example usage
$startDate = [DateTime]::Parse("04-04-2025") 
$endDate = [DateTime]::Parse("06-04-2025")
$jsonFilePath = "$PSScriptRoot\data\gdata.js"
$description = "Clive Unavailable"

Create-JsonEntries -StartDate $startDate -EndDate $endDate -JsonFilePath $jsonFilePath -Description $description
