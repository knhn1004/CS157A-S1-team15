<%@ page import="java.sql.*" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page session="true" %>
<%
  String username = (String) session.getAttribute("username");
  String name = (String) session.getAttribute("name");
  if (username == null) {
    response.sendRedirect("index.jsp");
    return;
  }

  final String DB_URL  = "jdbc:mysql://localhost:3306/Team_15?autoReconnect=true&useSSL=false&allowPublicKeyRetrieval=true";
  final String DB_USER = "root";
  final String DB_PASS = "password";

  String errorMsg  = "";
  String actionMsg = "";
  String actionKind = "";

  if ("POST".equalsIgnoreCase(request.getMethod())) {
    String action = request.getParameter("action");
    String sender = request.getParameter("sender");
    if (sender != null) sender = sender.trim();

    if (("accept_request".equals(action) || "decline_request".equals(action))
        && sender != null && !sender.isEmpty() && !sender.equals(username)) {

      Connection actCon = null;
      try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        actCon = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
        actCon.setAutoCommit(false);

        PreparedStatement ck = actCon.prepareStatement(
          "SELECT Status FROM Friend_Request " +
          " WHERE Sender_Username = ? AND Receiver_Username = ?"
        );
        ck.setString(1, sender);
        ck.setString(2, username);
        ResultSet ckRs = ck.executeQuery();

        boolean hasRow      = ckRs.next();
        boolean isPending   = hasRow && "Pending".equalsIgnoreCase(ckRs.getString("Status"));
        ckRs.close(); ck.close();

        if (!hasRow) {
          actionKind = "error";
          actionMsg  = "No friend request from @" + sender + " was found.";
        } else if (!isPending) {
          actionKind = "error";
          actionMsg  = "That friend request is no longer pending.";
        } else if ("accept_request".equals(action)) {
          PreparedStatement upd = actCon.prepareStatement(
            "UPDATE Friend_Request SET Status = 'Accepted' " +
            " WHERE Sender_Username = ? AND Receiver_Username = ?"
          );
          upd.setString(1, sender);
          upd.setString(2, username);
          upd.executeUpdate();
          upd.close();

          PreparedStatement ins = actCon.prepareStatement(
            "INSERT INTO Friends_With (Username1, Username2, Status) " +
            "VALUES (?, ?, 'Accepted') " +
            "ON DUPLICATE KEY UPDATE Status = 'Accepted'"
          );
          ins.setString(1, sender);
          ins.setString(2, username);
          ins.executeUpdate();
          ins.close();

          actCon.commit();
          actionKind = "success";
          actionMsg  = "You are now friends with @" + sender + ".";
        } else {
          PreparedStatement upd = actCon.prepareStatement(
            "UPDATE Friend_Request SET Status = 'Declined' " +
            " WHERE Sender_Username = ? AND Receiver_Username = ?"
          );
          upd.setString(1, sender);
          upd.setString(2, username);
          upd.executeUpdate();
          upd.close();
          actCon.commit();
          actionKind = "success";
          actionMsg  = "Declined friend request from @" + sender + ".";
        }
      } catch (Exception e) {
        if (actCon != null) try { actCon.rollback(); } catch (Exception ignore) {}
        actionKind = "error";
        actionMsg  = "Database error: " + e.getMessage();
      } finally {
        if (actCon != null) try { actCon.close(); } catch (Exception ignore) {}
      }
    }
  }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Friends - SpartanStudyCircle</title>
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
      max-width: 980px;
      margin: 32px auto;
      padding: 0 16px;
    }

    .card {
      background: white;
      border-radius: 12px;
      padding: 24px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.08);
    }

    h2 {
      font-size: 18px;
      color: #0055A2;
      font-weight: 700;
      margin-bottom: 8px;
    }

    .subtitle {
      font-size: 13px;
      color: #6b7280;
      margin-bottom: 18px;
      padding-bottom: 14px;
      border-bottom: 2px solid #e5e7eb;
    }

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
    }

    tr:last-child td { border-bottom: none; }

    .badge {
      display: inline-block;
      padding: 2px 8px;
      border-radius: 999px;
      font-size: 11px;
      font-weight: 600;
      background: #dbeafe;
      color: #1e40af;
    }

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
      margin-bottom: 14px;
    }

    .banner-success {
      background: #dcfce7;
      color: #166534;
      padding: 12px 16px;
      border-radius: 8px;
      font-size: 13px;
      font-weight: 600;
      margin-bottom: 16px;
    }

    .banner-error {
      background: #fee2e2;
      color: #991b1b;
      padding: 12px 16px;
      border-radius: 8px;
      font-size: 13px;
      font-weight: 600;
      margin-bottom: 16px;
    }

    .card + .card { margin-top: 20px; }

    .badge-pending  { background: #fef3c7; color: #92400e; }

    .row-actions {
      display: flex;
      gap: 6px;
    }

    .btn-accept, .btn-decline {
      padding: 6px 12px;
      border: none;
      border-radius: 6px;
      font-size: 12px;
      font-weight: 600;
      cursor: pointer;
    }

    .btn-accept  { background: #16a34a; color: white; }
    .btn-accept:hover  { background: #15803d; }

    .btn-decline { background: #e5e7eb; color: #111827; }
    .btn-decline:hover { background: #d1d5db; }
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
      <a href="friends.jsp" class="active">Friends</a>
      <a href="profile.jsp">My Profile</a>
    </div>
    <div class="user-info">
      <span><%= name %></span>
      <a class="logout" href="home.jsp?action=logout">Log Out</a>
    </div>
  </nav>

  <div class="container">
    <% if (!actionMsg.isEmpty() && "success".equals(actionKind)) { %>
      <div class="banner-success">&#10003; <%= actionMsg %></div>
    <% } else if (!actionMsg.isEmpty()) { %>
      <div class="banner-error"><%= actionMsg %></div>
    <% } %>

    <div class="card">
      <h2>Pending Friend Requests</h2>
      <p class="subtitle">Requests from other users waiting on your response.</p>

      <%
        Connection prCon = null;
        PreparedStatement prPs = null;
        ResultSet prRs = null;
        String pendingError = "";
        try {
          Class.forName("com.mysql.cj.jdbc.Driver");
          prCon = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
          prPs = prCon.prepareStatement(
            "SELECT u.Username, u.Name, u.Major, u.Year, fr.Created_At " +
            "FROM Friend_Request fr " +
            "JOIN Users u ON u.Username = fr.Sender_Username " +
            "WHERE fr.Receiver_Username = ? AND fr.Status = 'Pending' " +
            "ORDER BY fr.Created_At DESC, u.Name ASC"
          );
          prPs.setString(1, username);
          prRs = prPs.executeQuery();
      %>

      <table>
        <thead>
          <tr>
            <th>Name</th>
            <th>Username</th>
            <th>Major</th>
            <th>Year</th>
            <th>Sent</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody>
          <%
            boolean hasPending = false;
            while (prRs.next()) {
              hasPending = true;
              String prSender = prRs.getString("Username");
          %>
            <tr>
              <td><strong><%= prRs.getString("Name") %></strong></td>
              <td>@<%= prSender %></td>
              <td><%= prRs.getString("Major") != null ? prRs.getString("Major") : "—" %></td>
              <td><%= prRs.getObject("Year") != null ? prRs.getInt("Year") : "—" %></td>
              <td><%= prRs.getString("Created_At") != null ? prRs.getString("Created_At") : "—" %></td>
              <td>
                <div class="row-actions">
                  <form method="POST" action="friends.jsp" style="display:inline;">
                    <input type="hidden" name="action" value="accept_request" />
                    <input type="hidden" name="sender" value="<%= prSender %>" />
                    <button type="submit" class="btn-accept">Accept</button>
                  </form>
                  <form method="POST" action="friends.jsp" style="display:inline;">
                    <input type="hidden" name="action" value="decline_request" />
                    <input type="hidden" name="sender" value="<%= prSender %>" />
                    <button type="submit" class="btn-decline">Decline</button>
                  </form>
                </div>
              </td>
            </tr>
          <% } %>
          <% if (!hasPending) { %>
            <tr><td colspan="6" class="no-data">No pending friend requests.</td></tr>
          <% } %>
        </tbody>
      </table>

      <%
        } catch (Exception e) {
          pendingError = "Database error: " + e.getMessage();
        } finally {
          if (prRs != null) try { prRs.close(); } catch (Exception ignore) {}
          if (prPs != null) try { prPs.close(); } catch (Exception ignore) {}
          if (prCon != null) try { prCon.close(); } catch (Exception ignore) {}
        }
      %>

      <% if (!pendingError.isEmpty()) { %>
        <p class="error-msg"><%= pendingError %></p>
      <% } %>
    </div>

    <div class="card">
      <h2>My Friends</h2>
      <p class="subtitle">People you are currently connected with.</p>

      <%
        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
          Class.forName("com.mysql.cj.jdbc.Driver");
          con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
          ps = con.prepareStatement(
            "SELECT u.Username, u.Name, u.Major, u.Year " +
            "FROM Friends_With f " +
            "JOIN Users u ON u.Username = CASE WHEN f.Username1 = ? THEN f.Username2 ELSE f.Username1 END " +
            "WHERE (f.Username1 = ? OR f.Username2 = ?) " +
            "  AND (f.Status = 'Accepted' OR f.Status IS NULL) " +
            "ORDER BY u.Name ASC"
          );
          ps.setString(1, username);
          ps.setString(2, username);
          ps.setString(3, username);
          rs = ps.executeQuery();
      %>

      <table>
        <thead>
          <tr>
            <th>Name</th>
            <th>Username</th>
            <th>Major</th>
            <th>Year</th>
            <th>Connection</th>
          </tr>
        </thead>
        <tbody>
          <%
            boolean hasRows = false;
            while (rs.next()) {
              hasRows = true;
          %>
            <tr>
              <td><strong><%= rs.getString("Name") %></strong></td>
              <td>@<%= rs.getString("Username") %></td>
              <td><%= rs.getString("Major") != null ? rs.getString("Major") : "—" %></td>
              <td><%= rs.getObject("Year") != null ? rs.getInt("Year") : "—" %></td>
              <td><span class="badge">Accepted</span></td>
            </tr>
          <% } %>
          <% if (!hasRows) { %>
            <tr><td colspan="5" class="no-data">You do not have any friends yet.</td></tr>
          <% } %>
        </tbody>
      </table>

      <%
        } catch (Exception e) {
          errorMsg = "Database error: " + e.getMessage();
        } finally {
          if (rs != null) try { rs.close(); } catch (Exception ignore) {}
          if (ps != null) try { ps.close(); } catch (Exception ignore) {}
          if (con != null) try { con.close(); } catch (Exception ignore) {}
        }
      %>

      <% if (!errorMsg.isEmpty()) { %>
        <p class="error-msg"><%= errorMsg %></p>
      <% } %>
    </div>
  </div>
</body>
</html>
