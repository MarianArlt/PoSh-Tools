# Powershell Script to import any copied virtual machines in-place from a specific directory
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

$parent_directory = "C:\_VMs"

# Self elevating Shell
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-File",('"{0}"' -f $MyInvocation.MyCommand.Path) -Verb RunAs
    exit
}

# Inform user about possible incompatibilities
"`n`n  Important!!!`n`n  Make sure that all vNICs configured in the imported`n  machines exist in the targeted Hyper-V environment!!!" | Out-Host
Read-Host "  Press [Enter] to continue"
$total_found = $total_imported = $total_errors = 0

# Loop over all machines found in parent directory and import them in-place
$search_path = Join-Path $parent_directory "*.vmcx"
Get-ChildItem -Path $search_path -Recurse | ForEach-Object {
	$vm_path = $_.FullName
	$vm_guid = $_.Name
	
    try {
		$total_found += 1
		"  Found $vm_path" | Out-Host
        Import-VM $vm_path -ErrorAction Stop | Out-Null
		"  Successfully imported $vm_guid`n" | Out-Host
		$total_imported += 1
		
    } catch {
		$error_message = $_.Exception.Message.Split('.')[1].Trim()
		
		if ($error_message -Match "Compare-VM") {
			$report = Compare-VM -Path $vm_path
			$report = $report.Incompatibilities | Select-Object -ExpandProperty Message
			"  Error: $report`n" | Out-Host
		} else {
			"  Error: $error_message.`n" | Out-Host
		}
        $total_errors += 1
    }
}

# Inform user about script success/failure
$error_string = if ($total_errors -gt 0) { " $total_errors" } else { "out" }
"`n  Finished importing $total_imported of $total_found machines found, with$error_string error(s)." | Out-Host
Read-Host "  Press [Enter] to leave"