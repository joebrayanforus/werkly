$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path $PSScriptRoot -Parent
$androidRoot = Join-Path $projectRoot 'android'
$secretPath = Join-Path $androidRoot 'upload-key-password.dpapi'
$keystorePath = Join-Path $androidRoot 'upload-keystore.jks'
$localPropertiesPath = Join-Path $androidRoot 'local.properties'

if (-not (Test-Path -LiteralPath $secretPath)) {
    throw 'Secret de signature absent. La clé doit être créée avant la compilation.'
}

if (-not (Test-Path -LiteralPath $keystorePath)) {
    throw 'Clé de signature absente. Restaure android/upload-keystore.jks.'
}

$securePassword = Get-Content -LiteralPath $secretPath | ConvertTo-SecureString
$passwordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)

try {
    $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($passwordPointer)
    $env:WERKLY_UPLOAD_STORE_PASSWORD = $plainPassword
    $env:WERKLY_UPLOAD_KEY_PASSWORD = $plainPassword
    $env:WERKLY_UPLOAD_KEY_ALIAS = 'upload'

    $flutterLine = Select-String -LiteralPath $localPropertiesPath -Pattern '^flutter\.sdk=' | Select-Object -First 1
    if ($null -eq $flutterLine) {
        throw 'Chemin Flutter absent de android/local.properties.'
    }
    $flutterSdk = $flutterLine.Line.Substring('flutter.sdk='.Length).Replace('\\', '\')
    $flutterCommand = Join-Path $flutterSdk 'bin\flutter.bat'
    $flutterArguments = @('build', 'appbundle', '--release', '--no-pub')

    Push-Location $projectRoot
    try {
        & $flutterCommand @flutterArguments
        if ($LASTEXITCODE -ne 0) {
            throw "La compilation Android a échoué avec le code $LASTEXITCODE."
        }
    }
    finally {
        Pop-Location
    }
}
finally {
    $env:WERKLY_UPLOAD_STORE_PASSWORD = $null
    $env:WERKLY_UPLOAD_KEY_PASSWORD = $null
    $env:WERKLY_UPLOAD_KEY_ALIAS = $null
    if ($passwordPointer -ne [IntPtr]::Zero) {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPointer)
    }
}
