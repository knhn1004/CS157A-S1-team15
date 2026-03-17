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
CREATE TABLE StudySession (
    Session_ID VARCHAR(50) PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Time VARCHAR(50),
    Date VARCHAR(50),
    Location VARCHAR(100),
    Description VARCHAR(200),
    Capacity INTEGER,
    Topic VARCHAR(100),
    Visibility VARCHAR(50),
    Organizer_Username VARCHAR(50),
    FOREIGN KEY (Organizer_Username) REFERENCES Users(Username)
);

CREATE TABLE Class (
    Subject_Abbr VARCHAR(10) NOT NULL,
    Course_No VARCHAR(20) NOT NULL,
    Section VARCHAR(10) NOT NULL,
    Class_Name VARCHAR(100),
    Time VARCHAR(50),
    Days VARCHAR(50),
    PRIMARY KEY (Subject_Abbr, Course_No, Section)
);

CREATE TABLE Enrolls (
    Username VARCHAR(50) NOT NULL,
    Subject_Abbr VARCHAR(10) NOT NULL,
    Course_No VARCHAR(20) NOT NULL,
    Section VARCHAR(10) NOT NULL,
    Notes VARCHAR(200),
    PRIMARY KEY (Username, Subject_Abbr, Course_No, Section),
    FOREIGN KEY (Username) REFERENCES Users(Username),
    FOREIGN KEY (Subject_Abbr, Course_No, Section) REFERENCES Class(Subject_Abbr, Course_No, Section)
);
