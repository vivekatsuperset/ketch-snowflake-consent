-- create separate schema that will host the row access policy
CREATE SCHEMA MOONRAKER.CONSENT_POLICIES;

GRANT IMPORTED PRIVILEGES ON DATABASE KETCH_CONSENT_DATA TO ROLE PURPOSE_POLICY_ROLE;

CREATE OR REPLACE ROW ACCESS POLICY MOONRAKER.CONSENT_POLICIES.PURPOSE_POLICY
AS (user_hashed_email_input varchar) RETURNS BOOLEAN ->
    CURRENT_ACCOUNT() = '<MOONRAKER_SNOWFLAKE_ACCOUNT>' AND 
    (
	    CURRENT_ROLE() IN ('SYSADMIN', 'ACCOUNTADMIN')
	    OR EXISTS (
	      SELECT 1 FROM KETCH_CONSENT_DATA.ORG_SHARED_VIEWS.MOONRAKER_USER_CONSENT
	        WHERE UPPER(purpose) = CURRENT_ROLE()
	        AND identity_space = 'email_sha256'
	        AND identity_value = user_hashed_email_input
	        AND consent = TRUE
	    )
	  )
);

GRANT OWNERSHIP ON ROW ACCESS POLICY MOONRAKER.CONSENT_POLICIES.PURPOSE_POLICY TO PURPOSE_POLICY_ROLE;

-- Grant the requisite privilges for the purpose roles (example for ANALYTICS)
GRANT USAGE ON DATABASE MOONRAKER TO ROLE ANALYTICS;
GRANT USAGE ON SCHEMA MOONRAKER.CDP TO ROLE ANALYTICS;
GRANT USAGE ON SCHEMA MOONRAKER.CONSENT_POLICIES TO ROLE ANALYTICS;
GRANT SELECT ON TABLE MOONRAKER.CDP.USER_DATA TO ROLE ANALYTICS;
GRANT SELECT ON TABLE MOONRAKER.CDP.USER_PAGE_VIEW_EVENTS TO ROLE ANALYTICS;

ALTER TABLE MOONRAKER.CDP.USER_DATA
    ADD ROW ACCESS POLICY MOONRAKER.CONSENT_POLICIES.PURPOSE_POLICY ON (user_hashed_email);
ALTER TABLE MOONRAKER.CDP.USER_PAGE_VIEW_EVENTS
    ADD ROW ACCESS POLICY MOONRAKER.CONSENT_POLICIES.PURPOSE_POLICY ON (user_hashed_email);

