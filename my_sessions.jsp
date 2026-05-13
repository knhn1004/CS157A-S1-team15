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

  String actionParam    = request.getParameter("action");
  String actionSessionId = request.getParameter("sessionId");
  String actionMsg      = "";
  String actionMsgType  = "success";

  // ── LEAVE ─────────────────────────────────────────────────────────────────
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
      actionMsg     = rows > 0 ? "You have left the session." : "You were not registered for that session.";
      actionMsgType = rows > 0 ? "success" : "error";
    } catch (Exception e) {
      actionMsg = "Error leaving session: " + h(e.getMessage());
      actionMsgType = "error";
    }

  // ── ACCEPT INVITE ─────────────────────────────────────────────────────────
  } else if ("accept_invite".equals(actionParam) && actionSessionId != null && !actionSessionId.trim().isEmpty()) {
    String sid = actionSessionId.trim();
    Connection actCon = null;
    try {
      Class.forName("com.mysql.cj.jdbc.Driver");
      actCon = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
      actCon.setAutoCommit(false);

      // Verify invite exists
      PreparedStatement ckPs = actCon.prepareStatement(
        "SELECT Response FROM Invited_To WHERE Session_ID = ? AND Invitee = ?"
      );
      ckPs.setString(1, sid); ckPs.setString(2, username);
      ResultSet ckRs = ckPs.executeQuery();
      if (!ckRs.next()) {
        actionMsg = "Invitation not found."; actionMsgType = "error";
        actCon.rollback();
      } else {
        String curResp = ckRs.getString("Response");
        ckRs.close(); ckPs.close();
        if (curResp != null && !curResp.equalsIgnoreCase("Pending") && !curResp.isEmpty()) {
          actionMsg = "This invitation has already been " + curResp.toLowerCase() + ".";
          actionMsgType = "info";
          actCon.rollback();
        } else {
          // Check capacity
          PreparedStatement capPs = actCon.prepareStatement(
            "SELECT ss.Capacity, (SELECT COUNT(*) FROM Attends WHERE Session_ID = ss.Session_ID) AS cur " +
            "FROM StudySession ss WHERE ss.Session_ID = ?"
          );
          capPs.setString(1, sid);
          ResultSet capRs = capPs.executeQuery();
          boolean full = false;
          if (capRs.next()) {
            int cap = capRs.getInt("Capacity"); int cur = capRs.getInt("cur");
            if (!capRs.wasNull() && cap > 0 && cur >= cap) full = true;
          }
          capRs.close(); capPs.close();

          if (full) {
            actCon.rollback();
            actionMsg = "This session is full — you could not be added."; actionMsgType = "error";
          } else {
            // Update Invited_To
            PreparedStatement updPs = actCon.prepareStatement(
              "UPDATE Invited_To SET Response = 'Accepted' WHERE Session_ID = ? AND Invitee = ?"
            );
            updPs.setString(1, sid); updPs.setString(2, username);
            updPs.executeUpdate(); updPs.close();

            // Insert into Attends if not already there
            PreparedStatement alPs = actCon.prepareStatement(
              "SELECT 1 FROM Attends WHERE Session_ID = ? AND Username = ?"
            );
            alPs.setString(1, sid); alPs.setString(2, username);
            ResultSet alRs = alPs.executeQuery();
            boolean alreadyIn = alRs.next();
            alRs.close(); alPs.close();

            if (!alreadyIn) {
              PreparedStatement insPs = actCon.prepareStatement(
                "INSERT INTO Attends (Session_ID, Username, Status) VALUES (?, ?, 'Confirmed')"
              );
              insPs.setString(1, sid); insPs.setString(2, username);
              insPs.executeUpdate(); insPs.close();
            }
            actCon.commit();
            actionMsg = "&#10003; You have joined the session! It now appears in Upcoming &amp; Current.";
            actionMsgType = "success";
          }
        }
      }
    } catch (Exception e) {
      if (actCon != null) try { actCon.rollback(); } catch (Exception ignore) {}
      actionMsg = "Error: " + h(e.getMessage()); actionMsgType = "error";
    } finally {
      if (actCon != null) try { actCon.setAutoCommit(true); actCon.close(); } catch (Exception ignore) {}
    }

  // ── DECLINE INVITE ────────────────────────────────────────────────────────
  } else if ("decline_invite".equals(actionParam) && actionSessionId != null && !actionSessionId.trim().isEmpty()) {
    String sid = actionSessionId.trim();
    try {
      Class.forName("com.mysql.cj.jdbc.Driver");
      Connection dCon = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
      PreparedStatement dPs = dCon.prepareStatement(
        "UPDATE Invited_To SET Response = 'Declined' WHERE Session_ID = ? AND Invitee = ?"
      );
      dPs.setString(1, sid); dPs.setString(2, username);
      int rows = dPs.executeUpdate();
      dPs.close(); dCon.close();
      actionMsg = rows > 0 ? "Invitation declined." : "Invitation not found.";
      actionMsgType = rows > 0 ? "info" : "error";
    } catch (Exception e) {
      actionMsg = "Error: " + h(e.getMessage()); actionMsgType = "error";
    }
  }

  // Which tab to open (default to invitations tab if an invite action just ran)
  String activeTab = request.getParameter("tab") != null ? request.getParameter("tab") : "upcoming";
  if ("accept_invite".equals(actionParam) || "decline_invite".equals(actionParam)) {
    activeTab = "invitations";
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

    .page-header h1 { font-size: 22px; font-weight: 700; color: #111827; }
    .page-header p  { font-size: 13px; color: #6b7280; margin-top: 3px; }

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
    .alert-info    { background: #dbeafe; color: #1e40af; }

    /* ── Tabs ── */
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
      display: flex;
      align-items: center;
      gap: 6px;
    }

    .tab-btn.active { color: #0055A2; border-bottom-color: #0055A2; }
    .tab-btn:hover  { color: #0055A2; }

    .tab-badge {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      min-width: 18px;
      height: 18px;
      padding: 0 5px;
      background: #f59e0b;
      color: white;
      font-size: 10px;
      font-weight: 800;
      border-radius: 999px;
    }

    .tab-panel { display: none; }
    .tab-panel.active { display: block; }

    /* ── Session cards ── */
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
      display: flex;
      flex-direction: column;
    }

    .session-card:hover {
      box-shadow: 0 4px 16px rgba(0,0,0,0.12);
      transform: translateY(-2px);
    }

    .session-card.past      { border-left-color: #9ca3af; opacity: 0.85; }
    .session-card.invite    { border-left-color: #d97706; }
    .session-card.inv-accepted { border-left-color: #059669; opacity: 0.9; }
    .session-card.inv-declined { border-left-color: #9ca3af; opacity: 0.7; }

    .card-top {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 10px;
      gap: 8px;
    }

    .session-card h3 {
      font-size: 15px;
      font-weight: 700;
      color: #111827;
      flex: 1;
      margin-right: 6px;
    }

    .badges { display: flex; gap: 4px; flex-wrap: wrap; justify-content: flex-end; }

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
    .badge-private    { background: #ede9fe; color: #5b21b6; }
    .badge-past       { background: #f3f4f6; color: #6b7280; }
    .badge-upcoming   { background: #eff6ff; color: #1e40af; }
    .badge-organizer  { background: #fef3c7; color: #92400e; }
    .badge-inv-pending  { background: #fef3c7; color: #92400e; }
    .badge-inv-accepted { background: #dcfce7; color: #166534; }
    .badge-inv-declined { background: #f3f4f6; color: #6b7280; }

    .tag-topic {
      display: inline-block;
      background: #eff6ff;
      color: #1e40af;
      font-size: 11px;
      font-weight: 600;
      padding: 2px 8px;
      border-radius: 6px;
      margin-bottom: 10px;
    }

    .inviter-row {
      font-size: 12px;
      color: #6b7280;
      margin-bottom: 10px;
    }

    .inviter-row strong { color: #374151; }

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
    .meta-item strong { color: #374151; font-weight: 600; }

    .description-text {
      font-size: 12px;
      color: #6b7280;
      line-height: 1.5;
      margin-bottom: 14px;
      flex: 1;
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
      margin-top: auto;
      gap: 8px;
    }

    .organizer-label { font-size: 11px; color: #9ca3af; }
    .organizer-label strong { color: #6b7280; }

    .btn-action {
      padding: 6px 13px;
      border-radius: 6px;
      font-size: 12px;
      font-weight: 700;
      cursor: pointer;
      text-decoration: none;
      border: none;
      display: inline-block;
    }

    .btn-leave {
      background: #fff;
      border: 1.5px solid #e5e7eb;
      color: #6b7280;
      transition: all 0.15s;
    }

    .btn-leave:hover { background: #fee2e2; border-color: #fca5a5; color: #991b1b; }

    .btn-accept {
      background: #059669;
      color: white;
      transition: background 0.15s;
    }

    .btn-accept:hover { background: #047857; }

    .btn-decline-inv {
      background: #fff;
      border: 1.5px solid #e5e7eb;
      color: #6b7280;
      transition: all 0.15s;
    }

    .btn-decline-inv:hover { background: #fee2e2; border-color: #fca5a5; color: #991b1b; }

    .no-data {
      text-align: center;
      padding: 52px 0;
      color: #9ca3af;
      background: white;
      border-radius: 12px;
      box-shadow: 0 1px 4px rgba(0,0,0,0.07);
    }

    .no-data .no-data-icon { font-size: 40px; margin-bottom: 12px; }
    .no-data p { font-size: 14px; line-height: 1.7; }
    .no-data a { color: #0055A2; font-weight: 600; text-decoration: none; }
    .no-data a:hover { text-decoration: underline; }

    .section-summary { font-size: 13px; color: #6b7280; margin-bottom: 16px; }
    .section-summary strong { color: #374151; }

    /* Invite sub-tabs */
    .inv-subtabs {
      display: flex;
      gap: 0;
      border-bottom: 1.5px solid #e5e7eb;
      margin-bottom: 20px;
    }

    .inv-stab {
      padding: 7px 16px;
      font-size: 13px;
      font-weight: 600;
      color: #6b7280;
      background: none;
      border: none;
      border-bottom: 3px solid transparent;
      margin-bottom: -2px;
      cursor: pointer;
    }

    .inv-stab.active { color: #0055A2; border-bottom-color: #0055A2; }
    .inv-stab:hover  { color: #0055A2; }

    .inv-subpanel { display: none; }
    .inv-subpanel.active { display: block; }

    /* Decline confirm modal */
    .modal-backdrop {
      position: fixed;
      inset: 0;
      background: rgba(17,24,39,0.5);
      display: none;
      align-items: center;
      justify-content: center;
      padding: 16px;
      z-index: 999;
    }

    .modal-backdrop.open { display: flex; }

    .modal {
      width: 100%;
      max-width: 400px;
      background: white;
      border-radius: 12px;
      padding: 24px;
      box-shadow: 0 10px 30px rgba(0,0,0,0.2);
    }

    .modal h3 { font-size: 16px; font-weight: 700; color: #111827; margin-bottom: 8px; }
    .modal p  { font-size: 13px; color: #6b7280; margin-bottom: 20px; }

    .modal-actions { display: flex; gap: 10px; justify-content: flex-end; }

    .btn-modal-cancel {
      padding: 9px 18px;
      border: 1.5px solid #e5e7eb;
      background: white;
      color: #374151;
      border-radius: 8px;
      font-size: 13px;
      font-weight: 600;
      cursor: pointer;
    }

    .btn-modal-cancel:hover { background: #f9fafb; }

    .btn-modal-confirm {
      padding: 9px 18px;
      background: #ef4444;
      color: white;
      border: none;
      border-radius: 8px;
      font-size: 13px;
      font-weight: 700;
      cursor: pointer;
    }

    .btn-modal-confirm:hover { background: #dc2626; }
  </style>
</head>
<body>

<nav>
  <span class="brand">&#128218; SpartanStudyCircle</span>
  <div class="nav-links">
    <a href="home.jsp">Home</a>
    <a href="schedule.jsp">My Schedule</a>
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

  <div class="page-header">
    <div>
      <h1>My Study Sessions</h1>
      <p>Sessions you've joined, are organizing, or been invited to</p>
    </div>
    <a href="browse_sessions.jsp" class="btn-primary">&#43; Join a Session</a>
  </div>

  <% if (!actionMsg.isEmpty()) { %>
    <div class="alert alert-<%= actionMsgType %>"><%= actionMsg %></div>
  <% } %>

  <% if ("1".equals(request.getParameter("joined"))) { %>
    <div class="alert alert-success">&#10003; You have successfully joined the session!</div>
  <% } %>

  <%
    // ── LOAD SESSIONS ────────────────────────────────────────────────────────
    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    String dbError = "";

    java.util.List<java.util.Map<String,String>> upcomingSessions = new java.util.ArrayList<>();
    java.util.List<java.util.Map<String,String>> pastSessions     = new java.util.ArrayList<>();

    // Invitations split into three buckets
    java.util.List<java.util.Map<String,String>> invPending  = new java.util.ArrayList<>();
    java.util.List<java.util.Map<String,String>> invAccepted = new java.util.ArrayList<>();
    java.util.List<java.util.Map<String,String>> invDeclined = new java.util.ArrayList<>();

    try {
      Class.forName("com.mysql.cj.jdbc.Driver");
      con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
      java.time.LocalDate today = java.time.LocalDate.now();

      // ── 1. Sessions user is attending ────────────────────────────────────
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
          try { isPast = java.time.LocalDate.parse(dateStr).isBefore(today); } catch (Exception ignored) {}
        }
        if (isPast) pastSessions.add(m); else upcomingSessions.add(m);
      }
      rs.close(); ps.close();

      // ── 2. Sessions user organizes but hasn't joined via Attends ─────────
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
          try { isPast = java.time.LocalDate.parse(dateStr).isBefore(java.time.LocalDate.now()); } catch (Exception ignored) {}
        }
        if (isPast) pastSessions.add(m); else upcomingSessions.add(m);
      }
      rs.close(); ps.close();

      // ── 3. Invitations (Invited_To WHERE Invitee = user) ─────────────────
      ps = con.prepareStatement(
        "SELECT it.Session_ID, it.Inviter, it.Response, " +
        "       ss.Name, ss.Date, ss.Time, ss.Location, ss.Description, " +
        "       ss.Topic, ss.Capacity, ss.Organizer_Username, " +
        "       (SELECT COUNT(*) FROM Attends WHERE Session_ID = ss.Session_ID) AS attendee_count, " +
        "       inv.Name AS inviter_name " +
        "FROM Invited_To it " +
        "JOIN StudySession ss ON ss.Session_ID = it.Session_ID " +
        "LEFT JOIN Users inv ON inv.Username = it.Inviter " +
        "WHERE it.Invitee = ? " +
        "ORDER BY " +
        "  CASE WHEN (it.Response IS NULL OR it.Response = 'Pending') THEN 0 " +
        "       WHEN it.Response = 'Accepted' THEN 1 ELSE 2 END ASC, " +
        "  ss.Date ASC, ss.Time ASC"
      );
      ps.setString(1, username);
      rs = ps.executeQuery();

      while (rs.next()) {
        java.util.Map<String,String> m = new java.util.LinkedHashMap<>();
        m.put("sessionId",     rs.getString("Session_ID"));
        m.put("inviter",       rs.getString("Inviter") != null ? rs.getString("Inviter") : "—");
        m.put("inviterName",   rs.getString("inviter_name") != null ? rs.getString("inviter_name") : "—");
        String resp = rs.getString("Response");
        m.put("response",      resp != null ? resp : "Pending");
        m.put("name",          rs.getString("Name") != null ? rs.getString("Name") : "Untitled");
        m.put("date",          rs.getString("Date") != null ? rs.getString("Date") : "TBD");
        m.put("time",          rs.getString("Time") != null ? rs.getString("Time") : "—");
        m.put("location",      rs.getString("Location") != null ? rs.getString("Location") : "—");
        m.put("description",   rs.getString("Description") != null ? rs.getString("Description") : "");
        m.put("topic",         rs.getString("Topic") != null ? rs.getString("Topic") : "");
        m.put("organizer",     rs.getString("Organizer_Username") != null ? rs.getString("Organizer_Username") : "—");
        m.put("attendeeCount", String.valueOf(rs.getInt("attendee_count")));
        int cap = rs.getInt("Capacity");
        m.put("capacity",      rs.wasNull() ? "—" : String.valueOf(cap));

        String r = m.get("response");
        if ("Accepted".equalsIgnoreCase(r))      invAccepted.add(m);
        else if ("Declined".equalsIgnoreCase(r)) invDeclined.add(m);
        else                                      invPending.add(m);
      }
      rs.close(); ps.close();

    } catch (Exception e) {
      dbError = "Database error: " + h(e.getMessage());
    } finally {
      if (rs  != null) try { rs.close();  } catch (Exception ignore) {}
      if (ps  != null) try { ps.close();  } catch (Exception ignore) {}
      if (con != null) try { con.close(); } catch (Exception ignore) {}
    }
  %>

  <% if (!dbError.isEmpty()) { %>
    <div class="alert alert-error"><%= dbError %></div>
  <% } %>

  <!-- ── Tab navigation ── -->
  <div class="tabs">
    <button class="tab-btn <%= "upcoming".equals(activeTab) ? "active" : "" %>"
            onclick="switchTab('upcoming', this)">
      Upcoming &amp; Current
    </button>
    <button class="tab-btn <%= "past".equals(activeTab) ? "active" : "" %>"
            onclick="switchTab('past', this)">
      Past Sessions
    </button>
    <button class="tab-btn <%= "invitations".equals(activeTab) ? "active" : "" %>"
            onclick="switchTab('invitations', this)">
      &#9993; Invitations
      <% if (!invPending.isEmpty()) { %>
        <span class="tab-badge"><%= invPending.size() %></span>
      <% } %>
    </button>
  </div>

  <!-- ══════════════════════════════════════════════════════════════════════ -->
  <!-- UPCOMING TAB                                                           -->
  <!-- ══════════════════════════════════════════════════════════════════════ -->
  <div id="tab-upcoming" class="tab-panel <%= "upcoming".equals(activeTab) ? "active" : "" %>">
    <p class="section-summary">
      Showing <strong><%= upcomingSessions.size() %></strong> upcoming or active session(s).
    </p>

    <% if (upcomingSessions.isEmpty()) { %>
      <div class="no-data">
        <div class="no-data-icon">&#128197;</div>
        <p>You have no upcoming study sessions.<br/>
           <a href="browse_sessions.jsp">Browse sessions</a> to join one!</p>
      </div>
    <% } else { %>
      <div class="sessions-grid">
        <% for (java.util.Map<String,String> sess : upcomingSessions) {
             String vis = sess.get("visibility");
             String visClass = "Public".equals(vis) ? "badge-public" : "Private".equals(vis) ? "badge-private" : "badge-friends";
             String statusVal = sess.get("status");
             String statusClass = "Pending".equals(statusVal) ? "badge-pending" :
                                  "Declined".equals(statusVal) ? "badge-declined" :
                                  "Organizer".equals(statusVal) ? "badge-organizer" : "badge-confirmed";
             boolean isOrg = "true".equals(sess.get("isOrganizer"));
        %>
        <div class="session-card">
          <div class="card-top">
            <h3><%= h(sess.get("name")) %></h3>
            <span class="badge <%= statusClass %>"><%= h(statusVal) %></span>
          </div>
          <% if (!sess.get("topic").isEmpty()) { %>
            <span class="tag-topic">&#128218; <%= h(sess.get("topic")) %></span>
          <% } %>
          <div class="meta-grid">
            <div class="meta-item"><span class="icon">&#128197;</span> <strong><%= h(sess.get("date") != null ? sess.get("date") : "TBD") %></strong></div>
            <div class="meta-item"><span class="icon">&#128336;</span> <strong><%= h(sess.get("time")) %></strong></div>
            <div class="meta-item"><span class="icon">&#128205;</span> <strong><%= h(sess.get("location")) %></strong></div>
            <div class="meta-item"><span class="icon">&#128101;</span>
              <strong><%= h(sess.get("attendeeCount")) %><%= !sess.get("capacity").equals("—") ? "/" + h(sess.get("capacity")) : "" %></strong>&nbsp;attending
            </div>
          </div>
          <% if (!sess.get("description").isEmpty()) { %>
            <p class="description-text"><%= h(sess.get("description")) %></p>
          <% } %>
          <div class="card-footer">
            <div>
              <span class="badge <%= visClass %>" style="margin-right:6px"><%= h(vis) %></span>
              <span class="organizer-label">by <strong>@<%= h(sess.get("organizer")) %></strong></span>
            </div>
            <% if (isOrg) { %>
              <a class="btn-action btn-leave" href="session_attendees.jsp?sessionId=<%= h(sess.get("sessionId")) %>">View Attendees</a>
            <% } else { %>
              <a class="btn-action btn-leave"
                 href="my_sessions.jsp?action=leave&sessionId=<%= h(sess.get("sessionId")) %>&tab=upcoming"
                 onclick="return confirm('Leave this session?')">Leave</a>
            <% } %>
          </div>
        </div>
        <% } %>
      </div>
    <% } %>
  </div>

  <!-- ══════════════════════════════════════════════════════════════════════ -->
  <!-- PAST TAB                                                               -->
  <!-- ══════════════════════════════════════════════════════════════════════ -->
  <div id="tab-past" class="tab-panel <%= "past".equals(activeTab) ? "active" : "" %>">
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
             String visClass = "Public".equals(vis) ? "badge-public" : "Private".equals(vis) ? "badge-private" : "badge-friends";
             String statusVal = sess.get("status");
             String statusClass = "Pending".equals(statusVal) ? "badge-pending" :
                                  "Declined".equals(statusVal) ? "badge-declined" :
                                  "Organizer".equals(statusVal) ? "badge-organizer" : "badge-confirmed";
             boolean isOrg = "true".equals(sess.get("isOrganizer"));
        %>
        <div class="session-card past">
          <div class="card-top">
            <h3><%= h(sess.get("name")) %></h3>
            <span class="badge badge-past">Past</span>
          </div>
          <% if (!sess.get("topic").isEmpty()) { %>
            <span class="tag-topic">&#128218; <%= h(sess.get("topic")) %></span>
          <% } %>
          <div class="meta-grid">
            <div class="meta-item"><span class="icon">&#128197;</span> <strong><%= h(sess.get("date") != null ? sess.get("date") : "—") %></strong></div>
            <div class="meta-item"><span class="icon">&#128336;</span> <strong><%= h(sess.get("time")) %></strong></div>
            <div class="meta-item"><span class="icon">&#128205;</span> <strong><%= h(sess.get("location")) %></strong></div>
            <div class="meta-item"><span class="icon">&#128101;</span> <strong><%= h(sess.get("attendeeCount")) %></strong>&nbsp;attended</div>
          </div>
          <% if (!sess.get("description").isEmpty()) { %>
            <p class="description-text"><%= h(sess.get("description")) %></p>
          <% } %>
          <div class="card-footer">
            <div>
              <span class="badge <%= visClass %>" style="margin-right:6px"><%= h(vis) %></span>
              <span class="organizer-label">by <strong>@<%= h(sess.get("organizer")) %></strong></span>
            </div>
            <% if (isOrg) { %>
              <a class="btn-action btn-leave" href="session_attendees.jsp?sessionId=<%= h(sess.get("sessionId")) %>">View Attendees</a>
            <% } else { %>
              <span class="badge <%= statusClass %>"><%= h(statusVal) %></span>
            <% } %>
          </div>
        </div>
        <% } %>
      </div>
    <% } %>
  </div>

  <!-- ══════════════════════════════════════════════════════════════════════ -->
  <!-- INVITATIONS TAB                                                        -->
  <!-- ══════════════════════════════════════════════════════════════════════ -->
  <div id="tab-invitations" class="tab-panel <%= "invitations".equals(activeTab) ? "active" : "" %>">

    <!-- Sub-tabs: Pending / Accepted / Declined -->
    <div class="inv-subtabs">
      <button class="inv-stab active" onclick="switchSubTab('inv-pending', this)">
        &#9200; Pending
        <% if (!invPending.isEmpty()) { %>&nbsp;(<%= invPending.size() %>)<% } %>
      </button>
      <button class="inv-stab" onclick="switchSubTab('inv-accepted', this)">
        &#10003; Accepted
        <% if (!invAccepted.isEmpty()) { %>&nbsp;(<%= invAccepted.size() %>)<% } %>
      </button>
      <button class="inv-stab" onclick="switchSubTab('inv-declined', this)">
        &#10005; Declined
        <% if (!invDeclined.isEmpty()) { %>&nbsp;(<%= invDeclined.size() %>)<% } %>
      </button>
    </div>

    <!-- PENDING invitations -->
    <div id="inv-pending" class="inv-subpanel active">
      <p class="section-summary">
        <strong><%= invPending.size() %></strong> pending invitation(s) waiting for your response.
      </p>
      <% if (invPending.isEmpty()) { %>
        <div class="no-data">
          <div class="no-data-icon">&#9993;</div>
          <p>No pending invitations.<br/>
             When someone invites you to a private session, it will appear here.</p>
        </div>
      <% } else { %>
        <div class="sessions-grid">
          <% for (java.util.Map<String,String> inv : invPending) { %>
          <div class="session-card invite">
            <div class="card-top">
              <h3><%= h(inv.get("name")) %></h3>
              <div class="badges">
                <span class="badge badge-inv-pending">&#9200; Pending</span>
                <span class="badge badge-private">&#128274; Private</span>
              </div>
            </div>
            <% if (!inv.get("topic").isEmpty()) { %>
              <span class="tag-topic">&#128218; <%= h(inv.get("topic")) %></span>
            <% } %>
            <div class="inviter-row">
              &#128100; Invited by <strong><%= h(inv.get("inviterName")) %></strong> (@<%= h(inv.get("inviter")) %>)
            </div>
            <div class="meta-grid">
              <div class="meta-item"><span class="icon">&#128197;</span> <strong><%= h(inv.get("date")) %></strong></div>
              <div class="meta-item"><span class="icon">&#128336;</span> <strong><%= h(inv.get("time")) %></strong></div>
              <div class="meta-item"><span class="icon">&#128205;</span> <strong><%= h(inv.get("location")) %></strong></div>
              <div class="meta-item"><span class="icon">&#128101;</span>
                <strong><%= h(inv.get("attendeeCount")) %><%= !inv.get("capacity").equals("—") ? "/" + h(inv.get("capacity")) : "" %></strong>&nbsp;attending
              </div>
            </div>
            <% if (!inv.get("description").isEmpty()) { %>
              <p class="description-text"><%= h(inv.get("description")) %></p>
            <% } %>
            <div class="card-footer">
              <span class="organizer-label">by <strong>@<%= h(inv.get("organizer")) %></strong></span>
              <div style="display:flex;gap:7px;">
                <button class="btn-action btn-decline-inv"
                        onclick="openDeclineModal('<%= h(inv.get("sessionId")) %>', '<%= h(inv.get("name")).replace("'","\\'"  ) %>')">
                  Decline
                </button>
                <a class="btn-action btn-accept"
                   href="my_sessions.jsp?action=accept_invite&sessionId=<%= h(inv.get("sessionId")) %>">
                  &#10003; Accept
                </a>
              </div>
            </div>
          </div>
          <% } %>
        </div>
      <% } %>
    </div>

    <!-- ACCEPTED invitations -->
    <div id="inv-accepted" class="inv-subpanel">
      <p class="section-summary">
        <strong><%= invAccepted.size() %></strong> accepted invitation(s).
      </p>
      <% if (invAccepted.isEmpty()) { %>
        <div class="no-data">
          <div class="no-data-icon">&#10003;</div>
          <p>No accepted invitations yet.</p>
        </div>
      <% } else { %>
        <div class="sessions-grid">
          <% for (java.util.Map<String,String> inv : invAccepted) { %>
          <div class="session-card inv-accepted">
            <div class="card-top">
              <h3><%= h(inv.get("name")) %></h3>
              <div class="badges">
                <span class="badge badge-inv-accepted">&#10003; Accepted</span>
                <span class="badge badge-private">&#128274; Private</span>
              </div>
            </div>
            <% if (!inv.get("topic").isEmpty()) { %>
              <span class="tag-topic">&#128218; <%= h(inv.get("topic")) %></span>
            <% } %>
            <div class="inviter-row">
              &#128100; Invited by <strong><%= h(inv.get("inviterName")) %></strong> (@<%= h(inv.get("inviter")) %>)
            </div>
            <div class="meta-grid">
              <div class="meta-item"><span class="icon">&#128197;</span> <strong><%= h(inv.get("date")) %></strong></div>
              <div class="meta-item"><span class="icon">&#128336;</span> <strong><%= h(inv.get("time")) %></strong></div>
              <div class="meta-item"><span class="icon">&#128205;</span> <strong><%= h(inv.get("location")) %></strong></div>
              <div class="meta-item"><span class="icon">&#128101;</span>
                <strong><%= h(inv.get("attendeeCount")) %><%= !inv.get("capacity").equals("—") ? "/" + h(inv.get("capacity")) : "" %></strong>&nbsp;attending
              </div>
            </div>
            <% if (!inv.get("description").isEmpty()) { %>
              <p class="description-text"><%= h(inv.get("description")) %></p>
            <% } %>
            <div class="card-footer">
              <span class="organizer-label">by <strong>@<%= h(inv.get("organizer")) %></strong></span>
              <a href="my_sessions.jsp?tab=upcoming"
                 style="font-size:12px;color:#059669;font-weight:700;text-decoration:none;">
                View in Upcoming &#8594;
              </a>
            </div>
          </div>
          <% } %>
        </div>
      <% } %>
    </div>

    <!-- DECLINED invitations -->
    <div id="inv-declined" class="inv-subpanel">
      <p class="section-summary">
        <strong><%= invDeclined.size() %></strong> declined invitation(s).
      </p>
      <% if (invDeclined.isEmpty()) { %>
        <div class="no-data">
          <div class="no-data-icon">&#10005;</div>
          <p>No declined invitations.</p>
        </div>
      <% } else { %>
        <div class="sessions-grid">
          <% for (java.util.Map<String,String> inv : invDeclined) { %>
          <div class="session-card inv-declined">
            <div class="card-top">
              <h3><%= h(inv.get("name")) %></h3>
              <div class="badges">
                <span class="badge badge-inv-declined">&#10005; Declined</span>
                <span class="badge badge-private">&#128274; Private</span>
              </div>
            </div>
            <% if (!inv.get("topic").isEmpty()) { %>
              <span class="tag-topic">&#128218; <%= h(inv.get("topic")) %></span>
            <% } %>
            <div class="inviter-row">
              &#128100; Invited by <strong><%= h(inv.get("inviterName")) %></strong> (@<%= h(inv.get("inviter")) %>)
            </div>
            <div class="meta-grid">
              <div class="meta-item"><span class="icon">&#128197;</span> <strong><%= h(inv.get("date")) %></strong></div>
              <div class="meta-item"><span class="icon">&#128336;</span> <strong><%= h(inv.get("time")) %></strong></div>
              <div class="meta-item"><span class="icon">&#128205;</span> <strong><%= h(inv.get("location")) %></strong></div>
              <div class="meta-item"><span class="icon">&#128101;</span>
                <strong><%= h(inv.get("attendeeCount")) %><%= !inv.get("capacity").equals("—") ? "/" + h(inv.get("capacity")) : "" %></strong>&nbsp;attending
              </div>
            </div>
            <% if (!inv.get("description").isEmpty()) { %>
              <p class="description-text"><%= h(inv.get("description")) %></p>
            <% } %>
            <div class="card-footer">
              <span class="organizer-label">by <strong>@<%= h(inv.get("organizer")) %></strong></span>
            </div>
          </div>
          <% } %>
        </div>
      <% } %>
    </div>

  </div><!-- /tab-invitations -->

</div><!-- /container -->

<!-- Decline confirmation modal -->
<div id="declineModal" class="modal-backdrop" aria-hidden="true">
  <div class="modal">
    <h3>Decline Invitation?</h3>
    <p id="declineModalText">Are you sure you want to decline this invitation?</p>
    <div class="modal-actions">
      <button class="btn-modal-cancel" onclick="closeDeclineModal()">Cancel</button>
      <a id="declineConfirmLink" href="#" class="btn-action btn-modal-confirm">Yes, Decline</a>
    </div>
  </div>
</div>

<script>
  // ── Main tab switching ───────────────────────────────────────────────────
  function switchTab(id, btn) {
    document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
    document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
    document.getElementById('tab-' + id).classList.add('active');
    btn.classList.add('active');
  }

  // ── Invitation sub-tab switching ────────────────────────────────────────
  function switchSubTab(id, btn) {
    document.querySelectorAll('.inv-subpanel').forEach(p => p.classList.remove('active'));
    document.querySelectorAll('.inv-stab').forEach(b => b.classList.remove('active'));
    document.getElementById(id).classList.add('active');
    btn.classList.add('active');
  }

  // ── Decline modal ────────────────────────────────────────────────────────
  function openDeclineModal(sessionId, sessionName) {
    document.getElementById('declineModalText').textContent =
      'Are you sure you want to decline the invitation to "' + sessionName + '"?';
    document.getElementById('declineConfirmLink').href =
      'my_sessions.jsp?action=decline_invite&sessionId=' + encodeURIComponent(sessionId);
    var m = document.getElementById('declineModal');
    m.classList.add('open');
    m.setAttribute('aria-hidden', 'false');
  }

  function closeDeclineModal() {
    var m = document.getElementById('declineModal');
    m.classList.remove('open');
    m.setAttribute('aria-hidden', 'true');
  }

  window.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') closeDeclineModal();
  });

  // ── Restore active tab from URL param ───────────────────────────────────
  (function() {
    var tab = '<%= activeTab %>';
    if (tab && tab !== 'upcoming') {
      document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
      document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
      var panel = document.getElementById('tab-' + tab);
      var btns  = document.querySelectorAll('.tab-btn');
      var idx   = tab === 'past' ? 1 : tab === 'invitations' ? 2 : 0;
      if (panel)     panel.classList.add('active');
      if (btns[idx]) btns[idx].classList.add('active');
    }
  })();
</script>
</body>
</html>
