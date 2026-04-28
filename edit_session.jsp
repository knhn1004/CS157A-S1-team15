<%@ page import="java.sql.*" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
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

  String sessionId = request.getParameter("sessionId") != null ? request.getParameter("sessionId").trim() : "";
  String errorMsg = "";

  String sessName = "";
  String sessDate = "";
  String sessTime = "";
  String location = "";
  String description = "";
  String topic = "";
  String capacity = "";
  String visibility = "Public";

  if ("POST".equalsIgnoreCase(request.getMethod()) && "update".equals(request.getParameter("action"))) {
    sessionId = request.getParameter("sessionId") != null ? request.getParameter("sessionId").trim() : "";
    sessName = request.getParameter("name") != null ? request.getParameter("name").trim() : "";
    sessDate = request.getParameter("date") != null ? request.getParameter("date").trim() : "";
    sessTime = request.getParameter("time") != null ? request.getParameter("time").trim() : "";
    location = request.getParameter("location") != null ? request.getParameter("location").trim() : "";
    description = request.getParameter("description") != null ? request.getParameter("description").trim() : "";
    topic = request.getParameter("topic") != null ? request.getParameter("topic").trim() : "";
    capacity = request.getParameter("capacity") != null ? request.getParameter("capacity").trim() : "";
    visibility = request.getParameter("visibility") != null ? request.getParameter("visibility").trim() : "Public";

    if (sessionId.isEmpty() || sessName.isEmpty()) {
      errorMsg = "Session ID and session name are required.";
    } else {
      Connection con = null;
      PreparedStatement ps = null;
      try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
        ps = con.prepareStatement(
          "UPDATE StudySession SET Name = ?, Time = ?, Date = ?, Location = ?, Description = ?, Capacity = ?, Topic = ?, Visibility = ? " +
          "WHERE Session_ID = ? AND Organizer_Username = ?"
        );
        ps.setString(1, sessName);
        ps.setString(2, sessTime.isEmpty() ? null : sessTime);
        ps.setString(3, sessDate.isEmpty() ? null : sessDate);
        ps.setString(4, location.isEmpty() ? null : location);
        ps.setString(5, description.isEmpty() ? null : description);
        if (!capacity.isEmpty()) ps.setInt(6, Integer.parseInt(capacity));
        else ps.setNull(6, java.sql.Types.INTEGER);
        ps.setString(7, topic.isEmpty() ? null : topic);
        ps.setString(8, visibility.isEmpty() ? "Public" : visibility);
        ps.setString(9, sessionId);
        ps.setString(10, username);

        int updated = ps.executeUpdate();
        ps.close();
        con.close();

        if (updated == 1) {
          response.sendRedirect("home.jsp?updated=1");
          return;
        }
        errorMsg = "Only the organizer can edit this study session.";
      } catch (Exception e) {
        errorMsg = "Database error: " + e.getMessage();
      } finally {
        if (ps != null) try { ps.close(); } catch (Exception ignore) {}
        if (con != null) try { con.close(); } catch (Exception ignore) {}
      }
    }
  }

  if (!sessionId.isEmpty() && sessName.isEmpty()) {
    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    try {
      Class.forName("com.mysql.cj.jdbc.Driver");
      con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
      ps = con.prepareStatement(
        "SELECT Name, Time, Date, Location, Description, Capacity, Topic, Visibility " +
        "FROM StudySession WHERE Session_ID = ? AND Organizer_Username = ?"
      );
      ps.setString(1, sessionId);
      ps.setString(2, username);
      rs = ps.executeQuery();

      if (rs.next()) {
        sessName = rs.getString("Name") != null ? rs.getString("Name") : "";
        sessTime = rs.getTime("Time") != null ? rs.getTime("Time").toString().substring(0, 5) : "";
        sessDate = rs.getDate("Date") != null ? rs.getDate("Date").toString() : "";
        location = rs.getString("Location") != null ? rs.getString("Location") : "";
        description = rs.getString("Description") != null ? rs.getString("Description") : "";
        capacity = rs.getObject("Capacity") != null ? String.valueOf(rs.getInt("Capacity")) : "";
        topic = rs.getString("Topic") != null ? rs.getString("Topic") : "";
        visibility = rs.getString("Visibility") != null ? rs.getString("Visibility") : "Public";
      } else {
        errorMsg = "Only the organizer can edit this study session.";
      }
      rs.close();
      ps.close();
      con.close();
    } catch (Exception e) {
      errorMsg = "Database error: " + e.getMessage();
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
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Edit Session - SpartanStudyCircle</title>
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
      max-width: 620px;
      margin: 40px auto;
      padding: 0 16px;
    }

    .card {
      background: white;
      border-radius: 12px;
      padding: 32px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.08);
    }

    .card h2 {
      font-size: 18px;
      color: #0055A2;
      margin-bottom: 6px;
    }

    .subtitle {
      font-size: 13px;
      color: #6b7280;
      margin-bottom: 24px;
      padding-bottom: 16px;
      border-bottom: 2px solid #e5e7eb;
    }

    .field { margin-bottom: 18px; }

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

    .row { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }

    .visibility-group {
      display: flex;
      gap: 12px;
    }

    .vis-option {
      flex: 1;
      text-align: center;
      border: 1.5px solid #d1d5db;
      border-radius: 8px;
      padding: 10px;
      cursor: pointer;
      font-size: 13px;
      font-weight: 600;
      color: #6b7280;
    }

    .vis-option input[type="radio"] { display: none; }
    .vis-option:has(input:checked) {
      border-color: #0055A2;
      background: #eff6ff;
      color: #0055A2;
    }

    .button-row {
      display: flex;
      gap: 10px;
      margin-top: 8px;
    }

    .btn, .link-btn {
      display: inline-block;
      padding: 11px 14px;
      border-radius: 8px;
      border: none;
      font-size: 14px;
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

    .alert {
      padding: 12px 16px;
      border-radius: 8px;
      font-size: 13px;
      margin-bottom: 20px;
      background: #fee2e2;
      color: #991b1b;
    }
  </style>
</head>
<body>
  <nav>
    <span class="brand">&#128218; SpartanStudyCircle</span>
    <div class="nav-links">
      <a href="home.jsp">Home</a>
      <a href="schedule.jsp">My Schedule</a>
      <a href="create_session.jsp" class="active">+ Create Session</a>
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
    <div class="card">
      <h2>Edit Study Session</h2>
      <p class="subtitle">Update the details of a study session you organize.</p>

      <% if (!errorMsg.isEmpty()) { %>
        <div class="alert"><%= errorMsg %></div>
      <% } %>

      <% if (!sessionId.isEmpty() && errorMsg.isEmpty()) { %>
        <form method="POST" action="edit_session.jsp">
          <input type="hidden" name="action" value="update" />
          <input type="hidden" name="sessionId" value="<%= sessionId %>" />

          <div class="field">
            <label>Session Name</label>
            <input type="text" name="name" value="<%= sessName %>" required />
          </div>

          <div class="field">
            <label>Topic / Class</label>
            <input type="text" name="topic" value="<%= topic %>" />
          </div>

          <div class="row">
            <div class="field">
              <label>Date</label>
              <input type="date" name="date" value="<%= sessDate %>" />
            </div>
            <div class="field">
              <label>Time</label>
              <input type="time" name="time" value="<%= sessTime %>" />
            </div>
          </div>

          <div class="row">
            <div class="field">
              <label>Location</label>
              <input type="text" name="location" value="<%= location %>" />
            </div>
            <div class="field">
              <label>Capacity</label>
              <input type="number" name="capacity" value="<%= capacity %>" min="1" max="100" />
            </div>
          </div>

          <div class="field">
            <label>Description</label>
            <textarea name="description"><%= description %></textarea>
          </div>

          <div class="field">
            <label>Visibility</label>
            <div class="visibility-group">
              <label class="vis-option">
                <input type="radio" name="visibility" value="Public" <%= "Public".equals(visibility) ? "checked" : "" %> />
                Public
              </label>
              <label class="vis-option">
                <input type="radio" name="visibility" value="Friends" <%= "Friends".equals(visibility) ? "checked" : "" %> />
                Friends Only
              </label>
              <label class="vis-option">
                <input type="radio" name="visibility" value="Private" <%= "Private".equals(visibility) ? "checked" : "" %> />
                Private
              </label>
            </div>
          </div>

          <div class="button-row">
            <button class="btn btn-primary" type="submit">Save Changes</button>
            <a class="link-btn" href="home.jsp">Back to Home</a>
          </div>
        </form>
      <% } %>
    </div>
  </div>
</body>
</html>
