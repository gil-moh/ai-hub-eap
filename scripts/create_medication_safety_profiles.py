"""
Create focused Medication Safety test profiles and save input artifacts.

Profiles created:
- med-safe-dup-001: duplicate therapy signal
- med-safe-allergy-001: medication-allergy overlap signal

Also writes input JSON files to:
  C:/Projects/FHIR/ai-hub-eap/med_safety_io/<patient-id>-input.json
"""

from __future__ import annotations

import json
from datetime import datetime
from pathlib import Path
from typing import Any

import requests

BASE_URL = "http://localhost:52773/fhir/r4"
AUTH = ("_SYSTEM", "SYS")

OUT_DIR = Path("C:/Projects/FHIR/ai-hub-eap/med_safety_io")
OUT_DIR.mkdir(parents=True, exist_ok=True)


def cc(system: str, code: str, display: str) -> dict[str, Any]:
    return {"coding": [{"system": system, "code": code, "display": display}], "text": display}


def tx_entry(resource: dict[str, Any]) -> dict[str, Any]:
    return {
        "resource": resource,
        "request": {"method": "PUT", "url": f"{resource['resourceType']}/{resource['id']}"},
    }


def build_profiles() -> dict[str, list[dict[str, Any]]]:
    profiles: dict[str, list[dict[str, Any]]] = {}

    p = "med-safe-dup-001"
    profiles[p] = [
        {
            "resourceType": "Patient",
            "id": p,
            "name": [{"use": "official", "family": "Shalev", "given": ["Eitan"]}],
            "gender": "male",
            "birthDate": "1972-03-19",
        },
        {
            "resourceType": "MedicationRequest",
            "id": "medrx-med-safe-dup-001-metformin-500",
            "subject": {"reference": f"Patient/{p}"},
            "status": "active",
            "intent": "order",
            "medicationCodeableConcept": cc(
                "http://www.nlm.nih.gov/research/umls/rxnorm", "860975", "Metformin 500 MG Oral Tablet"
            ),
            "authoredOn": "2026-05-15",
        },
        {
            "resourceType": "MedicationRequest",
            "id": "medrx-med-safe-dup-001-metformin-1000",
            "subject": {"reference": f"Patient/{p}"},
            "status": "active",
            "intent": "order",
            "medicationCodeableConcept": cc(
                "http://www.nlm.nih.gov/research/umls/rxnorm", "861007", "Metformin 1000 MG Oral Tablet"
            ),
            "authoredOn": "2026-05-18",
        },
        {
            "resourceType": "Condition",
            "id": "cond-med-safe-dup-001-dm2",
            "subject": {"reference": f"Patient/{p}"},
            "code": cc("http://snomed.info/sct", "44054006", "Type 2 diabetes mellitus"),
            "clinicalStatus": cc(
                "http://terminology.hl7.org/CodeSystem/condition-clinical", "active", "Active"
            ),
            "recordedDate": "2019-01-08",
        },
        {
            "resourceType": "Observation",
            "id": "obs-med-safe-dup-001-a1c",
            "status": "final",
            "code": cc("http://loinc.org", "4548-4", "Hemoglobin A1c/Hemoglobin.total in Blood"),
            "subject": {"reference": f"Patient/{p}"},
            "effectiveDateTime": "2026-05-20",
            "valueQuantity": {"value": 8.7, "unit": "%", "system": "http://unitsofmeasure.org", "code": "%"},
        },
    ]

    p = "med-safe-allergy-001"
    profiles[p] = [
        {
            "resourceType": "Patient",
            "id": p,
            "name": [{"use": "official", "family": "Naim", "given": ["Lior"]}],
            "gender": "female",
            "birthDate": "1988-12-02",
        },
        {
            "resourceType": "AllergyIntolerance",
            "id": "allergy-med-safe-allergy-001-amoxicillin",
            "patient": {"reference": f"Patient/{p}"},
            "code": cc("http://snomed.info/sct", "372687004", "Amoxicillin"),
            "clinicalStatus": cc(
                "http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical", "active", "Active"
            ),
            "verificationStatus": cc(
                "http://terminology.hl7.org/CodeSystem/allergyintolerance-verification", "confirmed", "Confirmed"
            ),
            "criticality": "high",
            "reaction": [
                {
                    "manifestation": [cc("http://snomed.info/sct", "271807003", "Skin rash")],
                    "severity": "moderate",
                }
            ],
            "recordedDate": "2024-08-10",
        },
        {
            "resourceType": "MedicationRequest",
            "id": "medrx-med-safe-allergy-001-augmentin",
            "subject": {"reference": f"Patient/{p}"},
            "status": "active",
            "intent": "order",
            "medicationCodeableConcept": cc(
                "http://www.nlm.nih.gov/research/umls/rxnorm", "617425", "Amoxicillin and clavulanate potassium 875 MG / 125 MG Oral Tablet"
            ),
            "authoredOn": "2026-05-22",
        },
        {
            "resourceType": "Condition",
            "id": "cond-med-safe-allergy-001-sinus",
            "subject": {"reference": f"Patient/{p}"},
            "code": cc("http://snomed.info/sct", "36971009", "Acute sinusitis"),
            "clinicalStatus": cc(
                "http://terminology.hl7.org/CodeSystem/condition-clinical", "active", "Active"
            ),
            "recordedDate": "2026-05-21",
        },
    ]

    return profiles


def send_transaction(resources: list[dict[str, Any]]) -> tuple[bool, str]:
    bundle = {
        "resourceType": "Bundle",
        "type": "transaction",
        "entry": [tx_entry(r) for r in resources],
    }
    s = requests.Session()
    s.auth = AUTH
    s.headers.update({"Content-Type": "application/fhir+json", "Accept": "application/fhir+json"})
    r = s.post(BASE_URL, json=bundle, timeout=120)
    if r.status_code not in (200, 201):
        return False, f"HTTP {r.status_code}: {r.text[:250]}"
    return True, "OK"


def main() -> int:
    print(f"[{datetime.now().isoformat(timespec='seconds')}] Creating medication safety profiles")
    profiles = build_profiles()
    failed = False

    for patient_id, resources in profiles.items():
        input_path = OUT_DIR / f"{patient_id}-input.json"
        with input_path.open("w", encoding="utf-8") as f:
            json.dump(resources, f, indent=2)

        ok, msg = send_transaction(resources)
        print(f"- {patient_id}: {'OK' if ok else 'FAIL'} ({len(resources)} resources) {msg}")
        print(f"  input: {input_path}")
        if not ok:
            failed = True

    print("Done.")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
