Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Xaml

# ====== CONFIG ======
# Update these paths as needed
$htmlPath = "C:\Users\User\OneDrive\Documents\repos\Hugo\outoforderband.github.io\static\Dates.html"
$jsonBackupPath = "$env:TEMP\unavailableDates-backup.json"
# gigs.json path (relative to script folder). Change if needed.
$gigsJsonPath = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) -ChildPath "data\gigs.json"

# ====== LOAD JSON FROM HTML ======
if (-not (Test-Path $htmlPath)) {
    [System.Windows.MessageBox]::Show("HTML file not found at $htmlPath", "Error", "OK", "Error")
    exit
}

$html = Get-Content $htmlPath -Raw

if ($html -match 'const\s+DATA\s*=\s*(\{[\s\S]*?\});') {
    $jsonText = $matches[1]
    try {
        $data = $jsonText | ConvertFrom-Json
    } catch {
        [System.Windows.MessageBox]::Show("Failed to parse JSON from HTML.`n$($_.Exception.Message)", "Error", "OK", "Error")
        exit
    }
} else {
    [System.Windows.MessageBox]::Show("Could not locate 'const DATA =' block in HTML.", "Error", "OK", "Error")
    exit
}

# Ensure structure exists
if (-not $data.PSObject.Properties.Name -contains 'unavailableDates') {
    $data | Add-Member -MemberType NoteProperty -Name unavailableDates -Value @{}
}
if (-not $data.PSObject.Properties.Name -contains 'names') {
    $data | Add-Member -MemberType NoteProperty -Name names -Value @()
}

# ====== XAML UI ======
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Manage Unavailable Dates" Height="480" Width="760" WindowStartupLocation="CenterScreen" ResizeMode="NoResize">
  <Grid Margin="10">
    <Grid.ColumnDefinitions>
      <ColumnDefinition Width="460"/>
      <ColumnDefinition Width="12"/>
      <ColumnDefinition Width="*"/>
    </Grid.ColumnDefinitions>

    <StackPanel Grid.Column="0" Orientation="Vertical" VerticalAlignment="Top">
      <TextBlock Text="Mode" FontWeight="Bold" Margin="0,0,0,6"/>
      <StackPanel Orientation="Horizontal" Margin="0,0,0,10">
        <RadioButton x:Name="rbAdd" Content="Add Dates" IsChecked="True" Width="110" Margin="0,0,10,0"/>
        <RadioButton x:Name="rbRemove" Content="Remove Dates" Width="120"/>
      </StackPanel>

      <CheckBox x:Name="chkApplyAll" Content="Apply to all people" Margin="0,0,0,8"/>

      <TextBlock Text="Select Name" FontWeight="Bold" Margin="0,6,0,4"/>
      <ComboBox x:Name="comboName" Height="26" />

      <StackPanel Orientation="Horizontal" Margin="0,12,0,0">
        <StackPanel>
          <TextBlock Text="Start Date" FontWeight="Bold" Margin="0,0,0,4"/>
          <DatePicker x:Name="startPicker" Width="180"/>
        </StackPanel>
        <StackPanel Margin="12,0,0,0">
          <TextBlock Text="End Date" FontWeight="Bold" Margin="0,0,0,4"/>
          <DatePicker x:Name="endPicker" Width="180"/>
        </StackPanel>
      </StackPanel>

      <CheckBox x:Name="chkClearAll" Content="Clear all unavailable dates (ignore date range)" Margin="0,12,0,0" Visibility="Collapsed"/>

      <StackPanel Orientation="Horizontal" Margin="0,18,0,0">
        <Button x:Name="btnAction" Content="Add Dates" Width="120" Height="30" Margin="0,0,10,0"/>
        <Button x:Name="btnPreview" Content="Preview JSON" Width="110" Height="30" Margin="0,0,10,0"/>
        <Button x:Name="btnImportGigs" Content="Import gigs.json (apply to all)" Width="200" Height="30" Margin="0,0,10,0"/>
        <Button x:Name="btnUndo" Content="Undo (restore backup)" Width="140" Height="30" Margin="0,0,10,0"/>
        <Button x:Name="btnCancel" Content="Close" Width="80" Height="30"/>
      </StackPanel>

      <TextBlock Text="gigs.json path:" FontWeight="Bold" Margin="0,12,0,4"/>
      <TextBlock x:Name="txtGigsPath" TextWrapping="Wrap" FontSize="11" Foreground="Gray"/>
    </StackPanel>

    <Border Grid.Column="2" BorderBrush="#DDD" BorderThickness="1" Padding="8">
      <StackPanel>
        <TextBlock Text="Existing Unavailable Dates" FontWeight="Bold" Margin="0,0,0,6"/>
        <ListBox x:Name="lstDates" Height="320" SelectionMode="Extended"/>
        <TextBlock Text="Tip: In Remove mode you can select individual dates above to remove them." FontStyle="Italic" FontSize="11" Margin="0,8,0,0"/>
      </StackPanel>
    </Border>
  </Grid>
</Window>
"@

# ====== LOAD XAML ======
$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]$xaml)
$window = [System.Windows.Markup.XamlReader]::Load($reader)

# Get controls
$rbAdd = $window.FindName("rbAdd")
$rbRemove = $window.FindName("rbRemove")
$chkApplyAll = $window.FindName("chkApplyAll")
$comboName = $window.FindName("comboName")
$startPicker = $window.FindName("startPicker")
$endPicker = $window.FindName("endPicker")
$chkClearAll = $window.FindName("chkClearAll")
$btnAction = $window.FindName("btnAction")
$btnPreview = $window.FindName("btnPreview")
$btnImportGigs = $window.FindName("btnImportGigs")
$btnUndo = $window.FindName("btnUndo")
$btnCancel = $window.FindName("btnCancel")
$lstDates = $window.FindName("lstDates")
$txtGigsPath = $window.FindName("txtGigsPath")

# ====== INITIALIZE VALUES ======
# Populate names
$comboName.Items.Clear()
if ($data.names) {
    foreach ($n in $data.names) { $comboName.Items.Add($n) | Out-Null }
}

# Show gigs.json path
$txtGigsPath.Text = $gigsJsonPath

# Set default dates
$startPicker.SelectedDate = [DateTime]::Today
$endPicker.SelectedDate = [DateTime]::Today

# Helper: refresh listbox for selected name
$refreshDates = {
    $lstDates.Items.Clear()
    $selectedName = $comboName.SelectedItem
    if ($selectedName -and $data.unavailableDates.$selectedName) {
        $dates = @($data.unavailableDates.$selectedName) | Sort-Object
        foreach ($d in $dates) { $lstDates.Items.Add($d) | Out-Null }
    }
}

# UI behavior functions
$updateMode = {
    if ($rbAdd.IsChecked) {
        $btnAction.Content = "Add Dates"
        $chkClearAll.Visibility = "Collapsed"
        $startPicker.IsEnabled = $true
        $endPicker.IsEnabled = $true
        $lstDates.IsEnabled = $false
    } else {
        $btnAction.Content = "Remove Dates"
        $chkClearAll.Visibility = "Visible"
        $startPicker.IsEnabled = -not $chkClearAll.IsChecked
        $endPicker.IsEnabled = -not $chkClearAll.IsChecked
        $lstDates.IsEnabled = $true
    }
}

# Wire events
$rbAdd.Add_Checked({ & $updateMode })
$rbRemove.Add_Checked({ & $updateMode })
$chkClearAll.Add_Checked({ & $updateMode })
$chkClearAll.Add_Unchecked({ & $updateMode })

$chkApplyAll.Add_Checked({
    $comboName.IsEnabled = $false
    $comboName.SelectedIndex = -1
    $lstDates.Items.Clear()
})
$chkApplyAll.Add_Unchecked({
    $comboName.IsEnabled = $true
})

$comboName.Add_SelectionChanged({ & $refreshDates })

# Prevent end before start
$startPicker.Add_SelectedDateChanged({
    if ($startPicker.SelectedDate -and $endPicker.SelectedDate -and $startPicker.SelectedDate -gt $endPicker.SelectedDate) {
        $endPicker.SelectedDate = $startPicker.SelectedDate
    }
})

# ====== ACTIONS ======
function Make-DateRangeList {
    param($startDate, $endDate)
    $list = @()
    for ($d = $startDate; $d -le $endDate; $d = $d.AddDays(1)) {
        $list += $d.ToString('yyyy-MM-dd')
    }
    return $list
}

$btnPreview.Add_Click({
    # Show preview of JSON block that would be written
    $previewData = $data | ConvertTo-Json -Depth 10 -Compress
    $dlg = New-Object System.Windows.Window
    $dlg.Title = "Preview JSON"
    $dlg.Width = 900
    $dlg.Height = 600
    $dlg.WindowStartupLocation = "CenterOwner"
    $dlg.Owner = $window

    $tb = New-Object System.Windows.Controls.TextBox
    $tb.Text = $previewData
    $tb.FontFamily = 'Consolas'
    $tb.FontSize = 12
    $tb.IsReadOnly = $true
    $tb.VerticalScrollBarVisibility = "Auto"
    $tb.HorizontalScrollBarVisibility = "Auto"
    $tb.TextWrapping = "NoWrap"
    $dlg.Content = $tb
    $dlg.ShowDialog() | Out-Null
})

$btnCancel.Add_Click({ $window.Close() })

$btnAction.Add_Click({
    $modeAdd = $rbAdd.IsChecked
    $clearAll = $chkClearAll.IsChecked
    $applyAll = $chkApplyAll.IsChecked

    if ($applyAll) {
        $namesToUpdate = $data.names
        if (-not $namesToUpdate) {
            [System.Windows.MessageBox]::Show("No names available in data to apply to.", "Error", "OK", "Error")
            return
        }
    } else {
        $sel = $comboName.SelectedItem
        if (-not $sel) {
            [System.Windows.MessageBox]::Show("Please select a name or check 'Apply to all people'.", "Error", "OK", "Error")
            return
        }
        $namesToUpdate = @($sel)
    }

    # Validate date range when needed
    $start = $startPicker.SelectedDate
    $end = $endPicker.SelectedDate
    if (-not $clearAll -and -not $start) {
        [System.Windows.MessageBox]::Show("Please select a start date.", "Error", "OK", "Error")
        return
    }
    if (-not $clearAll -and -not $end) {
        [System.Windows.MessageBox]::Show("Please select an end date.", "Error", "OK", "Error")
        return
    }
    if (-not $clearAll -and $start -gt $end) {
        [System.Windows.MessageBox]::Show("Start date cannot be after end date.", "Error", "OK", "Error")
        return
    }

    # Build list of dates to add or remove
    $datesToChange = @()
    if (-not $clearAll) {
        $datesToChange = Make-DateRangeList -startDate $start -endDate $end
    }

    # If in Remove mode and user selected individual dates in listbox, prefer those
    if (-not $modeAdd -and $lstDates.SelectedItems.Count -gt 0) {
        $datesToChange = @()
        foreach ($it in $lstDates.SelectedItems) { $datesToChange += $it }
    }

    # Build confirmation text
    $actionVerb = if ($modeAdd) { "Add" } else { "Remove" }
    $peopleText = if ($applyAll) { "all people" } else { ($namesToUpdate -join ", ") }
    $summary = "$actionVerb the following dates for $peopleText `n`n"

    if ($clearAll -and -not $modeAdd) {
        $summary += "(Clear all unavailable dates)"
    } elseif ($datesToChange.Count -eq 0 -and $modeAdd) {
        [System.Windows.MessageBox]::Show("No dates selected to add.", "Error", "OK", "Error")
        return
    } elseif ($datesToChange.Count -eq 0 -and -not $modeAdd) {
        [System.Windows.MessageBox]::Show("No dates selected to remove.", "Error", "OK", "Error")
        return
    } else {
        $summary += ($datesToChange -join ", ")
    }

    $summary += "`n`nProceed?"

    $res = [System.Windows.MessageBox]::Show($summary, "Confirm Changes", "YesNo", "Question")
    if ($res -ne "Yes") { return }

    # Backup JSON
    try {
        $data | ConvertTo-Json -Depth 10 | Set-Content $jsonBackupPath -Encoding UTF8
    } catch {
        [System.Windows.MessageBox]::Show("Failed to create backup: $($_.Exception.Message)", "Error", "OK", "Error")
        return
    }

    # Apply changes
    foreach ($nameToUpdate in $namesToUpdate) {
        if (-not $data.unavailableDates.PSObject.Properties.Name -contains $nameToUpdate) {
            $data.unavailableDates | Add-Member -MemberType NoteProperty -Name $nameToUpdate -Value @()
        }

        $existing = @()
        if ($data.unavailableDates.$nameToUpdate) { $existing = @($data.unavailableDates.$nameToUpdate) }

        if ($modeAdd) {
            $combined = ($existing + $datesToChange) | Sort-Object -Unique
            $data.unavailableDates.$nameToUpdate = $combined
        } else {
            if ($clearAll) {
                $data.unavailableDates.$nameToUpdate = @()
            } else {
                $remaining = $existing | Where-Object { $datesToChange -notcontains $_ }
                $data.unavailableDates.$nameToUpdate = @($remaining)
            }
        }
    }

    # Replace JSON in HTML
    try {
        $newJson = ($data | ConvertTo-Json -Depth 10 -Compress)
        $html = [Regex]::Replace(
            $html,
            'const\s+DATA\s*=\s*\{.*?\};',
            "const DATA = $newJson;",
            [System.Text.RegularExpressions.RegexOptions]::Singleline
        )
        Set-Content -Path $htmlPath -Value $html -Encoding UTF8
    } catch {
        [System.Windows.MessageBox]::Show("Failed to update HTML: $($_.Exception.Message)", "Error", "OK", "Error")
        return
    }

    # Success message
    if ($modeAdd) {
        [System.Windows.MessageBox]::Show("✅ Dates added for $peopleText.`nHTML updated successfully.", "Success", "OK", "Information")
    } else {
        if ($clearAll) {
            [System.Windows.MessageBox]::Show("✅ All unavailable dates cleared for $peopleText.`nHTML updated successfully.", "Success", "OK", "Information")
        } else {
            [System.Windows.MessageBox]::Show("✅ Dates removed for $peopleText.`nHTML updated successfully.", "Success", "OK", "Information")
        }
    }

    # Refresh list if single person selected
    & $refreshDates
})

# ====== Import gigs.json (apply to all) - only add new dates ======
$btnImportGigs.Add_Click({
    if (-not (Test-Path $gigsJsonPath)) {
        [System.Windows.MessageBox]::Show("gigs.json not found at:`n$gigsJsonPath", "Error", "OK", "Error")
        return
    }

    try {
        $gigsRaw = Get-Content $gigsJsonPath -Raw
        $gigs = $gigsRaw | ConvertFrom-Json
    } catch {
        [System.Windows.MessageBox]::Show("Failed to read/parse gigs.json:`n$($_.Exception.Message)", "Error", "OK", "Error")
        return
    }

    # Extract Date fields and normalize
    $importDates = @()
    foreach ($g in $gigs) {
        if ($null -ne $g.Date) {
            # Try parse various date formats robustly
            $dt = $null
            try {
                $dt = [DateTime]::Parse($g.Date)
            } catch {
                try { $dt = [DateTime]::ParseExact($g.Date, 'yyyy-MM-dd', $null) } catch { $dt = $null }
            }
            if ($dt) { $importDates += $dt.ToString('yyyy-MM-dd') }
        }
    }

    $importDates = $importDates | Sort-Object -Unique
    if ($importDates.Count -eq 0) {
        [System.Windows.MessageBox]::Show("No valid Date fields found in gigs.json.", "Info", "OK", "Information")
        return
    }

    # Gather all existing dates across all people in DATA.unavailableDates
    $existingAll = @()
    foreach ($prop in $data.unavailableDates.PSObject.Properties) {
        $vals = @($data.unavailableDates.$($prop.Name))
        if ($vals) { $existingAll += $vals }
    }
    $existingAll = ($existingAll | Sort-Object -Unique)

    # Compute only-new dates (importDates - existingAll)
    $newDates = $importDates | Where-Object { $existingAll -notcontains $_ }
    if ($newDates.Count -eq 0) {
        [System.Windows.MessageBox]::Show("All dates from gigs.json are already present in Dates.html. No changes needed.", "Info", "OK", "Information")
        return
    }

    # Confirm with user listing only the new dates
    $summary = "The following new dates from gigs.json will be added to ALL people:`n`n"
    $summary += ($newDates -join ", ")
    $summary += "`n`nProceed?"

    $res = [System.Windows.MessageBox]::Show($summary, "Confirm Import gigs.json", "YesNo", "Question")
    if ($res -ne "Yes") { return }

    # Backup JSON
    try {
        $data | ConvertTo-Json -Depth 10 | Set-Content $jsonBackupPath -Encoding UTF8
    } catch {
        [System.Windows.MessageBox]::Show("Failed to create backup: $($_.Exception.Message)", "Error", "OK", "Error")
        return
    }

    # Ensure names exist
    $namesToUpdate = $data.names
    if (-not $namesToUpdate -or $namesToUpdate.Count -eq 0) {
        [System.Windows.MessageBox]::Show("No names found in DATA.names to apply imported dates to.", "Error", "OK", "Error")
        return
    }

    # Apply only the new dates to all names
    foreach ($nameToUpdate in $namesToUpdate) {
        if (-not $data.unavailableDates.PSObject.Properties.Name -contains $nameToUpdate) {
            $data.unavailableDates | Add-Member -MemberType NoteProperty -Name $nameToUpdate -Value @()
        }
        $existing = @()
        if ($data.unavailableDates.$nameToUpdate) { $existing = @($data.unavailableDates.$nameToUpdate) }
        $combined = ($existing + $newDates) | Sort-Object -Unique
        $data.unavailableDates.$nameToUpdate = $combined
    }

    # Replace JSON in HTML
    try {
        $newJson = ($data | ConvertTo-Json -Depth 10 -Compress)
        $html = [Regex]::Replace(
            $html,
            'const\s+DATA\s*=\s*\{.*?\};',
            "const DATA = $newJson;",
            [System.Text.RegularExpressions.RegexOptions]::Singleline
        )
        Set-Content -Path $htmlPath -Value $html -Encoding UTF8
    } catch {
        [System.Windows.MessageBox]::Show("Failed to update HTML: $($_.Exception.Message)", "Error", "OK", "Error")
        return
    }

    [System.Windows.MessageBox]::Show("✅ Imported $($newDates.Count) new dates from gigs.json and applied to all people.`nHTML updated successfully.", "Success", "OK", "Information")

    # Refresh list if single person selected
    & $refreshDates
})

# ====== Undo (restore backup) ======
$btnUndo.Add_Click({
    if (-not (Test-Path $jsonBackupPath)) {
        [System.Windows.MessageBox]::Show("Backup file not found at:`n$jsonBackupPath", "Error", "OK", "Error")
        return
    }
    try {
        $backupJson = Get-Content $jsonBackupPath -Raw
        $backupData = $backupJson | ConvertFrom-Json
    } catch {
        [System.Windows.MessageBox]::Show("Failed to read/parse backup: $($_.Exception.Message)", "Error", "OK", "Error")
        return
    }

    $res = [System.Windows.MessageBox]::Show("Restore the backup JSON and overwrite Dates.html? This cannot be undone.", "Confirm Restore", "YesNo", "Warning")
    if ($res -ne "Yes") { return }

    try {
        $newJson = ($backupData | ConvertTo-Json -Depth 10 -Compress)
        $html = [Regex]::Replace(
            $html,
            'const\s+DATA\s*=\s*\{.*?\};',
            "const DATA = $newJson;",
            [System.Text.RegularExpressions.RegexOptions]::Singleline
        )
        Set-Content -Path $htmlPath -Value $html -Encoding UTF8

        # reload data variable in memory
        $data = $backupData
    } catch {
        [System.Windows.MessageBox]::Show("Failed to restore backup: $($_.Exception.Message)", "Error", "OK", "Error")
        return
    }

    [System.Windows.MessageBox]::Show("Backup restored and Dates.html updated.", "Success", "OK", "Information")
    & $refreshDates
})

# ====== Show window ======
& $updateMode
$window.ShowDialog() | Out-Null
