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

# variables
$net = "172.16.110"
$room = "110"
$monthSuffix = "03"
$amountHosts = "10"

# user GUI file picker function
Read-Host "`n`n  Press [Enter] to choose a file for distribution"
function Open-File([string] $initialDirectory) {
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.InitialDirectory = $initialDirectory
    $OpenFileDialog.Filter = "All files (*.*)| *.*"
    $OpenFileDialog.ShowDialog() | Out-Null

    return $OpenFileDialog.FileName
}
# file picker function call
$file = Open-File $env:USERPROFILE

# choose resource by file extension
$fileExtension = [System.IO.Path]::GetExtension($file)
if ($fileExtension -eq ".iso") {
    $directory = "_ISOs"
} elseif ($fileExtension -eq ".vhd" -or $fileExtension -eq ".vhdx") {
    $directory = "_HDs-Main"
} else {
    $directory = "_tools"
}

# prompt for sub directory
$subDir = Read-Host "  Do you want to place the file in a sub directory?`nThe file will currently be placed in C:\$directory on the remote hosts.`nPress [Enter] to provide a name or [n] to decline"

if ($file -ne "") {
    $stop = [int]$amountHosts * 10

    for ($i = 10; $i -le $stop; $i += 10) {
        $ipv4 = "$net.$i"
        $seat = $i.ToString().PadLeft(3,"0")

        $destination = Join-Path "R$room-PC$seat-$monthSuffix" "C$" $directory $subDir

        try {
            Test-Connection $ipv4 -Count 1 -ErrorAction Stop
            Copy-Item -Path $file -Destination "\\$destination"
        } catch {
            "  Could not reach $ipv4" | Out-Host
        }
    }
} else {
    Read-Host "  No file chosen. Exiting script"
}