<%@ page import="java.sql.*, java.util.*" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
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

  // ── HANDLE JOIN ────────────────────────────────────────────────────────────
  String actionParam    = request.getParameter("action");
  String actionSessId   = request.getParameter("joinSessionId");
  String joinMsg        = "";
  String joinMsgType    = "success";

  if ("join".equals(actionParam) && actionSessId != null && !actionSessId.trim().isEmpty()) {
    try {
      Class.forName("com.mysql.cj.jdbc.Driver");
      Connection joinCon = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

      // Check already joined
      PreparedStatement checkPs = joinCon.prepareStatement(
        "SELECT 1 FROM Attends WHERE Session_ID = ? AND Username = ?"
      );
      checkPs.setString(1, actionSessId.trim());
      checkPs.setString(2, username);
      ResultSet checkRs = checkPs.executeQuery();
      boolean alreadyJoined = checkRs.next();
      checkRs.close(); checkPs.close();

      if (alreadyJoined) {
        joinMsg = "You are already registered for this session.";
        joinMsgType = "info";
      } else {
        // Check capacity
        PreparedStatement capPs = joinCon.prepareStatement(
          "SELECT Capacity, (SELECT COUNT(*) FROM Attends WHERE Session_ID = ss.Session_ID) AS current_count " +
          "FROM StudySession ss WHERE Session_ID = ?"
        );
        capPs.setString(1, actionSessId.trim());
        ResultSet capRs = capPs.executeQuery();
        boolean full = false;
        if (capRs.next()) {
          int cap = capRs.getInt("Capacity");
          int cur = capRs.getInt("current_count");
          if (!capRs.wasNull() && cap > 0 && cur >= cap) full = true;
        }
        capRs.close(); capPs.close();

        if (full) {
          joinMsg = "This session is full.";
          joinMsgType = "error";
        } else {
          PreparedStatement joinPs = joinCon.prepareStatement(
            "INSERT INTO Attends (Session_ID, Username, Status) VALUES (?, ?, 'Confirmed')"
          );
          joinPs.setString(1, actionSessId.trim());
          joinPs.setString(2, username);
          joinPs.executeUpdate();
          joinPs.close();
          joinMsg = "&#10003; You have joined the session!";
          joinMsgType = "success";
        }
      }
      joinCon.close();
    } catch (Exception e) {
      joinMsg = "Error joining session: " + e.getMessage();
      joinMsgType = "error";
    }
  }

  // ── FILTER PARAMS ──────────────────────────────────────────────────────────
  String searchQ        = request.getParameter("q")           != null ? request.getParameter("q").trim()           : "";
  String filterTopic    = request.getParameter("topic")       != null ? request.getParameter("topic").trim()       : "";
  String filterLocation = request.getParameter("location")    != null ? request.getParameter("location").trim()    : "";
  String filterDay      = request.getParameter("day")         != null ? request.getParameter("day").trim()         : "";
  String filterTimeFrom = request.getParameter("timeFrom")    != null ? request.getParameter("timeFrom").trim()    : "";
  String filterTimeTo   = request.getParameter("timeTo")      != null ? request.getParameter("timeTo").trim()      : "";
  boolean filterFriends = "1".equals(request.getParameter("friendsOnly"));
  boolean filterSuggest = "1".equals(request.getParameter("suggested"));
  String activeTab      = request.getParameter("tab")         != null ? request.getParameter("tab")                : "all";

  // Distinct topics for filter dropdown
  List<String> topicOptions = new ArrayList<String>();
  try {
    Class.forName("com.mysql.cj.jdbc.Driver");
    Connection optCon = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
    PreparedStatement optPs = optCon.prepareStatement(
      "SELECT DISTINCT Topic FROM StudySession WHERE Topic IS NOT NULL AND TRIM(Topic) <> '' AND Visibility='Public' ORDER BY Topic"
    );
    ResultSet optRs = optPs.executeQuery();
    while (optRs.next()) topicOptions.add(optRs.getString("Topic"));
    optRs.close(); optPs.close(); optCon.close();
  } catch (Exception ignored) {}
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Browse Sessions - SpartanStudyCircle</title>
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

    .container {
      max-width: 1120px;
      margin: 28px auto;
      padding: 0 16px;
      display: grid;
      grid-template-columns: 260px 1fr;
      gap: 22px;
      align-items: start;
    }

    /* ── Sidebar filters ── */
    .sidebar {
      background: white;
      border-radius: 12px;
      padding: 20px;
      box-shadow: 0 1px 4px rgba(0,0,0,0.07);
      position: sticky;
      top: 20px;
    }

    .sidebar h3 {
      font-size: 14px;
      font-weight: 700;
      color: #0055A2;
      margin-bottom: 16px;
      padding-bottom: 10px;
      border-bottom: 2px solid #e5e7eb;
    }

    .filter-section { margin-bottom: 18px; }

    .filter-section label {
      display: block;
      font-size: 12px;
      font-weight: 700;
      color: #6b7280;
      letter-spacing: 0.04em;
      text-transform: uppercase;
      margin-bottom: 8px;
    }

    .filter-section input[type="text"],
    .filter-section input[type="time"],
    .filter-section select {
      width: 100%;
      padding: 8px 10px;
      border: 1.5px solid #d1d5db;
      border-radius: 8px;
      font-size: 13px;
      outline: none;
      font-family: inherit;
      color: #374151;
      margin-bottom: 6px;
    }

    .filter-section input:focus, .filter-section select:focus { border-color: #0055A2; }

    .checkbox-label {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 13px;
      color: #374151;
      cursor: pointer;
      padding: 4px 0;
    }

    .checkbox-label input[type="checkbox"] { width: 15px; height: 15px; cursor: pointer; }

    .time-row { display: grid; grid-template-columns: 1fr 1fr; gap: 6px; }

    .btn-apply {
      width: 100%;
      padding: 9px;
      background: #0055A2;
      color: white;
      border: none;
      border-radius: 8px;
      font-size: 13px;
      font-weight: 700;
      cursor: pointer;
      margin-top: 4px;
    }

    .btn-apply:hover { background: #004490; }

    .btn-clear {
      display: block;
      text-align: center;
      width: 100%;
      padding: 8px;
      background: #f3f4f6;
      color: #6b7280;
      border: none;
      border-radius: 8px;
      font-size: 12px;
      font-weight: 600;
      cursor: pointer;
      text-decoration: none;
      margin-top: 6px;
    }

    .btn-clear:hover { background: #e5e7eb; }

    /* ── Main content ── */
    .main-content { min-width: 0; }

    .main-header {
      display: flex;
      align-items: center;
      gap: 14px;
      margin-bottom: 18px;
      flex-wrap: wrap;
    }

    .search-wrap {
      flex: 1;
      position: relative;
      min-width: 200px;
    }

    .search-wrap input[type="text"] {
      width: 100%;
      padding: 10px 14px 10px 38px;
      border: 1.5px solid #d1d5db;
      border-radius: 8px;
      font-size: 14px;
      outline: none;
      font-family: inherit;
    }

    .search-wrap input:focus { border-color: #0055A2; }

    .search-icon {
      position: absolute;
      left: 12px;
      top: 50%;
      transform: translateY(-50%);
      font-size: 15px;
      color: #9ca3af;
    }

    .search-btn {
      padding: 10px 18px;
      background: #0055A2;
      color: white;
      border: none;
      border-radius: 8px;
      font-size: 14px;
      font-weight: 600;
      cursor: pointer;
      white-space: nowrap;
    }

    .search-btn:hover { background: #004490; }

    /* Tabs */
    .tabs {
      display: flex;
      gap: 0;
      border-bottom: 2px solid #e5e7eb;
      margin-bottom: 18px;
    }

    .tab-btn {
      padding: 9px 18px;
      font-size: 13px;
      font-weight: 600;
      color: #6b7280;
      background: none;
      border: none;
      border-bottom: 3px solid transparent;
      margin-bottom: -2px;
      cursor: pointer;
    }

    .tab-btn.active { color: #0055A2; border-bottom-color: #0055A2; }
    .tab-btn:hover { color: #0055A2; }

    .tab-panel { display: none; }
    .tab-panel.active { display: block; }

    /* Session cards */
    .sessions-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(290px, 1fr));
      gap: 14px;
    }

    .session-card {
      background: white;
      border-radius: 12px;
      padding: 18px;
      box-shadow: 0 1px 4px rgba(0,0,0,0.07);
      border-left: 4px solid #0055A2;
      transition: box-shadow 0.2s, transform 0.2s;
      display: flex;
      flex-direction: column;
    }

    .session-card:hover {
      box-shadow: 0 4px 16px rgba(0,0,0,0.11);
      transform: translateY(-2px);
    }

    .session-card.suggested { border-left-color: #7c3aed; }
    .session-card.friends   { border-left-color: #059669; }

    .card-top {
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 8px;
    }

    .card-top h3 {
      font-size: 14px;
      font-weight: 700;
      color: #111827;
      flex: 1;
      margin-right: 8px;
      line-height: 1.3;
    }

    .badges { display: flex; gap: 4px; flex-wrap: wrap; justify-content: flex-end; }

    .badge {
      display: inline-block;
      padding: 2px 8px;
      border-radius: 999px;
      font-size: 10px;
      font-weight: 700;
      white-space: nowrap;
    }

    .badge-public    { background: #dcfce7; color: #166534; }
    .badge-suggested { background: #ede9fe; color: #5b21b6; }
    .badge-friends   { background: #d1fae5; color: #065f46; }
    .badge-joined    { background: #dbeafe; color: #1e40af; }
    .badge-full      { background: #fee2e2; color: #991b1b; }
    .badge-organizer { background: #fef3c7; color: #92400e; }

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

    .meta-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 5px 10px;
      margin-bottom: 10px;
    }

    .meta-item {
      font-size: 11px;
      color: #6b7280;
      display: flex;
      align-items: center;
      gap: 4px;
    }

    .meta-item strong { color: #374151; font-weight: 600; }

    .description-text {
      font-size: 12px;
      color: #6b7280;
      line-height: 1.5;
      flex: 1;
      margin-bottom: 12px;
      display: -webkit-box;
      -webkit-line-clamp: 2;
      -webkit-box-orient: vertical;
      overflow: hidden;
    }

    .suggest-reason {
      font-size: 11px;
      color: #7c3aed;
      font-weight: 600;
      margin-bottom: 8px;
      display: flex;
      align-items: center;
      gap: 4px;
    }

    .friends-attending {
      font-size: 11px;
      color: #059669;
      font-weight: 600;
      margin-bottom: 8px;
    }

    .card-footer {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding-top: 10px;
      border-top: 1px solid #f3f4f6;
      margin-top: auto;
    }

    .organizer-label {
      font-size: 11px;
      color: #9ca3af;
    }

    .organizer-label strong { color: #6b7280; }

    .btn-join {
      padding: 6px 14px;
      background: #0055A2;
      color: white;
      border: none;
      border-radius: 6px;
      font-size: 12px;
      font-weight: 700;
      cursor: pointer;
      text-decoration: none;
      display: inline-block;
    }

    .btn-join:hover { background: #004490; }

    .btn-joined {
      padding: 6px 14px;
      background: #f0fdf4;
      color: #166534;
      border: 1.5px solid #bbf7d0;
      border-radius: 6px;
      font-size: 12px;
      font-weight: 700;
      cursor: default;
    }

    .btn-full {
      padding: 6px 14px;
      background: #f9fafb;
      color: #9ca3af;
      border: 1.5px solid #e5e7eb;
      border-radius: 6px;
      font-size: 12px;
      font-weight: 700;
      cursor: not-allowed;
    }

    .no-data {
      text-align: center;
      padding: 48px 0;
      color: #9ca3af;
      background: white;
      border-radius: 12px;
    }

    .no-data .icon { font-size: 36px; margin-bottom: 10px; }
    .no-data p { font-size: 14px; }

    .section-count {
      font-size: 13px;
      color: #6b7280;
      margin-bottom: 14px;
    }

    .section-count strong { color: #374151; }

    .alert {
      padding: 12px 16px;
      border-radius: 8px;
      font-size: 13px;
      font-weight: 600;
      margin-bottom: 14px;
    }

    .alert-success { background: #dcfce7; color: #166534; }
    .alert-error   { background: #fee2e2; color: #991b1b; }
    .alert-info    { background: #dbeafe; color: #1e40af; }
  </style>
</head>
<body>

<nav>
  <span class="brand">&#128218; SpartanStudyCircle</span>
  <div class="nav-links">
    <a href="home.jsp">Home</a>
    <a href="create_session.jsp">+ Create Session</a>
    <a href="browse_sessions.jsp" class="active">Browse Sessions</a>
    <a href="my_sessions.jsp">My Sessions</a>
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

  <!-- ── Sidebar Filters ── -->
  <aside class="sidebar">
    <h3>&#127775; Filter Sessions</h3>
    <form method="GET" action="browse_sessions.jsp" id="filterForm">
      <input type="hidden" name="q" id="hiddenQ" value="<%= searchQ %>" />

      <div class="filter-section">
        <label>Topic / Class</label>
        <select name="topic">
          <option value="">All Topics</option>
          <% for (String t : topicOptions) { %>
            <option value="<%= t %>" <%= t.equals(filterTopic) ? "selected" : "" %>><%= t %></option>
          <% } %>
        </select>
      </div>

      <div class="filter-section">
        <label>Location</label>
        <input type="text" name="location" value="<%= filterLocation %>" placeholder="e.g. Library Room A" />
      </div>

      <div class="filter-section">
        <label>Day of Week</label>
        <select name="day">
          <option value="">Any Day</option>
          <% String[] days = {"Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"};
             for (String d : days) { %>
            <option value="<%= d %>" <%= d.equals(filterDay) ? "selected" : "" %>><%= d %></option>
          <% } %>
        </select>
      </div>

      <div class="filter-section">
        <label>Time Range</label>
        <div class="time-row">
          <input type="time" name="timeFrom" value="<%= filterTimeFrom %>" title="From" />
          <input type="time" name="timeTo"   value="<%= filterTimeTo %>"   title="To"   />
        </div>
      </div>

      <div class="filter-section">
        <label>Special Filters</label>
        <label class="checkbox-label">
          <input type="checkbox" name="friendsOnly" value="1" <%= filterFriends ? "checked" : "" %> />
          Friends are attending
        </label>
        <label class="checkbox-label">
          <input type="checkbox" name="suggested" value="1" <%= filterSuggest ? "checked" : "" %> />
          Suggested for my classes
        </label>
      </div>

      <button type="submit" class="btn-apply">Apply Filters</button>
      <a class="btn-clear" href="browse_sessions.jsp">Clear All</a>
    </form>
  </aside>

  <!-- ── Main Content ── -->
  <main class="main-content">

    <% if (!joinMsg.isEmpty()) { %>
      <div class="alert alert-<%= joinMsgType %>"><%= joinMsg %></div>
    <% } %>

    <!-- Search bar -->
    <form method="GET" action="browse_sessions.jsp" class="main-header">
      <!-- Carry sidebar filters through search -->
      <input type="hidden" name="topic"       value="<%= filterTopic %>"/>
      <input type="hidden" name="location"    value="<%= filterLocation %>"/>
      <input type="hidden" name="day"         value="<%= filterDay %>"/>
      <input type="hidden" name="timeFrom"    value="<%= filterTimeFrom %>"/>
      <input type="hidden" name="timeTo"      value="<%= filterTimeTo %>"/>
      <input type="hidden" name="friendsOnly" value="<%= filterFriends ? "1" : "" %>"/>
      <input type="hidden" name="suggested"   value="<%= filterSuggest ? "1" : "" %>"/>

      <div class="search-wrap">
        <span class="search-icon">&#128269;</span>
        <input type="text" name="q" value="<%= searchQ %>" placeholder="Search session name or description..." />
      </div>
      <button type="submit" class="search-btn">Search</button>
    </form>

    <!-- Tabs -->
    <div class="tabs">
      <button class="tab-btn <%= "all".equals(activeTab) || activeTab.isEmpty() ? "active" : "" %>"
              onclick="switchTab('all', this)">All Public</button>
      <button class="tab-btn <%= "suggested".equals(activeTab) ? "active" : "" %>"
              onclick="switchTab('suggested', this)">&#10024; Suggested for Me</button>
      <button class="tab-btn <%= "friends".equals(activeTab) ? "active" : "" %>"
              onclick="switchTab('friends', this)">&#128101; Friends Attending</button>
    </div>

    <%
      // ── QUERY ──────────────────────────────────────────────────────────────
      Connection con = null;
      String dbError = "";

      // Results maps: sessionId -> Map of fields + extra flags
      List<Map<String,String>> allSessions       = new ArrayList<>();
      List<Map<String,String>> suggestedSessions = new ArrayList<>();
      List<Map<String,String>> friendsSessions   = new ArrayList<>();

      // Set of sessions user is already attending
      Set<String> joinedSet = new HashSet<>();
      // Set of sessions that are full
      Set<String> fullSet = new HashSet<>();

      try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

        // Build main query
        StringBuilder sql = new StringBuilder();
        List<Object> params = new ArrayList<>();

        sql.append("SELECT ss.Session_ID, ss.Name, ss.Time, ss.Date, ss.Location, ss.Description, ");
        sql.append("       ss.Capacity, ss.Topic, ss.Visibility, ss.Organizer_Username, ");
        sql.append("       (SELECT COUNT(*) FROM Attends WHERE Session_ID = ss.Session_ID) AS attendee_count, ");
        sql.append("       EXISTS(SELECT 1 FROM Attends WHERE Session_ID = ss.Session_ID AND Username = ?) AS is_joined, ");
        sql.append("       (ss.Organizer_Username = ?) AS is_organizer, ");
        // Suggestion score: matched topic to enrolled class topics
        sql.append("       (SELECT COUNT(*) FROM Enrolls e JOIN Class c ON c.Subject_Abbr=e.Subject_Abbr AND c.Course_No=e.Course_No AND c.Section=e.Section ");
        sql.append("        WHERE e.Username = ? AND (ss.Topic LIKE CONCAT('%', e.Subject_Abbr, '%') OR ss.Topic LIKE CONCAT('%', c.Class_Name, '%'))) AS suggest_score, ");
        // Friend count attending
        sql.append("       (SELECT COUNT(*) FROM Attends fa JOIN Friends_With fw ON ");
        sql.append("         (fw.Username1 = ? AND fw.Username2 = fa.Username) OR (fw.Username2 = ? AND fw.Username1 = fa.Username) ");
        sql.append("        WHERE fa.Session_ID = ss.Session_ID) AS friend_count ");
        sql.append("FROM StudySession ss ");
        sql.append("WHERE ss.Visibility = 'Public' ");
        params.add(username); // is_joined
        params.add(username); // is_organizer
        params.add(username); // suggest_score
        params.add(username); // friend_count 1
        params.add(username); // friend_count 2

        if (!searchQ.isEmpty()) {
          sql.append("AND (ss.Name LIKE ? OR ss.Description LIKE ?) ");
          params.add("%" + searchQ + "%");
          params.add("%" + searchQ + "%");
        }

        if (!filterTopic.isEmpty()) {
          sql.append("AND ss.Topic = ? ");
          params.add(filterTopic);
        }

        if (!filterLocation.isEmpty()) {
          sql.append("AND ss.Location LIKE ? ");
          params.add("%" + filterLocation + "%");
        }

        if (!filterTimeFrom.isEmpty()) {
          sql.append("AND (ss.Time IS NULL OR ss.Time >= ?) ");
          params.add(filterTimeFrom);
        }

        if (!filterTimeTo.isEmpty()) {
          sql.append("AND (ss.Time IS NULL OR ss.Time <= ?) ");
          params.add(filterTimeTo);
        }

        // Day filter — compare DAYNAME(ss.Date)
        if (!filterDay.isEmpty()) {
          sql.append("AND DAYNAME(ss.Date) = ? ");
          params.add(filterDay);
        }

        if (filterFriends) {
          sql.append("HAVING friend_count > 0 ");
        } else if (filterSuggest) {
          sql.append("HAVING suggest_score > 0 ");
        }

        sql.append("ORDER BY suggest_score DESC, friend_count DESC, ss.Date ASC, ss.Time ASC ");
        sql.append("LIMIT 60");

        PreparedStatement ps = con.prepareStatement(sql.toString());
        for (int i = 0; i < params.size(); i++) {
          ps.setObject(i + 1, params.get(i));
        }
        ResultSet rs = ps.executeQuery();

        while (rs.next()) {
          Map<String,String> m = new LinkedHashMap<>();
          m.put("sessionId",    rs.getString("Session_ID"));
          m.put("name",         rs.getString("Name") != null ? rs.getString("Name") : "Untitled");
          m.put("time",         rs.getString("Time") != null ? rs.getString("Time") : "—");
          m.put("date",         rs.getString("Date") != null ? rs.getString("Date") : "TBD");
          m.put("location",     rs.getString("Location") != null ? rs.getString("Location") : "—");
          m.put("description",  rs.getString("Description") != null ? rs.getString("Description") : "");
          int cap = rs.getInt("Capacity");
          boolean capNull = rs.wasNull();
          m.put("capacity",     capNull ? "—" : String.valueOf(cap));
          m.put("topic",        rs.getString("Topic") != null ? rs.getString("Topic") : "");
          m.put("organizer",    rs.getString("Organizer_Username") != null ? rs.getString("Organizer_Username") : "—");
          int attCount = rs.getInt("attendee_count");
          m.put("attendeeCount", String.valueOf(attCount));
          boolean joined = rs.getInt("is_joined") == 1;
          boolean isOrg  = rs.getInt("is_organizer") == 1;
          int suggestScore = rs.getInt("suggest_score");
          int friendCount  = rs.getInt("friend_count");
          m.put("joined",       String.valueOf(joined));
          m.put("isOrganizer",  String.valueOf(isOrg));
          m.put("suggestScore", String.valueOf(suggestScore));
          m.put("friendCount",  String.valueOf(friendCount));

          boolean full = !capNull && cap > 0 && attCount >= cap;
          m.put("full", String.valueOf(full));
          if (joined)  joinedSet.add(rs.getString("Session_ID"));
          if (full)    fullSet.add(rs.getString("Session_ID"));

          allSessions.add(m);
          if (suggestScore > 0) suggestedSessions.add(m);
          if (friendCount  > 0) friendsSessions.add(m);
        }
        rs.close(); ps.close();

      } catch (Exception e) {
        dbError = "Database error: " + e.getMessage();
      } finally {
        if (con != null) try { con.close(); } catch (Exception ignore) {}
      }
    %>

    <% if (!dbError.isEmpty()) { %>
      <div class="alert alert-error"><%= dbError %></div>
    <% } %>

    <!-- ALL PUBLIC TAB -->
    <div id="tab-all" class="tab-panel <%= "all".equals(activeTab) || activeTab.isEmpty() ? "active" : "" %>">
      <p class="section-count">Found <strong><%= allSessions.size() %></strong> public session(s) matching your filters.</p>
      <% if (allSessions.isEmpty()) { %>
        <div class="no-data">
          <div class="icon">&#128197;</div>
          <p>No public sessions match your current filters.<br/>Try broadening your search.</p>
        </div>
      <% } else { %>
        <div class="sessions-grid">
          <% for (Map<String,String> sess : allSessions) {
               boolean joined   = "true".equals(sess.get("joined"));
               boolean isOrg    = "true".equals(sess.get("isOrganizer"));
               boolean full     = "true".equals(sess.get("full"));
               int sugScore     = Integer.parseInt(sess.get("suggestScore"));
               int frndCount    = Integer.parseInt(sess.get("friendCount"));
               String cardClass = sugScore > 0 ? "suggested" : (frndCount > 0 ? "friends" : "");
          %>
          <div class="session-card <%= cardClass %>">
            <div class="card-top">
              <h3><%= sess.get("name") %></h3>
              <div class="badges">
                <% if (isOrg) { %><span class="badge badge-organizer">Organizer</span><% } %>
                <% if (joined && !isOrg) { %><span class="badge badge-joined">Joined</span><% } %>
                <% if (sugScore > 0) { %><span class="badge badge-suggested">&#10024; Match</span><% } %>
                <% if (frndCount > 0) { %><span class="badge badge-friends">&#128101; Friends</span><% } %>
                <% if (full) { %><span class="badge badge-full">Full</span><% } %>
              </div>
            </div>
            <% if (!sess.get("topic").isEmpty()) { %>
              <span class="tag-topic">&#128218; <%= sess.get("topic") %></span>
            <% } %>
            <% if (sugScore > 0) { %>
              <div class="suggest-reason">&#10024; Matches your enrolled classes</div>
            <% } %>
            <% if (frndCount > 0) { %>
              <div class="friends-attending">&#128101; <%= sess.get("friendCount") %> friend(s) attending</div>
            <% } %>
            <div class="meta-grid">
              <div class="meta-item">&#128197; <strong><%= sess.get("date") %></strong></div>
              <div class="meta-item">&#128336; <strong><%= sess.get("time") %></strong></div>
              <div class="meta-item">&#128205; <strong><%= sess.get("location") %></strong></div>
              <div class="meta-item">&#128101; <strong><%= sess.get("attendeeCount") %><%= !sess.get("capacity").equals("—") ? "/" + sess.get("capacity") : "" %></strong></div>
            </div>
            <% if (!sess.get("description").isEmpty()) { %>
              <p class="description-text"><%= sess.get("description") %></p>
            <% } %>
            <div class="card-footer">
              <span class="organizer-label">by <strong>@<%= sess.get("organizer") %></strong></span>
              <% if (isOrg) { %>
                <a class="btn-join" href="session_attendees.jsp?sessionId=<%= sess.get("sessionId") %>">Manage</a>
              <% } else if (joined) { %>
                <span class="btn-joined">&#10003; Joined</span>
              <% } else if (full) { %>
                <span class="btn-full">Session Full</span>
              <% } else { %>
                <a class="btn-join" href="browse_sessions.jsp?action=join&joinSessionId=<%= sess.get("sessionId") %>&q=<%= searchQ %>&topic=<%= filterTopic %>&location=<%= filterLocation %>&day=<%= filterDay %>&timeFrom=<%= filterTimeFrom %>&timeTo=<%= filterTimeTo %><%= filterFriends ? "&friendsOnly=1" : "" %><%= filterSuggest ? "&suggested=1" : "" %>">Join</a>
              <% } %>
            </div>
          </div>
          <% } %>
        </div>
      <% } %>
    </div>

    <!-- SUGGESTED TAB -->
    <div id="tab-suggested" class="tab-panel <%= "suggested".equals(activeTab) ? "active" : "" %>">
      <p class="section-count">
        <strong><%= suggestedSessions.size() %></strong> session(s) suggested based on your enrolled classes.
      </p>
      <% if (suggestedSessions.isEmpty()) { %>
        <div class="no-data">
          <div class="icon">&#10024;</div>
          <p>No suggested sessions found.<br/>Make sure you have classes in your enrollment to get suggestions.</p>
        </div>
      <% } else { %>
        <div class="sessions-grid">
          <% for (Map<String,String> sess : suggestedSessions) {
               boolean joined = "true".equals(sess.get("joined"));
               boolean isOrg  = "true".equals(sess.get("isOrganizer"));
               boolean full   = "true".equals(sess.get("full"));
               int frndCount  = Integer.parseInt(sess.get("friendCount"));
          %>
          <div class="session-card suggested">
            <div class="card-top">
              <h3><%= sess.get("name") %></h3>
              <div class="badges">
                <span class="badge badge-suggested">&#10024; Match</span>
                <% if (joined) { %><span class="badge badge-joined">Joined</span><% } %>
                <% if (frndCount > 0) { %><span class="badge badge-friends">&#128101; Friends</span><% } %>
              </div>
            </div>
            <% if (!sess.get("topic").isEmpty()) { %>
              <span class="tag-topic">&#128218; <%= sess.get("topic") %></span>
            <% } %>
            <div class="suggest-reason">&#10024; Matches your enrolled classes</div>
            <% if (frndCount > 0) { %>
              <div class="friends-attending">&#128101; <%= sess.get("friendCount") %> friend(s) attending</div>
            <% } %>
            <div class="meta-grid">
              <div class="meta-item">&#128197; <strong><%= sess.get("date") %></strong></div>
              <div class="meta-item">&#128336; <strong><%= sess.get("time") %></strong></div>
              <div class="meta-item">&#128205; <strong><%= sess.get("location") %></strong></div>
              <div class="meta-item">&#128101; <strong><%= sess.get("attendeeCount") %><%= !sess.get("capacity").equals("—") ? "/" + sess.get("capacity") : "" %></strong></div>
            </div>
            <% if (!sess.get("description").isEmpty()) { %>
              <p class="description-text"><%= sess.get("description") %></p>
            <% } %>
            <div class="card-footer">
              <span class="organizer-label">by <strong>@<%= sess.get("organizer") %></strong></span>
              <% if (isOrg) { %>
                <a class="btn-join" href="session_attendees.jsp?sessionId=<%= sess.get("sessionId") %>">Manage</a>
              <% } else if (joined) { %>
                <span class="btn-joined">&#10003; Joined</span>
              <% } else if (full) { %>
                <span class="btn-full">Full</span>
              <% } else { %>
                <a class="btn-join" href="browse_sessions.jsp?action=join&joinSessionId=<%= sess.get("sessionId") %>&tab=suggested&q=<%= searchQ %>&topic=<%= filterTopic %>">Join</a>
              <% } %>
            </div>
          </div>
          <% } %>
        </div>
      <% } %>
    </div>

    <!-- FRIENDS TAB -->
    <div id="tab-friends" class="tab-panel <%= "friends".equals(activeTab) ? "active" : "" %>">
      <p class="section-count">
        <strong><%= friendsSessions.size() %></strong> session(s) where your friends are attending.
      </p>
      <% if (friendsSessions.isEmpty()) { %>
        <div class="no-data">
          <div class="icon">&#128101;</div>
          <p>None of your friends are attending any public sessions right now.</p>
        </div>
      <% } else { %>
        <div class="sessions-grid">
          <% for (Map<String,String> sess : friendsSessions) {
               boolean joined = "true".equals(sess.get("joined"));
               boolean isOrg  = "true".equals(sess.get("isOrganizer"));
               boolean full   = "true".equals(sess.get("full"));
               int sugScore   = Integer.parseInt(sess.get("suggestScore"));
          %>
          <div class="session-card friends">
            <div class="card-top">
              <h3><%= sess.get("name") %></h3>
              <div class="badges">
                <span class="badge badge-friends">&#128101; Friends</span>
                <% if (joined) { %><span class="badge badge-joined">Joined</span><% } %>
                <% if (sugScore > 0) { %><span class="badge badge-suggested">&#10024; Match</span><% } %>
              </div>
            </div>
            <% if (!sess.get("topic").isEmpty()) { %>
              <span class="tag-topic">&#128218; <%= sess.get("topic") %></span>
            <% } %>
            <div class="friends-attending">&#128101; <%= sess.get("friendCount") %> friend(s) attending this session</div>
            <div class="meta-grid">
              <div class="meta-item">&#128197; <strong><%= sess.get("date") %></strong></div>
              <div class="meta-item">&#128336; <strong><%= sess.get("time") %></strong></div>
              <div class="meta-item">&#128205; <strong><%= sess.get("location") %></strong></div>
              <div class="meta-item">&#128101; <strong><%= sess.get("attendeeCount") %><%= !sess.get("capacity").equals("—") ? "/" + sess.get("capacity") : "" %></strong></div>
            </div>
            <% if (!sess.get("description").isEmpty()) { %>
              <p class="description-text"><%= sess.get("description") %></p>
            <% } %>
            <div class="card-footer">
              <span class="organizer-label">by <strong>@<%= sess.get("organizer") %></strong></span>
              <% if (isOrg) { %>
                <a class="btn-join" href="session_attendees.jsp?sessionId=<%= sess.get("sessionId") %>">Manage</a>
              <% } else if (joined) { %>
                <span class="btn-joined">&#10003; Joined</span>
              <% } else if (full) { %>
                <span class="btn-full">Full</span>
              <% } else { %>
                <a class="btn-join" href="browse_sessions.jsp?action=join&joinSessionId=<%= sess.get("sessionId") %>&tab=friends&q=<%= searchQ %>">Join</a>
              <% } %>
            </div>
          </div>
          <% } %>
        </div>
      <% } %>
    </div>

  </main>
</div>

<script>
  function switchTab(id, btn) {
    document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
    document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
    document.getElementById('tab-' + id).classList.add('active');
    btn.classList.add('active');
  }

  // Initialize active tab from URL param
  (function() {
    var tabParam = '<%= activeTab %>';
    if (tabParam && tabParam !== 'all' && tabParam !== '') {
      var panelEl = document.getElementById('tab-' + tabParam);
      var btnEls = document.querySelectorAll('.tab-btn');
      if (panelEl) {
        document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
        btnEls.forEach(b => b.classList.remove('active'));
        panelEl.classList.add('active');
        var idx = tabParam === 'suggested' ? 1 : tabParam === 'friends' ? 2 : 0;
        if (btnEls[idx]) btnEls[idx].classList.add('active');
      }
    }
  })();
</script>
</body>
</html>
