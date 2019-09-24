###
#This script will convert whatever is currently inserted into the DVD ROM drive using a built in Handbrake preset,
#and then copy the output file to an internal NAS directory that is used by a Plex Media Server
###
Param (
    [string]$DestinationDirectory
)

#Find DVD drive
$DVDRom = Get-CimInstance -ClassName win32_logicaldisk | Where-Object { $_.DriveType -eq 5 }
$Title = $DVDRom.VolumeName
$Title = $Title -replace '[^\p{L}\p{Nd}/_]', ''
If (!($Title)){Throw "DVD drive is empty"}
$FileName = $Title + ".mp4"
$inputDir = $DVDRom.DeviceID + "\"
$output = "$ENV:USERPROFILE\Downloads\" + $FileName

#Define arguements for handbrake CLI, provide any custom specs here
#Preset: Roku 1080p30 Surround
$Arguments = @"
-i $inputDir -o $output --main-feature --preset="Roku 1080p30 Surround"
"@
$CLIPath = "C:\Program Files\HandBrake\HandBrakeCLI.exe"
If (!(Get-ChildItem -Path $CLIPath)){Throw "Cannot find Handbrake CLI file"}

#Initiating handbrake job
Start-Job -ScriptBlock { param($Arguments, $CLIPath) Start-Process -FilePath $CLIPath -ArgumentList $Arguments -Wait } -Name HandBrake -ArgumentList $Arguments, $CLIPath

#wait for job to complete
Get-Job | Wait-Job

#Upload file to the NAS directory
$NAS = $DestinationDirectory
$Destination = "$NAS" + "$Title"

If (!(Test-Path -Path $Destination)) {
    New-Item -ItemType Directory -Path $NAS -Name $Title | Out-Null
}

If (Get-ChildItem -Path $output){
Write-Output "Copying $output to $Destination..."
Copy-Item -Path $output -Destination $Destination -Force
}
Else {
    Throw "Handbrake failed to produce an output file"
}

If (Get-ChildItem -Path $Destination) {
    Remove-Item -Path $output -Force
}
else {
    Throw "$Output was not copied to the NAS folder"
}

#Eject media
$Diskmaster = New-Object -ComObject IMAPI2.MsftDiscMaster2
$DiskRecorder = New-Object -ComObject IMAPI2.MsftDiscRecorder2
$DiskRecorder.InitializeDiscRecorder($DiskMaster)
$DiskRecorder.EjectMedia()

Get-ScheduledTask -TaskName 'Check-DVDRom' | Start-ScheduledTask