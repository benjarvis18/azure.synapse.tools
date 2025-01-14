<#
.SYNOPSIS
Creates an instance of objects with options for publishing Synapse Workspace.

.DESCRIPTION
Creates an instance of objects with options for publishing Synapse Workspace.
Use it if you want specify particular behaviour during publish operation.

.PARAMETER FilterFilePath
Optional path to file which contains all filtering rules in multiline file (one line per rule).
When provided, the function adds items to appropriate array (Includes or Excludes).
Do use + or - character as a prefix of name to control where the rule should be added to.

.EXAMPLE
$opt = New-SynapsePublishOption
$opt.Includes.Add("pipeline.Copy*", "")
$opt.DeleteNotInSource = $false
Publish-SynapseFromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -SynapseWorkspaceName "$SynapseWorkspaceName" -Location "$Location" -Stage "UAT" -Option $opt

.EXAMPLE
$opt = New-SynapsePublishOption
$opt.DeleteNotInSource = $false
$opt.StopStartTriggers = $false
Publish-SynapseFromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -SynapseWorkspaceName "$SynapseWorkspaceName" -Location "$Location" -Stage "UAT" -Option $opt

.EXAMPLE
$opt = New-SynapsePublishOption -FilterFilePath ".\deployment\rules.txt"
Publish-SynapseFromJson -RootFolder "$RootFolder" -ResourceGroupName "$ResourceGroupName" -SynapseWorkspaceName "$SynapseWorkspaceName" -Location "$Location" -Stage "UAT" -Option $opt

.LINK
Online version: https://github.com/SQLPlayer/azure.synapse.tools/
#>
function New-SynapsePublishOption {
    [CmdletBinding()]
    param (   
        [parameter(Mandatory = $false)] 
        [String] $FilterFilePath
    )

    $opt = New-Object -TypeName SynapsePublishOption

    if (![string]::IsNullOrWhitespace($FilterFilePath)) {
        Write-Verbose "Loading rules for selective deployment from file '$FilterFilePath'..."
        if ($false -eq (Test-Path -Path $FilterFilePath)) {
            Write-Error "File does not exist: $FilterFilePath"
        }
        $FilterText = Get-Content -Path $FilterFilePath -Encoding "UTF8"

        $FilterArray = $FilterText.Replace(',', "`n").Replace("`r`n", "`n").Split("`n");

        # Include/Exclude options
        $FilterArray | Where-Object { ($_.Trim().Length -gt 0 -or $_.Trim().StartsWith('+')) -and (!$_.Trim().StartsWith('-')) } | ForEach-Object {
            $i = $_.Trim().Replace('+', '')
            Write-Verbose "- Include: $i"
            $opt.Includes.Add($i, "");
        }
        Write-Host "$($opt.Includes.Count) rule(s)/object(s) added to be included in deployment."
        
        $FilterArray | Where-Object { $_.Trim().StartsWith('-') } | ForEach-Object {
            $e = $_.Trim().Substring(1)
            Write-Verbose "- Exclude: $e"
            $opt.Excludes.Add($e, "");
        }
        Write-Host "$($opt.Excludes.Count) rule(s)/object(s) added to be excluded from deployment."
    }

    return $opt
}
