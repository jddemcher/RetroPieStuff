###
#This script will convert whatever is currently inserted into the DVD ROM drive using a built in Handbrake preset
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
$output = "$DestinationDirectory\" + $FileName

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

#Eject media
$Diskmaster = New-Object -ComObject IMAPI2.MsftDiscMaster2
$DiskRecorder = New-Object -ComObject IMAPI2.MsftDiscRecorder2
$DiskRecorder.InitializeDiscRecorder($DiskMaster)
$DiskRecorder.EjectMedia()

Get-ScheduledTask -TaskName 'Check-DVDRom' | Start-ScheduledTask