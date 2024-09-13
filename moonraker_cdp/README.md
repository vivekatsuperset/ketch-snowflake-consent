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

To setup the Moonraker CDP on your own, follow the steps below:
* Sign up for a new Snowflake Account. 
* As ACCOUNTADMIN:
    * Create a new database called MOONRAKER.
    * Create a new schema called MOONRAKER.CDP
    * Create two tables: USER_DATA and USER_PAGE_VIEW_EVENTS
    * Use the DDL statements in ketch/schema.sql to create the above objects via the Snowsight console.
* Ketch creates at least one "Organization" for every customer in the Ketch platform. In our example, we will be using two organizations: Moonraker and Skyfall. Follow the steps below to load user consent data in the permit vault for two organizations named Moonraker and Skyfall respectively.
* The simplest and fastest way to load user consent data into the Ketch permit vault is to load the data from the CSV files present in the data directory into SNOWFLAKE_CONSENT_DEMO.KETCH_CONSENT_DATA.USER_CONSENT_STAGE and then load the data into USER_CONSENT.
    * Use the SQL statements in loader.sql to load data from SNOWFLAKE_CONSENT_DEMO.KETCH_CONSENT_DATA.USER_CONSENT_STAGE into SNOWFLAKE_CONSENT_DEMO.KETCH_CONSENT_DATA.USER_CONSENT.

Now that we have user consent data loaded in the permit vault for Moonraker and Skyfall, we will now describe how to secure share user consent data for Moonraker with the Moonraker Snowflake account.

### Integrating Consent into User Data Processing

To integrate the consent data from Ketch into all user data tables, Moonraker can make use of Row Access policies in Snowflake. The process is described below:
* Define a Snowflake Role and User for each Purpose. Refer to roles.sql for the DDL required to do this.
* Create a Snowflake Role and User that will own the row access policy that we will define later. This is done to prevent runtime policy evaluation from being executed as ACCOUNTADMIN.See roles.sql for the DDL required to do this.
* Create the Row Access Policy. Refer to consent_policy.sql for the DDL required to do this.
    * Create a Snowflake schema to house the row access policy. While this step is not necessary, it is a good idea to organize your Snowflake objects using schemas.
    * Define the row access policy.
    * Grant the requisite privileges to role ANALYTICS.


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