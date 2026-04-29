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

  // Handle join/leave actions
  String actionParam = request.getParameter("action");
  String actionSessionId = request.getParameter("sessionId");
  String actionMsg = "";
  String actionMsgType = "success";

  if ("leave".equals(actionParam) && actionSessionId != null && !actionSessionId.trim().isEmpty()) {
    try {
      Class.forName("com.mysql.cj.jdbc.Driver");
      Connection leaveCon = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
      PreparedStatement leavePs = leaveCon.prepareStatement(
        "DELETE FROM Attends WHERE Session_ID = ? AND Username = ?"
      );
      leavePs.setString(1, actionSessionId.trim());
      leavePs.setString(2, username);
      int rows = leavePs.executeUpdate();
      leavePs.close();
      leaveCon.close();
      if (rows > 0) {
        actionMsg = "You have left the session.";
      } else {
        actionMsg = "You were not registered for that session.";
        actionMsgType = "error";
      }
    } catch (Exception e) {
      actionMsg = "Error leaving session: " + e.getMessage();
      actionMsgType = "error";
    }
  }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>My Sessions - SpartanStudyCircle</title>
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
      max-width: 1060px;
      margin: 32px auto;
      padding: 0 16px;
    }

    .page-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 22px;
    }

    .page-header h1 {
      font-size: 22px;
      font-weight: 700;
      color: #111827;
    }

    .page-header p {
      font-size: 13px;
      color: #6b7280;
      margin-top: 3px;
    }

    .btn-primary {
      display: inline-block;
      padding: 9px 18px;
      background: #0055A2;
      color: white;
      border-radius: 8px;
      font-size: 13px;
      font-weight: 600;
      text-decoration: none;
      border: none;
      cursor: pointer;
    }

    .btn-primary:hover { background: #004490; }

    .alert {
      padding: 12px 16px;
      border-radius: 8px;
      font-size: 13px;
      margin-bottom: 20px;
      font-weight: 600;
    }

    .alert-success { background: #dcfce7; color: #166534; }
    .alert-error   { background: #fee2e2; color: #991b1b; }

    /* Tab switcher */
    .tabs {
      display: flex;
      gap: 0;
      border-bottom: 2px solid #e5e7eb;
      margin-bottom: 24px;
    }

    .tab-btn {
      padding: 10px 20px;
      font-size: 14px;
      font-weight: 600;
      color: #6b7280;
      background: none;
      border: none;
      border-bottom: 3px solid transparent;
      margin-bottom: -2px;
      cursor: pointer;
      transition: all 0.15s;
    }

    .tab-btn.active {
      color: #0055A2;
      border-bottom-color: #0055A2;
    }

    .tab-btn:hover { color: #0055A2; }

    .tab-panel { display: none; }
    .tab-panel.active { display: block; }

    /* Session cards grid */
    .sessions-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
      gap: 16px;
    }

    .session-card {
      background: white;
      border-radius: 12px;
      padding: 20px;
      box-shadow: 0 1px 4px rgba(0,0,0,0.07);
      border-left: 4px solid #0055A2;
      transition: box-shadow 0.2s, transform 0.2s;
    }

    .session-card:hover {
      box-shadow: 0 4px 16px rgba(0,0,0,0.12);
      transform: translateY(-2px);
    }

    .session-card.past {
      border-left-color: #9ca3af;
      opacity: 0.85;
    }

    .session-card .card-top {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 10px;
    }

    .session-card h3 {
      font-size: 15px;
      font-weight: 700;
      color: #111827;
      flex: 1;
      margin-right: 10px;
    }

    .badge {
      display: inline-block;
      padding: 2px 9px;
      border-radius: 999px;
      font-size: 11px;
      font-weight: 700;
      white-space: nowrap;
    }

    .badge-confirmed  { background: #dcfce7; color: #166534; }
    .badge-pending    { background: #fef9c3; color: #854d0e; }
    .badge-declined   { background: #fee2e2; color: #991b1b; }
    .badge-public     { background: #dcfce7; color: #166534; }
    .badge-friends    { background: #dbeafe; color: #1e40af; }
    .badge-private    { background: #fee2e2; color: #991b1b; }
    .badge-past       { background: #f3f4f6; color: #6b7280; }
    .badge-upcoming   { background: #eff6ff; color: #1e40af; }
    .badge-organizer  { background: #fef3c7; color: #92400e; }

    .meta-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 6px 12px;
      margin-bottom: 14px;
    }

    .meta-item {
      font-size: 12px;
      color: #6b7280;
      display: flex;
      align-items: center;
      gap: 5px;
    }

    .meta-item .icon { font-size: 13px; }

    .meta-item strong {
      color: #374151;
      font-weight: 600;
    }

    .tag-topic {
      display: inline-block;
      background: #eff6ff;
      color: #1e40af;
      font-size: 11px;
      font-weight: 600;
      padding: 2px 8px;
      border-radius: 6px;
      margin-bottom: 12px;
    }

    .description-text {
      font-size: 12px;
      color: #6b7280;
      line-height: 1.5;
      margin-bottom: 14px;
      display: -webkit-box;
      -webkit-line-clamp: 2;
      -webkit-box-orient: vertical;
      overflow: hidden;
    }

    .card-footer {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding-top: 12px;
      border-top: 1px solid #f3f4f6;
    }

    .organizer-label {
      font-size: 11px;
      color: #9ca3af;
    }

    .organizer-label strong { color: #6b7280; }

    .btn-leave {
      padding: 6px 12px;
      background: #fff;
      border: 1.5px solid #e5e7eb;
      border-radius: 6px;
      font-size: 12px;
      font-weight: 600;
      color: #6b7280;
      cursor: pointer;
      transition: all 0.15s;
      text-decoration: none;
    }

    .btn-leave:hover {
      background: #fee2e2;
      border-color: #fca5a5;
      color: #991b1b;
    }

    .no-data {
      text-align: center;
      padding: 48px 0;
      color: #9ca3af;
    }

    .no-data .no-data-icon { font-size: 40px; margin-bottom: 12px; }
    .no-data p { font-size: 14px; }
    .no-data a { color: #0055A2; font-weight: 600; text-decoration: none; }
    .no-data a:hover { text-decoration: underline; }

    .section-summary {
      font-size: 13px;
      color: #6b7280;
      margin-bottom: 16px;
    }

    .section-summary strong { color: #374151; }

    .divider-label {
      font-size: 12px;
      font-weight: 700;
      color: #9ca3af;
      letter-spacing: 0.05em;
      text-transform: uppercase;
      margin: 24px 0 12px;
    }
  </style>
</head>
<body>

<nav>
  <span class="brand">&#128218; SpartanStudyCircle</span>
  <div class="nav-links">
    <a href="home.jsp">Home</a>
    <a href="create_session.jsp">+ Create Session</a>
    <a href="browse_sessions.jsp">Browse Sessions</a>
    <a href="my_sessions.jsp" class="active">My Sessions</a>
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

  <div class="page-header">
    <div>
      <h1>My Study Sessions</h1>
      <p>Sessions you've joined or are organizing</p>
    </div>
    <a href="browse_sessions.jsp" class="btn-primary">&#43; Join a Session</a>
  </div>

  <% if (!actionMsg.isEmpty()) { %>
    <div class="alert alert-<%= actionMsgType %>"><%= actionMsg %></div>
  <% } %>

  <%
    String joinedBanner = request.getParameter("joined");
    if ("1".equals(joinedBanner)) {
  %>
    <div class="alert alert-success">&#10003; You have successfully joined the session!</div>
  <% } %>

  <!-- Tab navigation -->
  <div class="tabs">
    <button class="tab-btn active" onclick="switchTab('upcoming', this)">Upcoming &amp; Current</button>
    <button class="tab-btn" onclick="switchTab('past', this)">Past Sessions</button>
  </div>

  <%
    // Load sessions from DB
    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    String dbError = "";

    // upcoming = date >= today OR date is null
    // past = date < today
    java.util.List<java.util.Map<String,String>> upcomingSessions = new java.util.ArrayList<>();
    java.util.List<java.util.Map<String,String>> pastSessions     = new java.util.ArrayList<>();

    try {
      Class.forName("com.mysql.cj.jdbc.Driver");
      con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

      // Sessions the user is attending (joined or organizer)
      ps = con.prepareStatement(
        "SELECT ss.Session_ID, ss.Name, ss.Time, ss.Date, ss.Location, ss.Description, " +
        "       ss.Capacity, ss.Topic, ss.Visibility, ss.Organizer_Username, " +
        "       a.Status, " +
        "       (ss.Organizer_Username = ?) AS is_organizer, " +
        "       (SELECT COUNT(*) FROM Attends WHERE Session_ID = ss.Session_ID) AS attendee_count " +
        "FROM StudySession ss " +
        "JOIN Attends a ON a.Session_ID = ss.Session_ID AND a.Username = ? " +
        "ORDER BY ss.Date ASC, ss.Time ASC"
      );
      ps.setString(1, username);
      ps.setString(2, username);
      rs = ps.executeQuery();

      java.time.LocalDate today = java.time.LocalDate.now();

      while (rs.next()) {
        java.util.Map<String,String> m = new java.util.LinkedHashMap<>();
        m.put("sessionId",    rs.getString("Session_ID"));
        m.put("name",         rs.getString("Name") != null ? rs.getString("Name") : "Untitled");
        m.put("time",         rs.getString("Time") != null ? rs.getString("Time") : "—");
        m.put("date",         rs.getString("Date") != null ? rs.getString("Date") : null);
        m.put("location",     rs.getString("Location") != null ? rs.getString("Location") : "—");
        m.put("description",  rs.getString("Description") != null ? rs.getString("Description") : "");
        m.put("capacity",     rs.getObject("Capacity") != null ? String.valueOf(rs.getInt("Capacity")) : "—");
        m.put("topic",        rs.getString("Topic") != null ? rs.getString("Topic") : "");
        m.put("visibility",   rs.getString("Visibility") != null ? rs.getString("Visibility") : "Public");
        m.put("organizer",    rs.getString("Organizer_Username") != null ? rs.getString("Organizer_Username") : "—");
        m.put("status",       rs.getString("Status") != null ? rs.getString("Status") : "—");
        m.put("isOrganizer",  String.valueOf(rs.getInt("is_organizer") == 1));
        m.put("attendeeCount",String.valueOf(rs.getInt("attendee_count")));

        String dateStr = m.get("date");
        boolean isPast = false;
        if (dateStr != null) {
          try {
            java.time.LocalDate sessDate = java.time.LocalDate.parse(dateStr);
            isPast = sessDate.isBefore(today);
          } catch (Exception ignored) {}
        }
        if (isPast) pastSessions.add(m);
        else upcomingSessions.add(m);
      }
      rs.close(); ps.close();

      // Also fetch sessions the user is organizing but might not be in Attends
      ps = con.prepareStatement(
        "SELECT ss.Session_ID, ss.Name, ss.Time, ss.Date, ss.Location, ss.Description, " +
        "       ss.Capacity, ss.Topic, ss.Visibility, ss.Organizer_Username, " +
        "       'Organizer' AS Status, 1 AS is_organizer, " +
        "       (SELECT COUNT(*) FROM Attends WHERE Session_ID = ss.Session_ID) AS attendee_count " +
        "FROM StudySession ss " +
        "WHERE ss.Organizer_Username = ? " +
        "AND ss.Session_ID NOT IN (SELECT Session_ID FROM Attends WHERE Username = ?) " +
        "ORDER BY ss.Date ASC, ss.Time ASC"
      );
      ps.setString(1, username);
      ps.setString(2, username);
      rs = ps.executeQuery();

      while (rs.next()) {
        java.util.Map<String,String> m = new java.util.LinkedHashMap<>();
        m.put("sessionId",    rs.getString("Session_ID"));
        m.put("name",         rs.getString("Name") != null ? rs.getString("Name") : "Untitled");
        m.put("time",         rs.getString("Time") != null ? rs.getString("Time") : "—");
        m.put("date",         rs.getString("Date") != null ? rs.getString("Date") : null);
        m.put("location",     rs.getString("Location") != null ? rs.getString("Location") : "—");
        m.put("description",  rs.getString("Description") != null ? rs.getString("Description") : "");
        m.put("capacity",     rs.getObject("Capacity") != null ? String.valueOf(rs.getInt("Capacity")) : "—");
        m.put("topic",        rs.getString("Topic") != null ? rs.getString("Topic") : "");
        m.put("visibility",   rs.getString("Visibility") != null ? rs.getString("Visibility") : "Public");
        m.put("organizer",    rs.getString("Organizer_Username") != null ? rs.getString("Organizer_Username") : "—");
        m.put("status",       "Organizer");
        m.put("isOrganizer",  "true");
        m.put("attendeeCount",String.valueOf(rs.getInt("attendee_count")));

        String dateStr = m.get("date");
        boolean isPast = false;
        if (dateStr != null) {
          try {
            java.time.LocalDate sessDate = java.time.LocalDate.parse(dateStr);
            isPast = sessDate.isBefore(java.time.LocalDate.now());
          } catch (Exception ignored) {}
        }
        if (isPast) pastSessions.add(m);
        else upcomingSessions.add(m);
      }
      rs.close(); ps.close();

    } catch (Exception e) {
      dbError = "Database error: " + e.getMessage();
    } finally {
      if (rs  != null) try { rs.close();  } catch (Exception ignore) {}
      if (ps  != null) try { ps.close();  } catch (Exception ignore) {}
      if (con != null) try { con.close(); } catch (Exception ignore) {}
    }
  %>

  <% if (!dbError.isEmpty()) { %>
    <div class="alert alert-error"><%= dbError %></div>
  <% } %>

  <!-- UPCOMING TAB -->
  <div id="tab-upcoming" class="tab-panel active">
    <p class="section-summary">
      Showing <strong><%= upcomingSessions.size() %></strong> upcoming or active session(s).
    </p>

    <% if (upcomingSessions.isEmpty()) { %>
      <div class="no-data">
        <div class="no-data-icon">&#128197;</div>
        <p>You have no upcoming study sessions.<br/><a href="browse_sessions.jsp">Browse sessions</a> to join one!</p>
      </div>
    <% } else { %>
      <div class="sessions-grid">
        <% for (java.util.Map<String,String> sess : upcomingSessions) {
             String vis = sess.get("visibility");
             String visClass = "badge-public";
             if ("Private".equals(vis)) visClass = "badge-private";
             else if ("Friends".equals(vis)) visClass = "badge-friends";
             String statusVal = sess.get("status");
             String statusClass = "badge-confirmed";
             if ("Pending".equals(statusVal)) statusClass = "badge-pending";
             else if ("Declined".equals(statusVal)) statusClass = "badge-declined";
             else if ("Organizer".equals(statusVal)) statusClass = "badge-organizer";
             boolean isOrg = "true".equals(sess.get("isOrganizer"));
        %>
        <div class="session-card">
          <div class="card-top">
            <h3><%= sess.get("name") %></h3>
            <span class="badge <%= statusClass %>"><%= statusVal %></span>
          </div>
          <% if (!sess.get("topic").isEmpty()) { %>
            <span class="tag-topic">&#128218; <%= sess.get("topic") %></span>
          <% } %>
          <div class="meta-grid">
            <div class="meta-item"><span class="icon">&#128197;</span> <strong><%= sess.get("date") != null ? sess.get("date") : "TBD" %></strong></div>
            <div class="meta-item"><span class="icon">&#128336;</span> <strong><%= sess.get("time") %></strong></div>
            <div class="meta-item"><span class="icon">&#128205;</span> <strong><%= sess.get("location") %></strong></div>
            <div class="meta-item"><span class="icon">&#128101;</span> <strong><%= sess.get("attendeeCount") %><%= !sess.get("capacity").equals("—") ? "/" + sess.get("capacity") : "" %></strong> attending</div>
          </div>
          <% if (!sess.get("description").isEmpty()) { %>
            <p class="description-text"><%= sess.get("description") %></p>
          <% } %>
          <div class="card-footer">
            <div>
              <span class="badge <%= visClass %>" style="margin-right:6px"><%= vis %></span>
              <span class="organizer-label">by <strong>@<%= sess.get("organizer") %></strong></span>
            </div>
            <% if (!isOrg) { %>
              <a class="btn-leave" href="my_sessions.jsp?action=leave&sessionId=<%= sess.get("sessionId") %>"
                 onclick="return confirm('Leave this session?')">Leave</a>
            <% } else { %>
              <a class="btn-leave" href="session_attendees.jsp?sessionId=<%= sess.get("sessionId") %>">View Attendees</a>
            <% } %>
          </div>
        </div>
        <% } %>
      </div>
    <% } %>
  </div>

  <!-- PAST TAB -->
  <div id="tab-past" class="tab-panel">
    <p class="section-summary">
      Showing <strong><%= pastSessions.size() %></strong> past session(s).
    </p>

    <% if (pastSessions.isEmpty()) { %>
      <div class="no-data">
        <div class="no-data-icon">&#128336;</div>
        <p>No past sessions on record yet.</p>
      </div>
    <% } else { %>
      <div class="sessions-grid">
        <% for (java.util.Map<String,String> sess : pastSessions) {
             String vis = sess.get("visibility");
             String visClass = "badge-public";
             if ("Private".equals(vis)) visClass = "badge-private";
             else if ("Friends".equals(vis)) visClass = "badge-friends";
             String statusVal = sess.get("status");
             String statusClass = "badge-confirmed";
             if ("Pending".equals(statusVal)) statusClass = "badge-pending";
             else if ("Declined".equals(statusVal)) statusClass = "badge-declined";
             else if ("Organizer".equals(statusVal)) statusClass = "badge-organizer";
             boolean isOrg = "true".equals(sess.get("isOrganizer"));
        %>
        <div class="session-card past">
          <div class="card-top">
            <h3><%= sess.get("name") %></h3>
            <span class="badge badge-past">Past</span>
          </div>
          <% if (!sess.get("topic").isEmpty()) { %>
            <span class="tag-topic">&#128218; <%= sess.get("topic") %></span>
          <% } %>
          <div class="meta-grid">
            <div class="meta-item"><span class="icon">&#128197;</span> <strong><%= sess.get("date") != null ? sess.get("date") : "—" %></strong></div>
            <div class="meta-item"><span class="icon">&#128336;</span> <strong><%= sess.get("time") %></strong></div>
            <div class="meta-item"><span class="icon">&#128205;</span> <strong><%= sess.get("location") %></strong></div>
            <div class="meta-item"><span class="icon">&#128101;</span> <span><strong><%= sess.get("attendeeCount") %></strong> attended</span></div>
          </div>
          <% if (!sess.get("description").isEmpty()) { %>
            <p class="description-text"><%= sess.get("description") %></p>
          <% } %>
          <div class="card-footer">
            <div>
              <span class="badge <%= visClass %>" style="margin-right:6px"><%= vis %></span>
              <span class="organizer-label">by <strong>@<%= sess.get("organizer") %></strong></span>
            </div>
            <% if (isOrg) { %>
              <a class="btn-leave" href="session_attendees.jsp?sessionId=<%= sess.get("sessionId") %>">View Attendees</a>
            <% } else { %>
              <span class="badge <%= statusClass %>"><%= statusVal %></span>
            <% } %>
          </div>
        </div>
        <% } %>
      </div>
    <% } %>
  </div>

</div>

<script>
  function switchTab(id, btn) {
    document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
    document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
    document.getElementById('tab-' + id).classList.add('active');
    btn.classList.add('active');
  }
</script>
</body>
</html>
