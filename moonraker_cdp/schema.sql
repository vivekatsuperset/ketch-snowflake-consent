-- execute in Snowflake as ACCOUNTADMIN

USE ROLE ACCOUNTADMIN;
CREATE DATABASE MOONRAKER;
CREATE SCHEMA MOONRAKER.CDP;

CREATE TABLE MOONRAKER.CDP.USER_DATA (
    user_hashed_email varchar(100) not null,
    gender varchar(20) not null,
    age_range varchar(20) not null,
    household_income varchar(50) not null,
    martial_status varchar(20) not null,
    profession varchar(50) not null
);

CREATE TABLE MOONRAKER.CDP.USER_PAGE_VIEW_EVENTS (
    user_hashed_email varchar(100) not null,
    site varchar(100) not null,
    event_timestamp timestamp not null
);