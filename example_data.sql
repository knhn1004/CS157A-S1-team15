USE Team_15;

INSERT INTO School (name) VALUES
('SJSU'),
('Stanford'),
('UC Berkeley'),
('UCLA'),
('USC'),
('MIT'),
('CalTech'),
('Harvard'),
('Yale'),
('Princeton');

INSERT INTO Users (User_ID, Username, Email, Name, Password_Hash, Major, Year, School_name) VALUES
('U001', 'sarah01', 'sarah@sjsu.edu', 'Sarah', 'hash001', 'Computer Science', 3, 'SJSU'),
('U002', 'oliver02', 'oliver@sjsu.edu', 'Oliver', 'hash002', 'Computer Science', 3, 'SJSU'),
('U003', 'karan03', 'karan@sjsu.edu', 'Karan', 'hash003', 'Computer Science', 4, 'SJSU'),
('U004', 'mikewu04', 'mikewu@sjsu.edu', 'Mike Wu', 'hash004', 'Software Engineering', 3, 'SJSU'),
('U005', 'student5', 'student5@sjsu.edu', 'Student5', 'hash005', 'Computer Science', 2, 'SJSU'),
('U006', 'student6', 'student6@sjsu.edu', 'Student6', 'hash006', 'Mathematics', 1, 'SJSU'),
('U007', 'student7', 'student7@sjsu.edu', 'Student7', 'hash007', 'Computer Science', 4, 'SJSU'),
('U008', 'student8', 'student8@sjsu.edu', 'Student8', 'hash008', 'Data Science', 2, 'SJSU'),
('U009', 'student9', 'student9@sjsu.edu', 'Student9', 'hash009', 'Software Engineering', 3, 'SJSU'),
('U010', 'student10', 'student10@sjsu.edu', 'Student10', 'hash010', 'Computer Science', 1, 'SJSU');

INSERT INTO TimeBlock (Block_ID, Name, Description, Date_Recurring, Created_User_ID) VALUES
('TB001', 'Morning Study', 'Early morning study block', 'Monday', 'U001'),
('TB002', 'Afternoon Review', 'Afternoon review session', 'Tuesday', 'U002'),
('TB003', 'Evening Practice', 'Evening coding practice', 'Wednesday', 'U003'),
('TB004', 'Weekend Grind', 'Weekend long study block', 'Saturday', 'U004'),
('TB005', 'Lunch Break Study', 'Quick study during lunch', 'Thursday', 'U005'),
('TB006', 'Night Owl', 'Late night study block', 'Friday', 'U006'),
('TB007', 'Lab Prep', 'Prepare for lab sessions', 'Monday', 'U007'),
('TB008', 'Exam Review', 'Review before exams', 'Wednesday', 'U008'),
('TB009', 'Group Work', 'Group project time', 'Tuesday', 'U009'),
('TB010', 'Office Hours', 'Visit office hours', 'Thursday', 'U010');

-- StudySession
INSERT INTO StudySession (Session_ID, Name, Time, Date, Location, Description, Capacity, Topic, Visibility, Organizer_Username) VALUES
('SS001', 'SQL Basics', '10:00', '2025-04-01', 'Library Room A', 'Intro to SQL queries', 10, 'Databases', 'Public', 'sarah01'),
('SS002', 'Normalization Review', '14:00', '2025-04-02', 'Library Room B', 'Review 1NF to 3NF', 8, 'Databases', 'Public', 'oliver02'),
('SS003', 'ER Diagrams', '16:00', '2025-04-03', 'Study Hall', 'Practice ER modeling', 6, 'Databases', 'Friends', 'karan03'),
('SS004', 'Java Review', '11:00', '2025-04-04', 'Lab 101', 'OOP concepts review', 12, 'Programming', 'Public', 'mikewu04'),
('SS005', 'Midterm Prep', '09:00', '2025-04-05', 'Library Room A', 'Midterm study session', 15, 'Databases', 'Public', 'student5'),
('SS006', 'Algo Practice', '13:00', '2025-04-06', 'Study Hall', 'Leetcode practice', 10, 'Algorithms', 'Public', 'student6'),
('SS007', 'Project Sprint', '15:00', '2025-04-07', 'Lab 102', 'Work on group project', 5, 'Project', 'Private', 'student7'),
('SS008', 'Final Review', '10:00', '2025-04-08', 'Library Room C', 'Final exam review', 20, 'Databases', 'Public', 'student8'),
('SS009', 'Presentation Prep', '12:00', '2025-04-09', 'Room 201', 'Practice presentations', 8, 'Project', 'Friends', 'student9'),
('SS010', 'Homework Help', '17:00', '2025-04-10', 'Lab 101', 'Help with assignments', 10, 'Databases', 'Public', 'student10');

-- Class
INSERT INTO Class (Subject_Abbr, Course_No, Section, Class_Name, Time, Days) VALUES
('CS', '157A', '01', 'Introduction to Database Management Systems', '10:30', 'MW'),
('CS', '157A', '02', 'Introduction to Database Management Systems', '12:00', 'MW'),
('CS', '146', '01', 'Data Structures and Algorithms', '09:00', 'TTh'),
('CS', '151', '01', 'Object-Oriented Design', '14:00', 'MW'),
('CS', '166', '01', 'Information Security', '10:30', 'TTh'),
('CS', '160', '01', 'Software Engineering', '15:00', 'MW'),
('MATH', '142', '01', 'Discrete Mathematics', '08:00', 'TTh'),
('CS', '152', '01', 'Programming Paradigms', '11:00', 'MW'),
('CS', '158A', '01', 'Computer Networks', '13:00', 'TTh'),
('CS', '149', '01', 'Operating Systems', '16:00', 'MW');

-- Enrolls
INSERT INTO Enrolls (Username, Subject_Abbr, Course_No, Section, Notes) VALUES
('sarah01', 'CS', '157A', '01', 'Need to review SQL'),
('oliver02', 'CS', '157A', '01', 'Focus on normalization'),
('karan03', 'CS', '157A', '02', 'ER diagrams practice'),
('mikewu04', 'CS', '157A', '01', 'Study for midterm'),
('student5', 'CS', '146', '01', 'Review sorting algos'),
('student6', 'MATH', '142', '01', 'Practice proofs'),
('student7', 'CS', '151', '01', 'Design patterns'),
('student8', 'CS', '166', '01', 'Crypto basics'),
('student9', 'CS', '160', '01', 'Agile methods'),
('student10', 'CS', '149', '01', 'Process scheduling');

