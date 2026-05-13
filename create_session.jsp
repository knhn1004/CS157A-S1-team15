<%@ page import="java.sql.*, java.util.*, java.util.UUID" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
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

  String errorMsg = "";

  // ── LOAD FRIENDS for invite picker ────────────────────────────────────────
  List<Map<String,String>> friendsList = new ArrayList<>();
  try {
    Class.forName("com.mysql.cj.jdbc.Driver");
    Connection fCon = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
    PreparedStatement fPs = fCon.prepareStatement(
      "SELECT u.Username, u.Name, u.Major, u.Year " +
      "FROM Friends_With fw " +
      "JOIN Users u ON u.Username = CASE WHEN fw.Username1 = ? THEN fw.Username2 ELSE fw.Username1 END " +
      "WHERE (fw.Username1 = ? OR fw.Username2 = ?) " +
      "  AND (fw.Status = 'Accepted' OR fw.Status IS NULL) " +
      "ORDER BY u.Name ASC"
    );
    fPs.setString(1, username); fPs.setString(2, username); fPs.setString(3, username);
    ResultSet fRs = fPs.executeQuery();
    while (fRs.next()) {
      Map<String,String> m = new LinkedHashMap<>();
      m.put("username", fRs.getString("Username"));
      m.put("name",     fRs.getString("Name") != null ? fRs.getString("Name") : fRs.getString("Username"));
      m.put("major",    fRs.getString("Major") != null ? fRs.getString("Major") : "");
      m.put("year",     fRs.getObject("Year") != null ? String.valueOf(fRs.getInt("Year")) : "");
      friendsList.add(m);
    }
    fRs.close(); fPs.close(); fCon.close();
  } catch (Exception ignored) {}

  // ── HANDLE CREATE ─────────────────────────────────────────────────────────
  if ("create".equals(request.getParameter("action"))) {
    String sessName    = request.getParameter("name");
    String sessDate    = request.getParameter("date");
    String sessTime    = request.getParameter("time");
    String location    = request.getParameter("location");
    String description = request.getParameter("description");
    String topic       = request.getParameter("topic");
    String capacity    = request.getParameter("capacity");
    String visibility  = request.getParameter("visibility");
    String[] invitees  = request.getParameterValues("invitees");

    if (sessName == null || sessName.trim().isEmpty()) {
      errorMsg = "Session name is required.";
    } else if ("Friends".equals(visibility) && (invitees == null || invitees.length == 0) && !friendsList.isEmpty()) {
      errorMsg = "Please select at least one friend to invite for a Friends Only session.";
    } else {
      Connection con = null;
      try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
        con.setAutoCommit(false);

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
        ps.setString(8,  (topic      != null && !topic.trim().isEmpty())     ? topic.trim()     : null);
        ps.setString(9,  (visibility != null && !visibility.isEmpty())       ? visibility       : "Public");
        ps.setString(10, username);
        ps.executeUpdate();
        ps.close();

        // Insert Invited_To rows for Friends Only sessions
        if ("Friends".equals(visibility) && invitees != null && invitees.length > 0) {
          Set<String> friendSet = new HashSet<>();
          for (Map<String,String> f : friendsList) friendSet.add(f.get("username"));

          PreparedStatement invPs = con.prepareStatement(
            "INSERT INTO Invited_To (Session_ID, Inviter, Invitee, Response) VALUES (?, ?, ?, 'Pending')"
          );
          for (String invitee : invitees) {
            if (invitee != null && !invitee.trim().isEmpty() && friendSet.contains(invitee.trim())) {
              invPs.setString(1, sessionId);
              invPs.setString(2, username);
              invPs.setString(3, invitee.trim());
              invPs.addBatch();
            }
          }
          invPs.executeBatch();
          invPs.close();
        }

        con.commit();
        response.sendRedirect("home.jsp?created=1");
        return;

      } catch (Exception e) {
        if (con != null) try { con.rollback(); } catch (Exception ignore) {}
        errorMsg = "Database error: " + e.getMessage();
      } finally {
        if (con != null) try { con.setAutoCommit(true); con.close(); } catch (Exception ignore) {}
      }
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

    nav .nav-links a:hover, nav a.logout:hover { background: rgba(255,255,255,0.2); }
    nav .nav-links a.active { background: rgba(255,255,255,0.25); }

    nav .user-info { display: flex; align-items: center; gap: 12px; font-size: 14px; }

    .container { max-width: 620px; margin: 40px auto; padding: 0 16px; }

    .card {
      background: white;
      border-radius: 12px;
      padding: 32px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.08);
    }

    .card h2 { font-size: 18px; color: #0055A2; font-weight: 700; margin-bottom: 6px; }

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

    input[type="text"], input[type="date"], input[type="time"],
    input[type="number"], select, textarea {
      width: 100%;
      padding: 10px 12px;
      border: 1.5px solid #d1d5db;
      border-radius: 8px;
      font-size: 14px;
      outline: none;
      font-family: inherit;
      transition: border-color 0.2s;
      color: #374151;
    }

    input:focus, select:focus, textarea:focus { border-color: #0055A2; }
    textarea { resize: vertical; min-height: 80px; }
    .row { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }

    /* Visibility */
    .visibility-group { display: flex; gap: 12px; }

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

    /* Friends invite panel */
    #friends-invite-panel {
      display: none;
      margin-top: 16px;
      border: 1.5px solid #bfdbfe;
      border-radius: 10px;
      padding: 18px;
      background: #f0f7ff;
    }

    #friends-invite-panel.visible {
      display: block;
      animation: slideDown 0.18s ease;
    }

    @keyframes slideDown {
      from { opacity: 0; transform: translateY(-5px); }
      to   { opacity: 1; transform: translateY(0); }
    }

    .invite-panel-header {
      display: flex;
      align-items: baseline;
      gap: 8px;
      margin-bottom: 12px;
    }

    .invite-title { font-size: 13px; font-weight: 700; color: #1e40af; }
    .invite-subtitle { font-size: 12px; color: #6b7280; }

    .required-mark { color: #dc2626; font-size: 12px; font-weight: 700; }

    .friend-search-wrap { position: relative; margin-bottom: 8px; }

    .friend-search-wrap .search-icon {
      position: absolute;
      left: 10px;
      top: 50%;
      transform: translateY(-50%);
      color: #9ca3af;
      font-size: 13px;
      pointer-events: none;
    }

    .friend-search {
      width: 100%;
      padding: 8px 12px 8px 30px;
      border: 1.5px solid #c7d2fe;
      border-radius: 8px;
      font-size: 13px;
      outline: none;
      font-family: inherit;
      background: white;
      color: #374151;
    }

    .friend-search:focus { border-color: #0055A2; }

    .friend-list {
      max-height: 230px;
      overflow-y: auto;
      border: 1.5px solid #c7d2fe;
      border-radius: 8px;
      background: white;
      scrollbar-width: thin;
    }

    .friend-item {
      display: flex;
      align-items: center;
      gap: 10px;
      padding: 9px 12px;
      border-bottom: 1px solid #e0e7ff;
      cursor: pointer;
      transition: background 0.1s;
    }

    .friend-item:last-child { border-bottom: none; }
    .friend-item:hover { background: #eff6ff; }
    .friend-item.selected { background: #dbeafe; }
    .friend-item.hidden { display: none; }

    .friend-item input[type="checkbox"] {
      width: 15px;
      height: 15px;
      flex-shrink: 0;
      cursor: pointer;
      accent-color: #0055A2;
      margin: 0;
      padding: 0;
      border: none;
    }

    .friend-avatar {
      width: 30px;
      height: 30px;
      border-radius: 50%;
      background: #0055A2;
      color: white;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 12px;
      font-weight: 700;
      flex-shrink: 0;
    }

    .friend-info { flex: 1; min-width: 0; }
    .friend-info .fname { font-size: 13px; font-weight: 600; color: #111827; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    .friend-info .fmeta { font-size: 11px; color: #6b7280; margin-top: 1px; }

    .invite-footer {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-top: 9px;
    }

    .selected-count { font-size: 12px; color: #1e40af; font-weight: 600; }

    .btn-select-all {
      font-size: 12px;
      color: #0055A2;
      background: none;
      border: none;
      padding: 0;
      cursor: pointer;
      font-weight: 600;
      width: auto;
      margin: 0;
    }

    .btn-select-all:hover { text-decoration: underline; background: none; }

    .no-friends-msg {
      text-align: center;
      padding: 20px;
      color: #9ca3af;
      font-size: 13px;
    }

    .no-friends-msg a { color: #0055A2; font-weight: 600; text-decoration: none; }
    .no-friends-msg a:hover { text-decoration: underline; }

    /* Submit */
    .btn-submit {
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

    .btn-submit:hover { background: #004490; }

    .alert { padding: 12px 16px; border-radius: 8px; font-size: 13px; margin-bottom: 20px; }
    .alert-error { background: #fee2e2; color: #991b1b; }

    .optional { font-size: 11px; color: #9ca3af; font-weight: 400; margin-left: 4px; }
  </style>
</head>
<body>

<nav>
  <span class="brand">&#128218; SpartanStudyCircle</span>
  <div class="nav-links">
    <a href="home.jsp">Home</a>
    <a href="schedule.jsp">My Schedule</a>
    <a href="create_session.jsp" class="active">+ Create Session</a>
    <a href="browse_sessions.jsp">Browse Sessions</a>
    <a href="my_sessions.jsp">My Sessions</a>
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
    <h2>Create Study Session</h2>
    <p class="subtitle">Organize a new session for other students to join.</p>

    <% if (!errorMsg.isEmpty()) { %>
      <div class="alert alert-error"><%= h(errorMsg) %></div>
    <% } %>

    <form method="POST" action="create_session.jsp" id="createForm">
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

      <!-- ── Visibility ── -->
      <div class="field">
        <label>Visibility</label>
        <div class="visibility-group">
          <label class="vis-option">
            <input type="radio" name="visibility" value="Public" checked onchange="onVisChange('Public')" />
            &#127760; Public
          </label>
          <label class="vis-option">
            <input type="radio" name="visibility" value="Friends" onchange="onVisChange('Friends')" />
            &#128101; Friends Only
          </label>
          <label class="vis-option">
            <input type="radio" name="visibility" value="Private" onchange="onVisChange('Private')" />
            &#128274; Private
          </label>
        </div>

        <!-- Friends invite panel -->
        <div id="friends-invite-panel">
          <div class="invite-panel-header">
            <span class="invite-title">&#9993; Invite Friends</span>
            <span class="required-mark">* required</span>
            <span class="invite-subtitle">— choose who gets access to this session</span>
          </div>

          <% if (friendsList.isEmpty()) { %>
            <div class="no-friends-msg">
              You have no friends to invite yet.<br/>
              <a href="people.jsp">Find people</a> to add friends first, then come back.
            </div>
          <% } else { %>
            <div class="friend-search-wrap">
              <span class="search-icon">&#128269;</span>
              <input type="text" class="friend-search" id="friendSearch"
                     placeholder="Search by name or username..."
                     oninput="filterFriends(this.value)" autocomplete="off" />
            </div>

            <div class="friend-list" id="friendList">
              <% for (Map<String,String> f : friendsList) {
                   String initial = f.get("name").length() > 0 ? f.get("name").substring(0,1).toUpperCase() : "?";
                   String meta = "";
                   if (!f.get("major").isEmpty()) meta += f.get("major");
                   if (!f.get("year").isEmpty())  meta += (meta.isEmpty() ? "" : " · ") + "Year " + f.get("year");
              %>
              <label class="friend-item"
                     data-name="<%= h(f.get("name").toLowerCase()) %>"
                     data-user="<%= h(f.get("username").toLowerCase()) %>">
                <input type="checkbox" name="invitees" value="<%= h(f.get("username")) %>"
                       onchange="onCheckChange(this)" />
                <div class="friend-avatar"><%= h(initial) %></div>
                <div class="friend-info">
                  <div class="fname"><%= h(f.get("name")) %></div>
                  <div class="fmeta">@<%= h(f.get("username")) %><%= !meta.isEmpty() ? " · " + h(meta) : "" %></div>
                </div>
              </label>
              <% } %>
            </div>

            <div class="invite-footer">
              <span class="selected-count" id="selCount">0 selected</span>
              <button type="button" class="btn-select-all" id="selAllBtn" onclick="toggleSelectAll()">Select All</button>
            </div>
          <% } %>
        </div>
      </div>

      <button type="submit" class="btn-submit">Create Session</button>
    </form>
  </div>
</div>

<script>
  var allSelected = false;
  var hasFriends = <%= friendsList.isEmpty() ? "false" : "true" %>;

  function onVisChange(val) {
    var panel = document.getElementById('friends-invite-panel');
    if (val === 'Friends') {
      panel.classList.add('visible');
    } else {
      panel.classList.remove('visible');
      // Clear checkboxes
      document.querySelectorAll('#friendList input[type="checkbox"]').forEach(function(cb) {
        cb.checked = false;
        cb.closest('.friend-item').classList.remove('selected');
      });
      updateCount();
    }
  }

  function filterFriends(q) {
    q = q.toLowerCase().trim();
    document.querySelectorAll('#friendList .friend-item').forEach(function(item) {
      var match = !q || item.dataset.name.includes(q) || item.dataset.user.includes(q);
      item.classList.toggle('hidden', !match);
    });
  }

  function onCheckChange(cb) {
    cb.closest('.friend-item').classList.toggle('selected', cb.checked);
    updateCount();
  }

  function updateCount() {
    var count = document.querySelectorAll('#friendList input[type="checkbox"]:checked').length;
    var total = document.querySelectorAll('#friendList input[type="checkbox"]').length;
    var el = document.getElementById('selCount');
    if (el) el.textContent = count + ' selected';
    allSelected = (count === total && total > 0);
    var btn = document.getElementById('selAllBtn');
    if (btn) btn.textContent = allSelected ? 'Deselect All' : 'Select All';
  }

  function toggleSelectAll() {
    allSelected = !allSelected;
    document.querySelectorAll('#friendList input[type="checkbox"]').forEach(function(cb) {
      cb.checked = allSelected;
      cb.closest('.friend-item').classList.toggle('selected', allSelected);
    });
    updateCount();
  }

  // Client-side validation before submit
  document.getElementById('createForm').addEventListener('submit', function(e) {
    var vis = document.querySelector('input[name="visibility"]:checked');
    if (vis && vis.value === 'Friends' && hasFriends) {
      var checked = document.querySelectorAll('#friendList input[type="checkbox"]:checked').length;
      if (checked === 0) {
        e.preventDefault();
        alert('Please select at least one friend to invite for a Friends Only session.');
      }
    }
  });
</script>
</body>
</html>
