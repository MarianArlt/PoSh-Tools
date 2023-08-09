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
[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null

# variables
$room = "110"
$suffix = "03"
$hosts = "10"

"`n`n  This script copies a single file to multiple remote hosts`n  where the format of the targeted resources is of:`n      R<Room>-PC###-<Suffix>`n" | Out-Host
if (!($r = Read-Host "  Provide room or press [Enter] to accept '110'")) { $r = $room }
if (!($s = Read-Host "  Provide suffix or press [Enter] to accept '03'")) { $s = $suffix }
if (!($h = Read-Host "  Provide number of remote hosts in total or press [Enter] to accept '10'")) { $h = $hosts }
"`n  File will be copied to $h hosts of format:`n      R$r-PC###-$s`n  starting with R$r-PC010-$s in increments of 10.`n" | Out-Host

$net = "172.16.$r"

# user GUI file picker function
Read-Host "  Press [Enter] to choose a file for distribution"
function Open-File([string] $initialDirectory) {
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
$sub = Read-Host @"
  The following file will be queued for distribution:
      $file

  Target destination on remote hosts:
      C:\$directory

  Provide additional sub directories or hit [Enter]
"@

if ($file -ne "") {
    $stop = [int]$h * 10

    for ($i = 10; $i -le $stop; $i += 10) {
        $ipv4 = "$net.$i"
        $seat = $i.ToString().PadLeft(3,"0")
        $destination = Join-Path "\\R$r-PC$seat-$s" "C$" $directory $sub

        try {
            Test-Connection $ipv4 -Count 1 -ErrorAction Stop
            Copy-Item -Path $file -Destination $destination
        } catch {
            "  Could not reach $ipv4" | Out-Host
        }
    }
} else {
    Read-Host "  No file chosen. Exiting script"
}