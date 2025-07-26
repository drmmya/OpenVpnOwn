<?php
require 'config.php';
session_start();
if (!isset($_SESSION['loggedin'])) {
    header('Location: login.php');
    exit;
}
echo "<h2>Welcome to OpenVPN Admin Panel</h2>";
?>
<a href='users.php'>Manage Users</a> | <a href='logs.php'>View Logs</a> | <a href='restart.php'>Restart VPN</a> | <a href='password.php'>Change Password</a> | <a href='logout.php'>Logout</a>
