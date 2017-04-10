echo %1

C:\project-open\bin\bash.exe -l -c "echo '%1' | tr '\\' '/' | xargs /installer/project_open_installer_upload.bash"

exit 0

