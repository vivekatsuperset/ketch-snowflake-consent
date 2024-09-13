# Introduction
This directory contains SQL scripts and sample data that can be used to mimic the behaviour of the Ketch Permit Vault in Snowflake. Please note that all the table definitions described here are not exact matches but representative of the actual Ketch platform.

# Permit Vault
Ketch stores user consent as permits in the Ketch Permit Vault in Snowflake. The Ketch Permit Vault is a multi-tenant table that contains permits for all users across all organizations that are Ketch customers. When requested by the customer, Ketch shares their a secure view of their permit vault with the customer using Snowflake Secure Share. 

The structure of the Ketch Permit Vault is like so:
```sql
    organization_code varchar(100) not null,
    identity_space varchar(100) not null,
    identity_value varchar(1024) not null,
    purpose varchar(32) not null,
    consent boolean not null,
    recorded_at timestamp
```

To setup the Ketch Permit Vault on your own, follow the steps below:
* Sign up for a new Snowflake Account. 
* As ACCOUNTADMIN:
    * Create a new database called SNOWFLAKE_CONSENT_DEMO.
    * Create a new schema called SNOWFLAKE_CONSENT_DEMO.KETCH_CONSENT_DATA
    * Create two tables: USER_CONSENT and USER_CONSENT_STAGE. 
    * Use the DDL statements in ketch/schema.sql to create the above objects via the Snowsight console.
* Ketch creates at least one "Organization" for every customer in the Ketch platform. In our example, we will be using two organizations: Moonraker and Skyfall. Follow the steps below to load user consent data in the permit vault for two organizations named Moonraker and Skyfall respectively.
* The simplest and fastest way to load user consent data into the Ketch permit vault is to load the data from the CSV files present in the data directory into SNOWFLAKE_CONSENT_DEMO.KETCH_CONSENT_DATA.USER_CONSENT_STAGE and then load the data into USER_CONSENT.
    * Use the SQL statements in loader.sql to load data from SNOWFLAKE_CONSENT_DEMO.KETCH_CONSENT_DATA.USER_CONSENT_STAGE into SNOWFLAKE_CONSENT_DEMO.KETCH_CONSENT_DATA.USER_CONSENT.

Now that we have user consent data loaded in the permit vault for Moonraker and Skyfall, we will now describe how to secure share Moonraker's user consent data with the Moonraker Snowflake account.

# Permit Vault Data Sharing using Snowflake Secure Share

