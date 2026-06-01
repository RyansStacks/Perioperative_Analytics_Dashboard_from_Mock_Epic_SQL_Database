SELECT 'HospitalDim', COUNT(*) FROM HospitalDim
UNION ALL SELECT 'PayorDim', COUNT(*) FROM PayorDim
UNION ALL SELECT 'ProviderDim', COUNT(*) FROM ProviderDim
UNION ALL SELECT 'PatientDim', COUNT(*) FROM PatientDim
UNION ALL SELECT 'EncounterFact', COUNT(*) FROM EncounterFact
UNION ALL SELECT 'ProcedureFact', COUNT(*) FROM ProcedureFact
UNION ALL SELECT 'DiagnosisFact', COUNT(*) FROM DiagnosisFact
UNION ALL SELECT 'MedicationFact', COUNT(*) FROM MedicationFact
UNION ALL SELECT 'LabResultFact', COUNT(*) FROM LabResultFact;
