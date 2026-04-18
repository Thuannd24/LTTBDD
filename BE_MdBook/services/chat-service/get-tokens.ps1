param(
    [string]$KeycloakUrl = "http://localhost:8181",
    [string]$Realm = "clinic-realm",
    [string]$ClientId = "clinic-client",
    [string]$ClientSecret = "clinic-client-secret"
)

$testUsers = @(
    @{ username = "alice_test"; password = "alice_test" },
    @{ username = "bob_test"; password = "bob_test" },
    @{ username = "testuser1"; password = "testuser1" }
)

Write-Host "🔐 Keycloak Token Retrieval" -ForegroundColor Cyan
Write-Host "==========================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Keycloak URL: $KeycloakUrl"
Write-Host "Realm: $Realm"
Write-Host "Client: $ClientId"
Write-Host ""
Write-Host "Fetching tokens for test users...`n"

$results = @()

foreach ($user in $testUsers) {
    Write-Host "Getting token for $($user.username)..." -ForegroundColor Yellow
    
    $tokenUrl = "$KeycloakUrl/realms/$Realm/protocol/openid-connect/token"
    $body = @{
        grant_type = "password"
        client_id = $ClientId
        client_secret = $ClientSecret
        username = $user.username
        password = $user.password
        scope = "openid profile email"
    }
    
    try {
        $response = Invoke-WebRequest -Uri $tokenUrl -Method Post -Body $body -ContentType "application/x-www-form-urlencoded" -UseBasicParsing -ErrorAction Stop
        $tokenData = $response.Content | ConvertFrom-Json
        
        Write-Host "✅ Success" -ForegroundColor Green
        $expiresIn = $tokenData.expires_in
        Write-Host ("   Token expires in {0} seconds:" -f $expiresIn)
        $tokenPreview = $tokenData.access_token.Substring(0, 50)
        Write-Host ("   {0}..." -f $tokenPreview)
        Write-Host ""
        
        $results += @{
            username = $user.username
            success = $true
            token = $tokenData.access_token
            expires_in = $expiresIn
        }
    } catch {
        Write-Host "❌ Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Export for environment
Write-Host "`n📝 Environment Variables:" -ForegroundColor Cyan
Write-Host "`nExport these to use tokens in tests:`n"

$results | ForEach-Object {
    if ($_.success) {
        $envName = "$($_.username.ToUpper() -replace '[^A-Z0-9]', '_')_TOKEN"
        Write-Host ('$env:{0} = "{1}"' -f $envName, $_.token)
    }
}

Write-Host "`n💡 Usage:`n" -ForegroundColor Cyan
Write-Host "For PowerShell:"
$results | ForEach-Object {
    if ($_.success) {
        $envName = "$($_.username.ToUpper() -replace '[^A-Z0-9]', '_')_TOKEN"
        Write-Host "`$env:$envName = '$($_.token)'"
    }
}

Write-Host "`nThen run: node test-e2e.js"
