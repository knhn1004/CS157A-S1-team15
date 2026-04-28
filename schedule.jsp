<%@ page import="java.sql.*, java.util.UUID" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page session="true" %>
<%
  String username = (String) session.getAttribute("username");
  String name     = (String) session.getAttribute("name");
  if (username == null) {
    response.sendRedirect("index.jsp");
    return;
  }

  final String DB_URL  = "jdbc:mysql://localhost:3306/Team_15?autoReconnect=true&useSSL=false&allowPublicKeyRetrieval=true";
  final String DB_USER = "root";
  final String DB_PASS = "password";

  String notice = request.getParameter("notice") != null ? request.getParameter("notice").trim() : "";
  String bannerMsg = "";
  String bannerClass = "banner-success";

  if ("class_added".equals(notice)) {
    bannerMsg = "Class added to your schedule.";
  } else if ("class_updated".equals(notice)) {
    bannerMsg = "Class notes updated.";
  } else if ("class_deleted".equals(notice)) {
    bannerMsg = "Class removed from your schedule.";
  } else if ("class_exists".equals(notice)) {
    bannerMsg = "That class is already on your schedule.";
    bannerClass = "banner-info";
  } else if ("class_error".equals(notice)) {
    bannerMsg = "Could not save the class.";
    bannerClass = "banner-error";
  } else if ("timeblock_added".equals(notice)) {
    bannerMsg = "Time block added.";
  } else if ("timeblock_updated".equals(notice)) {
    bannerMsg = "Time block updated.";
  } else if ("timeblock_deleted".equals(notice)) {
    bannerMsg = "Time block deleted.";
  } else if ("timeblock_error".equals(notice)) {
    bannerMsg = "Could not save the time block.";
    bannerClass = "banner-error";
  }

  String classSubject = request.getParameter("subject") != null ? request.getParameter("subject").trim() : "";
  String classCourse = request.getParameter("courseNo") != null ? request.getParameter("courseNo").trim() : "";
  String classSection = request.getParameter("section") != null ? request.getParameter("section").trim() : "";
  String className = request.getParameter("className") != null ? request.getParameter("className").trim() : "";
  String classTime = request.getParameter("classTime") != null ? request.getParameter("classTime").trim() : "";
  String classDays = request.getParameter("classDays") != null ? request.getParameter("classDays").trim() : "";
  String classNotes = request.getParameter("notes") != null ? request.getParameter("notes").trim() : "";

  String blockId = request.getParameter("blockId") != null ? request.getParameter("blockId").trim() : "";
  String blockName = request.getParameter("blockName") != null ? request.getParameter("blockName").trim() : "";
  String blockTime = request.getParameter("blockTime") != null ? request.getParameter("blockTime").trim() : "";
  String blockDateRecurring = request.getParameter("blockDateRecurring") != null ? request.getParameter("blockDateRecurring").trim() : "";
  String blockDescription = request.getParameter("blockDescription") != null ? request.getParameter("blockDescription").trim() : "";

  String pageError = "";
  String classLookupMsg = "";
  String classLookupClass = "banner-info";
  boolean editingClass = false;
  boolean editingBlock = false;

  if ("POST".equalsIgnoreCase(request.getMethod())) {
    String action = request.getParameter("action") != null ? request.getParameter("action").trim() : "";
    Connection actionCon = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
      Class.forName("com.mysql.cj.jdbc.Driver");
      actionCon = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

      if ("lookup_class".equals(action)) {
        if (classSubject.isEmpty() || classCourse.isEmpty() || classSection.isEmpty()) {
          classLookupMsg = "Enter subject, course number, and section first.";
          classLookupClass = "banner-error";
        } else {
          ps = actionCon.prepareStatement(
            "SELECT Class_Name, Time, Days FROM Class WHERE Subject_Abbr = ? AND Course_No = ? AND Section = ?"
          );
          ps.setString(1, classSubject);
          ps.setString(2, classCourse);
          ps.setString(3, classSection);
          rs = ps.executeQuery();
          if (rs.next()) {
            className = rs.getString("Class_Name") != null ? rs.getString("Class_Name") : "";
            classTime = rs.getTime("Time") != null ? rs.getTime("Time").toString().substring(0, 5) : "";
            classDays = rs.getString("Days") != null ? rs.getString("Days") : "";
            classLookupMsg = "Existing class found. Details were filled in for you.";
            classLookupClass = "banner-success";
          } else {
            classLookupMsg = "Class not found. Enter the class details manually below.";
            classLookupClass = "banner-info";
          }
          rs.close();
          ps.close();
        }
      } else if ("add_class".equals(action)) {
        if (classSubject.isEmpty() || classCourse.isEmpty() || classSection.isEmpty()) {
          pageError = "Subject, course number, and section are required.";
        } else {
          ps = actionCon.prepareStatement(
            "SELECT 1 FROM Enrolls WHERE Username = ? AND Subject_Abbr = ? AND Course_No = ? AND Section = ?"
          );
          ps.setString(1, username);
          ps.setString(2, classSubject);
          ps.setString(3, classCourse);
          ps.setString(4, classSection);
          rs = ps.executeQuery();
          boolean alreadyEnrolled = rs.next();
          rs.close();
          ps.close();

          if (alreadyEnrolled) {
            response.sendRedirect("schedule.jsp?notice=class_exists");
            return;
          }

          ps = actionCon.prepareStatement(
            "SELECT Class_Name, Time, Days FROM Class WHERE Subject_Abbr = ? AND Course_No = ? AND Section = ?"
          );
          ps.setString(1, classSubject);
          ps.setString(2, classCourse);
          ps.setString(3, classSection);
          rs = ps.executeQuery();
          boolean classExists = rs.next();

          if (!classExists) {
            rs.close();
            ps.close();

            if (className.isEmpty() || classTime.isEmpty() || classDays.isEmpty()) {
              pageError = "For a new class, name, time, and days are required.";
            } else {
              ps = actionCon.prepareStatement(
                "INSERT INTO Class (Subject_Abbr, Course_No, Section, Class_Name, Time, Days) VALUES (?, ?, ?, ?, ?, ?)"
              );
              ps.setString(1, classSubject);
              ps.setString(2, classCourse);
              ps.setString(3, classSection);
              ps.setString(4, className);
              ps.setString(5, classTime);
              ps.setString(6, classDays);
              ps.executeUpdate();
              ps.close();
            }
          } else {
            rs.close();
            ps.close();
          }

          if (pageError.isEmpty()) {
            ps = actionCon.prepareStatement(
              "INSERT INTO Enrolls (Username, Subject_Abbr, Course_No, Section, Notes) VALUES (?, ?, ?, ?, ?)"
            );
            ps.setString(1, username);
            ps.setString(2, classSubject);
            ps.setString(3, classCourse);
            ps.setString(4, classSection);
            ps.setString(5, classNotes.isEmpty() ? null : classNotes);
            ps.executeUpdate();
            ps.close();

            response.sendRedirect("schedule.jsp?notice=class_added");
            return;
          }
        }
      } else if ("update_class".equals(action)) {
        ps = actionCon.prepareStatement(
          "UPDATE Enrolls SET Notes = ? WHERE Username = ? AND Subject_Abbr = ? AND Course_No = ? AND Section = ?"
        );
        ps.setString(1, classNotes.isEmpty() ? null : classNotes);
        ps.setString(2, username);
        ps.setString(3, classSubject);
        ps.setString(4, classCourse);
        ps.setString(5, classSection);
        int updated = ps.executeUpdate();
        ps.close();

        if (updated == 1) {
          response.sendRedirect("schedule.jsp?notice=class_updated");
          return;
        }
        pageError = "Could not update that class.";
      } else if ("delete_class".equals(action)) {
        ps = actionCon.prepareStatement(
          "DELETE FROM Enrolls WHERE Username = ? AND Subject_Abbr = ? AND Course_No = ? AND Section = ?"
        );
        ps.setString(1, username);
        ps.setString(2, classSubject);
        ps.setString(3, classCourse);
        ps.setString(4, classSection);
        int deleted = ps.executeUpdate();
        ps.close();

        if (deleted == 1) {
          response.sendRedirect("schedule.jsp?notice=class_deleted");
          return;
        }
        pageError = "Could not delete that class.";
      } else if ("add_timeblock".equals(action)) {
        if (blockName.isEmpty() || blockTime.isEmpty() || blockDateRecurring.isEmpty()) {
          pageError = "Time block name, time, and date/recurring value are required.";
        } else {
          String newBlockId = "TB" + UUID.randomUUID().toString().replace("-", "").substring(0, 8).toUpperCase();
          ps = actionCon.prepareStatement(
            "INSERT INTO TimeBlock (Block_ID, Name, Time, Description, Date_Recurring, Created_Username) VALUES (?, ?, ?, ?, ?, ?)"
          );
          ps.setString(1, newBlockId);
          ps.setString(2, blockName);
          ps.setString(3, blockTime);
          ps.setString(4, blockDescription.isEmpty() ? null : blockDescription);
          ps.setString(5, blockDateRecurring);
          ps.setString(6, username);
          ps.executeUpdate();
          ps.close();

          response.sendRedirect("schedule.jsp?notice=timeblock_added");
          return;
        }
      } else if ("update_timeblock".equals(action)) {
        ps = actionCon.prepareStatement(
          "UPDATE TimeBlock SET Name = ?, Time = ?, Description = ?, Date_Recurring = ? " +
          "WHERE Block_ID = ? AND Created_Username = ?"
        );
        ps.setString(1, blockName);
        ps.setString(2, blockTime);
        ps.setString(3, blockDescription.isEmpty() ? null : blockDescription);
        ps.setString(4, blockDateRecurring);
        ps.setString(5, blockId);
        ps.setString(6, username);
        int updated = ps.executeUpdate();
        ps.close();

        if (updated == 1) {
          response.sendRedirect("schedule.jsp?notice=timeblock_updated");
          return;
        }
        pageError = "Could not update that time block.";
      } else if ("delete_timeblock".equals(action)) {
        ps = actionCon.prepareStatement(
          "DELETE FROM TimeBlock WHERE Block_ID = ? AND Created_Username = ?"
        );
        ps.setString(1, blockId);
        ps.setString(2, username);
        int deleted = ps.executeUpdate();
        ps.close();

        if (deleted == 1) {
          response.sendRedirect("schedule.jsp?notice=timeblock_deleted");
          return;
        }
        pageError = "Could not delete that time block.";
      }
    } catch (Exception e) {
      pageError = "Database error: " + e.getMessage();
    } finally {
      if (rs != null) try { rs.close(); } catch (Exception ignore) {}
      if (ps != null) try { ps.close(); } catch (Exception ignore) {}
      if (actionCon != null) try { actionCon.close(); } catch (Exception ignore) {}
    }
  }

  String editClassSubject = request.getParameter("editClassSubject") != null ? request.getParameter("editClassSubject").trim() : "";
  String editClassCourse = request.getParameter("editClassCourse") != null ? request.getParameter("editClassCourse").trim() : "";
  String editClassSection = request.getParameter("editClassSection") != null ? request.getParameter("editClassSection").trim() : "";

  if (!editClassSubject.isEmpty() && !editClassCourse.isEmpty() && !editClassSection.isEmpty()) {
    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    try {
      Class.forName("com.mysql.cj.jdbc.Driver");
      con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
      ps = con.prepareStatement(
        "SELECT c.Class_Name, c.Time, c.Days, e.Notes " +
        "FROM Enrolls e JOIN Class c ON c.Subject_Abbr = e.Subject_Abbr AND c.Course_No = e.Course_No AND c.Section = e.Section " +
        "WHERE e.Username = ? AND e.Subject_Abbr = ? AND e.Course_No = ? AND e.Section = ?"
      );
      ps.setString(1, username);
      ps.setString(2, editClassSubject);
      ps.setString(3, editClassCourse);
      ps.setString(4, editClassSection);
      rs = ps.executeQuery();
      if (rs.next()) {
        editingClass = true;
        classSubject = editClassSubject;
        classCourse = editClassCourse;
        classSection = editClassSection;
        className = rs.getString("Class_Name") != null ? rs.getString("Class_Name") : "";
        classTime = rs.getTime("Time") != null ? rs.getTime("Time").toString().substring(0, 5) : "";
        classDays = rs.getString("Days") != null ? rs.getString("Days") : "";
        classNotes = rs.getString("Notes") != null ? rs.getString("Notes") : "";
      }
      rs.close();
      ps.close();
      con.close();
    } catch (Exception e) {
      pageError = "Database error: " + e.getMessage();
    } finally {
      if (rs != null) try { rs.close(); } catch (Exception ignore) {}
      if (ps != null) try { ps.close(); } catch (Exception ignore) {}
      if (con != null) try { con.close(); } catch (Exception ignore) {}
    }
  }

  String editBlockId = request.getParameter("editBlockId") != null ? request.getParameter("editBlockId").trim() : "";
  if (!editBlockId.isEmpty()) {
    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    try {
      Class.forName("com.mysql.cj.jdbc.Driver");
      con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
      ps = con.prepareStatement(
        "SELECT Name, Time, Description, Date_Recurring FROM TimeBlock WHERE Block_ID = ? AND Created_Username = ?"
      );
      ps.setString(1, editBlockId);
      ps.setString(2, username);
      rs = ps.executeQuery();
      if (rs.next()) {
        editingBlock = true;
        blockId = editBlockId;
        blockName = rs.getString("Name") != null ? rs.getString("Name") : "";
        blockTime = rs.getTime("Time") != null ? rs.getTime("Time").toString().substring(0, 5) : "";
        blockDescription = rs.getString("Description") != null ? rs.getString("Description") : "";
        blockDateRecurring = rs.getString("Date_Recurring") != null ? rs.getString("Date_Recurring") : "";
      }
      rs.close();
      ps.close();
      con.close();
    } catch (Exception e) {
      pageError = "Database error: " + e.getMessage();
    } finally {
      if (rs != null) try { rs.close(); } catch (Exception ignore) {}
      if (ps != null) try { ps.close(); } catch (Exception ignore) {}
      if (con != null) try { con.close(); } catch (Exception ignore) {}
    }
  }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>My Schedule - SpartanStudyCircle</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }

    body {
      font-family: 'Segoe UI', sans-serif;
      background: #f3f4f6;
      min-height: 100vh;
    }

    nav {
      background: #0055A2;
      color: white;
      padding: 0 32px;
      height: 56px;
      display: flex;
      align-items: center;
      justify-content: space-between;
    }

    nav .brand { font-size: 18px; font-weight: 700; }
    nav .nav-links { display: flex; gap: 8px; }

    nav .nav-links a, nav a.logout {
      color: white;
      text-decoration: none;
      padding: 6px 14px;
      border-radius: 6px;
      font-size: 13px;
      font-weight: 600;
    }

    nav .nav-links a:hover, nav a.logout:hover { background: rgba(255,255,255,0.2); }
    nav .nav-links a.active { background: rgba(255,255,255,0.25); }

    nav .user-info {
      display: flex;
      align-items: center;
      gap: 12px;
      font-size: 14px;
    }

    .container {
      max-width: 1100px;
      margin: 32px auto;
      padding: 0 16px;
    }

    .banner {
      border-radius: 8px;
      padding: 12px 14px;
      font-size: 13px;
      font-weight: 600;
      margin-bottom: 16px;
    }

    .banner-success {
      background: #dcfce7;
      color: #166534;
    }

    .banner-info {
      background: #dbeafe;
      color: #1d4ed8;
    }

    .banner-error {
      background: #fee2e2;
      color: #991b1b;
    }

    .grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 20px;
      margin-bottom: 20px;
    }

    .card {
      background: white;
      border-radius: 12px;
      padding: 24px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.08);
      margin-bottom: 20px;
    }

    h2 {
      font-size: 18px;
      color: #0055A2;
      margin-bottom: 8px;
    }

    .subtitle {
      font-size: 13px;
      color: #6b7280;
      margin-bottom: 18px;
      padding-bottom: 14px;
      border-bottom: 2px solid #e5e7eb;
    }

    .field { margin-bottom: 14px; }

    label {
      display: block;
      font-size: 13px;
      font-weight: 600;
      color: #374151;
      margin-bottom: 6px;
    }

    input, textarea {
      width: 100%;
      padding: 10px 12px;
      border: 1.5px solid #d1d5db;
      border-radius: 8px;
      font-size: 14px;
      outline: none;
      font-family: inherit;
    }

    input:focus, textarea:focus { border-color: #0055A2; }
    textarea { resize: vertical; min-height: 80px; }

    .row {
      display: grid;
      grid-template-columns: 1fr 1fr 1fr;
      gap: 12px;
    }

    .row-2 {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 12px;
    }

    .button-row {
      display: flex;
      gap: 10px;
      flex-wrap: wrap;
      margin-top: 8px;
    }

    .btn, .link-btn {
      display: inline-block;
      padding: 10px 14px;
      border-radius: 8px;
      border: none;
      font-size: 13px;
      font-weight: 600;
      cursor: pointer;
      text-decoration: none;
      text-align: center;
    }

    .btn-primary, .link-btn {
      background: #0055A2;
      color: white;
    }

    .btn-primary:hover, .link-btn:hover { background: #004490; }

    .btn-secondary {
      background: #e5e7eb;
      color: #111827;
    }

    .btn-secondary:hover { background: #d1d5db; }

    .btn-danger {
      background: #fee2e2;
      color: #991b1b;
    }

    .btn-danger:hover { background: #fecaca; }

    table {
      width: 100%;
      border-collapse: collapse;
      font-size: 13px;
    }

    thead tr { background: #f9fafb; }

    th, td {
      text-align: left;
      padding: 10px 12px;
      color: #374151;
      border-bottom: 1px solid #f3f4f6;
      vertical-align: middle;
    }

    th {
      font-weight: 600;
      border-bottom-color: #e5e7eb;
    }

    .table-actions {
      display: flex;
      gap: 8px;
      flex-wrap: wrap;
    }

    .inline-form { margin: 0; }

    .muted {
      color: #6b7280;
      font-size: 12px;
    }

    .no-data {
      text-align: center;
      color: #9ca3af;
      padding: 24px 0;
      font-size: 14px;
    }
  </style>
</head>
<body>
  <nav>
    <span class="brand">&#128218; SpartanStudyCircle</span>
    <div class="nav-links">
      <a href="home.jsp">Home</a>
      <a href="schedule.jsp" class="active">My Schedule</a>
      <a href="create_session.jsp">+ Create Session</a>
      <a href="people.jsp">Find People</a>
      <a href="friends.jsp">Friends</a>
      <a href="profile.jsp">My Profile</a>
    </div>
    <div class="user-info">
      <span><%= name %></span>
      <a class="logout" href="home.jsp?action=logout">Log Out</a>
    </div>
  </nav>

  <div class="container">
    <% if (!bannerMsg.isEmpty()) { %>
      <div class="banner <%= bannerClass %>"><%= bannerMsg %></div>
    <% } %>

    <% if (!pageError.isEmpty()) { %>
      <div class="banner banner-error"><%= pageError %></div>
    <% } %>

    <div class="grid">
      <div class="card">
        <h2><%= editingClass ? "Edit Class Notes" : "Add Class" %></h2>
        <p class="subtitle">Add classes to your schedule, look up existing class info, and edit your own notes.</p>

        <% if (!classLookupMsg.isEmpty()) { %>
          <div class="banner <%= classLookupClass %>"><%= classLookupMsg %></div>
        <% } %>

        <% if (editingClass) { %>
          <form method="POST" action="schedule.jsp">
            <input type="hidden" name="action" value="update_class" />
            <input type="hidden" name="subject" value="<%= classSubject %>" />
            <input type="hidden" name="courseNo" value="<%= classCourse %>" />
            <input type="hidden" name="section" value="<%= classSection %>" />

            <div class="field">
              <label>Course</label>
              <input type="text" value="<%= classSubject %> <%= classCourse %>-<%= classSection %>" readonly />
            </div>
            <div class="field">
              <label>Class Name</label>
              <input type="text" value="<%= className %>" readonly />
            </div>
            <div class="row-2">
              <div class="field">
                <label>Time</label>
                <input type="text" value="<%= classTime %>" readonly />
              </div>
              <div class="field">
                <label>Days</label>
                <input type="text" value="<%= classDays %>" readonly />
              </div>
            </div>
            <div class="field">
              <label>My Notes</label>
              <textarea name="notes" placeholder="Optional notes for this class"><%= classNotes %></textarea>
            </div>
            <div class="button-row">
              <button class="btn btn-primary" type="submit">Save Notes</button>
              <a class="link-btn" href="schedule.jsp">Cancel</a>
            </div>
          </form>
        <% } else { %>
          <form method="POST" action="schedule.jsp">
            <div class="row">
              <div class="field">
                <label>Subject</label>
                <input type="text" name="subject" value="<%= classSubject %>" placeholder="CS" />
              </div>
              <div class="field">
                <label>Course Number</label>
                <input type="text" name="courseNo" value="<%= classCourse %>" placeholder="157A" />
              </div>
              <div class="field">
                <label>Section</label>
                <input type="text" name="section" value="<%= classSection %>" placeholder="01" />
              </div>
            </div>

            <div class="button-row">
              <button class="btn btn-secondary" type="submit" name="action" value="lookup_class">Look Up Existing Class</button>
            </div>

            <div class="row-2">
              <div class="field">
                <label>Class Name</label>
                <input type="text" name="className" value="<%= className %>" placeholder="Introduction to Database Management Systems" />
              </div>
              <div class="field">
                <label>Time</label>
                <input type="time" name="classTime" value="<%= classTime %>" />
              </div>
            </div>

            <div class="field">
              <label>Days</label>
              <input type="text" name="classDays" value="<%= classDays %>" placeholder="MW or TTh" />
            </div>

            <div class="field">
              <label>My Notes</label>
              <textarea name="notes" placeholder="Optional notes for this class"><%= classNotes %></textarea>
            </div>

            <div class="button-row">
              <button class="btn btn-primary" type="submit" name="action" value="add_class">Add Class to Schedule</button>
            </div>
          </form>
        <% } %>
      </div>

      <div class="card">
        <h2><%= editingBlock ? "Edit Time Block" : "Add Time Block" %></h2>
        <p class="subtitle">Create custom time blocks for study, work, or anything else on your schedule.</p>

        <form method="POST" action="schedule.jsp">
          <input type="hidden" name="action" value="<%= editingBlock ? "update_timeblock" : "add_timeblock" %>" />
          <input type="hidden" name="blockId" value="<%= blockId %>" />

          <div class="field">
            <label>Name</label>
            <input type="text" name="blockName" value="<%= blockName %>" placeholder="Morning Study" />
          </div>

          <div class="row-2">
            <div class="field">
              <label>Time</label>
              <input type="time" name="blockTime" value="<%= blockTime %>" />
            </div>
            <div class="field">
              <label>Date / Recurring</label>
              <input type="text" name="blockDateRecurring" value="<%= blockDateRecurring %>" placeholder="Monday or 2026-05-01" />
            </div>
          </div>

          <div class="field">
            <label>Description</label>
            <textarea name="blockDescription" placeholder="Optional details"><%= blockDescription %></textarea>
          </div>

          <div class="button-row">
            <button class="btn btn-primary" type="submit"><%= editingBlock ? "Save Time Block" : "Add Time Block" %></button>
            <% if (editingBlock) { %>
              <a class="link-btn" href="schedule.jsp">Cancel</a>
            <% } %>
          </div>
        </form>
      </div>
    </div>

    <div class="card">
      <h2>My Classes</h2>
      <p class="subtitle">Edit your own class notes or remove a class from your schedule.</p>

      <%
        Connection classCon = null;
        PreparedStatement classPs = null;
        ResultSet classRs = null;
        try {
          Class.forName("com.mysql.cj.jdbc.Driver");
          classCon = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
          classPs = classCon.prepareStatement(
            "SELECT e.Subject_Abbr, e.Course_No, e.Section, e.Notes, c.Class_Name, c.Time, c.Days " +
            "FROM Enrolls e JOIN Class c ON c.Subject_Abbr = e.Subject_Abbr AND c.Course_No = e.Course_No AND c.Section = e.Section " +
            "WHERE e.Username = ? " +
            "ORDER BY c.Subject_Abbr ASC, c.Course_No ASC, c.Section ASC"
          );
          classPs.setString(1, username);
          classRs = classPs.executeQuery();
      %>
      <table>
        <thead>
          <tr>
            <th>Course</th>
            <th>Class Name</th>
            <th>Days</th>
            <th>Time</th>
            <th>Notes</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody>
          <%
            boolean hasClasses = false;
            while (classRs.next()) {
              hasClasses = true;
          %>
            <tr>
              <td><strong><%= classRs.getString("Subject_Abbr") %> <%= classRs.getString("Course_No") %>-<%= classRs.getString("Section") %></strong></td>
              <td><%= classRs.getString("Class_Name") != null ? classRs.getString("Class_Name") : "—" %></td>
              <td><%= classRs.getString("Days") != null ? classRs.getString("Days") : "—" %></td>
              <td><%= classRs.getTime("Time") != null ? classRs.getTime("Time").toString().substring(0, 5) : "—" %></td>
              <td><%= classRs.getString("Notes") != null ? classRs.getString("Notes") : "—" %></td>
              <td>
                <div class="table-actions">
                  <a class="link-btn" href="schedule.jsp?editClassSubject=<%= classRs.getString("Subject_Abbr") %>&editClassCourse=<%= classRs.getString("Course_No") %>&editClassSection=<%= classRs.getString("Section") %>">Edit Notes</a>
                  <form class="inline-form" method="POST" action="schedule.jsp">
                    <input type="hidden" name="action" value="delete_class" />
                    <input type="hidden" name="subject" value="<%= classRs.getString("Subject_Abbr") %>" />
                    <input type="hidden" name="courseNo" value="<%= classRs.getString("Course_No") %>" />
                    <input type="hidden" name="section" value="<%= classRs.getString("Section") %>" />
                    <button class="btn btn-danger" type="submit">Delete</button>
                  </form>
                </div>
              </td>
            </tr>
          <% } %>
          <% if (!hasClasses) { %>
            <tr><td colspan="6" class="no-data">No classes on your schedule yet.</td></tr>
          <% } %>
        </tbody>
      </table>
      <%
        } catch (Exception e) {
      %>
        <div class="banner banner-error">Database error: <%= e.getMessage() %></div>
      <%
        } finally {
          if (classRs != null) try { classRs.close(); } catch (Exception ignore) {}
          if (classPs != null) try { classPs.close(); } catch (Exception ignore) {}
          if (classCon != null) try { classCon.close(); } catch (Exception ignore) {}
        }
      %>
    </div>

    <div class="card">
      <h2>My Time Blocks</h2>
      <p class="subtitle">Edit or delete only the time blocks you created.</p>

      <%
        Connection blockCon = null;
        PreparedStatement blockPs = null;
        ResultSet blockRs = null;
        try {
          Class.forName("com.mysql.cj.jdbc.Driver");
          blockCon = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
          blockPs = blockCon.prepareStatement(
            "SELECT Block_ID, Name, Time, Description, Date_Recurring FROM TimeBlock WHERE Created_Username = ? ORDER BY Name ASC"
          );
          blockPs.setString(1, username);
          blockRs = blockPs.executeQuery();
      %>
      <table>
        <thead>
          <tr>
            <th>Name</th>
            <th>Time</th>
            <th>Date / Recurring</th>
            <th>Description</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody>
          <%
            boolean hasBlocks = false;
            while (blockRs.next()) {
              hasBlocks = true;
          %>
            <tr>
              <td><strong><%= blockRs.getString("Name") %></strong></td>
              <td><%= blockRs.getTime("Time") != null ? blockRs.getTime("Time").toString().substring(0, 5) : "—" %></td>
              <td><%= blockRs.getString("Date_Recurring") != null ? blockRs.getString("Date_Recurring") : "—" %></td>
              <td><%= blockRs.getString("Description") != null ? blockRs.getString("Description") : "—" %></td>
              <td>
                <div class="table-actions">
                  <a class="link-btn" href="schedule.jsp?editBlockId=<%= blockRs.getString("Block_ID") %>">Edit</a>
                  <form class="inline-form" method="POST" action="schedule.jsp">
                    <input type="hidden" name="action" value="delete_timeblock" />
                    <input type="hidden" name="blockId" value="<%= blockRs.getString("Block_ID") %>" />
                    <button class="btn btn-danger" type="submit">Delete</button>
                  </form>
                </div>
              </td>
            </tr>
          <% } %>
          <% if (!hasBlocks) { %>
            <tr><td colspan="5" class="no-data">No time blocks on your schedule yet.</td></tr>
          <% } %>
        </tbody>
      </table>
      <%
        } catch (Exception e) {
      %>
        <div class="banner banner-error">Database error: <%= e.getMessage() %></div>
      <%
        } finally {
          if (blockRs != null) try { blockRs.close(); } catch (Exception ignore) {}
          if (blockPs != null) try { blockPs.close(); } catch (Exception ignore) {}
          if (blockCon != null) try { blockCon.close(); } catch (Exception ignore) {}
        }
      %>
    </div>
  </div>
</body>
</html>
