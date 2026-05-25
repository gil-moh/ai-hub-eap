Include (%AI, %occStatus)

/// Read-only FHIR medication safety tool.
///
/// Focuses on MVP medication review needs:
/// - active medication list
/// - duplicate therapy detection
/// - allergy cross-check
/// - adherence signal hints
///
/// Configure FHIR endpoint with:
///   FHIR_BASE_URL
///   FHIR_BEARER_TOKEN (optional)
///   FHIR_BASIC_USER / FHIR_BASIC_PASS (optional)
Class Sample.AI.Tools.MedicationSafetyReadOnly Extends %AI.Tool
{

Property Name As %String [ InitialExpression = "MedicationSafetyReadOnly" ];
Property Description As %String(MAXLEN = "") [ InitialExpression = "Read-only medication safety review over FHIR resources" ];

/// Get MedicationRequest resources for a patient.
ClassMethod GetMedicationRequests(patientId As %String, status As %String = "active", limit As %Integer = 50) As %DynamicObject
{
    If patientId = "" {
        Return {"error":"patientId is required"}
    }
    Set max = $SELECT(limit>200:200, limit<1:1, 1:limit)
    Set query = "patient=" _ ..UrlEncode(patientId) _ "&_count=" _ max
    If status '= "" {
        Set query = query _ "&status=" _ ..UrlEncode(status)
    }
    Return ..GetFHIR("MedicationRequest?" _ query)
}

/// Get MedicationStatement resources for a patient.
ClassMethod GetMedicationStatements(patientId As %String, status As %String = "active", limit As %Integer = 50) As %DynamicObject
{
    If patientId = "" {
        Return {"error":"patientId is required"}
    }
    Set max = $SELECT(limit>200:200, limit<1:1, 1:limit)
    Set query = "patient=" _ ..UrlEncode(patientId) _ "&_count=" _ max
    If status '= "" {
        Set query = query _ "&status=" _ ..UrlEncode(status)
    }
    Return ..GetFHIR("MedicationStatement?" _ query)
}

/// Get AllergyIntolerance resources for a patient.
ClassMethod GetAllergies(patientId As %String, limit As %Integer = 50) As %DynamicObject
{
    If patientId = "" {
        Return {"error":"patientId is required"}
    }
    Set max = $SELECT(limit>200:200, limit<1:1, 1:limit)
    Set query = "patient=" _ ..UrlEncode(patientId) _ "&_count=" _ max
    Return ..GetFHIR("AllergyIntolerance?" _ query)
}

/// Get Condition resources for a patient.
ClassMethod GetConditions(patientId As %String, status As %String = "", limit As %Integer = 50) As %DynamicObject
{
    If patientId = "" {
        Return {"error":"patientId is required"}
    }
    Set max = $SELECT(limit>200:200, limit<1:1, 1:limit)
    Set query = "patient=" _ ..UrlEncode(patientId) _ "&_count=" _ max
    If status '= "" {
        Set query = query _ "&clinical-status=" _ ..UrlEncode(status)
    }
    Return ..GetFHIR("Condition?" _ query)
}

/// Get Observation resources for a patient.
ClassMethod GetObservations(patientId As %String, category As %String = "", limit As %Integer = 50) As %DynamicObject
{
    If patientId = "" {
        Return {"error":"patientId is required"}
    }
    Set max = $SELECT(limit>200:200, limit<1:1, 1:limit)
    Set query = "patient=" _ ..UrlEncode(patientId) _ "&_count=" _ max _ "&_sort=-date"
    If category '= "" {
        Set query = query _ "&category=" _ ..UrlEncode(category)
    }
    Return ..GetFHIR("Observation?" _ query)
}

/// Build a medication safety snapshot for deterministic review.
ClassMethod BuildMedicationReviewSnapshot(patientId As %String, limit As %Integer = 50) As %DynamicObject
{
    If patientId = "" {
        Return {"error":"patientId is required"}
    }

    Set requests = ..GetMedicationRequests(patientId, "", limit)
    Set statements = ..GetMedicationStatements(patientId, "", limit)
    Set allergies = ..GetAllergies(patientId, limit)
    Set conditions = ..GetConditions(patientId, "", limit)
    Set observations = ..GetObservations(patientId, "", limit)

    Set medList = ..BuildActiveMedicationList(requests, statements)
    Set duplicateFindings = ..DetectDuplicateTherapy(medList)
    Set allergyFindings = ..CrossCheckAllergies(medList, allergies)
    Set adherenceFindings = ..DetectAdherenceSignals(requests, statements, observations)

    Return {
        "patientId": (patientId),
        "generatedAt": ($ZDATETIME($HOROLOG, 3, 1)),
        "resourceCounts": {
            "medicationRequests": (..CountBundleEntries(requests)),
            "medicationStatements": (..CountBundleEntries(statements)),
            "allergies": (..CountBundleEntries(allergies)),
            "conditions": (..CountBundleEntries(conditions)),
            "observations": (..CountBundleEntries(observations))
        },
        "activeMedicationList": (medList),
        "duplicateTherapyFindings": (duplicateFindings),
        "allergyCrossCheckFindings": (allergyFindings),
        "adherenceSignals": (adherenceFindings),
        "vectorSearch": (..GetGuidanceSnippets("medication safety and interaction counseling", 3)),
        "raw": {
            "medicationRequests": (requests),
            "medicationStatements": (statements),
            "allergies": (allergies),
            "conditions": (conditions),
            "observations": (observations)
        }
    }
}

/// Placeholder hook for Vector Search-backed contextual guidance.
ClassMethod GetGuidanceSnippets(query As %String, topK As %Integer = 3) As %DynamicObject
{
    Set k = $SELECT(topK>10:10, topK<1:1, 1:topK)
    Return {
        "enabled": (0),
        "topK": (k),
        "query": (query),
        "status": "not-configured",
        "hint": "Connect this method to IRIS Vector Search to retrieve drug guidance or patient education snippets."
    }
}

ClassMethod BuildActiveMedicationList(requestBundle As %DynamicObject, statementBundle As %DynamicObject = "") As %DynamicArray [ Internal ]
{
    Set out = []

    Do ..AppendMedicationEntries(out, requestBundle, "MedicationRequest")
    If $ISOBJECT(statementBundle) {
        Do ..AppendMedicationEntries(out, statementBundle, "MedicationStatement")
    }

    Return out
}

ClassMethod AppendMedicationEntries(ByRef out As %DynamicArray, bundle As %DynamicObject, sourceType As %String) [ Internal ]
{
    If '$ISOBJECT(bundle) {
        Quit
    }

    Set entries = bundle.%Get("entry")
    If '$ISOBJECT(entries) {
        Quit
    }

    For i=0:1:(entries.%Size()-1) {
        Set e = entries.%Get(i)
        If '$ISOBJECT(e) {
            Continue
        }
        Set r = e.%Get("resource")
        If '$ISOBJECT(r) {
            Continue
        }

        Set medName = ..ExtractMedicationName(r)
        If medName = "" {
            Continue
        }

        Set one = {
            "name": (medName),
            "normalizedKey": (..NormalizeMedicationKey(medName)),
            "resourceId": (..SafeGet(r, "id")),
            "status": (..SafeGet(r, "status")),
            "source": (sourceType),
            "authoredOn": (..SafeGet(r, "authoredOn")),
            "effectiveDateTime": (..SafeGet(r, "effectiveDateTime"))
        }
        Do out.%Push(one)
    }
}

ClassMethod DetectDuplicateTherapy(medList As %DynamicArray) As %DynamicArray [ Internal ]
{
    Set findings = []
    If '$ISOBJECT(medList) || (medList.%Size()=0) {
        Return findings
    }

    Kill keyCount, keyNames, keyIds
    For i=0:1:(medList.%Size()-1) {
        Set one = medList.%Get(i)
        If '$ISOBJECT(one) {
            Continue
        }
        Set key = ..SafeGet(one, "normalizedKey")
        Set name = ..SafeGet(one, "name")
        If (key = "") || (name = "") {
            Continue
        }
        Set keyCount(key) = $Get(keyCount(key)) + 1
        Set keyNames(key, keyCount(key)) = name
        Set keyIds(key, keyCount(key)) = ..SafeGet(one, "resourceId")
    }

    Set key = ""
    For {
        Set key = $Order(keyCount(key))
        Quit:key=""
        If $Get(keyCount(key))<2 {
            Continue
        }
        Set names = ""
        Set ids = []
        For idx=1:1:keyCount(key) {
            Set n = $Get(keyNames(key, idx))
            If n = "" {
                Continue
            }
            If names = "" {
                Set names = n
            } Else {
                Set names = names _ "; " _ n
            }

            Set rid = $Get(keyIds(key, idx))
            If rid '= "" {
                Do ids.%Push(rid)
            }
        }
        Do findings.%Push({
            "risk": "possible-duplicate-therapy",
            "key": (key),
            "count": (keyCount(key)),
            "evidence": (names),
            "resourceIds": (ids),
            "source": {
                "type": "heuristic",
                "method": "normalized-medication-name-match",
                "resources": "MedicationRequest/MedicationStatement"
            },
            "message": "Potential duplicate therapy detected. Review overlapping active medications."
        })
    }

    Return findings
}

ClassMethod CrossCheckAllergies(medList As %DynamicArray, allergyBundle As %DynamicObject) As %DynamicArray [ Internal ]
{
    Set findings = []
    If '$ISOBJECT(medList) || '$ISOBJECT(allergyBundle) {
        Return findings
    }

    Set allergyTerms = []
    Set entries = allergyBundle.%Get("entry")
    If '$ISOBJECT(entries) {
        Return findings
    }

    For i=0:1:(entries.%Size()-1) {
        Set e = entries.%Get(i)
        If '$ISOBJECT(e) {
            Continue
        }
        Set r = e.%Get("resource")
        If '$ISOBJECT(r) {
            Continue
        }
        Set term = ..ExtractAllergyName(r)
        If term '= "" {
            Do allergyTerms.%Push({
                "term": (term),
                "allergyId": (..SafeGet(r, "id"))
            })
        }
    }

    If allergyTerms.%Size()=0 {
        Return findings
    }

    For i=0:1:(medList.%Size()-1) {
        Set med = medList.%Get(i)
        If '$ISOBJECT(med) {
            Continue
        }
        Set medName = ..SafeGet(med, "name")
        If medName = "" {
            Continue
        }

        For j=0:1:(allergyTerms.%Size()-1) {
            Set oneAllergy = allergyTerms.%Get(j)
            If '$ISOBJECT(oneAllergy) {
                Continue
            }
            Set term = ..SafeGet(oneAllergy, "term")
            Set allergyId = ..SafeGet(oneAllergy, "allergyId")
            If ..ContainsInsensitive(medName, term) || ..ContainsInsensitive(term, medName) {
                Do findings.%Push({
                    "risk": "possible-allergy-conflict",
                    "medication": (medName),
                    "medicationResourceId": (..SafeGet(med, "resourceId")),
                    "allergy": (term),
                    "allergyResourceId": (allergyId),
                    "source": {
                        "type": "heuristic",
                        "method": "medication-name-overlaps-allergy-term",
                        "resources": "MedicationRequest/MedicationStatement + AllergyIntolerance"
                    },
                    "message": "Medication name appears to overlap a documented allergy. Confirm before prescribing or administering."
                })
            }
        }
    }

    Return findings
}

ClassMethod DetectAdherenceSignals(requestBundle As %DynamicObject, statementBundle As %DynamicObject, observationBundle As %DynamicObject) As %DynamicArray [ Internal ]
{
    Set findings = []

    Set reqCount = ..CountBundleEntries(requestBundle)
    Set stmtCount = ..CountBundleEntries(statementBundle)

    If (reqCount>0) && (stmtCount=0) {
        Do findings.%Push({
            "risk": "possible-adherence-gap",
            "message": "MedicationRequest records exist but no MedicationStatement records were found. Consider adherence and reconciliation follow-up."
        })
    }

    If $ISOBJECT(requestBundle) {
        Set entries = requestBundle.%Get("entry")
        If $ISOBJECT(entries) {
            For i=0:1:(entries.%Size()-1) {
                Set e = entries.%Get(i)
                If '$ISOBJECT(e) {
                    Continue
                }
                Set r = e.%Get("resource")
                If '$ISOBJECT(r) {
                    Continue
                }
                Set st = $ZCVT(..SafeGet(r, "status"), "L")
                If (st = "on-hold") || (st = "stopped") || (st = "cancelled") {
                    Do findings.%Push({
                        "risk": "medication-status-warning",
                        "status": (st),
                        "medication": (..ExtractMedicationName(r)),
                        "message": "Medication status indicates interruption or discontinuation. Verify current treatment plan and patient understanding."
                    })
                }
            }
        }
    }

    // Lightweight clinical cue: elevated A1c may indicate adherence or regimen gap.
    If $ISOBJECT(observationBundle) {
        Set entries = observationBundle.%Get("entry")
        If $ISOBJECT(entries) {
            For i=0:1:(entries.%Size()-1) {
                Set e = entries.%Get(i)
                If '$ISOBJECT(e) {
                    Continue
                }
                Set r = e.%Get("resource")
                If '$ISOBJECT(r) {
                    Continue
                }
                Set codeText = $ZCVT(..ExtractCodeableText(r.%Get("code")), "L")
                Set vq = r.%Get("valueQuantity")
                If '$ISOBJECT(vq) {
                    Continue
                }
                Set val = +..SafeGet(vq, "value")
                If (codeText [ "a1c") || (codeText [ "hemoglobin a1c") {
                    If val>8 {
                        Do findings.%Push({
                            "risk": "glycemic-control-concern",
                            "value": (val),
                            "message": "Recent A1c is elevated. Review adherence, education needs, and therapy adjustments."
                        })
                    }
                }
            }
        }
    }

    Return findings
}

ClassMethod ExtractMedicationName(resource As %DynamicObject) As %String [ Internal ]
{
    If '$ISOBJECT(resource) {
        Return ""
    }

    Set c = resource.%Get("medicationCodeableConcept")
    Set name = ..ExtractCodeableText(c)
    If name '= "" {
        Return name
    }

    Set ref = resource.%Get("medicationReference")
    If $ISOBJECT(ref) {
        Set name = ..SafeGet(ref, "display")
        If name '= "" {
            Return name
        }
        Set name = ..SafeGet(ref, "reference")
        If name '= "" {
            Return name
        }
    }

    Return ""
}

ClassMethod ExtractAllergyName(resource As %DynamicObject) As %String [ Internal ]
{
    If '$ISOBJECT(resource) {
        Return ""
    }

    Set name = ..ExtractCodeableText(resource.%Get("code"))
    If name '= "" {
        Return name
    }

    Return ..SafeGet(resource, "substance")
}

ClassMethod ExtractCodeableText(cc As %DynamicObject) As %String [ Internal ]
{
    If '$ISOBJECT(cc) {
        Return ""
    }

    Set t = ..SafeGet(cc, "text")
    If t '= "" {
        Return t
    }

    Set coding = cc.%Get("coding")
    If '$ISOBJECT(coding) || (coding.%Size()=0) {
        Return ""
    }

    Set first = coding.%Get(0)
    If '$ISOBJECT(first) {
        Return ""
    }

    Set t = ..SafeGet(first, "display")
    If t '= "" {
        Return t
    }

    Return ..SafeGet(first, "code")
}

ClassMethod NormalizeMedicationKey(name As %String) As %String [ Internal ]
{
    Set t = $ZCVT(name, "L")
    Set t = $Translate(t, ",.()-/", "       ")

    Set out = ""
    For i=1:1:$Length(t, " ") {
        Set tok = $Piece(t, " ", i)
        If tok = "" {
            Continue
        }
        If +tok>0 {
            Continue
        }
        If (tok="mg") || (tok="mcg") || (tok="ml") || (tok="tablet") || (tok="capsule") || (tok="oral") || (tok="solution") {
            Continue
        }
        If out = "" {
            Set out = tok
        } Else {
            Set out = out _ " " _ tok
        }
    }

    Return $Extract(out, 1, 40)
}

ClassMethod ContainsInsensitive(text As %String, needle As %String) As %Boolean [ Internal ]
{
    If (text="") || (needle="") {
        Return 0
    }
    Set t = $ZCVT(text, "L")
    Set n = $ZCVT(needle, "L")
    Quit $Find(t, n)>0
}

ClassMethod CountBundleEntries(bundle As %DynamicObject) As %Integer [ Internal ]
{
    If '$ISOBJECT(bundle) {
        Return 0
    }
    Set entries = bundle.%Get("entry")
    If '$ISOBJECT(entries) {
        Return 0
    }
    Return entries.%Size()
}

ClassMethod SafeGet(obj As %DynamicObject, key As %String) As %String [ Internal ]
{
    If '$ISOBJECT(obj) {
        Return ""
    }
    Try {
        Set val = obj.%Get(key)
    } Catch ex {
        Return ""
    }
    If val = "" {
        Return ""
    }
    Return val
}

ClassMethod GetFHIR(path As %String) As %DynamicObject [ Internal ]
{
    Set baseUrl = ..GetBaseUrl()
    Set fullUrl = baseUrl _ "/" _ path

    Set req = ##class(%Net.HttpRequest).%New()
    Set req.SSLCheckServerIdentity = 0

    Set basicUser = $SYSTEM.Util.GetEnviron("FHIR_BASIC_USER")
    If basicUser = "" {
        Set basicUser = $GET(^||ENV("FHIR_BASIC_USER"))
    }
    Set basicPass = $SYSTEM.Util.GetEnviron("FHIR_BASIC_PASS")
    If basicPass = "" {
        Set basicPass = $GET(^||ENV("FHIR_BASIC_PASS"))
    }
    If (basicUser '= "") && (basicPass '= "") {
        Set req.Username = basicUser
        Set req.Password = basicPass
    } Else {
        Set token = $SYSTEM.Util.GetEnviron("FHIR_BEARER_TOKEN")
        If token = "" {
            Set token = $GET(^||ENV("FHIR_BEARER_TOKEN"))
        }
        If token '= "" {
            Do req.SetHeader("Authorization", "Bearer " _ token)
        }
    }
    Do req.SetHeader("Accept", "application/fhir+json")

    Set sc = req.Get(fullUrl)
    If $$$ISERR(sc) {
        Return {
            "error": "HTTP request failed",
            "status": ($SYSTEM.Status.GetErrorText(sc)),
            "url": (fullUrl)
        }
    }

    Set code = +req.HttpResponse.StatusCode
    Set raw = ..ReadResponseBody(req.HttpResponse.Data)
    If (code<200) || (code>299) {
        Return {
            "error": "FHIR request failed",
            "statusCode": (code),
            "url": (fullUrl),
            "body": (raw)
        }
    }

    Try {
        Return ##class(%DynamicAbstractObject).%FromJSON(raw)
    } Catch ex {
        Return {
            "resourceType": "Binary",
            "contentType": (req.HttpResponse.GetHeader("Content-Type")),
            "data": (raw)
        }
    }
}

ClassMethod GetBaseUrl() As %String [ Internal ]
{
    Set base = $SYSTEM.Util.GetEnviron("FHIR_BASE_URL")
    If base = "" {
        Set base = $GET(^||ENV("FHIR_BASE_URL"))
    }
    If base = "" {
        Set base = "http://localhost:52773/fhir/r4"
    }
    Return $ZSTRIP(base, "<W", "/")
}

ClassMethod ReadResponseBody(stream As %Stream.Object) As %String [ Internal ]
{
    If '$ISOBJECT(stream) {
        Return ""
    }

    Set out = ""
    While 'stream.AtEnd {
        Set out = out _ stream.Read(32000)
    }
    Return out
}

ClassMethod UrlEncode(s As %String) As %String [ Internal ]
{
    Quit $ZCONVERT(s, "O", "URL")
}

ClassMethod ExtractHost(url As %String) As %String [ Internal ]
{
    Set tmp = url
    If $Extract(tmp,1,8)="https://" {
        Set tmp = $Extract(tmp,9,*)
    } ElseIf $Extract(tmp,1,7)="http://" {
        Set tmp = $Extract(tmp,8,*)
    }
    Set hp = $Piece(tmp, "/", 1)
    Quit $Piece(hp, ":", 1)
}

ClassMethod ExtractPort(url As %String) As %Integer [ Internal ]
{
    Set https = ($Extract(url,1,8)="https://")
    Set tmp = url
    If https {
        Set tmp = $Extract(tmp,9,*)
    } ElseIf $Extract(tmp,1,7)="http://" {
        Set tmp = $Extract(tmp,8,*)
    }
    Set hp = $Piece(tmp, "/", 1)
    Set p = +$Piece(hp, ":", 2)
    If p>0 {
        Quit p
    }
    Quit $Select(https:443, 1:80)
}

ClassMethod ExtractLocation(url As %String) As %String [ Internal ]
{
    Set tmp = url
    If $Extract(tmp,1,8)="https://" {
        Set tmp = $Extract(tmp,9,*)
    } ElseIf $Extract(tmp,1,7)="http://" {
        Set tmp = $Extract(tmp,8,*)
    }
    Set path = $Piece(tmp, "/", 2, *)
    Quit "/" _ path
}

}
