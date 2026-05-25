# Smart Patient Summary Agent for FHIR (Contest Submission)

This repository contains a contest submission for InterSystems Programming Contest: AI Agents for FHIR.

## Contest Submission Details

- Contest: InterSystems Programming Contest: AI Agents for FHIR
- Category fit: AI agent used in an interoperability FHIR solution
- Open source repository: this repository
- Primary implementation language: ObjectScript (with supporting Python test-data tooling)

## Idea Link

- Idea page: TODO add your idea or Open Exchange idea link here

## Team

- Team lead: Gil Tavassy (InterSystems Developer Community profile: https://community.intersystems.com/user/gil-tavassy)
- LinkedIn: https://www.linkedin.com/in/gil-tavassy-5703b311b

Submission mode: solo project.

## What This App Does

Smart Patient Summary Agent generates role-specific clinical summaries over FHIR data for:

- ED Doctor
- Care Manager
- Patient
- Family Caregiver

The output is deterministic, evidence-based, and formatted as actionable narrative sections:

- Patient Overview
- Clinical Details (conditions, medications, allergies, encounters, observations, care plans)
- Current Issues
- Recent Changes
- Risks / Follow-up
- Role-specific action plan

## Originality and Significant Improvement

This submission provides a concrete, working FHIR-focused agent workflow rather than a generic chat wrapper.
Key differentiators:

- Role-specific narrative adaptation from the same FHIR evidence set
- Deterministic summary generation for reproducible judging
- Clinical-detail extraction that surfaces medication names, allergy details, encounter reasons, and inactive-condition timelines
- Full-evidence mode without hidden truncation, to keep review transparent
- Rich synthetic profile generator for realistic scenario testing (demo-rich-002 to demo-rich-005)

## Installation and Run (Quick Path)

Detailed steps are in [RUNBOOK.md](RUNBOOK.md). Quick path (PowerShell, Windows):

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
do ##class(Sample.AI.Examples.FHIRSummary).DemoNarrativeAllRoles("demo-rich-003","detailed")
halt
'@

Set-Content -Path C:\Projects\FHIR\ai-hub-eap\tmp_contest_demo.mac -Value $script -NoNewline
& $docker cp C:\Projects\FHIR\ai-hub-eap\tmp_contest_demo.mac iris-ai-hub-162:/tmp/aihub/tmp_contest_demo.mac
& $docker exec iris-ai-hub-162 sh -lc "iris session IRIS < /tmp/aihub/tmp_contest_demo.mac"
```

Expected result:

- Narrative output printed for all roles with populated clinical details

## Demo Profiles

Additional realistic test profiles can be generated with:

```powershell
c:/Projects/FHIR/.venv/Scripts/python.exe C:/Projects/FHIR/FHIR_TestServer/create_rich_demo_profiles.py
```

Available profile IDs:

- demo-rich-002
- demo-rich-003
- demo-rich-004
- demo-rich-005

## Detailed Behavior Description (No Video Required)

This submission uses a detailed written behavior description instead of a demo video.
The README and [RUNBOOK.md](RUNBOOK.md) provide reproducible commands and expected outputs for evaluator verification.

## Contest Compliance Checklist

- Fully functional application or library: yes
- Original work / significant improvement: yes (see section above)
- Open source code: yes
- English README with installation steps: yes
- Link to idea included: TODO fill before submission
- Video demo or detailed app description: detailed behavior description provided in this README and in [RUNBOOK.md](RUNBOOK.md)
- Team members listed (if team submission): not applicable (solo submission)

---

# InterSystems AI Hub EAP

Welcome to the Early Access Program for the InterSystems AI Hub! 
The [InterSystems AI Hub](#what-is-the-ai-hub) helps InterSystems customers accelerate their AI development and govern their use of AI assets. Whether you're looking for a native IRIS experience to build agents from scratch, expose IRIS-based business logic to external agents, or operationalize a langchain app by integrating it with the IRIS security model, the AI Hub gets you going as fast as you can say G-P-T.

See below for instructions to download and install the software, and an overview of the documentation per use case. 

> [!IMPORTANT]
> As part of the EAP, we're making pre-release software available through this portal.  We're working hard to get the packaging and integration with core IRIS features, including credential management, right and therefore some of the APIs and access control features are likely to change in the course of the API. We intend to document such changes here, in the change log at the bottom of the page.

> [!CAUTION]
> This pre-release software is not meant to be used in production environments.

For any questions, bug reports or other feedback, please use the Issues section of this repository.

## Accessing the software

You can download full kits or docker container images that include the latest InterSystems AI Hub updates from the [Early Access Program portal](https://evaluation.intersystems.com/Eval/early-access/AIHub). 

> [!NOTE]
> In the instructions below, please note the version number is included in some of the file names, and you may need to adjust the commands to match the files you downloaded.

No specific license is required to use the AI Hub. You can use your regular development license. 

The kits posted on this page can be installed like a normal InterSystems IRIS kit using interactive or silent installer. 

When using a container image, use the following commands to import and launch the image after downloading:

```Shell
docker image load -i /path/to/iris-community-2026.2.0AI.162.0-docker.tar.gz

docker run --name iris-ai-hub -p 1972:1972 -p 52773:52773 \
-d  docker.iscinternal.com/docker-intersystems/intersystems/iris-community:2026.2.0AI.162.0
```

Note, if you want to create a remote HTTP MCP server, you may wish to expose a third port, e.g. `-p 8080:8080`. If you are using a M-Chip Mac, you will need to use the arm64 version, and change image name in the commands above accordingly. 

For more about optional parameters, such as `--key` and `--volume`, see the documentation on [running IRIS in containers](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=AFL_containers#AFL_containers_deploy_run1).

To change the default password, see the documentation above or use the following commands:
```Shell
docker exec -it iris-ai-hub iris session iris -U %SYS

%SYS> write ##class(Security.Users).UnExpireUserPasswords("*")
```

## What is the AI Hub?

The AI Hub consists of two main pieces:

The **AI SDK** helps users who develop applications on IRIS to take advantage of AI resources such as AI models (with an initial focus on LLMs) and external MCP Servers. It offers an API that abstracts over the specifics of the various AI service providers' own APIs and governs access to these using IRIS RBAC policies, consistent with the security model of the rest of your IRIS based logic. 
The AI SDK is available for ObjectScript, Python, and Java developers. For Python and Java, we're ensuring this is familiar to developers already working with AI by implementing the [langchain](https://docs.langchain.com/) and [LangChain4J](https://docs.langchain4j.dev/) APIs, respectively, but ensuring access to resources is governed through the same IRIS Config Store.

The **MCP Server** facilitates exposing customer business logic and existing IRIS functionality through an MCP Server, such that Agents and other external MCP Clients can easily include this in their agentic workflows. Again, access to these is governed using standard IRIS RBAC policies. 
Exposing business logic as MCP tools can be achieved entirely declaratively, either using an XData block in a class definition, or a simple user interface.

![Basic Diagram](img/basic-diagram.png)

The blocks in the middle of the diagram represent MCP Server and toolset definitions that we'll build on top of the MCP Server capability and will start making available as part of future IRIS releases.

> [!NOTE]
> Not all capabilities have been fully implemented or included in the available kits, please check in regularly for updates, or subscribe to this repo for updates!

## How to use the AI Hub?

The AI Hub offers dedicated experiences for specific audiences and use cases:

### :lobster: I've got my own agent, just give me tools!

If you're not looking to develop, but rather wire an AI such as Claude Desktop to your existing business logic or data, the AI Hub includes an MCP Server capability that allows you to publish your IRIS-native code and data as tools. Through a low-code interface, you can assemble a toolset that contains any combination of class methods, SQL or FHIR queries, and Business Services, and choose the security policies appropriate for your scenario.

* [MCP Server guide](MCP_Server_Guide.md)
* [MCP Server examples](MCP_Server_Examples.md)
* [Declarative toolset definition](ObjectScript_SDK_Guide.md#building-toolsets)
* [Toolset definition UI] (forthcoming)

### :robot: I'm an IRIS developer, looking to build an agent

The AI Hub includes a rich SDK for ObjectScript developers who want to build AI apps or agents using intuitive abstractions that run natively on IRIS. 
We take care of the plumbing, security, accounting, and other boring stuff so you can innovate faster and teach that agent exactly what's specific to your business. 

* [ObjectScript guide - basics](ObjectScript_SDK_Guide.md)
* [ObjectScript guide - advanced features](ObjectScript_SDK.Advanced.md)
* [ObjectScript examples](ObjectScript_SDK_Examples.md)

### :snake: I'm a langchain developer, looking to deploy to production

If you're developing in [langchain](https://docs.langchain.com/), the leading Python framework for developing AI applications, you can easily integrate your app with the IRIS security model. Simply store the configuration and credentials for hosted LLMs and remote MCP Servers in the [Config Store](#the-config-store) on IRIS and avoid having to juggle those through impractical environment variables or files. IRIS will not only enforce Role-Based Access Control (RBAC) policies, but can also take care of auditing and offer a central point of governance. 
This same langchain extension also offers access to our `VectorStore` implementation, exposing IRIS Vector Search to langchain users.

* [LangChain guide](langchain_SDK.md)
* [Config Store guide](Config_Store_Guide.md)

### :coffee: I'm a LangChain4J developer, looking to deploiy to production

An experience very similar to the Python one for langchain described above will soon be available for [LangChain4J](https://docs.langchain4j.dev/).

* [LangChain4J guide] (forthcoming)

### :lock: The Config Store

While not specific to the AI Hub, this EAP distribution also includes a new feature called the Config Store, which enables secure storage and governed access to various types of configurations, for example to reach out to external systems. It stores credentials and other secrets in the [IRIS Wallet](https://docs.intersystems.com/irislatest/csp/docbook/Doc.View.cls?KEY=ROARS_secrets_mgmt), adding a convenient mechanism to manage the coordinates and settings that complement those credentials. 
The different components in the AI Hub are all designed to find LLM and remote MCP server configurations in this new store.

* [Config Store guide](Config_Store_Guide.md)

You can find an example of how to use the config store as part of the [langchain guide](langchain_SDK.md)

## How to reach out

If you have any questions or feedback, please file them as issues on this repository, which makes them visible for the combined InterSystems team, or send them straight through email to [Benjamin De Boe](mailto:benjamin.de.boe@intersystems.com).