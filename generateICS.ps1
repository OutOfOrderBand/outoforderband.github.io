$gigs = Get-Content "./data/gigs.json" | ConvertFrom-Json
$outDir = "./static/ics"

if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir | Out-Null
}

foreach ($gig in $gigs) {

    if (-not $gig.Date -or -not $gig.Location) {
        continue
    }

    $date = [DateTime]::Parse($gig.Date).ToUniversalTime()
    $end  = $date.AddHours(3)

    $slug = ($gig.Location -replace '[^a-zA-Z0-9]+','-').ToLower()
    $file = "{0}-{1}.ics" -f $date.ToString("yyyyMMdd"), $slug

    $ics = @"
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Out Of Order Band//Gig//EN
BEGIN:VEVENT
UID:$($date.ToString("yyyyMMdd"))-$slug@outoforderband.co.uk
DTSTAMP:$([DateTime]::UtcNow.ToString("yyyyMMddTHHmmssZ"))
DTSTART:$($date.ToString("yyyyMMddTHHmmssZ"))
DTEND:$($end.ToString("yyyyMMddTHHmmssZ"))
SUMMARY:Out Of Order Band – $($gig.Location)
DESCRIPTION:Live gig at $($gig.Location)
LOCATION:$($gig.Location)
END:VEVENT
END:VCALENDAR
"@

    $ics | Out-File -Encoding utf8 -FilePath (Join-Path $outDir $file)
}
