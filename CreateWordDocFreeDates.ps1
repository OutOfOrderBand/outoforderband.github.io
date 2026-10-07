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

$selection = $word.Selection
$selection.TypeText("Free Friday, Saturday, Sunday Dates for $year")
$selection.TypeParagraph()
$selection.TypeParagraph()

foreach ($d in $freeDates) {
    $selection.TypeText($d.ToString("yyyy-MM-dd (dddd)"))
    $selection.TypeParagraph()
}

$doc.SaveAs([ref]$outputDoc)
$doc.Close()
$word.Quit()

Write-Host "Word document created at $outputDoc"
