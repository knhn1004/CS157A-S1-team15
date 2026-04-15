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

  String errorMsg = "";
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
  </style>
</head>
<body>
  <nav>
    <span class="brand">&#128218; SpartanStudyCircle</span>
    <div class="nav-links">
      <a href="home.jsp">Home</a>
      <a href="create_session.jsp">+ Create Session</a>
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
