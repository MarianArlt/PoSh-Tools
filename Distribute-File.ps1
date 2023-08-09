# Powershell Script to copy a single file to multiple remote hosts for use in a specific educational environment
# Copyright (C) 2023  Marian Arlt
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

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