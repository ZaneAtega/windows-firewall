#Requires -RunAsAdministrator

# netstat -ano | findstr LISTENING

@(
    "CDPSvc" # Connected Devices Platform Service
    "FDResPub" # Function Discovery Resource Publication

    "LanmanServer" #  Server
    "srv2"
    "srvnet"

    "SessionEnv" # Remote Desktop Configuration
    "Netlogon"
    "LanmanWorkstation" # Workstation
    "mrxsmb20"

    "Agent"
) | % {
    sc.exe stop $_
    sc.exe config $_ start= disabled
}

# IPv4 > Advanced
Get-WmiObject Win32_NetworkAdapterConfiguration | ? IPEnabled | % {
    $_.SetTcpipNetbios(2)
}

Get-NetFirewallRule -Direction Inbound -Enabled True -Action Allow | Get-NetFirewallApplicationFilter | ? {
    $_.Program -and
    $_.Program -ne "System" -and
    $_.Program -notlike "%SystemRoot%\system32\*" -and
    $_.Program -notlike "C:\Windows\SystemApps\*"
} | % {
    $rule = $_ | Get-NetFirewallRule
    $port = $rule | Get-NetFirewallPortFilter

    [PSCustomObject]@{
        Rule = $rule.DisplayName
        Program = $_.Program
        Protocol = $port.Protocol
        LocalPort = $port.LocalPort
    }
} | Format-Table -AutoSize

Set-NetFirewallProfile -Profile Domain,Private,Public -DefaultOutboundAction Block

$outbound = Get-NetFirewallRule -Direction Outbound | Get-NetFirewallApplicationFilter | Select-Object -ExpandProperty Program

@(
    "C:\Program Files\Google\Chrome\Application\chrome.exe"
    "C:\Program Files\Mozilla Firefox\firefox.exe"

    "E:\Wuthering Waves Game\Client\Binaries\Win64\Client-Win64-Shipping.exe"
    "E:\Wuthering Waves\2.6.5.0\launcher_main.exe"
    "E:\Wuthering Waves\2.6.5.0\launcher_updater.exe"
    "E:\Wuthering Waves\2.6.5.0\KRInstallExternal.exe"
    "E:\Wuthering Waves Game\Client\Binaries\Win64\ThirdParty\KrPcSdk_Global\KRSDKExternal.exe"
    "E:\Wuthering Waves Game\Client\Binaries\Win64\ThirdParty\KrPcSdk_Global\KRSDKRes\KRSDKWebView\KRWebView.exe"
    "E:\Wuthering Waves Game\Client\Binaries\Win64\ThirdParty\KrPcSdk_Global\KRSDKRes\KRSDKUnsupportedVideoWebView\KRWebView.exe"

    "C:\Windows\System32\OpenSSH\ssh.exe"
    "C:\Program Files (x86)\WinSCP\WinSCP.exe"

    "E:\Python\Python311\python.exe"
    "E:\Python\Python311\Lib\site-packages\selenium\webdriver\common\windows\selenium-manager.exe" # python -c "import selenium, os; print(os.path.dirname(selenium.__file__))"

    "E:\Git\mingw64\libexec\git-core\git-remote-https.exe"
    "E:\nodejs\node.exe"
    "E:\xampp\apache\bin\httpd.exe"
    "C:\Program Files (x86)\cloudflared.exe"

    "E:\qBittorrent\qbittorrent.exe"

    "C:\Windows\System32\MRT.exe"

    # nvngx_update.exe NVDisplay.Container.exe REDlauncher.exe REDupdater.exe CapCut.exe VEDetector.exe Agent.exe
) | % {
    if ($outbound -notcontains $_) {
        New-NetFirewallRule -DisplayName "Allow $([IO.Path]::GetFileNameWithoutExtension($_))" -Direction Outbound -Action Allow -Program $_
    }
}

# C:\Windows\System32\LogFiles\Firewall\pfirewall.log
Set-NetFirewallProfile -Profile Domain,Private,Public -LogBlocked True