@echo off
setlocal

set "MAVEN_VERSION=3.9.9"
set "WRAPPER_ROOT=%USERPROFILE%\.m2\wrapper\dists\apache-maven-%MAVEN_VERSION%"
set "MAVEN_HOME=%WRAPPER_ROOT%\apache-maven-%MAVEN_VERSION%"
set "MAVEN_CMD=%MAVEN_HOME%\bin\mvn.cmd"

if not exist "%MAVEN_CMD%" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $version='%MAVEN_VERSION%'; $root='%WRAPPER_ROOT%'; $url='https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/' + $version + '/apache-maven-' + $version + '-bin.zip'; $zip=Join-Path $env:TEMP ('apache-maven-' + $version + '-bin.zip'); New-Item -ItemType Directory -Force -Path $root | Out-Null; Invoke-WebRequest -Uri $url -OutFile $zip; Expand-Archive -Path $zip -DestinationPath $root -Force"
    if errorlevel 1 exit /b %errorlevel%
)

"%MAVEN_CMD%" %*
exit /b %errorlevel%
