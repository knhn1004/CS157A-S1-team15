<%@ page import="java.sql.*" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page session="true" %>
<%
  // Session guard — redirect to login if not authenticated
  String username = (String) session.getAttribute("username");
  String name     = (String) session.getAttribute("name");
  if (username == null) {
    response.sendRedirect("index.jsp");
    return;
  }

  // Logout
  if ("logout".equals(request.getParameter("action"))) {
    session.invalidate();
    response.sendRedirect("index.jsp");
    return;
  }

  // DB connection helper
  final String DB_URL  = "jdbc:mysql://localhost:3306/Team_15?autoReconnect=true&useSSL=false&allowPublicKeyRetrieval=true";
  final String DB_USER = "root";
  final String DB_PASS = "password";
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Home - SpartanStudyCircle</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }

    body {
      font-family: 'Segoe UI', sans-serif;
      background: #f3f4f6;
      min-height: 100vh;
    }

    /* ── Navbar ── */
    nav {
      background: #0055A2;
      color: white;
      padding: 0 32px;
      height: 56px;
      display: flex;
      align-items: center;
      justify-content: space-between;
    }

    nav .brand {
      font-size: 18px;
      font-weight: 700;
    }

    nav .user-info {
      display: flex;
      align-items: center;
      gap: 16px;
      font-size: 14px;
    }

    nav a.logout {
      color: white;
      text-decoration: none;
      background: rgba(255,255,255,0.15);
      padding: 6px 14px;
      border-radius: 6px;
      font-size: 13px;
      font-weight: 600;
    }

    nav a.logout:hover { background: rgba(255,255,255,0.25); }

    nav .nav-links { display: flex; gap: 8px; }

    nav .nav-links a {
      color: white;
      text-decoration: none;
      padding: 6px 14px;
      border-radius: 6px;
      font-size: 13px;
      font-weight: 600;
    }

    nav .nav-links a:hover { background: rgba(255,255,255,0.2); }
    nav .nav-links a.active { background: rgba(255,255,255,0.25); }

    .banner-success {
      background: #dcfce7;
      color: #166534;
      padding: 12px 16px;
      border-radius: 8px;
      font-size: 13px;
      font-weight: 600;
      margin-bottom: 16px;
    }

    /* ── Layout ── */
    .container {
      max-width: 960px;
      margin: 32px auto;
      padding: 0 16px;
      display: grid;
      grid-template-columns: 260px 1fr;
      gap: 24px;
    }

    /* ── Profile Card ── */
    .profile-card {
      background: white;
      border-radius: 12px;
      padding: 24px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.08);
      align-self: start;
    }

    .profile-card .avatar {
      width: 60px;
      height: 60px;
      border-radius: 50%;
      background: #0055A2;
      color: white;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 24px;
      font-weight: 700;
      margin: 0 auto 16px;
    }

    .profile-card h2 {
      font-size: 16px;
      color: #111827;
      text-align: center;
      margin-bottom: 4px;
    }

    .profile-card .username-label {
      font-size: 13px;
      color: #6b7280;
      text-align: center;
      margin-bottom: 16px;
    }

    .profile-detail {
      display: flex;
      justify-content: space-between;
      font-size: 13px;
      padding: 6px 0;
      border-bottom: 1px solid #f3f4f6;
      color: #374151;
    }

    .profile-detail span:first-child { color: #6b7280; }

    /* ── Sessions Panel ── */
    .panel {
      background: white;
      border-radius: 12px;
      padding: 24px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.08);
    }

    .panel h3 {
      font-size: 16px;
      color: #0055A2;
      font-weight: 700;
      margin-bottom: 16px;
      padding-bottom: 10px;
      border-bottom: 2px solid #e5e7eb;
    }

    table {
      width: 100%;
      border-collapse: collapse;
      font-size: 13px;
    }

    thead tr {
      background: #f9fafb;
    }

    th {
      text-align: left;
      padding: 10px 12px;
      font-weight: 600;
      color: #374151;
      border-bottom: 1px solid #e5e7eb;
    }

    td {
      padding: 10px 12px;
      color: #374151;
      border-bottom: 1px solid #f3f4f6;
    }

    tr:last-child td { border-bottom: none; }

    .badge {
      display: inline-block;
      padding: 2px 8px;
      border-radius: 999px;
      font-size: 11px;
      font-weight: 600;
    }

    .badge-public   { background: #dcfce7; color: #166534; }
    .badge-private  { background: #fee2e2; color: #991b1b; }
    .badge-friends  { background: #dbeafe; color: #1e40af; }

    .table-link {
      color: #0055A2;
      text-decoration: none;
      font-weight: 600;
    }

    .table-link:hover { text-decoration: underline; }

    .muted {
      color: #9ca3af;
      font-size: 13px;
      font-weight: 600;
    }

    .no-data {
      text-align: center;
      color: #9ca3af;
      padding: 32px 0;
      font-size: 14px;
    }

    .error-msg {
      color: #ef4444;
      font-size: 13px;
      padding: 12px;
      background: #fee2e2;
      border-radius: 8px;
    }
  </style>
</head>
<body>

  <!-- NAVBAR -->
  <nav>
    <span class="brand">&#128218; SpartanStudyCircle</span>
    <div class="nav-links">
      <a href="home.jsp" class="active">Home</a>
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

    <!-- PROFILE CARD (pulled from DB) -->
    <aside class="profile-card">
      <div class="avatar"><%= name.substring(0, 1).toUpperCase() %></div>
      <h2><%= name %></h2>
      <p class="username-label">@<%= username %></p>

      <%
        String email = "", major = "", yearStr = "", school = "";
        String profileError = "";
        try {
          Class.forName("com.mysql.cj.jdbc.Driver");
          Connection con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
          PreparedStatement ps = con.prepareStatement(
            "SELECT Email, Major, Year, School_name FROM Users WHERE Username = ?"
          );
          ps.setString(1, username);
          ResultSet rs = ps.executeQuery();
          if (rs.next()) {
            email   = rs.getString("Email")       != null ? rs.getString("Email")       : "";
            major   = rs.getString("Major")       != null ? rs.getString("Major")       : "—";
            yearStr = rs.getObject("Year")        != null ? String.valueOf(rs.getInt("Year")) : "—";
            school  = rs.getString("School_name") != null ? rs.getString("School_name") : "—";
          }
          rs.close(); ps.close(); con.close();
        } catch (Exception e) {
          profileError = e.getMessage();
        }
      %>

      <% if (!profileError.isEmpty()) { %>
        <p class="error-msg"><%= profileError %></p>
      <% } else { %>
        <div class="profile-detail"><span>Email</span>  <span><%= email   %></span></div>
        <div class="profile-detail"><span>Major</span>  <span><%= major   %></span></div>
        <div class="profile-detail"><span>Year</span>   <span><%= yearStr %></span></div>
        <div class="profile-detail"><span>School</span> <span><%= school  %></span></div>
      <% } %>
    </aside>

    <!-- STUDY SESSIONS PANEL -->
    <main>
      <div class="panel">
        <% if ("1".equals(request.getParameter("created"))) { %>
          <div class="banner-success">&#10003; Study session created successfully!</div>
        <% } %>
        <h3>Public Study Sessions</h3>

        <%
          String sessionsError = "";
          ResultSet sessions = null;
          Connection sessionCon = null;
          try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            sessionCon = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
            PreparedStatement ps2 = sessionCon.prepareStatement(
              "SELECT Session_ID, Name, Date, Time, Location, Topic, Capacity, Visibility, Organizer_Username " +
              "FROM StudySession " +
              "WHERE Visibility = 'Public' " +
              "ORDER BY Date ASC, Time ASC " +
              "LIMIT 10"
            );
            sessions = ps2.executeQuery();
        %>

        <table>
          <thead>
            <tr>
              <th>Session</th>
              <th>Topic</th>
              <th>Date</th>
              <th>Time</th>
              <th>Location</th>
              <th>Spots</th>
              <th>Visibility</th>
              <th>Attendees</th>
            </tr>
          </thead>
          <tbody>
          <%
            boolean hasRows = false;
            while (sessions.next()) {
              hasRows = true;
              String vis = sessions.getString("Visibility");
              String badgeClass = "badge-public";
              if      ("Private".equals(vis)) badgeClass = "badge-private";
              else if ("Friends".equals(vis)) badgeClass = "badge-friends";
              String orgUser = sessions.getString("Organizer_Username");
              boolean rowIsOrg = orgUser != null && orgUser.equals(username);
          %>
            <tr>
              <td><strong><%= sessions.getString("Name") %></strong></td>
              <td><%= sessions.getString("Topic") != null ? sessions.getString("Topic") : "—" %></td>
              <td><%= sessions.getString("Date")  != null ? sessions.getString("Date")  : "—" %></td>
              <td><%= sessions.getString("Time")  != null ? sessions.getString("Time")  : "—" %></td>
              <td><%= sessions.getString("Location") != null ? sessions.getString("Location") : "—" %></td>
              <td><%= sessions.getObject("Capacity") != null ? sessions.getInt("Capacity") : "—" %></td>
              <td><span class="badge <%= badgeClass %>"><%= vis %></span></td>
              <td>
                <% if (rowIsOrg) { %>
                  <a class="table-link" href="session_attendees.jsp?sessionId=<%= sessions.getString("Session_ID") %>">View Attendees</a>
                <% } else { %>
                  <span class="muted">Organizer only</span>
                <% } %>
              </td>
            </tr>
          <%
            }
            sessions.close();
            sessionCon.close();
          %>
          <% if (!hasRows) { %>
            <tr><td colspan="8" class="no-data">No public sessions found.</td></tr>
          <% } %>
          </tbody>
        </table>

        <%
          } catch (Exception e) {
            sessionsError = e.getMessage();
          }
          if (!sessionsError.isEmpty()) {
        %>
          <p class="error-msg">Database error: <%= sessionsError %></p>
        <% } %>
      </div>
    </main>

  </div>
</body>
</html>
