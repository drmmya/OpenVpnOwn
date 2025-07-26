<?php
require 'config.php';
session_start();
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    if ($_POST['username'] === $admin_user && $_POST['password'] === $admin_pass) {
        $_SESSION['loggedin'] = true;
        header('Location: index.php');
        exit;
    } else {
        $error = "Invalid credentials";
    }
}
?>
<form method='post'>
Username: <input name='username'><br>
Password: <input type='password' name='password'><br>
<button type='submit'>Login</button>
</form>
<?php if (isset($error)) echo "<p>$error</p>"; ?>
