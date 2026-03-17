CREATE DATABASE IF NOT EXISTS Team_15;
USE Team_15;

CREATE TABLE School (
    name VARCHAR(100) PRIMARY KEY
);

CREATE TABLE Users (
    User_ID VARCHAR(50) PRIMARY KEY,
    Username VARCHAR(50) UNIQUE NOT NULL,
    Email VARCHAR(100) NOT NULL,
    Name VARCHAR(50) NOT NULL,
    Password_Hash VARCHAR(100) NOT NULL,
    Major VARCHAR(50),
    Year INTEGER,
    School_name VARCHAR(100),
    FOREIGN KEY (School_name) REFERENCES School(name)
);

CREATE TABLE TimeBlock (
    Block_ID VARCHAR(50) PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Description VARCHAR(200),
    Date_Recurring VARCHAR(50),
    Created_User_ID VARCHAR(50),
    FOREIGN KEY (Created_User_ID) REFERENCES Users(User_ID)
);
