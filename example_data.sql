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

INSERT INTO Users (Username, Email, Name, Password_Hash, Major, Year, School_name) VALUES
('sarah01', 'sarah@sjsu.edu', 'Sarah', 'hash001', 'Computer Science', 3, 'SJSU'),
('oliver02', 'oliver@sjsu.edu', 'Oliver', 'hash002', 'Computer Science', 3, 'SJSU'),
('karan03', 'karan@sjsu.edu', 'Karan', 'hash003', 'Computer Science', 4, 'SJSU'),
('mikewu04', 'mikewu@sjsu.edu', 'Mike Wu', 'hash004', 'Software Engineering', 3, 'SJSU'),
('student5', 'student5@sjsu.edu', 'Student5', 'hash005', 'Computer Science', 2, 'SJSU'),
('student6', 'student6@sjsu.edu', 'Student6', 'hash006', 'Mathematics', 1, 'SJSU'),
('student7', 'student7@sjsu.edu', 'Student7', 'hash007', 'Computer Science', 4, 'SJSU'),
('student8', 'student8@sjsu.edu', 'Student8', 'hash008', 'Data Science', 2, 'SJSU'),
('student9', 'student9@sjsu.edu', 'Student9', 'hash009', 'Software Engineering', 3, 'SJSU'),
('student10', 'student10@sjsu.edu', 'Student10', 'hash010', 'Computer Science', 1, 'SJSU');

INSERT INTO TimeBlock (Block_ID, Name, Description, Date_Recurring, Created_Username) VALUES
('TB001', 'Morning Study', 'Early morning study block', 'Monday', 'sarah01'),
('TB002', 'Afternoon Review', 'Afternoon review session', 'Tuesday', 'oliver02'),
('TB003', 'Evening Practice', 'Evening coding practice', 'Wednesday', 'karan03'),
('TB004', 'Weekend Grind', 'Weekend long study block', 'Saturday', 'mikewu04'),
('TB005', 'Lunch Break Study', 'Quick study during lunch', 'Thursday', 'student5'),
('TB006', 'Night Owl', 'Late night study block', 'Friday', 'student6'),
('TB007', 'Lab Prep', 'Prepare for lab sessions', 'Monday', 'student7'),
('TB008', 'Exam Review', 'Review before exams', 'Wednesday', 'student8'),
('TB009', 'Group Work', 'Group project time', 'Tuesday', 'student9'),
('TB010', 'Office Hours', 'Visit office hours', 'Thursday', 'student10');


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

INSERT INTO Attends (Session_ID, Username, Status) VALUES
('SS001', 'sarah01', 'Confirmed'),
('SS001', 'oliver02', 'Confirmed'),
('SS001', 'karan03', 'Confirmed'),
('SS002', 'mikewu04', 'Confirmed'),
('SS002', 'student5', 'Pending'),
('SS003', 'student6', 'Confirmed'),
('SS004', 'student7', 'Declined'),
('SS005', 'student8', 'Confirmed'),
('SS006', 'student9', 'Pending'),
('SS007', 'student10', 'Confirmed');

INSERT INTO Invited_To (Inviter, Invitee, Session_ID, Response) VALUES
('sarah01', 'oliver02', 'SS001', 'Accepted'),
('sarah01', 'karan03', 'SS001', 'Accepted'),
('sarah01', 'mikewu04', 'SS001', 'Pending'),
('oliver02', 'student5', 'SS002', 'Accepted'),
('karan03', 'student6', 'SS003', 'Declined'),
('mikewu04', 'student7', 'SS004', 'Accepted'),
('student5', 'student8', 'SS005', 'Pending'),
('student6', 'student9', 'SS006', 'Accepted'),
('student7', 'student10', 'SS007', 'Accepted'),
('student8', 'sarah01', 'SS008', 'Pending');

INSERT INTO Friends_With (Username1, Username2, Status) VALUES
('sarah01', 'oliver02', 'Accepted'),
('sarah01', 'karan03', 'Accepted'),
('sarah01', 'mikewu04', 'Accepted'),
('oliver02', 'karan03', 'Accepted'),
('oliver02', 'mikewu04', 'Accepted'),
('karan03', 'mikewu04', 'Accepted'),
('student5', 'student6', 'Accepted'),
('student7', 'student8', 'Accepted'),
('student9', 'student10', 'Accepted'),
('sarah01', 'student5', 'Accepted');

INSERT INTO Friend_Request (Sender_Username, Receiver_Username, Status, Created_At) VALUES
('sarah01', 'student6', 'Pending', '2025-03-01'),
('oliver02', 'student7', 'Pending', '2025-03-02'),
('karan03', 'student8', 'Accepted', '2025-03-03'),
('mikewu04', 'student9', 'Declined', '2025-03-04'),
('student5', 'sarah01', 'Accepted', '2025-03-05'),
('student6', 'oliver02', 'Pending', '2025-03-06'),
('student7', 'karan03', 'Accepted', '2025-03-07'),
('student8', 'mikewu04', 'Pending', '2025-03-08'),
('student9', 'student5', 'Declined', '2025-03-09'),
('student10', 'student6', 'Pending', '2025-03-10');
