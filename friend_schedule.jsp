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

  String friendUser = request.getParameter("u") != null ? request.getParameter("u").trim() : "";

  String accessError   = "";
  String friendName    = "";
  String friendMajor   = "";
  String friendYear    = "";
  String friendSchool  = "";
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Friend's Schedule - SpartanStudyCircle</title>
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
      margin-bottom: 20px;
    }

    .header-row {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 12px;
      margin-bottom: 8px;
    }

    h2 {
      font-size: 18px;
      color: #0055A2;
      font-weight: 700;
    }

    .subtitle {
      font-size: 13px;
      color: #6b7280;
      margin-bottom: 18px;
      padding-bottom: 14px;
      border-bottom: 2px solid #e5e7eb;
    }

    .back-link {
      color: #0055A2;
      text-decoration: none;
      font-size: 13px;
      font-weight: 600;
    }

    .back-link:hover { text-decoration: underline; }

    .grid {
      display: grid;
      grid-template-columns: 1fr 1fr 1fr;
      gap: 16px;
      margin-bottom: 18px;
    }

    .field {
      font-size: 13px;
      color: #374151;
    }

    .field span.label {
      display: block;
      font-weight: 600;
      color: #6b7280;
      margin-bottom: 6px;
    }

    .panel-title {
      font-size: 15px;
      font-weight: 700;
      color: #0055A2;
      margin: 10px 0 10px;
      padding-bottom: 8px;
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

    .no-data {
      text-align: center;
      color: #9ca3af;
      padding: 22px 0;
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
      <div class="header-row">
        <h2>Friend's Schedule</h2>
        <a class="back-link" href="friends.jsp">&#8592; Back to Friends</a>
      </div>

      <%
        if (friendUser.isEmpty()) {
          accessError = "Missing friend username.";
        } else if (friendUser.equals(username)) {
          accessError = "Use your own profile page to see your schedule.";
        }
      %>

      <% if (!accessError.isEmpty()) { %>
        <p class="error-msg"><%= h(accessError) %></p>
      <% } else { %>
        <%
          Connection con = null;
          PreparedStatement authPs = null;
          PreparedStatement userPs = null;
          PreparedStatement classPs = null;
          PreparedStatement blockPs = null;
          ResultSet authRs = null;
          ResultSet userRs = null;
          ResultSet classRs = null;
          ResultSet blockRs = null;

          try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

            authPs = con.prepareStatement(
              "SELECT 1 FROM Friends_With " +
              " WHERE ((Username1 = ? AND Username2 = ?) " +
              "    OR  (Username1 = ? AND Username2 = ?)) " +
              "   AND (Status = 'Accepted' OR Status IS NULL)"
            );
            authPs.setString(1, username);
            authPs.setString(2, friendUser);
            authPs.setString(3, friendUser);
            authPs.setString(4, username);
            authRs = authPs.executeQuery();
            boolean isFriend = authRs.next();
            authRs.close(); authPs.close();

            if (!isFriend) {
              accessError = "You can only view the schedule of a confirmed friend.";
            } else {
              userPs = con.prepareStatement(
                "SELECT Name, Major, Year, School_name FROM Users WHERE Username = ?"
              );
              userPs.setString(1, friendUser);
              userRs = userPs.executeQuery();
              if (!userRs.next()) {
                accessError = "User not found.";
              } else {
                friendName   = userRs.getString("Name") != null ? userRs.getString("Name") : "";
                friendMajor  = userRs.getString("Major") != null ? userRs.getString("Major") : "—";
                friendYear   = userRs.getObject("Year") != null ? String.valueOf(userRs.getInt("Year")) : "—";
                friendSchool = userRs.getString("School_name") != null ? userRs.getString("School_name") : "—";
              }
              userRs.close(); userPs.close();
            }
        %>

        <% if (!accessError.isEmpty()) { %>
          <p class="error-msg"><%= h(accessError) %></p>
        <% } else { %>
          <p class="subtitle">
            <strong><%= h(friendName) %></strong> &nbsp;·&nbsp; @<%= h(friendUser) %>
          </p>

          <div class="grid">
            <div class="field"><span class="label">Major</span><%= h(friendMajor) %></div>
            <div class="field"><span class="label">Year</span><%= h(friendYear) %></div>
            <div class="field"><span class="label">School</span><%= h(friendSchool) %></div>
          </div>

          <div class="panel-title">Classes</div>

          <%
            classPs = con.prepareStatement(
              "SELECT c.Subject_Abbr, c.Course_No, c.Section, c.Class_Name, c.Time, c.Days, e.Notes " +
              "FROM Enrolls e " +
              "JOIN Class c ON c.Subject_Abbr = e.Subject_Abbr " +
              "             AND c.Course_No   = e.Course_No " +
              "             AND c.Section     = e.Section " +
              "WHERE e.Username = ? " +
              "ORDER BY c.Days ASC, c.Time ASC, c.Subject_Abbr ASC, c.Course_No ASC"
            );
            classPs.setString(1, friendUser);
            classRs = classPs.executeQuery();
          %>

          <table>
            <thead>
              <tr>
                <th>Course</th>
                <th>Class Name</th>
                <th>Days</th>
                <th>Time</th>
              </tr>
            </thead>
            <tbody>
              <%
                boolean hasClasses = false;
                while (classRs.next()) {
                  hasClasses = true;
              %>
                <tr>
                  <td><strong><%= h(classRs.getString("Subject_Abbr")) %> <%= h(classRs.getString("Course_No")) %>-<%= h(classRs.getString("Section")) %></strong></td>
                  <td><%= classRs.getString("Class_Name") != null ? h(classRs.getString("Class_Name")) : "—" %></td>
                  <td><%= classRs.getString("Days") != null ? h(classRs.getString("Days")) : "—" %></td>
                  <td><%= classRs.getString("Time") != null ? h(classRs.getString("Time")) : "—" %></td>
                </tr>
              <% } %>
              <% if (!hasClasses) { %>
                <tr><td colspan="4" class="no-data">No classes on file for this user.</td></tr>
              <% } %>
            </tbody>
          </table>

          <div class="panel-title">Time Blocks</div>

          <%
            classRs.close(); classPs.close();
            blockPs = con.prepareStatement(
              "SELECT Block_ID, Name, Description, Date_Recurring " +
              "FROM TimeBlock " +
              "WHERE Created_Username = ? " +
              "ORDER BY Date_Recurring ASC, Name ASC"
            );
            blockPs.setString(1, friendUser);
            blockRs = blockPs.executeQuery();
          %>

          <table>
            <thead>
              <tr>
                <th>Block</th>
                <th>Description</th>
                <th>When</th>
              </tr>
            </thead>
            <tbody>
              <%
                boolean hasBlocks = false;
                while (blockRs.next()) {
                  hasBlocks = true;
              %>
                <tr>
                  <td><strong><%= blockRs.getString("Name") != null ? h(blockRs.getString("Name")) : "—" %></strong></td>
                  <td><%= blockRs.getString("Description") != null ? h(blockRs.getString("Description")) : "—" %></td>
                  <td><%= blockRs.getString("Date_Recurring") != null ? h(blockRs.getString("Date_Recurring")) : "—" %></td>
                </tr>
              <% } %>
              <% if (!hasBlocks) { %>
                <tr><td colspan="3" class="no-data">No time blocks on file for this user.</td></tr>
              <% } %>
            </tbody>
          </table>

          <%
            }
          } catch (Exception e) {
            accessError = "Database error: " + e.getMessage();
        %>
          <p class="error-msg"><%= h(accessError) %></p>
        <%
          } finally {
            if (blockRs != null) try { blockRs.close(); } catch (Exception ignore) {}
            if (classRs != null) try { classRs.close(); } catch (Exception ignore) {}
            if (userRs  != null) try { userRs.close();  } catch (Exception ignore) {}
            if (authRs  != null) try { authRs.close();  } catch (Exception ignore) {}
            if (blockPs != null) try { blockPs.close(); } catch (Exception ignore) {}
            if (classPs != null) try { classPs.close(); } catch (Exception ignore) {}
            if (userPs  != null) try { userPs.close();  } catch (Exception ignore) {}
            if (authPs  != null) try { authPs.close();  } catch (Exception ignore) {}
            if (con     != null) try { con.close();     } catch (Exception ignore) {}
          }
        %>
      <% } %>
    </div>
  </div>
</body>
</html>
