Include (%AI, %occStatus)

/// FHIR interoperability assistant focused on read-only analysis.
///
/// Required environment variables:
///   OPENAI_API_KEY (or ANTHROPIC_API_KEY / GEMINI_API_KEY / GROK_API_KEY)
/// Optional:
///   FHIR_BASE_URL, FHIR_BEARER_TOKEN
Class Sample.AI.Agent.FHIRInteropAgent Extends %AI.Agent
{

Parameter TOOLSETS = "Sample.AI.ToolSet.FHIRReadOnly";

/// Default models per provider when auto-detecting provider from environment.
Parameter MODELS = "openai=gpt-4o,anthropic=claude-haiku-4-5-20251001,gemini=gemini-2.0-flash,grok=grok-3";

XData INSTRUCTIONS [ MimeType = text/markdown ]
{
# FHIR Interop Assistant

You are an interoperability assistant for FHIR-based workflows.

## Core behavior

- Prefer using tools to retrieve factual clinical data.
- Be explicit when data is missing or ambiguous.
- Keep responses concise and clinically neutral.
- Never fabricate patient fields that are absent from the resource.

## Available capabilities

- Search patients by name/identifier/birthDate
- Read one patient resource by id
- Read observations for a patient
- Read allergies for a patient
}

Method %OnInit() As %Status
{
    If $ISOBJECT(..Provider) {
        Quit $$$OK
    }

    Set key = ##class(Sample.AI.Utils).GetAPIKey("", .providerName)
    If key = "" {
        Return $$$ERROR($$$GeneralError, "No API key found. Set OPENAI_API_KEY, ANTHROPIC_API_KEY, GEMINI_API_KEY, or GROK_API_KEY")
    }

    Set ..Provider = ##class(%AI.Provider).Create(providerName, {"api_key":(key)})

    For i=1:1:$LENGTH(..#MODELS, ",") {
        Set pair = $PIECE(..#MODELS, ",", i)
        If $PIECE(pair, "=", 1) = providerName {
            Set ..Model = $PIECE(pair, "=", 2)
            Quit
        }
    }

    Write "[FHIRInteropAgent] Provider: ", providerName, "  Model: ", ..Model, !
    Quit $$$OK
}

ClassMethod Demo() As %Status
{
    Write !, "=== FHIRInteropAgent Demo ===", !
    Write "FHIR_BASE_URL: ", $SYSTEM.Util.GetEnviron("FHIR_BASE_URL"), !

    Set agent = ..%New()
    Set sc = agent.%Init()
    If $$$ISERR(sc) {
        Write !, "Initialization failed: ", $SYSTEM.Status.GetErrorText(sc), !
        Quit sc
    }

    Set session = agent.CreateSession()

    Set prompt = "Find up to 5 patients named John and summarize the first patient in bullet points."
    Write !, "Prompt: ", prompt, !

    Set response = agent.Chat(session, prompt)
    Do ##class(%AI.System).RenderMarkdown(response.Content)
    Write !

    Quit $$$OK
}

}