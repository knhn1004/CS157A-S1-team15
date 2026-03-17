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
