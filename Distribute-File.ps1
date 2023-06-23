# Anpassbar:
$net = "172.16.110"
$room = "110"
$monthSuffix = "03"
$amountHosts = "10"

function Open-File([string] $initialDirectory) {
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.InitialDirectory = $initialDirectory
    $OpenFileDialog.Filter = "All files (*.*)| *.*"
    $OpenFileDialog.ShowDialog() | Out-Null

    return $OpenFileDialog.FileName
}

$file = Open-File $env:USERPROFILE

if ($file -ne "") {
    $stop = [int]$amountHosts * 10
    for ($i = 10; $i -le $stop; $i += 10) {
        $ipv4 = "$net.$i"
        $seat = $i.ToString().PadLeft(3,"0")
        $fileExtension = [System.IO.Path]::GetExtension($file)
        if ($fileExtension -eq ".iso") {
            $directory = "_ISOs"
        } elseif ($fileExtension -eq ".vhd" -or $fileExtension -eq ".vhdx") {
            $directory = "_HDs-Main"
        } else {
            $directory = "_tools"
        }
        $destination = "\\R$room-PC$seat-$monthSuffix\c$\$directory"
        try {
            Test-Connection $ipv4 -Count 1 -ErrorAction Stop
            Copy-Item -Path $file -Destination $destination
        } catch {
            Write-Output "$ipv4 konnte nicht erreicht werden."
        }
    }
} else {
    Write-Output "Keine Datei ausgewaehlt."
}