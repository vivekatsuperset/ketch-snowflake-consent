# Introduction

Privacy compliance, particularly consent-based data processing, is becoming a critical requirement for companies due to the increasing focus on user data protection and the regulatory landscape. GDPR, CCPA. and other regional privacy regulations now require that store user data is collected, stored, and processed in a manner that respects consumer choice. Consent-based data processing empowers individuals to control how their data is used, providing clarity on its purposes and offering the ability to withdraw consent at any time. Failure to comply not only risks hefty fines but also damages consumer trust, leading to long-term reputational harm. As users become more conscious of their digital privacy rights, organizations that prioritize privacy compliance gain a competitive advantage, fostering trust and safeguarding their operations in an evolving regulatory environment.

Many organizations have adopted Snowflake as their CDP (Customer Data Platform) for managing user and customer data. While these organizations have implemented various use cases to use, process, and activate customer data, often times those implementations do not integrate user consent data into those 

# Setup

### Moonraker CDP

Moonraker is a Ketch customer that collects and processes user data. Moonraker stores its user data in two Snowflake tables: user_data and user_page_view_events. All user data is keyed off the SHA256 encoding of the user’s email address. The table structures are as under:

```sql
Table: MOONRAKER.CDP.USER_DATA
Columns:
	user_hashed_email varchar(100) not null,
    gender varchar(20) not null,
    age_range varchar(20) not null,
    household_income varchar(50) not null,
    martial_status varchar(20) not null,
    profession varchar(50) not null
    
Table: MOONRAKER.CDP.USER_PAGE_VIEW_EVENTS
Columns:
    user_hashed_email varchar(100) not null,
    site varchar(100) not null,
    event_timestamp timestamp not null
```

### Ketch Consent

Ketch stores user consent as permits in the Ketch Permit Vault in Snowflake. The Ketch Permit Vault is a multi-tenant table that contains permits for all users across all organizations that are Ketch customers. When requested by the customer, Ketch shares their a secure view of their permit vault with the customer using Snowflake Secure Share. 

After Ketch has shared the consent view with Moonraker, a Snowflake ACCOUNTADMIN at Moonraker can accept the share and create a database from the share like so:

```sql
CREATE DATABASE KETCH_CONSENT_DATA FROM SHARE ZJUBOVK.KETCH_DEV_PDX.MOONRAKER_SHARE;
```

After that statement executes successfully, a new view is available in the Moornaker Snowflake instance:

```sql
View: KETCH_CONSENT_DATA.ORG_SHARED_VIEWS.MOONRAKER_USER_CONSENT
Columns:
    organization_code varchar(100) not null,
    identity_space varchar(100) not null,
    identity_value varchar(1024) not null,
    purpose varchar(32) not null,
    consent boolean not null,
    recorded_at timestamp

```

### Integrating Consent into User Data Processing

To integrate the consent data from Ketch into all user data tables, Moonraker can make use of Row Access policies in Snowflake. The process is described below:


- Define a Snowflake Role and User for each Purpose (example using purpose = ANALYTICS shown below).

```sql
CREATE ROLE ANALYTICS;
CREATE USER ANALYTICS_USER PASSWORD='Ch1ng5m5!42' DEFAULT_ROLE = ANALYTICS MUST_CHANGE_PASSWORD = FALSE;
GRANT ROLE ANALYTICS TO USER ANALYTICS_USER;
```

- Create a Snowflake Role and User that will own the row access policy that we will define later. This is done to prevent runtime policy evaluation from being executed as ACCOUNTADMIN.

```sql
CREATE ROLE PURPOSE_POLICY_ROLE;
CREATE USER PURPOSE_POLICY_USER PASSWORD='Ch1ng5m5!42'
    DEFAULT_ROLE = PURPOSE_POLICY_ROLE MUST_CHANGE_PASSWORD = FALSE;
GRANT ROLE PURPOSE_POLICY_ROLE TO USER PURPOSE_POLICY_USER;
GRANT IMPORTED PRIVILEGES ON DATABASE KETCH_CONSENT_DATA TO ROLE PURPOSE_POLICY_ROLE;
```

- Create a Snowflake schema to house the row access policy. While this step is not necessary, it is a good idea to organize your Snowflake objects using schemas.

```sql
CREATE SCHEMA MOONRAKER.CONSENT_POLICIES;
```

- Define the row access policy

```sql
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
```

- Grant the requisite privileges to role ANALYTICS.

```sql
GRANT USAGE ON DATABASE MOONRAKER TO ROLE ANALYTICS;
GRANT USAGE ON SCHEMA MOONRAKER.CDP TO ROLE ANALYTICS;
GRANT USAGE ON SCHEMA MOONRAKER.CONSENT_POLICIES TO ROLE ANALYTICS;
GRANT SELECT ON TABLE MOONRAKER.CDP.USER_DATA TO ROLE ANALYTICS;
GRANT SELECT ON TABLE MOONRAKER.CDP.USER_PAGE_VIEW_EVENTS TO ROLE ANALYTICS;
```

The row access policy is not useful in and of itself. It needs to be added (or associated) with a table or view for it to be useful.

```sql
ALTER TABLE MOONRAKER.CDP.USER_DATA
    ADD ROW ACCESS POLICY MOONRAKER.CONSENT_POLICIES.PURPOSE_POLICY ON (user_hashed_email);
```

The above statement adds the row access policy to the USER_DATA table and binds the user_hashed_email column from the USER_DATA table to the user_hashed_email_input parameter of the row access policy. 

After this policy is applied to the USER_DATA table, the following access rules apply:

- the logged in Snowflake user must be part of the <MOONRAKER_SNOWFLAKE_ACCOUNT> AND have SYSADMIN or ACCOUNTADMIN privileges, OR
- the logged in Snowflake user must be part of the <MOONRAKER_SNOWFLAKE_ACCOUNT>  and be logged in as a role that matches the value of the “purpose” column in the MOONRAKER_USER_CONSENT table AND the value of the “user_hashed_email” column in the USER_DATA table must match the value of the “identity_value” column when the value of the “identity_space” column is “email_sha256”

In other words, outside of Snowflake admins (SYSADMIN and ACCOUNTADMIN), the USER_DATA table can only be accessed by Snowflake DB users who are logged in with a role that matches a purpose in the MOONRAKER_USER_CONSENT table and those DB users will only be able to access rows for users that given consent for their data to be used for the corresponding purpose.

- Repeat the above process for the USER_PAGE_VIEW_EVENTS table:

```sql
ALTER TABLE MOONRAKER.CDP.USER_PAGE_VIEW_EVENTS
    ADD ROW ACCESS POLICY MOONRAKER.CONSENT_POLICIES.PURPOSE_POLICY ON (user_hashed_email);
```