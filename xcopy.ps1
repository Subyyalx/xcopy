# Load necessary assembly
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Initialize form
$form = New-Object System.Windows.Forms.Form
$form.Text = "File Sync Tool"
$form.Size = New-Object System.Drawing.Size(500, 450)
$form.StartPosition = "CenterScreen"

# Source Folders ListBox
$sourceListBox = New-Object System.Windows.Forms.ListBox
$sourceListBox.Size = New-Object System.Drawing.Size(300, 100)
$sourceListBox.Location = New-Object System.Drawing.Point(10, 30)
$form.Controls.Add($sourceListBox)

# Destination Folder TextBox
$destTextBox = New-Object System.Windows.Forms.TextBox
$destTextBox.Size = New-Object System.Drawing.Size(300, 20)
$destTextBox.Location = New-Object System.Drawing.Point(10, 150)
$form.Controls.Add($destTextBox)

# Buttons for adding and removing source folders
$addSourceButton = New-Object System.Windows.Forms.Button
$addSourceButton.Text = "Add Source"
$addSourceButton.Size = New-Object System.Drawing.Size(80, 30)
$addSourceButton.Location = New-Object System.Drawing.Point(320, 30)
$form.Controls.Add($addSourceButton)

$removeSourceButton = New-Object System.Windows.Forms.Button
$removeSourceButton.Text = "Remove Source"
$removeSourceButton.Size = New-Object System.Drawing.Size(100, 30)
$removeSourceButton.Location = New-Object System.Drawing.Point(320, 70)
$form.Controls.Add($removeSourceButton)

# Button to browse destination folder
$browseDestButton = New-Object System.Windows.Forms.Button
$browseDestButton.Text = "Browse Destination"
$browseDestButton.Size = New-Object System.Drawing.Size(130, 30)
$browseDestButton.Location = New-Object System.Drawing.Point(320, 140)
$form.Controls.Add($browseDestButton)

# Button to load JSON configuration
$loadConfigButton = New-Object System.Windows.Forms.Button
$loadConfigButton.Text = "Load Config"
$loadConfigButton.Size = New-Object System.Drawing.Size(100, 30)
$loadConfigButton.Location = New-Object System.Drawing.Point(10, 180)
$form.Controls.Add($loadConfigButton)

# ProgressBar for sync progress
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Size = New-Object System.Drawing.Size(460, 20)
$progressBar.Location = New-Object System.Drawing.Point(10, 220)
$form.Controls.Add($progressBar)

# Start Sync Button
$startSyncButton = New-Object System.Windows.Forms.Button
$startSyncButton.Text = "Start Sync"
$startSyncButton.Size = New-Object System.Drawing.Size(80, 30)
$startSyncButton.Location = New-Object System.Drawing.Point(10, 250)
$form.Controls.Add($startSyncButton)

# TextBox for logging
$logTextBox = New-Object System.Windows.Forms.TextBox
$logTextBox.Multiline = $true
$logTextBox.Size = New-Object System.Drawing.Size(460, 80)
$logTextBox.Location = New-Object System.Drawing.Point(10, 290)
$form.Controls.Add($logTextBox)

# Browse folder function
function Browse-Folder {
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $folderBrowser.SelectedPath
    }
    return $null
}

# Function to load JSON configuration
function Load-Config {
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Filter = "JSON Files (*.json)|*.json"
    if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $configFile = $openFileDialog.FileName
        $config = Get-Content -Path $configFile | ConvertFrom-Json

        # Populate the source and destination fields
        $sourceListBox.Items.Clear()
        foreach ($source in $config.SourceFolders) {
            $sourceListBox.Items.Add($source)
        }
        $destTextBox.Text = $config.DestinationFolder
    }
}

# Event handlers
$addSourceButton.Add_Click({
    $folder = Browse-Folder
    if ($folder) {
        $sourceListBox.Items.Add($folder)
    }
})

$removeSourceButton.Add_Click({
    $selectedItem = $sourceListBox.SelectedItem
    if ($selectedItem) {
        $sourceListBox.Items.Remove($selectedItem)
    }
})

$browseDestButton.Add_Click({
    $folder = Browse-Folder
    if ($folder) {
        $destTextBox.Text = $folder
    }
})

$loadConfigButton.Add_Click({
    Load-Config
})

$startSyncButton.Add_Click({
    $sourceFolders = @()
    foreach ($item in $sourceListBox.Items) {
        $sourceFolders += $item
    }
    
    $destinationFolder = $destTextBox.Text

    if ($sourceFolders.Count -eq 0 -or [string]::IsNullOrEmpty($destinationFolder)) {
        [System.Windows.Forms.MessageBox]::Show("Please add source folders and select a destination")
        return
    }

    # Start Sync Process
    $progressBar.Value = 0
    $logTextBox.AppendText("Starting synchronization..." + [Environment]::NewLine)
    
    foreach ($sourceFolder in $sourceFolders) {
        $destPath = Join-Path -Path $destinationFolder -ChildPath $(Split-Path -Leaf $sourceFolder)
        if (-not (Test-Path $destPath)) {
            New-Item -Path $destPath -ItemType Directory -Force | Out-Null
        }

        # Run Robocopy
        $robocopyCommand = "robocopy `"$sourceFolder`" `"$destPath`" /MIR /R:3 /W:5"
        $logTextBox.AppendText("Running: $robocopyCommand" + [Environment]::NewLine)
        
        try {
            $result = Invoke-Expression $robocopyCommand
            $progressBar.Value += (100 / $sourceFolders.Count)
            $logTextBox.AppendText($result + [Environment]::NewLine)
        } catch {
            $logTextBox.AppendText("Error: $($_.Exception.Message)" + [Environment]::NewLine)
        }
    }
    
    $logTextBox.AppendText("Synchronization complete." + [Environment]::NewLine)
})

# Show the form
$form.Add_Shown({$form.Activate()})
[void]$form.ShowDialog()
