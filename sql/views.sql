/* =========================================================
   DROP VIEWS IF THEY ALREADY EXIST
   ========================================================= */

IF OBJECT_ID('dbo.vw_HospitalDim', 'V') IS NOT NULL DROP VIEW dbo.vw_HospitalDim;
IF OBJECT_ID('dbo.vw_PayorDim', 'V') IS NOT NULL DROP VIEW dbo.vw_PayorDim;
IF OBJECT_ID('dbo.vw_ProviderDim', 'V') IS NOT NULL DROP VIEW dbo.vw_ProviderDim;
IF OBJECT_ID('dbo.vw_PatientDim', 'V') IS NOT NULL DROP VIEW dbo.vw_PatientDim;

IF OBJECT_ID('dbo.vw_EncounterFact', 'V') IS NOT NULL DROP VIEW dbo.vw_EncounterFact;
IF OBJECT_ID('dbo.vw_ProcedureFact', 'V') IS NOT NULL DROP VIEW dbo.vw_ProcedureFact;
IF OBJECT_ID('dbo.vw_DiagnosisFact', 'V') IS NOT NULL DROP VIEW dbo.vw_DiagnosisFact;
IF OBJECT_ID('dbo.vw_MedicationFact', 'V') IS NOT NULL DROP VIEW dbo.vw_MedicationFact;
IF OBJECT_ID('dbo.vw_LabResultFact', 'V') IS NOT NULL DROP VIEW dbo.vw_LabResultFact;

IF OBJECT_ID('dbo.vw_EncounterRVU', 'V') IS NOT NULL DROP VIEW dbo.vw_EncounterRVU;
IF OBJECT_ID('dbo.vw_EncounterLabAbnormal', 'V') IS NOT NULL DROP VIEW dbo.vw_EncounterLabAbnormal;

IF OBJECT_ID('dbo.vw_SurgeryCases', 'V') IS NOT NULL DROP VIEW dbo.vw_SurgeryCases;
IF OBJECT_ID('dbo.vw_SurgeonPerformance', 'V') IS NOT NULL DROP VIEW dbo.vw_SurgeonPerformance;
IF OBJECT_ID('dbo.vw_ORUtilizationDaily', 'V') IS NOT NULL DROP VIEW dbo.vw_ORUtilizationDaily;
GO


/* =========================================================
   1. Base Dimension Views
   ========================================================= */

CREATE VIEW dbo.vw_HospitalDim AS
SELECT HospitalDurableKey, HospitalName, SnapshotDateTime, RowStatus
FROM dbo.HospitalDim;
GO

CREATE VIEW dbo.vw_PayorDim AS
SELECT PayorDurableKey, PayorName, PayorType, SnapshotDateTime, RowStatus
FROM dbo.PayorDim;
GO

CREATE VIEW dbo.vw_ProviderDim AS
SELECT ProviderDurableKey, ProviderName, Specialty, SnapshotDateTime, RowStatus
FROM dbo.ProviderDim;
GO

CREATE VIEW dbo.vw_PatientDim AS
SELECT PatientDurableKey, Gender, DOB, ZipCode, SnapshotDateTime, RowStatus
FROM dbo.PatientDim;
GO


/* =========================================================
   2. Base Fact Views
   ========================================================= */

CREATE VIEW dbo.vw_EncounterFact AS
SELECT
    EncounterDurableKey,
    PatientDurableKey,
    HospitalDurableKey,
    SurgeonDurableKey,
    PayorDurableKey,
    AdmitDateTime,
    SurgeryStart,
    SurgeryEnd,
    ASAClass,
    AnesthesiaType,
    SnapshotDateTime,
    RowStatus
FROM dbo.EncounterFact;
GO

CREATE VIEW dbo.vw_ProcedureFact AS
SELECT
    ProcedureDurableKey,
    EncounterDurableKey,
    CPTCode,
    PrimaryProcedureFlag,
    TotalRVU,
    SnapshotDateTime,
    RowStatus
FROM dbo.ProcedureFact;
GO

CREATE VIEW dbo.vw_DiagnosisFact AS
SELECT
    DiagnosisDurableKey,
    EncounterDurableKey,
    ICD10Code,
    SnapshotDateTime,
    RowStatus
FROM dbo.DiagnosisFact;
GO

CREATE VIEW dbo.vw_MedicationFact AS
SELECT
    MedicationDurableKey,
    EncounterDurableKey,
    RxNormCode,
    SnapshotDateTime,
    RowStatus
FROM dbo.MedicationFact;
GO

CREATE VIEW dbo.vw_LabResultFact AS
SELECT
    LabResultDurableKey,
    EncounterDurableKey,
    LOINCCode,
    ResultValue,
    ResultFlag,
    SnapshotDateTime,
    RowStatus
FROM dbo.LabResultFact;
GO


/* =========================================================
   3. Aggregation Views
   ========================================================= */

CREATE VIEW dbo.vw_EncounterRVU AS
SELECT
    EncounterDurableKey,
    SUM(TotalRVU) AS TotalRVU
FROM dbo.vw_ProcedureFact
GROUP BY EncounterDurableKey;
GO

CREATE VIEW dbo.vw_EncounterLabAbnormal AS
SELECT
    EncounterDurableKey,
    COUNT(*) AS AbnormalLabCount
FROM dbo.vw_LabResultFact
WHERE ResultFlag IN ('H','L')
GROUP BY EncounterDurableKey;
GO


/* =========================================================
   4. Star Schema View
   ========================================================= */

CREATE VIEW dbo.vw_SurgeryCases AS
SELECT
    e.EncounterDurableKey,
    e.PatientDurableKey,
    e.HospitalDurableKey,
    e.SurgeonDurableKey,
    e.PayorDurableKey,

    p.Gender,
    p.DOB,
    p.ZipCode,

    h.HospitalName,
    pr.ProviderName AS SurgeonName,
    pr.Specialty    AS SurgeonSpecialty,
    pa.PayorName,
    pa.PayorType,

    e.AdmitDateTime,
    e.SurgeryStart,
    e.SurgeryEnd,
    DATEDIFF(MINUTE, e.SurgeryStart, e.SurgeryEnd) AS CaseMinutes,
    e.ASAClass,
    e.AnesthesiaType,

    rv.TotalRVU,
    la.AbnormalLabCount
FROM dbo.vw_EncounterFact e
LEFT JOIN dbo.vw_PatientDim p ON e.PatientDurableKey = p.PatientDurableKey
LEFT JOIN dbo.vw_HospitalDim h ON e.HospitalDurableKey = h.HospitalDurableKey
LEFT JOIN dbo.vw_ProviderDim pr ON e.SurgeonDurableKey = pr.ProviderDurableKey
LEFT JOIN dbo.vw_PayorDim pa ON e.PayorDurableKey = pa.PayorDurableKey
LEFT JOIN dbo.vw_EncounterRVU rv ON e.EncounterDurableKey = rv.EncounterDurableKey
LEFT JOIN dbo.vw_EncounterLabAbnormal la ON e.EncounterDurableKey = la.EncounterDurableKey;
GO


/* =========================================================
   5. Surgeon Performance (CTEs + Window Functions)
   ========================================================= */

CREATE VIEW dbo.vw_SurgeonPerformance AS
WITH CaseDurations AS (
    SELECT
        e.SurgeonDurableKey,
        pr.ProviderName AS SurgeonName,
        pr.Specialty    AS SurgeonSpecialty,
        DATEDIFF(MINUTE, e.SurgeryStart, e.SurgeryEnd) AS CaseMinutes
    FROM dbo.vw_EncounterFact e
    LEFT JOIN dbo.vw_ProviderDim pr
        ON e.SurgeonDurableKey = pr.ProviderDurableKey
),
Agg AS (
    SELECT
        SurgeonDurableKey,
        SurgeonName,
        SurgeonSpecialty,
        COUNT(*) AS CaseCount,
        AVG(CAST(CaseMinutes AS FLOAT)) AS AvgCaseMinutes
    FROM CaseDurations
    GROUP BY SurgeonDurableKey, SurgeonName, SurgeonSpecialty
),
WithMedian AS (
    SELECT
        cd.SurgeonDurableKey,
        cd.SurgeonName,
        cd.SurgeonSpecialty,
        a.CaseCount,
        a.AvgCaseMinutes,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY cd.CaseMinutes)
            OVER (PARTITION BY cd.SurgeonDurableKey) AS MedianCaseMinutes
    FROM CaseDurations cd
    INNER JOIN Agg a
        ON cd.SurgeonDurableKey = a.SurgeonDurableKey
)
SELECT DISTINCT
    SurgeonDurableKey,
    SurgeonName,
    SurgeonSpecialty,
    CaseCount,
    AvgCaseMinutes,
    MedianCaseMinutes,
    RANK() OVER (ORDER BY MedianCaseMinutes) AS RankByMedianDuration
FROM WithMedian;
GO


/* =========================================================
   6. OR Utilization (Daily)
   ========================================================= */

CREATE VIEW dbo.vw_ORUtilizationDaily AS
WITH Cases AS (
    SELECT
        e.HospitalDurableKey,
        h.HospitalName,
        CAST(e.SurgeryStart AS DATE) AS SurgeryDate,
        DATEDIFF(MINUTE, e.SurgeryStart, e.SurgeryEnd) AS CaseMinutes
    FROM dbo.vw_EncounterFact e
    LEFT JOIN dbo.vw_HospitalDim h
        ON e.HospitalDurableKey = h.HospitalDurableKey
),
Agg AS (
    SELECT
        HospitalDurableKey,
        HospitalName,
        SurgeryDate,
        SUM(CaseMinutes) AS TotalCaseMinutes
    FROM Cases
    GROUP BY HospitalDurableKey, HospitalName, SurgeryDate
)
SELECT
    HospitalDurableKey,
    HospitalName,
    SurgeryDate,
    TotalCaseMinutes,
    TotalCaseMinutes / 1440.0 AS ORUtilizationDays
FROM Agg;
GO
