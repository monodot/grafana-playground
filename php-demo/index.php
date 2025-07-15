<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PHP User List</title>
    <!-- Include Tailwind CSS for styling -->
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        body {
            font-family: 'Inter', sans-serif;
        }
    </style>
</head>
<body class="bg-gray-100 text-gray-800">

    <div class="container mx-auto p-4 sm:p-6 lg:p-8">
        <div class="bg-white rounded-xl shadow-lg overflow-hidden">
            <div class="p-6 border-b border-gray-200">
                <h1 class="text-2xl sm:text-3xl font-bold text-gray-900">User List</h1>
                <p class="mt-1 text-gray-600">A simple list of users from the database.</p>
            </div>

            <?php
            // --- Database Connection ---
            // Get database credentials from environment variables
            $db_host = getenv('DB_HOST');
            $db_name = getenv('DB_NAME');
            $db_user = getenv('DB_USER');
            $db_pass = getenv('DB_PASSWORD');

            // Create a new MySQLi object to connect to the database
            // The '@' symbol suppresses warnings, allowing for custom error handling
            @$mysqli = new mysqli($db_host, $db_user, $db_pass, $db_name);

            // Check for connection errors
            if ($mysqli->connect_error) {
                echo '<div class="p-6 text-center text-red-600 bg-red-50 rounded-b-xl">';
                echo '<h3 class="font-semibold">Database Connection Failed</h3>';
                // Use htmlspecialchars to prevent XSS attacks when printing user-facing errors
                echo '<p class="mt-1 text-sm">' . htmlspecialchars($mysqli->connect_error) . '</p>';
                echo '</div>';
            } else {
                // --- Fetch Data ---
                $sql = "SELECT id, name, email, registration_date FROM users";
                $result = $mysqli->query($sql);

                // Check if the query returned any results
                if ($result && $result->num_rows > 0) {
            ?>
                    <!-- User Table -->
                    <div class="overflow-x-auto">
                        <table class="min-w-full text-sm text-left">
                            <thead class="bg-gray-50 border-b border-gray-200">
                                <tr>
                                    <th scope="col" class="px-6 py-3 font-medium text-gray-500 uppercase tracking-wider">ID</th>
                                    <th scope="col" class="px-6 py-3 font-medium text-gray-500 uppercase tracking-wider">Name</th>
                                    <th scope="col" class="px-6 py-3 font-medium text-gray-500 uppercase tracking-wider">Email</th>
                                    <th scope="col" class="px-6 py-3 font-medium text-gray-500 uppercase tracking-wider">Registration Date</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-gray-200">
                                <?php
                                // Loop through the result set and display each user in a table row
                                while($row = $result->fetch_assoc()) {
                                    echo "<tr class='hover:bg-gray-50'>";
                                    // Sanitize output with htmlspecialchars to prevent XSS
                                    echo "<td class='px-6 py-4 whitespace-nowrap font-medium text-gray-900'>" . htmlspecialchars($row["id"]) . "</td>";
                                    echo "<td class='px-6 py-4 whitespace-nowrap'>" . htmlspecialchars($row["name"]) . "</td>";
                                    echo "<td class='px-6 py-4 whitespace-nowrap'>" . htmlspecialchars($row["email"]) . "</td>";
                                    echo "<td class='px-6 py-4 whitespace-nowrap'>" . htmlspecialchars($row["registration_date"]) . "</td>";
                                    echo "</tr>";
                                }
                                ?>
                            </tbody>
                        </table>
                    </div>
            <?php
                } else {
                    // Display a message if no users are found in the table
                    echo '<div class="p-6 text-center text-gray-500 bg-gray-50 rounded-b-xl">';
                    echo '<h3 class="font-semibold">No Users Found</h3>';
                    echo '<p class="mt-1 text-sm">The \'users\' table is empty.</p>';
                    echo '</div>';
                }
                // Close the database connection
                $mysqli->close();
            }
            ?>
        </div>
    </div>
</body>
</html>
