-- Run this SQL AFTER you have loaded data from ketch/data/user_consent.csv into SNOWFLAKE_CONSENT_DEMO.KETCH_CONSENT_DATA.USER_CONSENT_STAGE 
INSERT INTO SNOWFLAKE_CONSENT_DEMO.KETCH_CONSENT_DATA.USER_CONSENT (
    organization_code, identity_space, identity_value, purpose, consent, recorded_at
) (
    SELECT 'MOONRAKER', 'email_sha256', user_hashed_email, purpose, consent, recorded_at
    FROM SNOWFLAKE_CONSENT_DEMO.KETCH_CONSENT_DATA.USER_CONSENT_STAGE
);

DELETE FROM SNOWFLAKE_CONSENT_DEMO.KETCH_CONSENT_DATA.USER_CONSENT_STAGE;

-- Run this SQL AFTER you have loaded data from ketch/data/user_consent_skyfall.csv into SNOWFLAKE_CONSENT_DEMO.KETCH_CONSENT_DATA.USER_CONSENT_STAGE 
INSERT INTO SNOWFLAKE_CONSENT_DEMO.KETCH_CONSENT_DATA.USER_CONSENT (
    organization_code, identity_space, identity_value, purpose, consent, recorded_at
) (
    SELECT 'SKYFALL', 'email_sha256', user_hashed_email, purpose, consent, recorded_at
    FROM SNOWFLAKE_CONSENT_DEMO.KETCH_CONSENT_DATA.USER_CONSENT_STAGE
);