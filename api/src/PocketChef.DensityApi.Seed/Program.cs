using System.Globalization;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using PocketChef.DensityApi.Application;
using PocketChef.DensityApi.Application.Seeding;
using PocketChef.DensityApi.Infrastructure;

// One-off import of UsdaSeedData into the density table (PLAN.md Phase 9.1). Safe to re-run:
// ingredients already in the table are reported and left alone (see DensitySeeder).
//
//   dotnet run --project src/PocketChef.DensityApi.Seed -- --connection "<connection string>"
//
// Without --connection it reads ConnectionStrings__DensityApi from the environment, the same
// variable the API host uses in production (docs/deploy.md §2).

var connectionString = ReadConnectionString(args);
if (connectionString is null)
{
    Console.Error.WriteLine("Pass --connection \"<connection string>\" or set ConnectionStrings__DensityApi.");
    return 2;
}

await using var services = new ServiceCollection()
    .AddDensityApiInfrastructure(connectionString)
    .BuildServiceProvider();
await using var scope = services.CreateAsyncScope();

// Migrations are a deliberate manual step (docs/deploy.md §5), so don't run them here, but
// don't seed a schema that's behind the model either.
var context = scope.ServiceProvider.GetRequiredService<DensityApiDbContext>();
var pending = (await context.Database.GetPendingMigrationsAsync()).ToList();
if (pending.Count > 0)
{
    Console.Error.WriteLine($"The database has {pending.Count} pending migration(s) ({string.Join(", ", pending)}). Run `dotnet ef database update` first.");
    return 1;
}

var seeder = new DensitySeeder(scope.ServiceProvider.GetRequiredService<IDensityEntryRepository>());
var result = await seeder.SeedAsync(UsdaSeedData.Rows, CancellationToken.None);

foreach (var entry in result.Inserted)
{
    Console.WriteLine(string.Create(CultureInfo.InvariantCulture, $"inserted  {entry.IngredientName}: {entry.GramsPerMilliliter:0.####} g/ml"));
}

foreach (var (row, existing) in result.Skipped)
{
    var note = existing.GramsPerMilliliter.Equals(row.GramsPerMilliliter)
        ? "same value"
        : string.Create(CultureInfo.InvariantCulture, $"kept {existing.GramsPerMilliliter:0.####} g/ml, seed has {row.GramsPerMilliliter:0.####}");
    Console.WriteLine($"exists    {existing.IngredientName} ({note})");
}

Console.WriteLine($"{result.Inserted.Count} inserted, {result.Skipped.Count} already present.");
return 0;

static string? ReadConnectionString(string[] args)
{
    var index = Array.IndexOf(args, "--connection");
    if (index >= 0 && index + 1 < args.Length)
    {
        return args[index + 1];
    }

    return Environment.GetEnvironmentVariable("ConnectionStrings__DensityApi");
}
