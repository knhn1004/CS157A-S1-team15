<%@ page import="java.sql.*" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page session="true" %>
<%
  String viewer = (String) session.getAttribute("username");
  String viewerName = (String) session.getAttribute("name");
  if (viewer == null) {
    response.sendRedirect("index.jsp");
    return;
  }

  final String DB_URL  = "jdbc:mysql://localhost:3306/Team_15?autoReconnect=true&useSSL=false&allowPublicKeyRetrieval=true";
  final String DB_USER = "root";
  final String DB_PASS = "password";

  String targetUser = request.getParameter("u") != null ? request.getParameter("u").trim() : "";
  String sessionId = request.getParameter("sessionId") != null ? request.getParameter("sessionId").trim() : "";

  String errorMsg = "";
  String displayName = "";
  String major = "";
  String yearStr = "";
  String school = "";
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Public Profile - SpartanStudyCircle</title>
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

    nav .user-info {
      display: flex;
      align-items: center;
      gap: 12px;
      font-size: 14px;
    }

    .container {
      max-width: 900px;
      margin: 32px auto;
      padding: 0 16px;
    }

    .card {
      background: white;
      border-radius: 12px;
      padding: 24px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.08);
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
      grid-template-columns: 1fr 1fr;
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
      <a href="friends.jsp">Friends</a>
      <a href="profile.jsp">My Profile</a>
    </div>
    <div class="user-info">
      <span><%= viewerName %></span>
      <a class="logout" href="home.jsp?action=logout">Log Out</a>
    </div>
  </nav>

  <div class="container">
    <div class="card">
      <div class="header-row">
        <h2>Public Profile</h2>
        <a class="back-link" href="session_attendees.jsp?sessionId=<%= sessionId %>">&#8592; Back to Attendees</a>
      </div>

      <%
        if (targetUser.isEmpty() || sessionId.isEmpty()) {
          errorMsg = "Missing user or session.";
        }
      %>

      <% if (!errorMsg.isEmpty()) { %>
        <p class="error-msg"><%= errorMsg %></p>
      <% } else { %>
        <%
          Connection con = null;
          PreparedStatement authPs = null;
          PreparedStatement userPs = null;
          PreparedStatement enrollPs = null;
          ResultSet authRs = null;
          ResultSet userRs = null;
          ResultSet enrollRs = null;
          try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

            authPs = con.prepareStatement(
              "SELECT ss.Organizer_Username, " +
              "       EXISTS(SELECT 1 FROM Attends a WHERE a.Session_ID = ss.Session_ID AND a.Username = ?) AS is_attendee " +
              "FROM StudySession ss " +
              "WHERE ss.Session_ID = ?"
            );
            authPs.setString(1, targetUser);
            authPs.setString(2, sessionId);
            authRs = authPs.executeQuery();

            if (!authRs.next()) {
              errorMsg = "Study session not found.";
            } else {
              String organizer = authRs.getString("Organizer_Username");
              boolean isAttendee = authRs.getInt("is_attendee") == 1;
              if (organizer == null || !organizer.equals(viewer)) {
                errorMsg = "Only the session organizer can view attendee profiles from this page.";
              } else if (!isAttendee) {
                errorMsg = "That user is not attending this session.";
              }
            }
            authRs.close();
            authPs.close();

            if (errorMsg.isEmpty()) {
              userPs = con.prepareStatement(
                "SELECT Name, Major, Year, School_name FROM Users WHERE Username = ?"
              );
              userPs.setString(1, targetUser);
              userRs = userPs.executeQuery();
              if (!userRs.next()) {
                errorMsg = "User not found.";
              } else {
                displayName = userRs.getString("Name") != null ? userRs.getString("Name") : "";
                major = userRs.getString("Major") != null ? userRs.getString("Major") : "—";
                yearStr = userRs.getObject("Year") != null ? String.valueOf(userRs.getInt("Year")) : "—";
                school = userRs.getString("School_name") != null ? userRs.getString("School_name") : "—";
              }
              userRs.close();
              userPs.close();
            }

            if (errorMsg.isEmpty()) {
              enrollPs = con.prepareStatement(
                "SELECT c.Subject_Abbr, c.Course_No, c.Section, c.Class_Name " +
                "FROM Enrolls e " +
                "JOIN Class c ON c.Subject_Abbr = e.Subject_Abbr AND c.Course_No = e.Course_No AND c.Section = e.Section " +
                "WHERE e.Username = ? " +
                "ORDER BY c.Subject_Abbr ASC, c.Course_No ASC, c.Section ASC"
              );
              enrollPs.setString(1, targetUser);
              enrollRs = enrollPs.executeQuery();
            }
        %>

        <% if (!errorMsg.isEmpty()) { %>
          <p class="error-msg"><%= errorMsg %></p>
        <% } else { %>
          <p class="subtitle">
            <strong><%= displayName %></strong> &nbsp;·&nbsp; @<%= targetUser %> &nbsp;·&nbsp; Session <%= sessionId %>
          </p>

          <div class="grid">
            <div class="field"><span class="label">Major</span><%= major %></div>
            <div class="field"><span class="label">Year</span><%= yearStr %></div>
            <div class="field" style="grid-column: 1 / -1;"><span class="label">School</span><%= school %></div>
          </div>

          <div class="panel-title">Classes</div>

          <table>
            <thead>
              <tr>
                <th>Course</th>
                <th>Class Name</th>
              </tr>
            </thead>
            <tbody>
              <%
                boolean hasClasses = false;
                while (enrollRs.next()) {
                  hasClasses = true;
                  String subj = enrollRs.getString("Subject_Abbr");
                  String course = enrollRs.getString("Course_No");
                  String sec = enrollRs.getString("Section");
                  String cname = enrollRs.getString("Class_Name") != null ? enrollRs.getString("Class_Name") : "—";
              %>
                <tr>
                  <td><strong><%= subj %> <%= course %>-<%= sec %></strong></td>
                  <td><%= cname %></td>
                </tr>
              <% } %>
              <% if (!hasClasses) { %>
                <tr><td colspan="2" class="no-data">No classes on file for this user.</td></tr>
              <% } %>
            </tbody>
          </table>

          <%
              enrollRs.close();
              enrollPs.close();
            }
          } catch (Exception e) {
            errorMsg = "Database error: " + e.getMessage();
        %>
          <p class="error-msg"><%= errorMsg %></p>
        <%
          } finally {
            if (enrollRs != null) try { enrollRs.close(); } catch (Exception ignore) {}
            if (userRs != null) try { userRs.close(); } catch (Exception ignore) {}
            if (authRs != null) try { authRs.close(); } catch (Exception ignore) {}
            if (enrollPs != null) try { enrollPs.close(); } catch (Exception ignore) {}
            if (userPs != null) try { userPs.close(); } catch (Exception ignore) {}
            if (authPs != null) try { authPs.close(); } catch (Exception ignore) {}
            if (con != null) try { con.close(); } catch (Exception ignore) {}
          }
        %>
      <% } %>
    </div>
  </div>
</body>
</html>
