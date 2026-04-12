<%@ page import="java.sql.*, java.security.*" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page session="true" %>
<%!
  private String hashPassword(String password) throws Exception {
    MessageDigest md = MessageDigest.getInstance("SHA-256");
    byte[] hash = md.digest(password.getBytes("UTF-8"));
    StringBuilder sb = new StringBuilder();
    for (byte b : hash) sb.append(String.format("%02x", b));
    return sb.toString();
  }

  private Connection getConnection() throws Exception {
    Class.forName("com.mysql.cj.jdbc.Driver");
    return DriverManager.getConnection(
      "jdbc:mysql://localhost:3306/Team_15?autoReconnect=true&useSSL=false&allowPublicKeyRetrieval=true",
      "root", "password"
    );
  }
%>
<%
  // If already logged in, go to home
  if (session.getAttribute("username") != null) {
    response.sendRedirect("home.jsp");
    return;
  }

  String action     = request.getParameter("action");
  String loginError = "";
  String registerMsg = "";
  boolean registerSuccess = false;
  String activeTab = "login"; // which tab to show on page load

  // ── LOGIN ──────────────────────────────────────────────────────────────────
  if ("login".equals(action)) {
    activeTab = "login";
    String username = request.getParameter("username");
    String password = request.getParameter("password");

    if (username != null && password != null) {
      try (Connection con = getConnection()) {
        String hashed = hashPassword(password);
        PreparedStatement ps = con.prepareStatement(
          "SELECT Username, Name FROM Users WHERE Username = ? AND Password_Hash = ?"
        );
        ps.setString(1, username.trim());
        ps.setString(2, hashed);
        ResultSet rs = ps.executeQuery();

        if (rs.next()) {
          session.setAttribute("username", rs.getString("Username"));
          session.setAttribute("name",     rs.getString("Name"));
          rs.close(); ps.close();
          response.sendRedirect("home.jsp");
          return;
        } else {
          loginError = "Incorrect username or password.";
        }
        rs.close(); ps.close();
      } catch (Exception e) {
        loginError = "Database error: " + e.getMessage();
      }
    }

  // ── REGISTER ───────────────────────────────────────────────────────────────
  } else if ("register".equals(action)) {
    activeTab = "register";
    String username = request.getParameter("username");
    String email    = request.getParameter("email");
    String name     = request.getParameter("name");
    String password = request.getParameter("password");
    String major    = request.getParameter("major");
    String year     = request.getParameter("year");

    if (username != null && password != null && email != null && name != null) {
      try (Connection con = getConnection()) {
        // Check if username already taken
        PreparedStatement check = con.prepareStatement(
          "SELECT Username FROM Users WHERE Username = ?"
        );
        check.setString(1, username.trim());
        ResultSet rs = check.executeQuery();
        boolean taken = rs.next();
        rs.close(); check.close();

        if (taken) {
          registerMsg = "Username already taken. Please choose another.";
        } else {
          String hashed = hashPassword(password);
          PreparedStatement insert = con.prepareStatement(
            "INSERT INTO Users (Username, Email, Name, Password_Hash, Major, Year, School_name) " +
            "VALUES (?, ?, ?, ?, ?, ?, 'SJSU')"
          );
          insert.setString(1, username.trim());
          insert.setString(2, email.trim());
          insert.setString(3, name.trim());
          insert.setString(4, hashed);
          insert.setString(5, (major != null && !major.trim().isEmpty()) ? major.trim() : null);
          if (year != null && !year.isEmpty()) {
            insert.setInt(6, Integer.parseInt(year));
          } else {
            insert.setNull(6, java.sql.Types.INTEGER);
          }
          insert.executeUpdate();
          insert.close();
          registerMsg    = "Account created! You can now log in.";
          registerSuccess = true;
          activeTab       = "login"; // switch to login tab after success
        }
      } catch (Exception e) {
        registerMsg = "Database error: " + e.getMessage();
      }
    }
  }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>SpartanStudyCircle</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }

    body {
      font-family: 'Segoe UI', sans-serif;
      background: #0055A2;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .card {
      background: white;
      border-radius: 12px;
      padding: 40px 36px;
      width: 100%;
      max-width: 380px;
      box-shadow: 0 8px 32px rgba(0,0,0,0.2);
    }

    .logo {
      text-align: center;
      margin-bottom: 28px;
    }

    .logo h1 {
      font-size: 22px;
      color: #0055A2;
      font-weight: 700;
    }

    .logo p {
      font-size: 13px;
      color: #6b7280;
      margin-top: 4px;
    }

    .tabs {
      display: flex;
      border-bottom: 2px solid #e5e7eb;
      margin-bottom: 24px;
    }

    .tab {
      flex: 1;
      text-align: center;
      padding: 10px;
      cursor: pointer;
      font-size: 14px;
      font-weight: 600;
      color: #6b7280;
      border-bottom: 3px solid transparent;
      margin-bottom: -2px;
    }

    .tab.active {
      color: #0055A2;
      border-bottom-color: #0055A2;
    }

    .form { display: none; flex-direction: column; gap: 16px; }
    .form.active { display: flex; }

    label {
      display: block;
      font-size: 13px;
      font-weight: 600;
      margin-bottom: 5px;
      color: #374151;
    }

    input, select {
      width: 100%;
      padding: 10px 12px;
      border: 1.5px solid #d1d5db;
      border-radius: 8px;
      font-size: 14px;
      outline: none;
      transition: border-color 0.2s;
    }

    input:focus, select:focus {
      border-color: #0055A2;
    }

    .row {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 12px;
    }

    button {
      width: 100%;
      padding: 11px;
      background: #0055A2;
      color: white;
      border: none;
      border-radius: 8px;
      font-size: 15px;
      font-weight: 600;
      cursor: pointer;
    }

    button:hover { background: #004490; }

    .msg {
      font-size: 13px;
      text-align: center;
      min-height: 18px;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="logo">
      <h1>&#128218; SpartanStudyCircle</h1>
      <p>San José State University</p>
    </div>

    <div class="tabs">
      <div class="tab" id="tab-login"    onclick="show('login',    this)">Log In</div>
      <div class="tab" id="tab-register" onclick="show('register', this)">Register</div>
    </div>

    <!-- LOGIN FORM -->
    <form class="form" id="login" method="POST" action="index.jsp">
      <input type="hidden" name="action" value="login" />
      <div>
        <label>Username</label>
        <input type="text" name="username" placeholder="Enter username" required />
      </div>
      <div>
        <label>Password</label>
        <input type="password" name="password" placeholder="Enter password" required />
      </div>
      <% if (!loginError.isEmpty()) { %>
        <div class="msg" style="color:#ef4444"><%= loginError %></div>
      <% } else { %>
        <div class="msg"></div>
      <% } %>
      <button type="submit">Log In</button>
    </form>

    <!-- REGISTER FORM -->
    <form class="form" id="register" method="POST" action="index.jsp">
      <input type="hidden" name="action" value="register" />
      <div>
        <label>Username</label>
        <input type="text" name="username" placeholder="Choose a unique username" required />
      </div>
      <div>
        <label>Email</label>
        <input type="email" name="email" placeholder="yourname@sjsu.edu" required />
      </div>
      <div>
        <label>Name</label>
        <input type="text" name="name" placeholder="Full name" required />
      </div>
      <div>
        <label>Password</label>
        <input type="password" name="password" placeholder="Create a password" required />
      </div>
      <div class="row">
        <div>
          <label>Major</label>
          <input type="text" name="major" placeholder="e.g. CS" />
        </div>
        <div>
          <label>Year</label>
          <select name="year">
            <option value="">—</option>
            <option>1</option>
            <option>2</option>
            <option>3</option>
            <option>4</option>
          </select>
        </div>
      </div>
      <% if (!registerMsg.isEmpty()) { %>
        <div class="msg" style="color:<%= registerSuccess ? "#22c55e" : "#ef4444" %>">
          <%= registerMsg %>
        </div>
      <% } else { %>
        <div class="msg"></div>
      <% } %>
      <button type="submit">Create Account</button>
    </form>
  </div>

  <script>
    function show(tab, el) {
      document.querySelectorAll('.tab').forEach(t  => t.classList.remove('active'));
      document.querySelectorAll('.form').forEach(f => f.classList.remove('active'));
      el.classList.add('active');
      document.getElementById(tab).classList.add('active');
    }

    // Set the active tab based on server-side state (e.g. after register success)
    window.addEventListener('DOMContentLoaded', function () {
      var activeTab = '<%= activeTab %>';
      var tabEl  = document.getElementById('tab-' + activeTab);
      var formEl = document.getElementById(activeTab);
      document.querySelectorAll('.tab').forEach(t  => t.classList.remove('active'));
      document.querySelectorAll('.form').forEach(f => f.classList.remove('active'));
      if (tabEl  && formEl) {
        tabEl.classList.add('active');
        formEl.classList.add('active');
      }
    });
  </script>
</body>
</html>
