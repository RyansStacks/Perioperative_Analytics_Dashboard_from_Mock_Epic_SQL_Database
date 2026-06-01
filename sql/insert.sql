------------------------------------------------------------
-- HospitalDim
------------------------------------------------------------
BULK INSERT dbo.HospitalDim
FROM 'C:\Users\bqbpb\OneDrive\Desktop\Project_Epic\data\csv\HospitalDim.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);

------------------------------------------------------------
-- PayorDim
------------------------------------------------------------
BULK INSERT dbo.PayorDim
FROM 'C:\Users\bqbpb\OneDrive\Desktop\Project_Epic\data\csv\PayorDim.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);

------------------------------------------------------------
-- ProviderDim
------------------------------------------------------------
BULK INSERT dbo.ProviderDim
FROM 'C:\Users\bqbpb\OneDrive\Desktop\Project_Epic\data\csv\ProviderDim.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);

------------------------------------------------------------
-- PatientDim
------------------------------------------------------------
BULK INSERT dbo.PatientDim
FROM 'C:\Users\bqbpb\OneDrive\Desktop\Project_Epic\data\csv\PatientDim.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);

------------------------------------------------------------
-- EncounterFact
------------------------------------------------------------
BULK INSERT dbo.EncounterFact
FROM 'C:\Users\bqbpb\OneDrive\Desktop\Project_Epic\data\csv\EncounterFact.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);

------------------------------------------------------------
-- ProcedureFact
------------------------------------------------------------
BULK INSERT dbo.ProcedureFact
FROM 'C:\Users\bqbpb\OneDrive\Desktop\Project_Epic\data\csv\ProcedureFact.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);

------------------------------------------------------------
-- DiagnosisFact
------------------------------------------------------------
BULK INSERT dbo.DiagnosisFact
FROM 'C:\Users\bqbpb\OneDrive\Desktop\Project_Epic\data\csv\DiagnosisFact.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);

------------------------------------------------------------
-- MedicationFact
------------------------------------------------------------
BULK INSERT dbo.MedicationFact
FROM 'C:\Users\bqbpb\OneDrive\Desktop\Project_Epic\data\csv\MedicationFact.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);

------------------------------------------------------------
-- LabResultFact
------------------------------------------------------------
BULK INSERT dbo.LabResultFact
FROM 'C:\Users\bqbpb\OneDrive\Desktop\Project_Epic\data\csv\LabResultFact.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);
