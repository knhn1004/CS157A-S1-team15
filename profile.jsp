<%@ page import="java.sql.*" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
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

  // ── HANDLE UPDATE ──────────────────────────────────────────────────────────
  if ("update".equals(request.getParameter("action"))) {
    String newEmail = request.getParameter("email");
    String newName  = request.getParameter("name");
    String newMajor = request.getParameter("major");
    String newYear  = request.getParameter("year");

    try {
      Class.forName("com.mysql.cj.jdbc.Driver");
      Connection con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
      PreparedStatement ps = con.prepareStatement(
        "UPDATE Users SET Email = ?, Name = ?, Major = ?, Year = ? WHERE Username = ?"
      );
      ps.setString(1, newEmail != null ? newEmail.trim() : "");
      ps.setString(2, newName  != null ? newName.trim()  : "");
      ps.setString(3, newMajor != null && !newMajor.trim().isEmpty() ? newMajor.trim() : null);
      if (newYear != null && !newYear.isEmpty()) {
        ps.setInt(4, Integer.parseInt(newYear));
      } else {
        ps.setNull(4, java.sql.Types.INTEGER);
      }
      ps.setString(5, username);
      ps.executeUpdate();
      ps.close();
      con.close();

      // Update session name if it changed
      if (newName != null && !newName.trim().isEmpty()) {
        session.setAttribute("name", newName.trim());
        name = newName.trim();
      }
      successMsg = "Profile updated successfully.";
    } catch (Exception e) {
      errorMsg = "Database error: " + e.getMessage();
    }
  }

  // ── LOAD CURRENT PROFILE ──────────────────────────────────────────────────
  String curEmail = "", curName = name, curMajor = "", curYear = "", curSchool = "";
  try {
    Class.forName("com.mysql.cj.jdbc.Driver");
    Connection con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
    PreparedStatement ps = con.prepareStatement(
      "SELECT Email, Name, Major, Year, School_name FROM Users WHERE Username = ?"
    );
    ps.setString(1, username);
    ResultSet rs = ps.executeQuery();
    if (rs.next()) {
      curEmail  = rs.getString("Email")       != null ? rs.getString("Email")       : "";
      curName   = rs.getString("Name")        != null ? rs.getString("Name")        : "";
      curMajor  = rs.getString("Major")       != null ? rs.getString("Major")       : "";
      curYear   = rs.getObject("Year")        != null ? String.valueOf(rs.getInt("Year")) : "";
      curSchool = rs.getString("School_name") != null ? rs.getString("School_name") : "";
    }
    rs.close(); ps.close(); con.close();
  } catch (Exception e) {
    if (errorMsg.isEmpty()) errorMsg = "Could not load profile: " + e.getMessage();
  }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>My Profile - SpartanStudyCircle</title>
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
      max-width: 600px;
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
      margin-bottom: 8px;
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

    input, select {
      width: 100%;
      padding: 10px 12px;
      border: 1.5px solid #d1d5db;
      border-radius: 8px;
      font-size: 14px;
      outline: none;
      transition: border-color 0.2s;
    }

    input:focus, select:focus { border-color: #0055A2; }

    input[readonly] {
      background: #f9fafb;
      color: #6b7280;
      cursor: not-allowed;
    }

    .row { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }

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

    .alert-success { background: #dcfce7; color: #166534; }
    .alert-error   { background: #fee2e2; color: #991b1b; }

    .readonly-note {
      font-size: 12px;
      color: #9ca3af;
      margin-top: 4px;
    }
  </style>
</head>
<body>

  <nav>
    <span class="brand">&#128218; SpartanStudyCircle</span>
    <div class="nav-links">
      <a href="home.jsp">Home</a>
      <a href="create_session.jsp">+ Create Session</a>
      <a href="profile.jsp" class="active">My Profile</a>
    </div>
    <div class="user-info">
      <span><%= name %></span>
      <a class="logout" href="home.jsp?action=logout">Log Out</a>
    </div>
  </nav>

  <div class="container">
    <div class="card">
      <h2>My Profile</h2>
      <p class="subtitle">@<%= username %> &nbsp;·&nbsp; <%= curSchool %></p>

      <% if (!successMsg.isEmpty()) { %>
        <div class="alert alert-success"><%= successMsg %></div>
      <% } %>
      <% if (!errorMsg.isEmpty()) { %>
        <div class="alert alert-error"><%= errorMsg %></div>
      <% } %>

      <form method="POST" action="profile.jsp">
        <input type="hidden" name="action" value="update" />

        <div class="field">
          <label>Username</label>
          <input type="text" value="<%= username %>" readonly />
          <p class="readonly-note">Username cannot be changed.</p>
        </div>

        <div class="field">
          <label>Full Name</label>
          <input type="text" name="name" value="<%= curName %>" placeholder="Full name" required />
        </div>

        <div class="field">
          <label>Email</label>
          <input type="email" name="email" value="<%= curEmail %>" placeholder="yourname@sjsu.edu" required />
        </div>

        <div class="row">
          <div class="field">
            <label>Major</label>
            <input type="text" name="major" value="<%= curMajor %>" placeholder="e.g. CS" />
          </div>
          <div class="field">
            <label>Year</label>
            <select name="year">
              <option value="">—</option>
              <option <%= "1".equals(curYear) ? "selected" : "" %>>1</option>
              <option <%= "2".equals(curYear) ? "selected" : "" %>>2</option>
              <option <%= "3".equals(curYear) ? "selected" : "" %>>3</option>
              <option <%= "4".equals(curYear) ? "selected" : "" %>>4</option>
            </select>
          </div>
        </div>

        <button type="submit">Save Changes</button>
      </form>
    </div>
  </div>

</body>
</html>
