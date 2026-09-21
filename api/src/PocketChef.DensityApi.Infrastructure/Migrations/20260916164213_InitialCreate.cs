using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace PocketChef.DensityApi.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterDatabase()
                .Annotation("Npgsql:PostgresExtension:citext", ",,");

            migrationBuilder.CreateTable(
                name: "density_entries",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    IngredientName = table.Column<string>(type: "citext", nullable: false),
                    GramsPerCup = table.Column<double>(type: "double precision", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_density_entries", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_density_entries_IngredientName",
                table: "density_entries",
                column: "IngredientName",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "density_entries");
        }
    }
}
