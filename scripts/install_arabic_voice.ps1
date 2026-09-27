# Installs a Windows Arabic text-to-speech voice, so Nova (in Chrome, Edge or the
# Windows app) can read questions aloud in Arabic. Nova never reads Arabic with an
# English voice; without an Arabic voice installed, Arabic stays silent.
#
# Needs administrator rights: run it and accept the Windows prompt. Afterwards,
# close every browser window and open Nova again (browsers list voices at start).
#
# Undo: Settings > Time & language > Speech > Manage voices > remove the Arabic voice,
# or Remove-WindowsCapability -Online -Name <the name printed below>.

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

Write-Host "Looking for Arabic text-to-speech voices from Windows Update..."
$available = Get-WindowsCapability -Online | Where-Object { $_.Name -like 'Language.TextToSpeech~~~ar-*' }
if (-not $available) {
    Write-Host "No Arabic voice is offered for this Windows edition. Use Microsoft Edge (it has Arabic voices) instead."
    Read-Host "Press Enter to close"
    exit 1
}

# Saudi Arabic first (Modern Standard Arabic), then Egyptian, then any other.
$ordered = @($available | Sort-Object { if ($_.Name -like '*ar-SA*') { 0 } elseif ($_.Name -like '*ar-EG*') { 1 } else { 2 } })
$chosen = $ordered[0]
if ($chosen.State -eq 'Installed') {
    Write-Host "Already installed: $($chosen.Name)"
} else {
    Write-Host "Installing $($chosen.Name) (a few minutes)..."
    Add-WindowsCapability -Online -Name $chosen.Name | Out-Null
    Write-Host "Installed: $($chosen.Name)"
}

Write-Host ""
Write-Host "Arabic voices now on this PC:"
Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Speech_OneCore\Voices\Tokens" | ForEach-Object { (Get-ItemProperty $_.PSPath).'(default)' } | Where-Object { $_ -match 'Arabic' }
Write-Host ""
Write-Host "Now close ALL browser windows and open Nova again."
Read-Host "Press Enter to close"
