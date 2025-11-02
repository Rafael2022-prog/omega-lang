param([string]$Url='http://127.0.0.1:8080/health',[int]$N=10)
$ErrorActionPreference = 'Stop'
$responses = @()
for ($i = 0; $i -lt $N; $i++) {
  $responses += Invoke-WebRequest -UseBasicParsing -Uri $Url -Method GET
}
$codes = $responses | ForEach-Object { $_.StatusCode }
Write-Output ($codes -join ',')