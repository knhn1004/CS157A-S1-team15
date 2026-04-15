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

  String sessionId = request.getParameter("sessionId") != null ? request.getParameter("sessionId").trim() : "";
  String sessionName = "";
  String sessionDate = "";
  String sessionTime = "";
  String sessionLocation = "";
  String organizer = "";
  String errorMsg = "";
  boolean isOrganizer = false;
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Session Attendees - SpartanStudyCircle</title>
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

    .header-row {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 8px;
      gap: 12px;
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
      <span><%= name %></span>
      <a class="logout" href="home.jsp?action=logout">Log Out</a>
    </div>
  </nav>

  <div class="container">
    <div class="card">
      <div class="header-row">
        <h2>Session Attendees</h2>
        <a class="back-link" href="home.jsp">&#8592; Back to Home</a>
      </div>

      <%
        if (sessionId.isEmpty()) {
          errorMsg = "Missing session ID.";
        }
      %>

      <% if (!errorMsg.isEmpty()) { %>
        <p class="error-msg"><%= errorMsg %></p>
      <% } else { %>
        <%
          Connection con = null;
          PreparedStatement sessionPs = null;
          PreparedStatement attendeesPs = null;
          ResultSet sessionRs = null;
          ResultSet attendeesRs = null;
          try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

            sessionPs = con.prepareStatement(
              "SELECT Session_ID, Name, Date, Time, Location, Organizer_Username " +
              "FROM StudySession WHERE Session_ID = ?"
            );
            sessionPs.setString(1, sessionId);
            sessionRs = sessionPs.executeQuery();

            if (!sessionRs.next()) {
              errorMsg = "Study session not found.";
            } else {
              sessionName = sessionRs.getString("Name") != null ? sessionRs.getString("Name") : "Untitled Session";
              sessionDate = sessionRs.getString("Date") != null ? sessionRs.getString("Date") : "—";
              sessionTime = sessionRs.getString("Time") != null ? sessionRs.getString("Time") : "—";
              sessionLocation = sessionRs.getString("Location") != null ? sessionRs.getString("Location") : "—";
              organizer = sessionRs.getString("Organizer_Username") != null ? sessionRs.getString("Organizer_Username") : "—";
              isOrganizer = organizer != null && organizer.equals(username);
            }

            if (errorMsg.isEmpty() && !isOrganizer) {
              errorMsg = "Only the session organizer can view the attendee list.";
            }

            if (errorMsg.isEmpty()) {
              attendeesPs = con.prepareStatement(
                "SELECT a.Username, u.Name, u.Major, u.Year, a.Status " +
                "FROM Attends a " +
                "JOIN Users u ON u.Username = a.Username " +
                "WHERE a.Session_ID = ? " +
                "ORDER BY u.Name ASC"
              );
              attendeesPs.setString(1, sessionId);
              attendeesRs = attendeesPs.executeQuery();
            }
        %>

        <% if (!errorMsg.isEmpty()) { %>
          <p class="error-msg"><%= errorMsg %></p>
        <% } else { %>
          <p class="subtitle">
            <strong><%= sessionName %></strong> &nbsp;·&nbsp;
            ID: <%= sessionId %> &nbsp;·&nbsp;
            <%= sessionDate %> <%= sessionTime %> &nbsp;·&nbsp;
            <%= sessionLocation %> &nbsp;·&nbsp;
            Organizer: @<%= organizer %>
          </p>

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
              <%
                boolean hasRows = false;
                while (attendeesRs.next()) {
                  hasRows = true;
                  String attendeeUser = attendeesRs.getString("Username");
              %>
                <tr>
                  <td><strong><%= attendeesRs.getString("Name") %></strong></td>
                  <td>@<%= attendeeUser %></td>
                  <td><%= attendeesRs.getString("Major") != null ? attendeesRs.getString("Major") : "—" %></td>
                  <td><%= attendeesRs.getObject("Year") != null ? attendeesRs.getInt("Year") : "—" %></td>
                  <td><span class="badge"><%= attendeesRs.getString("Status") != null ? attendeesRs.getString("Status") : "—" %></span></td>
                  <td>
                    <a class="table-link" href="public_profile.jsp?u=<%= attendeeUser %>&sessionId=<%= sessionId %>">View Profile</a>
                  </td>
                </tr>
              <% } %>
              <% if (!hasRows) { %>
                <tr><td colspan="6" class="no-data">No attendees registered for this session.</td></tr>
              <% } %>
            </tbody>
          </table>
        <% } %>

        <%
          } catch (Exception e) {
            errorMsg = "Database error: " + e.getMessage();
        %>
          <p class="error-msg"><%= errorMsg %></p>
        <%
          } finally {
            if (attendeesRs != null) try { attendeesRs.close(); } catch (Exception ignore) {}
            if (sessionRs != null) try { sessionRs.close(); } catch (Exception ignore) {}
            if (attendeesPs != null) try { attendeesPs.close(); } catch (Exception ignore) {}
            if (sessionPs != null) try { sessionPs.close(); } catch (Exception ignore) {}
            if (con != null) try { con.close(); } catch (Exception ignore) {}
          }
        %>
      <% } %>
    </div>
  </div>
</body>
</html>
