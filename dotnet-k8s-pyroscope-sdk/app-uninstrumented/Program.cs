var builder = WebApplication.CreateBuilder(args);

var app = builder.Build();

// Simple health check endpoint
app.MapGet("/", () => new
{
    message = "Pyroscope .NET Profiling Demo",
    endpoints = new[]
    {
        "/health",
        "/fibonacci/{n}",
        "/prime/{n}",
        "/matrix/{size}",
        "/hash/{iterations}"
    }
});

app.MapGet("/health", () => Results.Ok(new { status = "healthy", timestamp = DateTime.UtcNow }));

// CPU-intensive: Calculate Fibonacci number recursively
app.MapGet("/fibonacci/{n}", (int n) =>
{
    if (n < 0 || n > 45)
        return Results.BadRequest("Please provide n between 0 and 45");

    var result = Fibonacci(n);
    return Results.Ok(new { n, result, calculation = "fibonacci" });
});

// CPU-intensive: Find prime numbers up to n
app.MapGet("/prime/{n}", (int n) =>
{
    if (n < 2 || n > 1000000)
        return Results.BadRequest("Please provide n between 2 and 1000000");

    var primes = FindPrimes(n);
    return Results.Ok(new { limit = n, count = primes.Count, calculation = "primes" });
});

// CPU-intensive: Matrix multiplication
app.MapGet("/matrix/{size}", (int size) =>
{
    if (size < 2 || size > 500)
        return Results.BadRequest("Please provide size between 2 and 500");

    var duration = MatrixMultiply(size);
    return Results.Ok(new { size, duration = $"{duration}ms", calculation = "matrix" });
});

// CPU-intensive: Hash calculation
app.MapGet("/hash/{iterations}", (int iterations) =>
{
    if (iterations < 1 || iterations > 1000000)
        return Results.BadRequest("Please provide iterations between 1 and 1000000");

    var duration = CalculateHashes(iterations);
    return Results.Ok(new { iterations, duration = $"{duration}ms", calculation = "hash" });
});

app.Run();

// Helper methods for CPU-intensive operations
static long Fibonacci(int n)
{
    if (n <= 1) return n;
    return Fibonacci(n - 1) + Fibonacci(n - 2);
}

static List<int> FindPrimes(int limit)
{
    var primes = new List<int>();
    for (int i = 2; i <= limit; i++)
    {
        if (IsPrime(i))
            primes.Add(i);
    }
    return primes;
}

static bool IsPrime(int number)
{
    if (number <= 1) return false;
    if (number == 2) return true;
    if (number % 2 == 0) return false;

    var boundary = (int)Math.Floor(Math.Sqrt(number));
    for (int i = 3; i <= boundary; i += 2)
    {
        if (number % i == 0)
            return false;
    }
    return true;
}

static long MatrixMultiply(int size)
{
    var sw = System.Diagnostics.Stopwatch.StartNew();

    var a = new double[size, size];
    var b = new double[size, size];
    var c = new double[size, size];

    // Initialize matrices
    for (int i = 0; i < size; i++)
    {
        for (int j = 0; j < size; j++)
        {
            a[i, j] = i + j;
            b[i, j] = i - j;
        }
    }

    // Matrix multiplication
    for (int i = 0; i < size; i++)
    {
        for (int j = 0; j < size; j++)
        {
            double sum = 0;
            for (int k = 0; k < size; k++)
            {
                sum += a[i, k] * b[k, j];
            }
            c[i, j] = sum;
        }
    }

    sw.Stop();
    return sw.ElapsedMilliseconds;
}

static long CalculateHashes(int iterations)
{
    var sw = System.Diagnostics.Stopwatch.StartNew();

    using var sha256 = System.Security.Cryptography.SHA256.Create();
    for (int i = 0; i < iterations; i++)
    {
        var data = System.Text.Encoding.UTF8.GetBytes($"iteration-{i}");
        var hash = sha256.ComputeHash(data);
    }

    sw.Stop();
    return sw.ElapsedMilliseconds;
}