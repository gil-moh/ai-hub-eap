# AI Hub Smart Summary Runbook

This runbook captures the working command sequence validated in this workspace.

## Contest Submission Quick Start

Use this section for evaluator-friendly verification.

1. Start containers:

```powershell
$docker = "C:\Program Files\Docker\Docker\resources\bin\docker.exe"
& $docker start iris_fhir iris-ai-hub-162
```

2. Compile latest classes and run one all-roles narrative sample:

```powershell
$docker = "C:\Program Files\Docker\Docker\resources\bin\docker.exe"
& $docker exec iris-ai-hub-162 sh -lc "mkdir -p /tmp/aihub/Sample/AI/Tools /tmp/aihub/Sample/AI/ToolSet /tmp/aihub/Sample/AI/Examples"
& $docker cp C:\Projects\FHIR\ai-hub-eap\objectscript\cls\Sample\AI\Tools\FHIRReadOnly.cls iris-ai-hub-162:/tmp/aihub/Sample/AI/Tools/FHIRReadOnly.cls
& $docker cp C:\Projects\FHIR\ai-hub-eap\objectscript\cls\Sample\AI\ToolSet\FHIRReadOnly.cls iris-ai-hub-162:/tmp/aihub/Sample/AI/ToolSet/FHIRReadOnly.cls
& $docker cp C:\Projects\FHIR\ai-hub-eap\objectscript\cls\Sample\AI\Examples\FHIRSummary.cls iris-ai-hub-162:/tmp/aihub/Sample/AI/Examples/FHIRSummary.cls

$script = @'
zn "USER"
do $system.OBJ.ImportDir("/tmp/aihub/Sample/AI/Tools","*.cls","ck")
do $system.OBJ.ImportDir("/tmp/aihub/Sample/AI/ToolSet","*.cls","ck")
do $system.OBJ.ImportDir("/tmp/aihub/Sample/AI/Examples","*.cls","ck")
set ^||ENV("FHIR_BASE_URL")="http://host.docker.internal:52773/fhir/r4"
set ^||ENV("FHIR_BASIC_USER")="_SYSTEM"
set ^||ENV("FHIR_BASIC_PASS")="SYS"
do ##class(Sample.AI.Examples.FHIRSummary).DemoNarrativeAllRoles("demo-rich-003","detailed")
halt
'@
Set-Content -Path C:\Projects\FHIR\ai-hub-eap\tmp_contest_quickstart.mac -Value $script -NoNewline
& $docker cp C:\Projects\FHIR\ai-hub-eap\tmp_contest_quickstart.mac iris-ai-hub-162:/tmp/aihub/tmp_contest_quickstart.mac
& $docker exec iris-ai-hub-162 sh -lc "iris session IRIS < /tmp/aihub/tmp_contest_quickstart.mac"
```

3. Expected confirmation in output:

- Example - Smart Patient Summary
- Summary for ED Doctor
- Summary for Care Manager
- Summary for Patient
- Summary for Family Caregiver

## Contest Packaging Checklist

- Keep [README.md](README.md) updated with:
  - idea link
  - team members (if team submission)
  - video link or equivalent detailed behavior description
  - installation and run steps
- Ensure repository remains open source and publicly accessible before Open Exchange submission.
- Confirm no private credentials are committed.
- Confirm submission count limit per developer is respected.

## Fast Path (Daily Use)

Run in PowerShell from `C:\Projects\FHIR`:

```powershell
$docker = "C:\Program Files\Docker\Docker\resources\bin\docker.exe"
& $docker start iris_fhir iris-ai-hub-162
& $docker exec iris-ai-hub-162 sh -lc "mkdir -p /tmp/aihub/Sample/AI/Tools /tmp/aihub/Sample/AI/ToolSet /tmp/aihub/Sample/AI/Examples"
& $docker cp C:\Projects\FHIR\ai-hub-eap\objectscript\cls\Sample\AI\Tools\FHIRReadOnly.cls iris-ai-hub-162:/tmp/aihub/Sample/AI/Tools/FHIRReadOnly.cls
& $docker cp C:\Projects\FHIR\ai-hub-eap\objectscript\cls\Sample\AI\ToolSet\FHIRReadOnly.cls iris-ai-hub-162:/tmp/aihub/Sample/AI/ToolSet/FHIRReadOnly.cls
& $docker cp C:\Projects\FHIR\ai-hub-eap\objectscript\cls\Sample\AI\Examples\FHIRSummary.cls iris-ai-hub-162:/tmp/aihub/Sample/AI/Examples/FHIRSummary.cls

$script = @'
zn "USER"
do $system.OBJ.ImportDir("/tmp/aihub/Sample/AI/Tools","*.cls","ck")
do $system.OBJ.ImportDir("/tmp/aihub/Sample/AI/ToolSet","*.cls","ck")
do $system.OBJ.ImportDir("/tmp/aihub/Sample/AI/Examples","*.cls","ck")
set ^||ENV("FHIR_BASE_URL")="http://host.docker.internal:52773/fhir/r4"
set ^||ENV("FHIR_BASIC_USER")="_SYSTEM"
set ^||ENV("FHIR_BASIC_PASS")="SYS"
do ##class(Sample.AI.Examples.FHIRSummary).DemoDeterministic("a3d599da-a9de-8caa-950a-6bc057b1b261","ed","brief")
halt
'@

Set-Content -Path C:\Projects\FHIR\ai-hub-eap\tmp_fastpath.mac -Value $script -NoNewline
& $docker cp C:\Projects\FHIR\ai-hub-eap\tmp_fastpath.mac iris-ai-hub-162:/tmp/aihub/tmp_fastpath.mac
& $docker exec iris-ai-hub-162 sh -lc "iris session IRIS < /tmp/aihub/tmp_fastpath.mac"
```

Expected quick check:

- Demo prints `=== Smart Patient Summary (Chunk 1) ===` and JSON output.

## 1) Prerequisites

- Docker Desktop running
- Image tar file exists:
  - `C:\Users\gil.tavassy\Downloads\iris-community-2026.2.0AI.162.0-docker.tar.gz`
- License key exists:
  - `C:\Users\gil.tavassy\Downloads\iris-container-x64.key`
- Workspace root:
  - `C:\Projects\FHIR`

## 2) Load AI Image

Run in PowerShell:

```powershell
$docker = "C:\Program Files\Docker\Docker\resources\bin\docker.exe"
& $docker image load -i C:\Users\gil.tavassy\Downloads\iris-community-2026.2.0AI.162.0-docker.tar.gz
& $docker image ls --no-trunc --format "table {{.Repository}}`t{{.Tag}}`t{{.ID}}" | Select-String -Pattern "2026\.2\.0AI|docker\.iscinternal"
```

Expected image tag:

- `docker.iscinternal.com/docker-intersystems/intersystems/iris-community:2026.2.0AI.162.0`

## 3) Start Containers

### 3.1 FHIR data container

```powershell
$docker = "C:\Program Files\Docker\Docker\resources\bin\docker.exe"
& $docker start iris_fhir
```

### 3.2 AI runtime container

```powershell
$docker = "C:\Program Files\Docker\Docker\resources\bin\docker.exe"
$name = "iris-ai-hub-162"
$img = "docker.iscinternal.com/docker-intersystems/intersystems/iris-community:2026.2.0AI.162.0"
$keyDir = "C:\Users\gil.tavassy\Downloads"

if((& $docker ps -a --format "{{.Names}}" | Select-String -SimpleMatch $name)){
  & $docker rm -f $name | Out-Null
}

& $docker run --name $name -d -p 3972:1972 -p 62774:52773 --volume "${keyDir}:/external/keys" $img -k /external/keys/iris-container-x64.key
& $docker ps --filter "name=$name" --format "table {{.Names}}`t{{.Status}}`t{{.Ports}}"
```

## 4) Verify AI SDK Availability

```powershell
$docker = "C:\Program Files\Docker\Docker\resources\bin\docker.exe"
$probe = @'
zn "%SYS"
write "%AI.Tool exists=",##class(%Dictionary.ClassDefinition).%ExistsId("%AI.Tool"),!
set stmt=##class(%SQL.Statement).%New()
set sc=stmt.%Prepare("SELECT COUNT(*) AS C FROM %Dictionary.ClassDefinition WHERE Name %STARTSWITH '%AI.'")
set r=stmt.%Execute() do r.%Next() write "AI_CLASS_COUNT_SQL=",r.%Get("C"),!
halt
'@
Set-Content -Path C:\Projects\FHIR\ai-hub-eap\tmp_ai_probe.mac -Value $probe -NoNewline
& $docker exec iris-ai-hub-162 sh -lc "mkdir -p /tmp/aihub"
& $docker cp C:\Projects\FHIR\ai-hub-eap\tmp_ai_probe.mac iris-ai-hub-162:/tmp/aihub/tmp_ai_probe.mac
& $docker exec iris-ai-hub-162 sh -lc "iris session IRIS < /tmp/aihub/tmp_ai_probe.mac"
```

Expected:

- `%AI.Tool exists=1`
- `AI_CLASS_COUNT_SQL` is non-zero

## 5) Compile and Run Smart Summary

```powershell
$docker = "C:\Program Files\Docker\Docker\resources\bin\docker.exe"

& $docker exec iris-ai-hub-162 sh -lc "mkdir -p /tmp/aihub/Sample/AI/Tools /tmp/aihub/Sample/AI/ToolSet /tmp/aihub/Sample/AI/Examples"
& $docker cp C:\Projects\FHIR\ai-hub-eap\objectscript\cls\Sample\AI\Tools\FHIRReadOnly.cls iris-ai-hub-162:/tmp/aihub/Sample/AI/Tools/FHIRReadOnly.cls
& $docker cp C:\Projects\FHIR\ai-hub-eap\objectscript\cls\Sample\AI\ToolSet\FHIRReadOnly.cls iris-ai-hub-162:/tmp/aihub/Sample/AI/ToolSet/FHIRReadOnly.cls
& $docker cp C:\Projects\FHIR\ai-hub-eap\objectscript\cls\Sample\AI\Examples\FHIRSummary.cls iris-ai-hub-162:/tmp/aihub/Sample/AI/Examples/FHIRSummary.cls

$script = @'
zn "USER"
do $system.OBJ.ImportDir("/tmp/aihub/Sample/AI/Tools","*.cls","ck")
do $system.OBJ.ImportDir("/tmp/aihub/Sample/AI/ToolSet","*.cls","ck")
do $system.OBJ.ImportDir("/tmp/aihub/Sample/AI/Examples","*.cls","ck")
set ^||ENV("FHIR_BASE_URL")="http://host.docker.internal:52773/fhir/r4"
set ^||ENV("FHIR_BASIC_USER")="_SYSTEM"
set ^||ENV("FHIR_BASIC_PASS")="SYS"
write !,"-- DemoDeterministic (ed, brief) --",!
do ##class(Sample.AI.Examples.FHIRSummary).DemoDeterministic("a3d599da-a9de-8caa-950a-6bc057b1b261","ed","brief")
write !,"-- DemoDeterministic (care_manager, detailed) --",!
do ##class(Sample.AI.Examples.FHIRSummary).DemoDeterministic("a3d599da-a9de-8caa-950a-6bc057b1b261","care_manager","detailed")
write !,"-- DemoRoleComparison (brief) --",!
do ##class(Sample.AI.Examples.FHIRSummary).DemoRoleComparison("a3d599da-a9de-8caa-950a-6bc057b1b261","brief")
halt
'@
Set-Content -Path C:\Projects\FHIR\ai-hub-eap\tmp_runverify_162.mac -Value $script -NoNewline
& $docker cp C:\Projects\FHIR\ai-hub-eap\tmp_runverify_162.mac iris-ai-hub-162:/tmp/aihub/runverify_162.mac
& $docker exec iris-ai-hub-162 sh -lc "iris session IRIS < /tmp/aihub/runverify_162.mac"
```

## 6) Quick Health Checks

```powershell
$docker = "C:\Program Files\Docker\Docker\resources\bin\docker.exe"
& $docker ps --format "table {{.Names}}`t{{.Status}}`t{{.Ports}}"
& $docker logs --tail 120 iris-ai-hub-162
```

## 7) Known Notes

- The AI runtime in this runbook is isolated on ports `3972` and `62774`.
- FHIR data source remains on `1972` and `52773` via `iris_fhir`.
- `FHIR_BASE_URL` from AI container uses host access to FHIR container:
  - `http://host.docker.internal:52773/fhir/r4`
- If `docker image load` hangs, restart Docker Desktop and ensure enough memory is allocated.
