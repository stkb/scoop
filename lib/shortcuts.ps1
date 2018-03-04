# Creates start menu shortcuts defined in the manifest
function create_startmenu_shortcuts($manifest, $dir, $global, $arch) {

    $shortcuts = @(arch_specific 'shortcuts' $manifest $arch)

    foreach($shortcutDef in $shortcuts) {
        $targetLeaf, $name, $arguments, $iconLeaf, $ignore = $shortcutDef
        $err = & {
            if(-not $targetLeaf) { "No target given" }
            elseif(-not $name) { "'$targetLeaf': No name given" }
        }
        if($err) {
            error "Error in shortcut in manifest: $err"
        }
        else {
            $err = startmenu_shortcut "$dir\$targetLeaf" $name $arguments "$dir\$iconLeaf" $global
            if($err) {
                error "Creating shortcut '$name': $err"
            }
            else {
                Write-Output "Created shortcut '$name' ($targetLeaf)"
            }
        }
    }
}

function shortcut_folder($global) {
    $envFolder = &{ if($global) { 'commonstartmenu' } else { 'startmenu' } }
    $directory = join-path ([Environment]::GetFolderPath($envFolder)) 'Programs\Scoop Apps'

    return $(ensure $directory)
}


# Creates a start menu shortcut, checking all arguments
# Returns nothing if successful, or an error message in an error occured
function startmenu_shortcut([string] $target, [string] $shortcutName, [string] $arguments, [string] $icon, $global) {
    if(-not (test-path -pathType leaf $target)) {
        "'$target' doesn't exist"
    }
    elseif($icon -and -not (test-path -pathType leaf $icon)) {
        "Icon file '$icon' doesn't exist"
    }
    else {
        $shortcutFile = join-path (shortcut_folder $global) "$shortcutName.lnk"
        ensure (split-path -parent $shortcutFile) > $null
        $workingDir = split-path -parent $target

        if($target.EndsWith('.jar')) {
            $arguments = "-jar `"$target`" " + $arguments
            $target = 'javaw.exe'
        }

        $wsShell = New-Object -ComObject WScript.Shell
        $shortcut = $wsShell.CreateShortcut($shortcutFile)
        $shortcut.TargetPath = $target
        $shortcut.WorkingDirectory = $workingDir
        if($arguments) { $shortcut.Arguments = $arguments }
        if($icon) { $shortcut.IconLocation = $icon }
        $shortcut.Save()
    }
}

# Removes the Startmenu shortcut if it exists
function rm_startmenu_shortcuts($manifest, $global, $arch) {
    $shortcuts = @(arch_specific 'shortcuts' $manifest $arch)
    $shortcuts | Where-Object { $_ -ne $null } | ForEach-Object {
        $name = $_.item(1)
        $shortcut = "$(shortcut_folder $global)\$name.lnk"
        write-host "Removing shortcut $(friendly_path $shortcut)"
        if(Test-Path -Path $shortcut) {
             Remove-Item $shortcut
        }
        # Before issue 1514 Startmenu shortcut removal
        #
        # Shortcuts that should have been installed globally would
        # have been installed locally up until 27 June 2017.
        #
        # TODO: Remove this 'if' block and comment after
        #       27 June 2018.
        if($global) {
            $shortcut = "$(shortcut_folder $false)\$name.lnk"
            if(Test-Path -Path $shortcut) {
                 Remove-Item $shortcut
            }
        }
    }
}
