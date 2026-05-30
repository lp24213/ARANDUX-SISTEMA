<#
deploy_arandux.ps1

Script de ajuda para automatizar os passos de build e deploy do AranduX.

Uso:
1) Abra PowerShell com Node e wrangler disponíveis no PATH.
2) Rode: .\deploy_arandux.ps1

O script NÃO guarda segredos em arquivos. Se você confirmar, ele vai enviar os valores para o `wrangler secret put` (stdin).
#>

function Read-SecureInput([string]$prompt) {
    $secure = Read-Host -AsSecureString -Prompt $prompt
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr) } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

Write-Host "=== ARANDUX DEPLOY HELPER ===" -ForegroundColor Cyan

# checar pré-requisitos
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Error "Node.js não encontrado no PATH. Instale Node e rerun o script."; exit 1
}
if (-not (Get-Command wrangler -ErrorAction SilentlyContinue)) {
    Write-Error "wrangler não encontrado no PATH. Instale o wrangler (npm i -g wrangler) e rerun o script."; exit 1
}

# pegar token Cloudflare - preferir variável de ambiente
if (-not $Env:CF_API_TOKEN) {
    $setToken = Read-Host "Nenhum CF_API_TOKEN encontrado. Deseja inserir um token temporário agora? (y/n)"
    if ($setToken -ieq 'y') {
        $tokenPlain = Read-SecureInput "Cloudflare API token (será mantido apenas na sessão)"
        $Env:CF_API_TOKEN = $tokenPlain
    } else {
        Write-Warning "Sem token CF_API_TOKEN o script não poderá registrar secrets nem publicar. Continuando apenas com build local."
    }
}

### BUILD FRONTEND
Push-Location .\frontend
try {
    Write-Host "Instalando dependências frontend (npm ci)..." -ForegroundColor Yellow
    npm ci
    Write-Host "Construindo frontend (npm run build)..." -ForegroundColor Yellow
    npm run build
    Write-Host "Build finalizado. Artefatos em frontend\dist" -ForegroundColor Green
} catch {
    Write-Error "Erro durante build frontend: $_"; Pop-Location; exit 1
} finally {
    Pop-Location
}

### PUBLISH PAGES
$projName = Read-Host "Nome do projeto Pages (project name). Deixe vazio para pular publicacao Pages"
if ($projName) {
    $confirm = Read-Host "Vai publicar frontend/dist em Pages/$projName agora? (y/n)"
    if ($confirm -ieq 'y') {
        Write-Host "Publicando Pages..." -ForegroundColor Yellow
        wrangler pages publish .\frontend\dist --project-name $projName --branch main
        if ($LASTEXITCODE -ne 0) { Write-Error "Erro ao publicar Pages." }
        else { Write-Host "Pages publicado com sucesso." -ForegroundColor Green }
    } else { Write-Host "Publicação Pages pulada." }
} else { Write-Host "Project name não informado. Pulando publicação Pages." }

### BACKEND / WORKER: registrar secrets e publicar
Push-Location .\backend
try {
    $doWorker = Read-Host "Deseja publicar o Worker backend daqui? (y/n)"
    if ($doWorker -ieq 'y') {
        if (-not $Env:CF_API_TOKEN) { Write-Error "CF_API_TOKEN não definido. Não é possível continuar com secrets/publish."; Pop-Location; exit 1 }

        Write-Host "Vou solicitar os secrets a seguir (pressione Enter para pular um secret):" -ForegroundColor Cyan
    $secrets = @('PAGARME_API_KEY','PAGARME_WEBHOOK_SECRET','DATABASE_URL','DATABASE_TOKEN','JWT_ACCESS_SECRET','JWT_REFRESH_SECRET')
        foreach ($name in $secrets) {
            $val = Read-SecureInput "Valor para $name (Enter para pular)"
            if ($val) {
                Write-Host "Registrando secret $name..." -ForegroundColor Yellow
                # envia o valor via stdin para wrangler secret put
                $pinfo = New-Object System.Diagnostics.ProcessStartInfo
                $pinfo.FileName = 'wrangler'
                $pinfo.Arguments = "secret put $name"
                $pinfo.RedirectStandardInput = $true
                $pinfo.RedirectStandardOutput = $true
                $pinfo.UseShellExecute = $false
                $proc = [System.Diagnostics.Process]::Start($pinfo)
                $proc.StandardInput.Write($val)
                $proc.StandardInput.Close()
                $out = $proc.StandardOutput.ReadToEnd()
                $proc.WaitForExit()
                Write-Host $out
                if ($proc.ExitCode -ne 0) { Write-Warning "wrangler secret put retornou código $($proc.ExitCode) para $name" }
            } else {
                Write-Host "Pulando $name" -ForegroundColor DarkYellow
            }
        }

        # publicar worker
        $confirmPublish = Read-Host "Confirmar publicação do worker agora? (y/n)"
        if ($confirmPublish -ieq 'y') {
            Write-Host "Publicando worker (wrangler deploy)..." -ForegroundColor Yellow
            wrangler deploy --env production
            if ($LASTEXITCODE -ne 0) { Write-Error "Erro ao publicar worker." } else { Write-Host "Worker publicado com sucesso." -ForegroundColor Green }
        } else { Write-Host "Publicação do worker pulada." }
    } else { Write-Host "Publicação do worker pulada conforme solicitado." }
} catch {
    Write-Error "Erro durante operações do backend: $_"; Pop-Location; exit 1
} finally {
    Pop-Location
}

Write-Host "Deploy script finalizado. Verifique painel Cloudflare e logs para confirmar." -ForegroundColor Cyan
