$src = "D:\AI Tools\Open Router Projects\AI Studio\index.html"
$worker = "D:\AI Tools\Open Router Projects\AI Studio\deploy\worker.js"

$html = Get-Content $src -Raw -Encoding UTF8
$safe = $html.Replace('`','``').Replace('$','$$')
$htmlConst = "/* ZeroShift Studio - single-file Cloudflare Worker */`nconst HTML = ``$safe``;`n"

# strip old header + import if present
$w = Get-Content $worker -Raw -Encoding UTF8
$w = $w -replace '^/\* ZeroShift Studio.*?\*/', ''
$w = $w -replace 'import \{ HTML \} from "\./app\.js";\s*', ''
$w = $w.TrimStart()

Set-Content -Path $worker -Value ($htmlConst + "`n" + $w) -Encoding UTF8
(Get-Item $worker).Length
