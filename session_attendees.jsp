<%@ page import="java.sql.*" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page session="true" %>
<%!
  private String h(String s) {
    if (s == null) return "";
    StringBuilder sb = new StringBuilder(s.length());
    for (int i = 0; i < s.length(); i++) {
      char c = s.charAt(i);
      switch (c) {
        case '&':  sb.append("&amp;");  break;
        case '<':  sb.append("&lt;");   break;
        case '>':  sb.append("&gt;");   break;
        case '"':  sb.append("&quot;"); break;
        case '\'': sb.append("&#39;");  break;
        default:   sb.append(c);
      }
    }
    return sb.toString();
  }
%>
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

  String sessionId       = request.getParameter("sessionId") != null ? request.getParameter("sessionId").trim() : "";
  String sessionName     = "";
  String sessionDate     = "";
  String sessionTime     = "";
  String sessionLocation = "";
  String sessionTopic    = "";
  String sessionVis      = "";
  String organizer       = "";
  String errorMsg        = "";
  boolean isOrganizer    = false;
  String activeTab       = request.getParameter("tab") != null ? request.getParameter("tab") : "attendees";
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Session Details - SpartanStudyCircle</title>
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

    nav .user-info { display: flex; align-items: center; gap: 12px; font-size: 14px; }

    .container { max-width: 980px; margin: 32px auto; padding: 0 16px; }

    .card {
      background: white;
      border-radius: 12px;
      padding: 24px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.08);
    }

    .header-row {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 10px;
      gap: 12px;
    }

    .header-row h2 { font-size: 18px; color: #0055A2; font-weight: 700; }

    .back-link {
      color: #0055A2;
      text-decoration: none;
      font-size: 13px;
      font-weight: 600;
      white-space: nowrap;
    }

    .back-link:hover { text-decoration: underline; }

    .session-meta {
      font-size: 13px;
      color: #6b7280;
      margin-bottom: 6px;
      line-height: 1.6;
    }

    .session-meta strong { color: #374151; }

    .badge-vis {
      display: inline-block;
      padding: 2px 9px;
      border-radius: 999px;
      font-size: 11px;
      font-weight: 700;
    }

    .badge-vis-public  { background: #dcfce7; color: #166534; }
    .badge-vis-friends { background: #ede9fe; color: #5b21b6; }
    .badge-vis-private { background: #fee2e2; color: #991b1b; }

    /* ── Tabs ── */
    .tabs {
      display: flex;
      border-bottom: 2px solid #e5e7eb;
      margin: 18px 0 20px;
      gap: 0;
    }

    .tab-btn {
      padding: 9px 20px;
      font-size: 13px;
      font-weight: 600;
      color: #6b7280;
      background: none;
      border: none;
      border-bottom: 3px solid transparent;
      margin-bottom: -2px;
      cursor: pointer;
      transition: all 0.15s;
      display: flex;
      align-items: center;
      gap: 6px;
    }

    .tab-btn.active { color: #0055A2; border-bottom-color: #0055A2; }
    .tab-btn:hover  { color: #0055A2; }

    .inv-badge {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      min-width: 17px;
      height: 17px;
      padding: 0 4px;
      background: #f59e0b;
      color: white;
      font-size: 10px;
      font-weight: 800;
      border-radius: 999px;
    }

    .tab-panel { display: none; }
    .tab-panel.active { display: block; }

    /* ── Tables ── */
    table {
      width: 100%;
      border-collapse: collapse;
      font-size: 13px;
    }

    thead tr { background: #f9fafb; }

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
      vertical-align: middle;
    }

    tr:last-child td { border-bottom: none; }

    .badge {
      display: inline-block;
      padding: 3px 10px;
      border-radius: 999px;
      font-size: 11px;
      font-weight: 700;
    }

    .badge-confirmed  { background: #dcfce7; color: #166534; }
    .badge-pending    { background: #fef3c7; color: #92400e; }
    .badge-accepted   { background: #dcfce7; color: #166534; }
    .badge-declined   { background: #fee2e2; color: #991b1b; }
    .badge-default    { background: #dbeafe; color: #1e40af; }

    .table-link {
      color: #0055A2;
      text-decoration: none;
      font-weight: 600;
      font-size: 12px;
    }

    .table-link:hover { text-decoration: underline; }

    .no-data {
      text-align: center;
      color: #9ca3af;
      padding: 28px 0;
      font-size: 14px;
    }

    .error-msg {
      color: #991b1b;
      font-size: 13px;
      padding: 12px;
      background: #fee2e2;
      border-radius: 8px;
      margin-bottom: 16px;
    }

    /* Summary stats row */
    .stats-row {
      display: flex;
      gap: 14px;
      margin-bottom: 16px;
      flex-wrap: wrap;
    }

    .stat-chip {
      background: #f9fafb;
      border: 1px solid #e5e7eb;
      border-radius: 8px;
      padding: 8px 14px;
      font-size: 12px;
      color: #374151;
      display: flex;
      align-items: center;
      gap: 6px;
    }

    .stat-chip .num { font-size: 16px; font-weight: 700; }
    .stat-chip .num.green  { color: #059669; }
    .stat-chip .num.amber  { color: #d97706; }
    .stat-chip .num.red    { color: #dc2626; }
    .stat-chip .num.blue   { color: #2563eb; }

    /* Invitee rows with status color-coding */
    tr.row-accepted td:first-child { border-left: 3px solid #059669; }
    tr.row-pending  td:first-child { border-left: 3px solid #f59e0b; }
    tr.row-declined td:first-child { border-left: 3px solid #dc2626; }
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
    <span><%= h(name) %></span>
    <a class="logout" href="home.jsp?action=logout">Log Out</a>
  </div>
</nav>

<div class="container">
  <div class="card">

    <div class="header-row">
      <h2>Session Details</h2>
      <a class="back-link" href="my_sessions.jsp">&#8592; Back to My Sessions</a>
    </div>

    <%
      if (sessionId.isEmpty()) {
        errorMsg = "Missing session ID.";
      }
    %>

    <% if (!errorMsg.isEmpty()) { %>
      <p class="error-msg"><%= h(errorMsg) %></p>
    <% } else { %>

    <%
      // ── LOAD SESSION + ATTENDEES + INVITATIONS ────────────────────────────
      Connection con = null;

      java.util.List<java.util.Map<String,String>> attendeeRows  = new java.util.ArrayList<>();
      java.util.List<java.util.Map<String,String>> inviteRows    = new java.util.ArrayList<>();
      int invPendingCount  = 0;
      int invAcceptedCount = 0;
      int invDeclinedCount = 0;

      try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

        // Load session header
        PreparedStatement sessPs = con.prepareStatement(
          "SELECT Session_ID, Name, Date, Time, Location, Topic, Visibility, Organizer_Username " +
          "FROM StudySession WHERE Session_ID = ?"
        );
        sessPs.setString(1, sessionId);
        ResultSet sessRs = sessPs.executeQuery();

        if (!sessRs.next()) {
          errorMsg = "Study session not found.";
        } else {
          sessionName     = sessRs.getString("Name")               != null ? sessRs.getString("Name")               : "Untitled";
          sessionDate     = sessRs.getString("Date")               != null ? sessRs.getString("Date")               : "TBD";
          sessionTime     = sessRs.getString("Time")               != null ? sessRs.getString("Time")               : "—";
          sessionLocation = sessRs.getString("Location")           != null ? sessRs.getString("Location")           : "—";
          sessionTopic    = sessRs.getString("Topic")              != null ? sessRs.getString("Topic")              : "";
          sessionVis      = sessRs.getString("Visibility")         != null ? sessRs.getString("Visibility")         : "Public";
          organizer       = sessRs.getString("Organizer_Username") != null ? sessRs.getString("Organizer_Username") : "—";
          isOrganizer     = organizer.equals(username);
        }
        sessRs.close(); sessPs.close();

        if (!errorMsg.isEmpty() || !isOrganizer) {
          if (errorMsg.isEmpty()) errorMsg = "Only the session organizer can view this page.";
        } else {

          // Load attendees
          PreparedStatement attPs = con.prepareStatement(
            "SELECT a.Username, u.Name, u.Major, u.Year, a.Status " +
            "FROM Attends a " +
            "JOIN Users u ON u.Username = a.Username " +
            "WHERE a.Session_ID = ? " +
            "ORDER BY u.Name ASC"
          );
          attPs.setString(1, sessionId);
          ResultSet attRs = attPs.executeQuery();
          while (attRs.next()) {
            java.util.Map<String,String> m = new java.util.LinkedHashMap<>();
            m.put("username", attRs.getString("Username"));
            m.put("name",     attRs.getString("Name") != null ? attRs.getString("Name") : "—");
            m.put("major",    attRs.getString("Major") != null ? attRs.getString("Major") : "—");
            m.put("year",     attRs.getObject("Year") != null ? String.valueOf(attRs.getInt("Year")) : "—");
            m.put("status",   attRs.getString("Status") != null ? attRs.getString("Status") : "—");
            attendeeRows.add(m);
          }
          attRs.close(); attPs.close();

          // Load invitations (only for Friends / Private sessions where Invited_To is used)
          PreparedStatement invPs = con.prepareStatement(
            "SELECT it.Invitee, it.Response, u.Name, u.Major, u.Year " +
            "FROM Invited_To it " +
            "JOIN Users u ON u.Username = it.Invitee " +
            "WHERE it.Session_ID = ? AND it.Inviter = ? " +
            "ORDER BY " +
            "  CASE WHEN (it.Response IS NULL OR it.Response = 'Pending') THEN 0 " +
            "       WHEN it.Response = 'Accepted' THEN 1 ELSE 2 END, " +
            "  u.Name ASC"
          );
          invPs.setString(1, sessionId);
          invPs.setString(2, username);
          ResultSet invRs = invPs.executeQuery();
          while (invRs.next()) {
            java.util.Map<String,String> m = new java.util.LinkedHashMap<>();
            m.put("username", invRs.getString("Invitee"));
            m.put("name",     invRs.getString("Name") != null ? invRs.getString("Name") : "—");
            m.put("major",    invRs.getString("Major") != null ? invRs.getString("Major") : "—");
            m.put("year",     invRs.getObject("Year") != null ? String.valueOf(invRs.getInt("Year")) : "—");
            String resp = invRs.getString("Response");
            m.put("response", resp != null ? resp : "Pending");
            inviteRows.add(m);
            if ("Accepted".equalsIgnoreCase(resp))      invAcceptedCount++;
            else if ("Declined".equalsIgnoreCase(resp)) invDeclinedCount++;
            else                                         invPendingCount++;
          }
          invRs.close(); invPs.close();
        }

      } catch (Exception e) {
        errorMsg = "Database error: " + h(e.getMessage());
      } finally {
        if (con != null) try { con.close(); } catch (Exception ignore) {}
      }
    %>

    <% if (!errorMsg.isEmpty()) { %>
      <p class="error-msg"><%= h(errorMsg) %></p>
    <% } else { %>

      <!-- Session header -->
      <div class="session-meta">
        <strong><%= h(sessionName) %></strong>
        &nbsp;&nbsp;
        <%
          String visClass = "badge-vis-public";
          if ("Friends".equals(sessionVis)) visClass = "badge-vis-friends";
          else if ("Private".equals(sessionVis)) visClass = "badge-vis-private";
        %>
        <span class="badge-vis <%= visClass %>"><%= h(sessionVis) %></span>
        <% if (!sessionTopic.isEmpty()) { %>
          &nbsp;·&nbsp; &#128218; <%= h(sessionTopic) %>
        <% } %>
        <br/>
        &#128197; <%= h(sessionDate) %> &nbsp;·&nbsp;
        &#128336; <%= h(sessionTime) %> &nbsp;·&nbsp;
        &#128205; <%= h(sessionLocation) %> &nbsp;·&nbsp;
        Organizer: <strong>@<%= h(organizer) %></strong>
      </div>

      <!-- Tabs -->
      <div class="tabs">
        <button class="tab-btn <%= "attendees".equals(activeTab) ? "active" : "" %>"
                onclick="switchTab('attendees', this)">
          &#128101; Attendees (<%= attendeeRows.size() %>)
        </button>
        <% if (!inviteRows.isEmpty()) { %>
        <button class="tab-btn <%= "invitations".equals(activeTab) ? "active" : "" %>"
                onclick="switchTab('invitations', this)">
          &#9993; Invitations
          <% if (invPendingCount > 0) { %>
            <span class="inv-badge"><%= invPendingCount %></span>
          <% } %>
        </button>
        <% } %>
      </div>

      <!-- ── ATTENDEES TAB ── -->
      <div id="tab-attendees" class="tab-panel <%= "attendees".equals(activeTab) ? "active" : "" %>">
        <div class="stats-row">
          <div class="stat-chip">
            <span class="num blue"><%= attendeeRows.size() %></span>
            <span>Total Registered</span>
          </div>
        </div>

        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Username</th>
              <th>Major</th>
              <th>Year</th>
              <th>Status</th>
              <th>Profile</th>
            </tr>
          </thead>
          <tbody>
            <% if (attendeeRows.isEmpty()) { %>
              <tr><td colspan="6" class="no-data">No attendees registered for this session yet.</td></tr>
            <% } else {
                 for (java.util.Map<String,String> att : attendeeRows) { %>
              <tr>
                <td><strong><%= h(att.get("name")) %></strong></td>
                <td>@<%= h(att.get("username")) %></td>
                <td><%= h(att.get("major")) %></td>
                <td><%= h(att.get("year")) %></td>
                <td>
                  <% String st = att.get("status");
                     String sc = "badge-default";
                     if ("Confirmed".equalsIgnoreCase(st)) sc = "badge-confirmed";
                  %>
                  <span class="badge <%= sc %>"><%= h(st) %></span>
                </td>
                <td>
                  <a class="table-link" href="public_profile.jsp?u=<%= h(att.get("username")) %>&sessionId=<%= h(sessionId) %>">
                    View Profile
                  </a>
                </td>
              </tr>
            <% } } %>
          </tbody>
        </table>
      </div>

      <!-- ── INVITATIONS TAB ── -->
      <% if (!inviteRows.isEmpty()) { %>
      <div id="tab-invitations" class="tab-panel <%= "invitations".equals(activeTab) ? "active" : "" %>">

        <div class="stats-row">
          <div class="stat-chip">
            <span class="num amber"><%= invPendingCount %></span>
            <span>Pending</span>
          </div>
          <div class="stat-chip">
            <span class="num green"><%= invAcceptedCount %></span>
            <span>Accepted</span>
          </div>
          <div class="stat-chip">
            <span class="num red"><%= invDeclinedCount %></span>
            <span>Declined</span>
          </div>
          <div class="stat-chip">
            <span class="num blue"><%= inviteRows.size() %></span>
            <span>Total Invited</span>
          </div>
        </div>

        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Username</th>
              <th>Major</th>
              <th>Year</th>
              <th>Response</th>
            </tr>
          </thead>
          <tbody>
            <% for (java.util.Map<String,String> inv : inviteRows) {
                 String resp = inv.get("response");
                 String rc   = "badge-pending";
                 String rowClass = "row-pending";
                 if ("Accepted".equalsIgnoreCase(resp)) { rc = "badge-accepted"; rowClass = "row-accepted"; }
                 else if ("Declined".equalsIgnoreCase(resp)) { rc = "badge-declined"; rowClass = "row-declined"; }
            %>
              <tr class="<%= rowClass %>">
                <td><strong><%= h(inv.get("name")) %></strong></td>
                <td>@<%= h(inv.get("username")) %></td>
                <td><%= h(inv.get("major")) %></td>
                <td><%= h(inv.get("year")) %></td>
                <td><span class="badge <%= rc %>"><%= h(resp) %></span></td>
              </tr>
            <% } %>
          </tbody>
        </table>
      </div>
      <% } %>

    <% } /* end errorMsg check */ %>
    <% } /* end outer errorMsg check */ %>

  </div><!-- /card -->
</div><!-- /container -->

<script>
  function switchTab(id, btn) {
    document.querySelectorAll('.tab-panel').forEach(function(p) { p.classList.remove('active'); });
    document.querySelectorAll('.tab-btn').forEach(function(b)   { b.classList.remove('active'); });
    document.getElementById('tab-' + id).classList.add('active');
    btn.classList.add('active');
  }

  // Restore tab from URL
  (function() {
    var tab = '<%= h(activeTab) %>';
    var panel = document.getElementById('tab-' + tab);
    var btns  = document.querySelectorAll('.tab-btn');
    if (panel && tab !== 'attendees') {
      document.querySelectorAll('.tab-panel').forEach(function(p) { p.classList.remove('active'); });
      btns.forEach(function(b) { b.classList.remove('active'); });
      panel.classList.add('active');
      var idx = tab === 'invitations' ? 1 : 0;
      if (btns[idx]) btns[idx].classList.add('active');
    }
  })();
</script>
</body>
</html>
