Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ====== CONFIG ======
$htmlPath = "C:\Users\User\OneDrive\Documents\repos\Hugo\outoforderband.github.io\Dates.html"
$outputDoc = "C:\Users\User\OneDrive\Documents\repos\Hugo\outoforderband.github.io\FreeDates2027.docx"

# ====== LOAD HTML ======
if (-not (Test-Path $htmlPath)) {
    Write-Host "HTML file not found at $htmlPath"
    exit
}

$html = Get-Content $htmlPath -Raw

# Extract JSON inside "const DATA = { ... };"
if ($html -match 'const\s+DATA\s*=\s*(\{[\s\S]*?\});') {
    $jsonText = $matches[1]
    try {
        $data = $jsonText | ConvertFrom-Json
    } catch {
        Write-Host "Failed to parse JSON"
        exit
    }
} else {
    Write-Host "Could not locate const DATA block"
    exit
}

# ====== BUILD UNAVAILABLE DATE LIST ======
$unavailable = @()

foreach ($person in $data.unavailableDates.PSObject.Properties.Name) {
    $unavailable += $data.unavailableDates.$person
}

# Convert to DateTime objects
$unavailableDT = $unavailable | ForEach-Object { [datetime]::Parse($_) }

# ====== GENERATE ALL FRI/SAT/SUN IN 2027 ======
$year = 2027
$start = Get-Date "$year-01-01"
$end   = Get-Date "$year-12-31"

$weekendDays = @()

for ($d = $start; $d -le $end; $d = $d.AddDays(1)) {
    if ($d.DayOfWeek -in @("Friday","Saturday","Sunday")) {
        $weekendDays += $d
    }
}

# ====== FILTER FREE DATES ======
$freeDates = $weekendDays | Where-Object { $_ -notin $unavailableDT }

# ====== OUTPUT TO WORD ======
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$doc = $word.Documents.Add()

# Set margins
$doc.PageSetup.TopMargin    = 36
$doc.PageSetup.BottomMargin = 36
$doc.PageSetup.LeftMargin   = 36
$doc.PageSetup.RightMargin  = 36

# Header/Footer
$doc.Sections.Item(1).Headers.Item(1).Range.Text = "Out Of Order – Availability Report"
$doc.Sections.Item(1).Footers.Item(1).Range.Text = "Generated on $(Get-Date -Format 'dd MMM yyyy')"

$selection = $word.Selection
$selection.Font.Name = "Calibri"
$selection.Font.Size = 14

# Title
$selection.ParagraphFormat.Alignment = 1   # Center
$selection.Font.Size = 22
$selection.Font.Bold = $true
$selection.TypeText("Free Weekend Dates")
$selection.TypeParagraph()

$selection.Font.Size = 16
$selection.Font.Bold = $false
$selection.TypeText("Fridays, Saturdays & Sundays – $year")
$selection.TypeParagraph()
$selection.TypeParagraph()

# Reset alignment
$selection.ParagraphFormat.Alignment = 0
$selection.Font.Size = 12

# Create table
$rows = $freeDates.Count + 1
$cols = 2

$table = $doc.Tables.Add($selection.Range, $rows, $cols)
$table.Style = "Table Grid"
$table.ApplyStyleHeadingRows = $true
$table.ApplyStyleLastRow = $false
$table.ApplyStyleFirstColumn = $false
$table.ApplyStyleLastColumn = $false

# Header row
$table.Cell(1,1).Range.Text = "Date"
$table.Cell(1,2).Range.Text = "Day"
$table.Rows.Item(1).Range.Font.Bold = $true
$table.Rows.Item(1).Shading.BackgroundPatternColor = 15395562  # Light grey

# Fill rows
$rowIndex = 2
foreach ($d in $freeDates) {
    $table.Cell($rowIndex,1).Range.Text = $d.ToString("yyyy-MM-dd")
    $table.Cell($rowIndex,2).Range.Text = $d.ToString("dddd")

    # Alternating row shading
    if ($rowIndex % 2 -eq 0) {
        $table.Rows.Item($rowIndex).Shading.BackgroundPatternColor = 16777215 # White
    } else {
        $table.Rows.Item($rowIndex).Shading.BackgroundPatternColor = 15790320 # Very light grey
    }

    $rowIndex++
}

$table.AutoFitBehavior(1) # AutoFit to contents

$doc.SaveAs([ref]$outputDoc)
$doc.Close()
$word.Quit()

Write-Host "Professional Word document created at $outputDoc"
