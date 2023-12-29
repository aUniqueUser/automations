# Creates a tempoary working dir
New-TemporaryFile | %{ rm $_; mkdir $_; cd $_; }

Expand-Archive -Path .\CrystalDiskInfoPortable.zip