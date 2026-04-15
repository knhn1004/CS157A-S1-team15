<%@ page import="java.sql.*, java.util.*" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page session="true" %>
<%
  // Session guard
  String username = (String) session.getAttribute("username");
  String name     = (String) session.getAttribute("name");
  if (username == null) {
    response.sendRedirect("index.jsp");
    return;
  }

  final String DB_URL  = "jdbc:mysql://localhost:3306/Team_15?autoReconnect=true&useSSL=false&allowPublicKeyRetrieval=true";
  final String DB_USER = "root";
  final String DB_PASS = "password";

  String searchText       = request.getParameter("q") != null ? request.getParameter("q").trim() : "";
  String majorFilter      = request.getParameter("major") != null ? request.getParameter("major").trim() : "";
  String yearFilter       = request.getParameter("year") != null ? request.getParameter("year").trim() : "";
  String classFilter      = request.getParameter("classFilter") != null ? request.getParameter("classFilter").trim() : "";
  boolean onlySharedClass = "1".equals(request.getParameter("onlySharedClass"));

  List<String> majorOptions = new ArrayList<String>();
  String loadError = "";
  String resultsError = "";
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Find People - SpartanStudyCircle</title>
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
      max-width: 1020px;
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

    .card h2 {
      font-size: 18px;
      color: #0055A2;
      font-weight: 700;
      margin-bottom: 8px;
    }

    .subtitle {
      font-size: 13px;
      color: #6b7280;
      margin-bottom: 20px;
    }

    .filters {
      display: grid;
      grid-template-columns: 2fr 1fr 1fr 1.2fr auto;
      gap: 12px;
      align-items: end;
    }

    .field label {
      display: block;
      font-size: 12px;
      font-weight: 600;
      color: #374151;
      margin-bottom: 6px;
    }

    input[type="text"], select {
      width: 100%;
      padding: 10px 12px;
      border: 1.5px solid #d1d5db;
      border-radius: 8px;
      font-size: 14px;
      outline: none;
    }

    input[type="text"]:focus, select:focus { border-color: #0055A2; }

    .checkbox-row {
      display: flex;
      align-items: center;
      gap: 8px;
      margin-top: 8px;
      font-size: 13px;
      color: #374151;
    }

    .actions {
      display: flex;
      gap: 8px;
    }

    button, .clear-btn {
      padding: 10px 14px;
      border-radius: 8px;
      border: none;
      font-size: 13px;
      font-weight: 600;
      cursor: pointer;
      text-decoration: none;
      text-align: center;
      white-space: nowrap;
    }

    button {
      background: #0055A2;
      color: white;
    }

    button:hover { background: #004490; }

    .clear-btn {
      background: #e5e7eb;
      color: #111827;
    }

    .clear-btn:hover { background: #d1d5db; }

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
    }
  </style>
</head>
<body>
  <nav>
    <span class="brand">&#128218; SpartanStudyCircle</span>
    <div class="nav-links">
      <a href="home.jsp">Home</a>
      <a href="create_session.jsp">+ Create Session</a>
      <a href="people.jsp" class="active">Find People</a>
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
      <h2>Find Classmates</h2>
      <p class="subtitle">Browse, search, and filter users. Suggestions are ranked by shared classes, major, and year.</p>

      <%
        try {
          Class.forName("com.mysql.cj.jdbc.Driver");
          Connection optionCon = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
          PreparedStatement majorPs = optionCon.prepareStatement(
            "SELECT DISTINCT Major FROM Users WHERE Major IS NOT NULL AND TRIM(Major) <> '' ORDER BY Major"
          );
          ResultSet majorRs = majorPs.executeQuery();
          while (majorRs.next()) {
            majorOptions.add(majorRs.getString("Major"));
          }
          majorRs.close();
          majorPs.close();
          optionCon.close();
        } catch (Exception e) {
          loadError = "Could not load filter options: " + e.getMessage();
        }
      %>

      <% if (!loadError.isEmpty()) { %>
        <p class="error-msg"><%= loadError %></p>
      <% } %>

      <form method="GET" action="people.jsp">
        <div class="filters">
          <div class="field">
            <label>Search (name or username)</label>
            <input type="text" name="q" value="<%= searchText %>" placeholder="Search people..." />
          </div>

          <div class="field">
            <label>Major</label>
            <select name="major">
              <option value="">All</option>
              <% for (String majorVal : majorOptions) { %>
                <option value="<%= majorVal %>" <%= majorVal.equals(majorFilter) ? "selected" : "" %>><%= majorVal %></option>
              <% } %>
            </select>
          </div>

          <div class="field">
            <label>Year</label>
            <select name="year">
              <option value="">All</option>
              <option value="1" <%= "1".equals(yearFilter) ? "selected" : "" %>>1</option>
              <option value="2" <%= "2".equals(yearFilter) ? "selected" : "" %>>2</option>
              <option value="3" <%= "3".equals(yearFilter) ? "selected" : "" %>>3</option>
              <option value="4" <%= "4".equals(yearFilter) ? "selected" : "" %>>4</option>
            </select>
          </div>

          <div class="field">
            <label>Class (e.g. CS 157A)</label>
            <input type="text" name="classFilter" value="<%= classFilter %>" placeholder="Subject or Course" />
            <div class="checkbox-row">
              <input type="checkbox" name="onlySharedClass" value="1" <%= onlySharedClass ? "checked" : "" %> />
              <span>Only show shared classes</span>
            </div>
          </div>

          <div class="actions">
            <button type="submit">Apply</button>
            <a class="clear-btn" href="people.jsp">Clear</a>
          </div>
        </div>
      </form>
    </div>

    <div class="card">
      <h2>Suggested People</h2>
      <p class="subtitle">Results include public profile basics: Name, Major, Year.</p>

      <%
        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
          Class.forName("com.mysql.cj.jdbc.Driver");
          con = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

          StringBuilder sql = new StringBuilder();
          List<Object> params = new ArrayList<Object>();

          sql.append("SELECT u.Username, u.Name, u.Major, u.Year, ");
          sql.append("       COUNT(DISTINCT CASE ");
          sql.append("         WHEN e1.Username IS NOT NULL ");
          sql.append("         THEN CONCAT(e2.Subject_Abbr, '-', e2.Course_No, '-', e2.Section) ");
          sql.append("         ELSE NULL ");
          sql.append("       END) AS shared_classes, ");
          sql.append("       (");
          sql.append("         (CASE WHEN u.Major IS NOT NULL AND u.Major = me.Major THEN 2 ELSE 0 END) + ");
          sql.append("         (CASE WHEN u.Year IS NOT NULL AND u.Year = me.Year THEN 1 ELSE 0 END) + ");
          sql.append("         COUNT(DISTINCT CASE ");
          sql.append("           WHEN e1.Username IS NOT NULL ");
          sql.append("           THEN CONCAT(e2.Subject_Abbr, '-', e2.Course_No, '-', e2.Section) ");
          sql.append("           ELSE NULL ");
          sql.append("         END)");
          sql.append("       ) AS suggestion_score ");
          sql.append("FROM Users u ");
          sql.append("JOIN Users me ON me.Username = ? ");
          sql.append("LEFT JOIN Enrolls e2 ON e2.Username = u.Username ");
          sql.append("LEFT JOIN Enrolls e1 ON e1.Username = me.Username ");
          sql.append("  AND e1.Subject_Abbr = e2.Subject_Abbr ");
          sql.append("  AND e1.Course_No = e2.Course_No ");
          sql.append("  AND e1.Section = e2.Section ");
          sql.append("WHERE u.Username <> ? ");
          params.add(username);
          params.add(username);

          if (!searchText.isEmpty()) {
            sql.append("AND (u.Name LIKE ? OR u.Username LIKE ?) ");
            params.add("%" + searchText + "%");
            params.add("%" + searchText + "%");
          }

          if (!majorFilter.isEmpty()) {
            sql.append("AND u.Major = ? ");
            params.add(majorFilter);
          }

          if (!yearFilter.isEmpty()) {
            sql.append("AND u.Year = ? ");
            params.add(Integer.parseInt(yearFilter));
          }

          if (!classFilter.isEmpty()) {
            sql.append("AND EXISTS (");
            sql.append("  SELECT 1 FROM Enrolls ef ");
            sql.append("  WHERE ef.Username = u.Username ");
            sql.append("    AND (ef.Subject_Abbr LIKE ? OR ef.Course_No LIKE ?)");
            sql.append(") ");
            params.add("%" + classFilter + "%");
            params.add("%" + classFilter + "%");
          }

          sql.append("GROUP BY u.Username, u.Name, u.Major, u.Year, me.Major, me.Year ");

          if (onlySharedClass) {
            sql.append("HAVING shared_classes > 0 ");
          }

          sql.append("ORDER BY suggestion_score DESC, shared_classes DESC, u.Name ASC ");
          sql.append("LIMIT 50");

          ps = con.prepareStatement(sql.toString());
          for (int i = 0; i < params.size(); i++) {
            Object val = params.get(i);
            if (val instanceof Integer) ps.setInt(i + 1, ((Integer) val).intValue());
            else ps.setString(i + 1, String.valueOf(val));
          }

          rs = ps.executeQuery();
      %>

      <table>
        <thead>
          <tr>
            <th>Name</th>
            <th>Username</th>
            <th>Major</th>
            <th>Year</th>
            <th>Shared Classes</th>
            <th>Suggestion Score</th>
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
              <td><span class="badge"><%= rs.getInt("shared_classes") %></span></td>
              <td><%= rs.getInt("suggestion_score") %></td>
            </tr>
          <% } %>
          <% if (!hasRows) { %>
            <tr><td colspan="6" class="no-data">No users match the current search/filter settings.</td></tr>
          <% } %>
        </tbody>
      </table>

      <%
        } catch (Exception e) {
          resultsError = "Database error: " + e.getMessage();
        } finally {
          if (rs != null) try { rs.close(); } catch (Exception ignore) {}
          if (ps != null) try { ps.close(); } catch (Exception ignore) {}
          if (con != null) try { con.close(); } catch (Exception ignore) {}
        }
      %>

      <% if (!resultsError.isEmpty()) { %>
        <p class="error-msg"><%= resultsError %></p>
      <% } %>
    </div>
  </div>
</body>
</html>
