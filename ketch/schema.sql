USE ROLE ACCOUNTADMIN;
CREATE DATABASE SNOWFLAKE_CONSENT_DEMO;
CREATE SCHEMA SNOWFLAKE_CONSENT_DEMO.KETCH_CONSENT_DATA;

CREATE TABLE SNOWFLAKE_CONSENT_DEMO.KETCH_CONSENT_DATA.USER_CONSENT (
    organization_code varchar(100) not null,
    identity_space varchar(100) not null,
    identity_value varchar(1024) not null,
    purpose varchar(32) not null,
    consent boolean not null,
    recorded_at timestamp
);

-- Intermediate table to help with ETL
CREATE TABLE SNOWFLAKE_CONSENT_DEMO.KETCH_CONSENT_DATA.USER_CONSENT_STAGE (
    user_hashed_email varchar(100) not null,
    purpose varchar(32) not null,
    consent boolean not null,
    recorded_at timestamp
);
