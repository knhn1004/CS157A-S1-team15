<%@ page import="java.sql.*, java.util.UUID" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page session="true" %>
<%
  // Session guard
  String username = (String) session.getAttribute("username");
  String name     = (String) session.getAttribute("name");
  if (username == null) {
    response.sendRedirect("index.jsp");
    return;
  }

  final String DB_URL  = "jdbc:mysql://localhost:3306/Team_15?autoReconnect=true&useSSL=false&allowPublicKeyRetrieval=true";
  final String DB_USER = "root";
  final String DB_PASS = "password";

  String successMsg = "";
  String errorMsg   = "";

  // ── HANDLE CREATE ──────────────────────────────────────────────────────────
  if ("create".equals(request.getParameter("action"))) {
    String sessName    = request.getParameter("name");
    String sessDate    = request.getParameter("date");
    String sessTime    = request.getParameter("time");
    String location    = request.getParameter("location");
    String description = request.getParameter("description");
    String topic       = request.getParameter("topic");
    String capacity    = request.getParameter("capacity");
    String visibility  = request.getParameter("visibility");

    if (sessName != null && !sessName.trim().isEmpty()) {
      try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

        // Generate unique Session_ID
        String sessionId = "SS" + UUID.randomUUID().toString().replace("-", "").substring(0, 8).toUpperCase();

        PreparedStatement ps = con.prepareStatement(
          "INSERT INTO StudySession (Session_ID, Name, Time, Date, Location, Description, Capacity, Topic, Visibility, Organizer_Username) " +
          "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
        );
        ps.setString(1, sessionId);
        ps.setString(2, sessName.trim());
        ps.setString(3, (sessTime    != null && !sessTime.trim().isEmpty())    ? sessTime.trim()    : null);
        ps.setString(4, (sessDate    != null && !sessDate.trim().isEmpty())    ? sessDate.trim()    : null);
        ps.setString(5, (location    != null && !location.trim().isEmpty())    ? location.trim()    : null);
        ps.setString(6, (description != null && !description.trim().isEmpty()) ? description.trim() : null);
        if (capacity != null && !capacity.trim().isEmpty()) {
          ps.setInt(7, Integer.parseInt(capacity.trim()));
        } else {
          ps.setNull(7, java.sql.Types.INTEGER);
        }
        ps.setString(8,  (topic      != null && !topic.trim().isEmpty())      ? topic.trim()      : null);
        ps.setString(9,  (visibility != null && !visibility.isEmpty())        ? visibility        : "Public");
        ps.setString(10, username);

        ps.executeUpdate();
        ps.close();
        con.close();

        response.sendRedirect("home.jsp?created=1");
        return;

      } catch (Exception e) {
        errorMsg = "Database error: " + e.getMessage();
      }
    } else {
      errorMsg = "Session name is required.";
    }
  }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Create Session - SpartanStudyCircle</title>
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

    nav .nav-links a:hover, nav a.logout:hover {
      background: rgba(255,255,255,0.2);
    }

    nav .nav-links a.active {
      background: rgba(255,255,255,0.25);
    }

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
      font-weight: 700;
      margin-bottom: 6px;
    }

    .card .subtitle {
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

    input, select, textarea {
      width: 100%;
      padding: 10px 12px;
      border: 1.5px solid #d1d5db;
      border-radius: 8px;
      font-size: 14px;
      outline: none;
      font-family: inherit;
      transition: border-color 0.2s;
    }

    input:focus, select:focus, textarea:focus { border-color: #0055A2; }

    textarea { resize: vertical; min-height: 80px; }

    .row { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
    .row-3 { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 16px; }

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
      transition: all 0.15s;
    }

    .vis-option input[type="radio"] { display: none; }

    .vis-option:has(input:checked) {
      border-color: #0055A2;
      background: #eff6ff;
      color: #0055A2;
    }

    button {
      width: 100%;
      padding: 11px;
      background: #0055A2;
      color: white;
      border: none;
      border-radius: 8px;
      font-size: 15px;
      font-weight: 600;
      cursor: pointer;
      margin-top: 8px;
    }

    button:hover { background: #004490; }

    .alert {
      padding: 12px 16px;
      border-radius: 8px;
      font-size: 13px;
      margin-bottom: 20px;
    }

    .alert-error { background: #fee2e2; color: #991b1b; }

    .optional {
      font-size: 11px;
      color: #9ca3af;
      font-weight: 400;
      margin-left: 4px;
    }
  </style>
</head>
<body>

  <nav>
    <span class="brand">&#128218; SpartanStudyCircle</span>
    <div class="nav-links">
      <a href="home.jsp">Home</a>
      <a href="create_session.jsp" class="active">+ Create Session</a>
      <a href="people.jsp">Find People</a>
      <a href="profile.jsp">My Profile</a>
    </div>
    <div class="user-info">
      <span><%= name %></span>
      <a class="logout" href="home.jsp?action=logout">Log Out</a>
    </div>
  </nav>

  <div class="container">
    <div class="card">
      <h2>Create Study Session</h2>
      <p class="subtitle">Organize a new session for other students to join.</p>

      <% if (!errorMsg.isEmpty()) { %>
        <div class="alert alert-error"><%= errorMsg %></div>
      <% } %>

      <form method="POST" action="create_session.jsp">
        <input type="hidden" name="action" value="create" />

        <div class="field">
          <label>Session Name</label>
          <input type="text" name="name" placeholder="e.g. SQL Midterm Review" required />
        </div>

        <div class="field">
          <label>Topic / Class <span class="optional">optional</span></label>
          <input type="text" name="topic" placeholder="e.g. Databases, Algorithms, CS 157A" />
        </div>

        <div class="row">
          <div class="field">
            <label>Date</label>
            <input type="date" name="date" />
          </div>
          <div class="field">
            <label>Time</label>
            <input type="time" name="time" />
          </div>
        </div>

        <div class="row">
          <div class="field">
            <label>Location <span class="optional">optional</span></label>
            <input type="text" name="location" placeholder="e.g. Library Room A" />
          </div>
          <div class="field">
            <label>Capacity <span class="optional">optional</span></label>
            <input type="number" name="capacity" placeholder="e.g. 10" min="1" max="100" />
          </div>
        </div>

        <div class="field">
          <label>Description <span class="optional">optional</span></label>
          <textarea name="description" placeholder="What will you cover in this session?"></textarea>
        </div>

        <div class="field">
          <label>Visibility</label>
          <div class="visibility-group">
            <label class="vis-option">
              <input type="radio" name="visibility" value="Public" checked />
              Public
            </label>
            <label class="vis-option">
              <input type="radio" name="visibility" value="Friends" />
              Friends Only
            </label>
            <label class="vis-option">
              <input type="radio" name="visibility" value="Private" />
              Private
            </label>
          </div>
        </div>

        <button type="submit">Create Session</button>
      </form>
    </div>
  </div>

</body>
</html>
