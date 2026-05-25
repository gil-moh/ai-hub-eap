# Smart Patient Summary Runtime Checklist

This project now includes Smart Patient Summary logic in:
- `objectscript/cls/Sample/AI/Tools/FHIRReadOnly.cls`
- `objectscript/cls/Sample/AI/ToolSet/FHIRReadOnly.cls`
- `objectscript/cls/Sample/AI/Examples/FHIRSummary.cls`

The classes depend on `%AI.*`, so they must run on an AI Hub-enabled IRIS runtime.

## 1) Load and run AI Hub container

1. Download an AI Hub docker image tarball from the EAP portal.
2. Load image:

```powershell
docker image load -i C:\path\to\iris-community-2026.2.0AI.xxx.0-docker.tar.gz
```

3. Start container (adjust image tag to your loaded one):

```powershell
docker run --name iris-ai-hub -d -p 1973:1972 -p 52774:52773 docker.iscinternal.com/docker-intersystems/intersystems/iris-community:2026.2.0AI.xxx.0
```

## 2) Copy classes into AI Hub container

```powershell
docker exec iris-ai-hub sh -lc "mkdir -p /tmp/aihub/Sample/AI/Tools /tmp/aihub/Sample/AI/ToolSet /tmp/aihub/Sample/AI/Examples"
docker cp objectscript/cls/Sample/AI/Tools/FHIRReadOnly.cls iris-ai-hub:/tmp/aihub/Sample/AI/Tools/FHIRReadOnly.cls
docker cp objectscript/cls/Sample/AI/ToolSet/FHIRReadOnly.cls iris-ai-hub:/tmp/aihub/Sample/AI/ToolSet/FHIRReadOnly.cls
docker cp objectscript/cls/Sample/AI/Examples/FHIRSummary.cls iris-ai-hub:/tmp/aihub/Sample/AI/Examples/FHIRSummary.cls
```

## 3) Compile classes in USER namespace

Open an IRIS terminal:

```powershell
docker exec -it iris-ai-hub iris session IRIS
```

Then run:

```objectscript
zn "USER"
do $system.OBJ.ImportDir("/tmp/aihub/Sample/AI/Tools","*.cls","ck")
do $system.OBJ.ImportDir("/tmp/aihub/Sample/AI/ToolSet","*.cls","ck")
do $system.OBJ.ImportDir("/tmp/aihub/Sample/AI/Examples","*.cls","ck")
```

## 4) Point summary tool to local FHIR test server

If your local FHIR test server is on host port `52773`, set process-private env values in IRIS:

```objectscript
set ^||ENV("FHIR_BASE_URL")="http://host.docker.internal:52773/fhir/r4"
set ^||ENV("FHIR_BASIC_USER")="_SYSTEM"
set ^||ENV("FHIR_BASIC_PASS")="SYS"
```

## 5) Run deterministic demos

```objectscript
// Single role
Do ##class(Sample.AI.Examples.FHIRSummary).DemoDeterministic("a3d599da-a9de-8caa-950a-6bc057b1b261", "ed", "brief")

// Detailed care manager view
Do ##class(Sample.AI.Examples.FHIRSummary).DemoDeterministic("a3d599da-a9de-8caa-950a-6bc057b1b261", "care_manager", "detailed")

// Compare all roles
Do ##class(Sample.AI.Examples.FHIRSummary).DemoRoleComparison("a3d599da-a9de-8caa-950a-6bc057b1b261", "brief")
```

## 6) Quick troubleshooting

- `%AI.* class does not exist`: you are not on an AI Hub-enabled IRIS image.
- `401 Unauthorized`: verify `FHIR_BASIC_USER` / `FHIR_BASIC_PASS`.
- Cannot reach FHIR host from container: use `host.docker.internal` rather than `localhost`.
- Empty bundles for some resources: expected for sparse demo patients; summary handles missing sections.
