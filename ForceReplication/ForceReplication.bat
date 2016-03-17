@ECHO OFF
 
REM Location of the ntfrsutil tool from the File Replication Service Diagnostics Tool.
REM This can be downloaded from: http://www.microsoft.com/en-gb/download/details.aspx?id=8613
SET NTFRSUTL="C:\Program Files (x86)\Windows Resource Kits\Tools\FRSDiag\ntfrsutl.exe"
 
CALL :ForceKCCUpdate
 
REM Get the forest partition dn without specifying the parent domain.
FOR /F %%p IN ('dsquery * forestroot -scope subtree -filter "(objectClass=crossRefContainer)" -l -limit 0') DO (
 
    REM Get all parent/child domains from the forest configuration.
    FOR /F %%d IN ('dsquery * %%p -scope subtree -filter "(&(objectClass=crossRef)(nETBIOSName=*))" -attr dnsRoot -l -limit 0') DO (
        CALL :ReplicateDomain %%d
    )
)
 
GOTO END
 
:ReplicateDomain
    ECHO Replicating Domain: %1
     
    REM Replicate SYSVOL.
    FOR /F %%f IN ('DsQuery Server -domain %1 -limit 0 -o rdn') DO (
        FOR /F %%t IN ('DsQuery Server -domain %1 -limit 0 -o rdn') DO (
            IF /I "%%f" NEQ "%%t" (
                ECHO Replicating SYSVOL from %%f to %%t
                %NTFRSUTL% forcerepl %%t /r "Domain System Volume (SYSVOL share)" /p %%f
            )
        )
    )
 
    REM Replicate AD.
    ECHO Replicating AD
    repadmin /syncall %1 /APed
 
GOTO END
 
:ForceKCCUpdate
    ECHO Forcing KCC Update
 
    REM Force the KCC to recalculate in all sites.
    FOR /F %%s IN ('DsQuery Site -limit 0 -o rdn') DO (
        repadmin /kcc site:%%s
    )
 
GOTO END
 
:END