$ErrorActionPreference = "SilentlyContinue"

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outJson = "$env:USERPROFILE\Desktop\model-health-$stamp.json"
$outTxt  = "$env:USERPROFILE\Desktop\model-health-$stamp.txt"

$results = New-Object System.Collections.Generic.List[object]

function Add-Result {
  param(
    [string]$Name,
    [string]$Family,
    [string]$Endpoint,
    [string]$Model,
    [string]$Status,
    [int]$Ms = 0,
    [string]$Reply = "",
    [string]$ErrorText = ""
  )

  $script:results.Add([pscustomobject]@{
    name = $Name
    family = $Family
    endpoint = $Endpoint
    model = $Model
    status = $Status
    ms = $Ms
    reply = $Reply
    error = $ErrorText
  })
}

function Test-OpenAIChat {
  param(
    [string]$Name,
    [string]$Family,
    [string]$BaseUrl,
    [string]$Model,
    [hashtable]$Headers = @{}
  )

  $uri = ($BaseUrl.TrimEnd("/")) + "/chat/completions"

  $body = @{
    model = $Model
    messages = @(
      @{ role = "system"; content = "You are a model health check. Follow the user exactly." },
      @{ role = "user"; content = "Reply with exactly this text and nothing else: OK" }
    )
    temperature = 0
    max_tokens = 16
    stream = $false
  } | ConvertTo-Json -Depth 10

  $sw = [Diagnostics.Stopwatch]::StartNew()
  try {
    $r = Invoke-RestMethod -Uri $uri -Method Post -Headers $Headers -ContentType "application/json" -Body $body -TimeoutSec 120
    $sw.Stop()

    $reply = ""
    if ($r.choices -and $r.choices.Count -gt 0) {
      $reply = [string]$r.choices[0].message.content
    }

    if ($reply.Trim() -match "^OK") {
      Add-Result $Name $Family $BaseUrl $Model "OK" $sw.ElapsedMilliseconds $reply ""
    } else {
      Add-Result $Name $Family $BaseUrl $Model "WEIRD_REPLY" $sw.ElapsedMilliseconds $reply ""
    }
  } catch {
    $sw.Stop()
    Add-Result $Name $Family $BaseUrl $Model "FAIL" $sw.ElapsedMilliseconds "" $_.Exception.Message
  }
}

function Test-OllamaGenerate {
  param(
    [string]$Name,
    [string]$BaseUrl,
    [string]$Model
  )

  $uri = ($BaseUrl.TrimEnd("/")) + "/api/generate"
  $body = @{
    model = $Model
    prompt = "Reply with exactly this text and nothing else: OK"
    stream = $false
    options = @{
      temperature = 0
      num_predict = 16
    }
  } | ConvertTo-Json -Depth 10

  $sw = [Diagnostics.Stopwatch]::StartNew()
  try {
    $r = Invoke-RestMethod -Uri $uri -Method Post -ContentType "application/json" -Body $body -TimeoutSec 120
    $sw.Stop()

    $reply = [string]$r.response
    if ($reply.Trim() -match "^OK") {
      Add-Result $Name "Ollama" $BaseUrl $Model "OK" $sw.ElapsedMilliseconds $reply ""
    } else {
      Add-Result $Name "Ollama" $BaseUrl $Model "WEIRD_REPLY" $sw.ElapsedMilliseconds $reply ""
    }
  } catch {
    $sw.Stop()
    Add-Result $Name "Ollama" $BaseUrl $Model "FAIL" $sw.ElapsedMilliseconds "" $_.Exception.Message
  }
}

function Test-OllamaEmbedding {
  param(
    [string]$Name,
    [string]$BaseUrl,
    [string]$Model
  )

  $uris = @(
    ($BaseUrl.TrimEnd("/") + "/api/embed"),
    ($BaseUrl.TrimEnd("/") + "/api/embeddings")
  )

  foreach ($uri in $uris) {
    $body = @{
      model = $Model
      input = "health check"
      prompt = "health check"
    } | ConvertTo-Json -Depth 10

    $sw = [Diagnostics.Stopwatch]::StartNew()
    try {
      $r = Invoke-RestMethod -Uri $uri -Method Post -ContentType "application/json" -Body $body -TimeoutSec 120
      $sw.Stop()

      $ok = $false
      if ($r.embeddings) { $ok = $true }
      if ($r.embedding) { $ok = $true }

      if ($ok) {
        Add-Result $Name "Ollama Embedding" $BaseUrl $Model "OK" $sw.ElapsedMilliseconds "embedding returned" ""
        return
      }
    } catch {
      $lastErr = $_.Exception.Message
    }
  }

  Add-Result $Name "Ollama Embedding" $BaseUrl $Model "FAIL" 0 "" $lastErr
}

Write-Host "Testing Docker Model Runner local models..."
$dmr = "http://localhost:12434/engines/llama.cpp/v1"

Test-OpenAIChat "DMR llama3.2" "Docker Model Runner" $dmr "docker.io/ai/llama3.2:latest"
Test-OpenAIChat "DMR smollm2" "Docker Model Runner" $dmr "docker.io/ai/smollm2:latest"
Test-OpenAIChat "DMR bartowski llama 1B" "Docker Model Runner" $dmr "huggingface.co/bartowski/llama-3.2-1b-instruct-gguf:latest"

Write-Host "Testing Ollama legacy models..."
$ollama = "http://localhost:11434"
Test-OllamaGenerate "Ollama llama3.2:3b" $ollama "llama3.2:3b"
Test-OllamaEmbedding "Ollama nomic-embed-text" $ollama "nomic-embed-text:latest"

Write-Host "Testing Z.AI GLM-5.2..."
if ($env:ZAI_API_KEY) {
  Test-OpenAIChat "Z.AI glm-5.2" "Z.AI Remote" "https://api.z.ai/api/paas/v4" "glm-5.2" @{ Authorization = "Bearer $env:ZAI_API_KEY" }
} else {
  Add-Result "Z.AI glm-5.2" "Z.AI Remote" "https://api.z.ai/api/paas/v4" "glm-5.2" "SKIP" 0 "" "Set `$env:ZAI_API_KEY first"
}

Write-Host "Testing OpenClaw from inside Open WebUI container..."
$webui = docker ps --format "{{.Names}}" | Where-Object { $_ -match "open-webui|webui" } | Select-Object -First 1

if ($webui) {
  $py = "$env:TEMP\openclaw-health.py"

@"
import json, time, urllib.request

models = ["openclaw", "openclaw/default", "openclaw/main"]
url = "http://openclaw-gateway:18789/v1/chat/completions"

for model in models:
    body = {
        "model": model,
        "messages": [
            {"role": "system", "content": "You are a model health check. Follow the user exactly."},
            {"role": "user", "content": "Reply with exactly this text and nothing else: OK"}
        ],
        "temperature": 0,
        "max_tokens": 16,
        "stream": False
    }
    started = time.time()
    try:
        req = urllib.request.Request(
            url,
            data=json.dumps(body).encode("utf-8"),
            headers={"Content-Type": "application/json"},
            method="POST"
        )
        with urllib.request.urlopen(req, timeout=120) as resp:
            raw = resp.read().decode("utf-8", errors="replace")
        elapsed = int((time.time() - started) * 1000)
        data = json.loads(raw)
        reply = data.get("choices", [{}])[0].get("message", {}).get("content", "")
        status = "OK" if reply.strip().startswith("OK") else "WEIRD_REPLY"
        print(json.dumps({
            "name": "OpenClaw " + model,
            "family": "OpenClaw Gateway",
            "endpoint": "http://openclaw-gateway:18789/v1",
            "model": model,
            "status": status,
            "ms": elapsed,
            "reply": reply,
            "error": ""
        }))
    except Exception as e:
        elapsed = int((time.time() - started) * 1000)
        print(json.dumps({
            "name": "OpenClaw " + model,
            "family": "OpenClaw Gateway",
            "endpoint": "http://openclaw-gateway:18789/v1",
            "model": model,
            "status": "FAIL",
            "ms": elapsed,
            "reply": "",
            "error": str(e)
        }))
"@ | Set-Content -Path $py -Encoding UTF8

  docker cp $py "$webui`:/tmp/openclaw-health.py" | Out-Null
  $openclawLines = docker exec $webui python /tmp/openclaw-health.py

  foreach ($line in $openclawLines) {
    try {
      $o = $line | ConvertFrom-Json
      Add-Result $o.name $o.family $o.endpoint $o.model $o.status $o.ms $o.reply $o.error
    } catch {
      Add-Result "OpenClaw check" "OpenClaw Gateway" "http://openclaw-gateway:18789/v1" "" "FAIL" 0 "" $line
    }
  }
} else {
  Add-Result "OpenClaw gateway" "OpenClaw Gateway" "http://openclaw-gateway:18789/v1" "openclaw/default/main" "SKIP" 0 "" "Open WebUI container not found"
}

$results |
  Sort-Object family, name |
  Format-Table name, family, model, status, ms, reply, error -AutoSize |
  Tee-Object -FilePath $outTxt

$results | ConvertTo-Json -Depth 10 | Set-Content -Path $outJson -Encoding UTF8

Write-Host ""
Write-Host "Saved:"
Write-Host $outTxt
Write-Host $outJson
Write-Host ""
Write-Host "Summary:"
$results | Group-Object status | Select-Object Name, Count | Format-Table -AutoSize
