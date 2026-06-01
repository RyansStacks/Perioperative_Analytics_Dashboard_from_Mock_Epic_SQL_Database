------------------------------------------------------------
-- 1. HospitalDim
------------------------------------------------------------
CREATE TABLE dbo.HospitalDim (
    HospitalDurableKey     VARCHAR(50),
    HospitalName           VARCHAR(200),
    SnapshotDateTime       DATETIME,
    RowStatus              VARCHAR(5)
);

------------------------------------------------------------
-- 2. PayorDim
------------------------------------------------------------
CREATE TABLE dbo.PayorDim (
    PayorDurableKey        VARCHAR(50),
    PayorName              VARCHAR(200),
    PayorType              VARCHAR(50),
    SnapshotDateTime       DATETIME,
    RowStatus              VARCHAR(5)
);

------------------------------------------------------------
-- 3. ProviderDim
------------------------------------------------------------
CREATE TABLE dbo.ProviderDim (
    ProviderDurableKey     VARCHAR(50),
    ProviderName           VARCHAR(200),
    Specialty              VARCHAR(100),
    SnapshotDateTime       DATETIME,
    RowStatus              VARCHAR(5)
);

------------------------------------------------------------
-- 4. PatientDim
------------------------------------------------------------
CREATE TABLE dbo.PatientDim (
    PatientDurableKey      VARCHAR(50),
    Gender                 VARCHAR(10),
    DOB                    DATE,
    ZipCode                VARCHAR(10),
    SnapshotDateTime       DATETIME,
    RowStatus              VARCHAR(5)
);

------------------------------------------------------------
-- 5. EncounterFact
------------------------------------------------------------
CREATE TABLE dbo.EncounterFact (
    EncounterDurableKey    VARCHAR(50),
    PatientDurableKey      VARCHAR(50),
    HospitalDurableKey     VARCHAR(50),
    SurgeonDurableKey      VARCHAR(50),
    PayorDurableKey        VARCHAR(50),
    AdmitDateTime          DATETIME,
    SurgeryStart           DATETIME,
    SurgeryEnd             DATETIME,
    ASAClass               INT,
    AnesthesiaType         VARCHAR(50),
    SnapshotDateTime       DATETIME,
    RowStatus              VARCHAR(5)
);

------------------------------------------------------------
-- 6. ProcedureFact
------------------------------------------------------------
CREATE TABLE dbo.ProcedureFact (
    ProcedureDurableKey    VARCHAR(50),
    EncounterDurableKey    VARCHAR(50),
    CPTCode                VARCHAR(20),
    PrimaryProcedureFlag   VARCHAR(5),
    TotalRVU               FLOAT,
    SnapshotDateTime       DATETIME,
    RowStatus              VARCHAR(5)
);

------------------------------------------------------------
-- 7. DiagnosisFact
------------------------------------------------------------
CREATE TABLE dbo.DiagnosisFact (
    DiagnosisDurableKey    VARCHAR(50),
    EncounterDurableKey    VARCHAR(50),
    ICD10Code              VARCHAR(20),
    SnapshotDateTime       DATETIME,
    RowStatus              VARCHAR(5)
);

------------------------------------------------------------
-- 8. MedicationFact
------------------------------------------------------------
CREATE TABLE dbo.MedicationFact (
    MedicationDurableKey   VARCHAR(50),
    EncounterDurableKey    VARCHAR(50),
    RxNormCode             VARCHAR(50),
    SnapshotDateTime       DATETIME,
    RowStatus              VARCHAR(5)
);

------------------------------------------------------------
-- 9. LabResultFact
------------------------------------------------------------
CREATE TABLE dbo.LabResultFact (
    LabResultDurableKey    VARCHAR(50),
    EncounterDurableKey    VARCHAR(50),
    LOINCCode              VARCHAR(20),
    ResultValue            FLOAT,
    ResultFlag             VARCHAR(5),
    SnapshotDateTime       DATETIME,
    RowStatus              VARCHAR(5)
);
