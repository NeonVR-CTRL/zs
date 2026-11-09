$src = "D:\AI Tools\Open Router Projects\AI Studio\index.html"
$dst = "D:\AI Tools\Open Router Projects\AI Studio\deploy\app.js"
$html = Get-Content $src -Raw -Encoding UTF8
$safe = $html.Replace('`','``').Replace('$','$$')
$js = "/* ZeroShift Studio - generated from index.html (single-file build) */`nconst HTML = ``$safe``;`nexport { HTML };`n"
Set-Content -Path $dst -Value $js -Encoding UTF8
(Get-Item $dst).Length
