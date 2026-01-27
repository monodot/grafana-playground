<%@ Page Language="C#" AutoEventWireup="true" %>
<!DOCTYPE html>
<html>
<head>
    <title>Demo .NET Framework 4.8 App</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #333; }
        .info { background: #e3f2fd; padding: 15px; border-radius: 4px; margin: 20px 0; }
        .info-item { margin: 10px 0; }
        .label { font-weight: bold; color: #1976d2; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Demo .NET Framework 4.8 Application</h1>
        <div class="info">
            <div class="info-item">
                <span class="label">Server:</span> <%= Environment.MachineName %>
            </div>
            <div class="info-item">
                <span class="label">.NET Version:</span> <%= Environment.Version %>
            </div>
            <div class="info-item">
                <span class="label">Request Time:</span> <%= DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") %>
            </div>
            <div class="info-item">
                <span class="label">Client IP:</span> <%= Request.UserHostAddress %>
            </div>
        </div>
        <p>This is a simple ASP.NET application running on IIS, demonstrating load balancing across multiple Windows VMs with Grafana Alloy collecting telemetry.</p>
    </div>
</body>
</html>
