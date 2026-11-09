$src = "D:\AI Tools\Open Router Projects\AI Studio\index.html"
$appjs = "D:\AI Tools\Open Router Projects\AI Studio\deploy\app.js"
$worker = "D:\AI Tools\Open Router Projects\AI Studio\deploy\worker.js"

# 1) embed index.html into app.js
$html = Get-Content $src -Raw -Encoding UTF8
$safe = $html.Replace('`','``').Replace('$','$$')
$js = "const HTML = ``$safe``;`nexport { HTML };`n"
Set-Content -Path $appjs -Value $js -Encoding UTF8

# 2) merge app.js into worker.js (single-file)
$w = Get-Content $worker -Raw -Encoding UTF8
$w = $w.Replace('import { HTML } from "./app.js";', '')
$w = $w.Replace('/* ZeroShift Studio — Cloudflare Worker (full static deploy, no KV/DB needed) */', "/* ZeroShift Studio - single-file Cloudflare Worker */`n" + $js)
Set-Content -Path $worker -Value $w -Encoding UTF8

# 3) delete app.js
Remove-Item $appjs -Force

(Get-Item $worker).Length
