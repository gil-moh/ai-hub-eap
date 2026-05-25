Include (%AI, %occStatus)

/// Example entry points for the Medication Safety and Interaction Assistant MVP.
Class Sample.AI.Examples.MedicationSafetyAssistant Extends %RegisteredObject
{

/// Build and print a medication safety review for a patient.
ClassMethod Demo(patientId As %String, detailMode As %String = "detailed") As %Status
{
    Try {
        Set tool = ##class(Sample.AI.Tools.MedicationSafetyReadOnly).%New()
        Set snapshot = tool.BuildMedicationReviewSnapshot(patientId, 50)

        If $ISOBJECT(snapshot) && (snapshot.%Get("error") '= "") {
            Write !, "Medication safety demo failed: ", snapshot.%Get("error"), !
            Return $$$ERROR($$$GeneralError, snapshot.%Get("error"))
        }

        Do ..WriteNarrative(snapshot, detailMode)
        Return $$$OK
    } Catch ex {
        Write !, "Medication safety demo failed: ", ex.DisplayString(), !
        Return ex.AsStatus()
    }
}

ClassMethod WriteNarrative(snapshot As %DynamicObject, detailMode As %String = "detailed") [ Internal ]
{
    Set patientId = ..SafeGet(snapshot, "patientId")
    Set counts = snapshot.%Get("resourceCounts")
    Set medList = snapshot.%Get("activeMedicationList")
    Set dupes = snapshot.%Get("duplicateTherapyFindings")
    Set allergies = snapshot.%Get("allergyCrossCheckFindings")
    Set adherence = snapshot.%Get("adherenceSignals")
    Set vectorSearch = snapshot.%Get("vectorSearch")

    Write !, "Example - Medication Safety and Interaction Assistant", !
    Write !, "Patient Overview", !
    Write "- Patient: ", patientId, !
    Write "- Evidence available: medication requests, medication statements, allergies, conditions, and observations.", !

    Write !, "Clinical Snapshot", !
    Do ..WriteBulletArray("Active Medications", medList)
    Do ..WriteBulletArray("Duplicate Therapy Findings", dupes)
    Do ..WriteBulletArray("Allergy Cross-Check Findings", allergies)
    Do ..WriteBulletArray("Adherence / Reconciliation Signals", adherence)

    Write !, "Counseling Summary", !
    Write "- Review the medication list for duplicates, allergy conflicts, or outdated therapy.", !
    Write "- Confirm how the patient is taking each medicine and whether any doses were missed.", !
    Write "- Keep the patient-facing explanation plain and specific to the current regimen.", !

    Write !, "Context-Aware Guidance", !
    If $ISOBJECT(vectorSearch) {
        Do ..WriteBulletArray("Vector Search", vectorSearch)
    }

    If detailMode '= "brief" {
        Write !, "Review Notes", !
        Write "- MedicationRequests: ", ..CountFromCounts(counts, "medicationRequests"), !
        Write "- MedicationStatements: ", ..CountFromCounts(counts, "medicationStatements"), !
        Write "- Allergies: ", ..CountFromCounts(counts, "allergies"), !
        Write "- Conditions: ", ..CountFromCounts(counts, "conditions"), !
        Write "- Observations: ", ..CountFromCounts(counts, "observations"), !
    }
}

ClassMethod WriteBulletArray(label As %String, arr As %DynamicObject) [ Internal ]
{
    Write label, !
    If '$ISOBJECT(arr) || (arr.%Size()=0) {
        Write "- (none)", !
        Quit
    }
    For i=0:1:(arr.%Size()-1) {
        Set item = arr.%Get(i)
        If '$ISOBJECT(item) {
            Continue
        }
        Do ..WriteBulletItem(item)
    }
}

ClassMethod WriteBulletItem(item As %DynamicObject) [ Internal ]
{
    Set text = ..SafeGet(item, "message")
    If text = "" {
        Set text = ..SafeGet(item, "risk")
    }
    If text = "" {
        Set text = ..SafeGet(item, "name")
    }
    If text = "" {
        Set text = item.%ToJSON()
    }
    Write "- ", text, !
}

ClassMethod CountFromCounts(counts As %DynamicObject, key As %String) As %String [ Internal ]
{
    If '$ISOBJECT(counts) {
        Return "0"
    }
    Try {
        Set value = counts.%Get(key)
    } Catch ex {
        Return "0"
    }
    Return value
}

ClassMethod SafeGet(obj As %DynamicObject, key As %String) As %String [ Internal ]
{
    If '$ISOBJECT(obj) {
        Return ""
    }
    Try {
        Set value = obj.%Get(key)
    } Catch ex {
        Return ""
    }
    Return value
}

}
