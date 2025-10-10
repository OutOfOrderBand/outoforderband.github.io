Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ====== CONFIG ======
$htmlPath = "C:\Users\User\OneDrive\Documents\repos\Hugo\outoforderband.github.io\static\Dates.html"
$jsonBackupPath = "$env:TEMP\unavailableDates-backup.json"

# ====== LOAD JSON FROM HTML ======
if (-not (Test-Path $htmlPath)) {
    [System.Windows.Forms.MessageBox]::Show("HTML file not found at $htmlPath", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    exit
}

$html = Get-Content $htmlPath -Raw

if ($html -match 'const\s+DATA\s*=\s*(\{[\s\S]*?\});') {
    $jsonText = $matches[1]
    try {
        $data = $jsonText | ConvertFrom-Json
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to parse JSON from HTML.`n$($_.Exception.Message)", "Error")
        exit
    }
} else {
    [System.Windows.Forms.MessageBox]::Show("Could not locate 'const DATA =' block in HTML.", "Error")
    exit
}

# ====== GUI FORM ======
$form = New-Object System.Windows.Forms.Form
$form.Text = "Add Unavailable Dates"
$form.Size = New-Object System.Drawing.Size(370, 280)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.MinimizeBox = $false

# "Apply to All" checkbox
$chkApplyAll = New-Object System.Windows.Forms.CheckBox
$chkApplyAll.Text = "Apply to all people"
$chkApplyAll.Location = New-Object System.Drawing.Point(20, 20)
$chkApplyAll.Width = 150
$form.Controls.Add($chkApplyAll)

# Name label + dropdown
$lblName = New-Object System.Windows.Forms.Label
$lblName.Text = "Select Name:"
$lblName.Location = New-Object System.Drawing.Point(20, 55)
$form.Controls.Add($lblName)

$comboName = New-Object System.Windows.Forms.ComboBox
$comboName.Location = New-Object System.Drawing.Point(150, 52)
$comboName.Width = 180
$comboName.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$comboName.Items.AddRange($data.names)
$form.Controls.Add($comboName)

# Start Date label + picker
$lblStart = New-Object System.Windows.Forms.Label
$lblStart.Text = "Start Date:"
$lblStart.Location = New-Object System.Drawing.Point(20, 100)
$form.Controls.Add($lblStart)

$startPicker = New-Object System.Windows.Forms.DateTimePicker
$startPicker.Format = [System.Windows.Forms.DateTimePickerFormat]::Short
$startPicker.Location = New-Object System.Drawing.Point(150, 97)
$startPicker.Width = 120
$startPicker.ShowUpDown = $false
$form.Controls.Add($startPicker)

# End Date label + picker
$lblEnd = New-Object System.Windows.Forms.Label
$lblEnd.Text = "End Date:"
$lblEnd.Location = New-Object System.Drawing.Point(20, 140)
$form.Controls.Add($lblEnd)

$endPicker = New-Object System.Windows.Forms.DateTimePicker
$endPicker.Format = [System.Windows.Forms.DateTimePickerFormat]::Short
$endPicker.Location = New-Object System.Drawing.Point(150, 137)
$endPicker.Width = 120
$endPicker.ShowUpDown = $false
$form.Controls.Add($endPicker)

# Optional: Prevent end date before start date
$startPicker.Add_ValueChanged({
    $endPicker.MinDate = $startPicker.Value
})

# Toggle dropdown based on checkbox
$chkApplyAll.Add_CheckedChanged({
    if ($chkApplyAll.Checked) {
        $comboName.Enabled = $false
        $comboName.SelectedIndex = -1
    } else {
        $comboName.Enabled = $true
    }
})

# Buttons
$btnAdd = New-Object System.Windows.Forms.Button
$btnAdd.Text = "Add Dates"
$btnAdd.Location = New-Object System.Drawing.Point(60, 190)
$btnAdd.Width = 100
$form.Controls.Add($btnAdd)

$btnCancel = New-Object System.Windows.Forms.Button
$btnCancel.Text = "Cancel"
$btnCancel.Location = New-Object System.Drawing.Point(190, 190)
$btnCancel.Width = 100
$form.Controls.Add($btnCancel)

# ====== EVENT HANDLERS ======
$btnCancel.Add_Click({ $form.Close() })

$btnAdd.Add_Click({
    $start = $startPicker.Value.Date
    $end = $endPicker.Value.Date

    # Determine which names to apply to
    if ($chkApplyAll.Checked) {
        $namesToUpdate = $data.names
    } else {
        $name = $comboName.SelectedItem
        if (-not $name) {
            [System.Windows.Forms.MessageBox]::Show("Please select a name or check 'Apply to all people'.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            return
        }
        $namesToUpdate = @($name)
    }

    if ($start -gt $end) {
        [System.Windows.Forms.MessageBox]::Show("Start date cannot be after end date.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    # Generate date list
    $dates = @()
    for ($d = $start; $d -le $end; $d = $d.AddDays(1)) {
        $dates += $d.ToString('yyyy-MM-dd')
    }

    # Update data for each selected name
    foreach ($nameToUpdate in $namesToUpdate) {
        $existing = $data.unavailableDates.$nameToUpdate
        if (-not $existing) { $existing = @() }
        $data.unavailableDates.$nameToUpdate = ($existing + $dates) | Sort-Object -Unique
    }

    # Backup JSON
    $data | ConvertTo-Json -Depth 5 | Set-Content $jsonBackupPath -Encoding UTF8

    # Replace JSON in HTML
    $newJson = ($data | ConvertTo-Json -Depth 5 -Compress)
    $html = [Regex]::Replace(
        $html,
        'const\s+DATA\s*=\s*\{.*?\};',
        "const DATA = $newJson;",
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )

    # Save updated HTML
    Set-Content -Path $htmlPath -Value $html -Encoding UTF8

    $peopleText = if ($chkApplyAll.Checked) { "all people" } else { $namesToUpdate[0] }
    [System.Windows.Forms.MessageBox]::Show("✅ Dates added for $peopleText.`nHTML updated successfully.", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    $form.Close()
})

# ====== SHOW GUI ======
[void]$form.ShowDialog()