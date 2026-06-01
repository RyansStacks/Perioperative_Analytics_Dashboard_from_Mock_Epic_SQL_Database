CREATE INDEX IX_EncounterFact_Patient ON EncounterFact(PatientDurableKey);
CREATE INDEX IX_EncounterFact_Hospital ON EncounterFact(HospitalDurableKey);
CREATE INDEX IX_ProcedureFact_Encounter ON ProcedureFact(EncounterDurableKey);
CREATE INDEX IX_DiagnosisFact_Encounter ON DiagnosisFact(EncounterDurableKey);
CREATE INDEX IX_MedicationFact_Encounter ON MedicationFact(EncounterDurableKey);
CREATE INDEX IX_LabResultFact_Encounter ON LabResultFact(EncounterDurableKey);
