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

    # Read the existing JSON file
    $json = Get-Content -Path $JsonFilePath -Raw | ConvertFrom-Json

    # Debugging output to check the JSON structure
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
            Date = $date.ToString("ddd dd MMM yyyy")
            Description = $Description
        }
        $json.GDates += $entry
    }

    # Debugging output to check the JSON structure after modification
    Write-Output "JSON structure after modification:"
    $json | ConvertTo-Json -Depth 3

    # Convert back to JSON and save to file
    $json | ConvertTo-Json -Depth 3 | Set-Content -Path $JsonFilePath
}

# Example usage
$startDate = [DateTime]::Parse("21-02-2025")
$endDate = [DateTime]::Parse("15-03-2025")
$jsonFilePath = "$PSScriptRoot\gdata.json"
$description = "Not Available"

Create-JsonEntries -StartDate $startDate -EndDate $endDate -JsonFilePath $jsonFilePath -Description $description